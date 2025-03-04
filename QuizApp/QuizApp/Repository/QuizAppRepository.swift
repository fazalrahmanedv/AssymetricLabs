import CoreData
import Combine
import QuizRepo
import UIKit
protocol QuizAppRepository {
    func fetchAppsList() async throws -> [QuizRepo.Countries]
    func fetchQuizList() async throws -> [QuizRepo.Quiz]
}

class QuizAppRepositoryImpl: QuizAppRepository {
    private let apiManager = ApiManager.shared
    private let coreDataStack = CoreDataStack.shared
    
    func fetchAppsList() async throws -> [QuizRepo.Countries] {
        let savedCountries = await fetchSavedCountries(context: coreDataStack.mainContext)
        if !savedCountries.isEmpty {
            print("✅ Returning countries from Core Data")
            return savedCountries
        }
        let result: Result<[Country], ApiManager.ApiError> = await apiManager.request(endPoint: .countriesList(method: .get))
        switch result {
        case .success(let countryList):
            await saveCountriesToCoreData(countryList, context: coreDataStack.mainContext)
            let savedCountries = await fetchSavedCountries(context: coreDataStack.mainContext)
            return savedCountries
        case .failure(let error):
            throw error
        }
    }
    
    func fetchQuizList() async throws -> [QuizRepo.Quiz] {
        let savedQuizzes = await fetchSavedQuizzes(context: coreDataStack.mainContext)
        if !apiManager.isNetworkReachable {
            if !savedQuizzes.isEmpty {
                print("✅ Returning quizzes from Core Data")
                return savedQuizzes
            } else {
                return []
            }
        }
        
        let result: Result<[QuizResponse], ApiManager.ApiError> = await apiManager.request(endPoint: .quizList(method: .get))
        switch result {
        case .success(let quizList):
            // Save quizzes to Core Data
            await self.saveQuizzesToCoreData(quizList, context: self.coreDataStack.mainContext)
            // Fetch all quizzes
            let allQuizzes = await fetchSavedQuizzes(context: self.coreDataStack.mainContext)
            // Fetch quizzes with questiionType "image"
            let imageQuizzes = await self.fetchImageQuizzes(context: self.coreDataStack.mainContext)
            print("Fetched \(imageQuizzes.count) image quizzes")
            
            // For each image quiz, download and cache its image concurrently
            await withTaskGroup(of: Void.self) { group in
                for quiz in imageQuizzes {
                    group.addTask {
                        await self.downloadAndCacheImage(forQuiz: quiz)
                    }
                }
            }
            
            return allQuizzes
        case .failure(let error):
            throw error
        }
    }
    
    // MARK: - Core Data Saving / Fetching
    
    private func saveCountriesToCoreData(_ countries: [Country], context: NSManagedObjectContext) async {
        await context.perform {
            for country in countries {
                _ = QuizRepo.Countries.from(country, context: context)
            }
            do {
                try context.save()
                print("✅ Countries saved to Core Data")
            } catch {
                print("❌ Failed to save countries: \(error)")
            }
        }
    }
    
    private func saveQuizzesToCoreData(_ quizzes: [QuizResponse], context: NSManagedObjectContext) async {
        await self.coreDataStack.deleteAllData(for: Quiz.self)
        await context.perform {
            for quiz in quizzes {
                _ = QuizRepo.Quiz.from(quiz, context: context)
            }
            do {
                try context.save()
                print("✅ Quizzes saved to Core Data")
            } catch {
                print("❌ Failed to save quizzes: \(error)")
            }
        }
    }
    
    private func fetchSavedCountries(context: NSManagedObjectContext) -> [QuizRepo.Countries] {
        let request: NSFetchRequest<QuizRepo.Countries> = QuizRepo.Countries.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "name", ascending: true)
        request.sortDescriptors = [sortDescriptor]
        do {
            return try context.fetch(request)
        } catch {
            print("❌ Failed to fetch countries: \(error)")
            return []
        }
    }
    
    private func fetchSavedQuizzes(context: NSManagedObjectContext) -> [QuizRepo.Quiz] {
        let request: NSFetchRequest<QuizRepo.Quiz> = QuizRepo.Quiz.fetchRequest()
        do {
            return try context.fetch(request)
        } catch {
            print("❌ Failed to fetch quizzes: \(error)")
            return []
        }
    }
    
    private func fetchImageQuizzes(context: NSManagedObjectContext) async -> [QuizRepo.Quiz] {
        await withCheckedContinuation { continuation in
            context.perform {
                let request: NSFetchRequest<QuizRepo.Quiz> = QuizRepo.Quiz.fetchRequest()
                request.predicate = NSPredicate(format: "questiionType == %@", "image")
                do {
                    let imageQuizzes = try context.fetch(request)
                    print("✅ Fetched \(imageQuizzes.count) image quizzes")
                    continuation.resume(returning: imageQuizzes)
                } catch {
                    print("❌ Failed to fetch image quizzes: \(error)")
                    continuation.resume(returning: [])
                }
            }
        }
    }
    
    // MARK: - Downloading and Caching Images
    
    private func downloadAndCacheImage(forQuiz quiz: QuizRepo.Quiz) async {
        guard let urlString = quiz.question, let url = URL(string: urlString) else {
            print("Invalid URL for quiz \(quiz)")
            return
        }
        // Check if image is already cached
        if let _ = ImageCache.shared.image(forKey: urlString) {
            return
        }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let image = UIImage(data: data) {
                // Cache in memory
                ImageCache.shared.setImage(image, forKey: urlString)
                // Save to disk
                saveImageToDisk(image, withFilename: url.lastPathComponent)
                print("Downloaded and cached image for quiz \(quiz)")
            }
        } catch {
            print("❌ Failed to download image for quiz \(quiz): \(error)")
        }
    }
    
    private func saveImageToDisk(_ image: UIImage, withFilename filename: String) {
        guard let data = image.jpegData(compressionQuality: 1.0) else { return }
        let fileManager = FileManager.default
        do {
            let cachesDirectory = try fileManager.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            let fileURL = cachesDirectory.appendingPathComponent(filename)
            try data.write(to: fileURL)
            print("Saved image to disk: \(fileURL.path)")
        } catch {
            print("❌ Error saving image to disk: \(error)")
        }
    }
}

// MARK: - Simple In-Memory Image Cache

class ImageCache {
    static let shared = ImageCache()
    private init() {}
    
    private let cache = NSCache<NSString, UIImage>()
    
    func image(forKey key: String) -> UIImage? {
        return cache.object(forKey: NSString(string: key))
    }
    
    func setImage(_ image: UIImage, forKey key: String) {
        cache.setObject(image, forKey: NSString(string: key))
    }
}

// MARK: - Core Data Model Extensions

extension QuizRepo.Quiz {
    static func from(_ quiz: QuizResponse, context: NSManagedObjectContext) -> QuizRepo.Quiz {
        let entity = QuizRepo.Quiz(context: context)
        entity.uuidIdentifier  = UUID(uuidString: quiz.uuidIdentifier ?? "")
        entity.correctOption = Int16(quiz.correctOption ?? 0)
        entity.option1  = quiz.option1
        entity.option2 = quiz.option2
        entity.option3  = quiz.option3
        entity.option4  = quiz.option4
        entity.question = quiz.question
        entity.questiionType = quiz.questionType?.rawValue ?? "text"
        let solution = QuizRepo.QuizSolution(context: context)
        solution.contentData = quiz.solution?.first?.contentData
        solution.contentType = quiz.solution?.first?.contentType?.rawValue ?? "text"
        solution.isDownloaded = false
        solution.ofQuiz = entity
        entity.solution =  solution
        entity.sort  =   Int16(quiz.sort ?? 0)
        entity.hasSkipped   = false
        entity.hasAnswered = false
        entity.hasBookmarked = false
        entity.selectedOption = 0
        return entity
    }
}

extension QuizRepo.Countries {
    static func from(_ country: Country, context: NSManagedObjectContext) -> QuizRepo.Countries {
        let entity = QuizRepo.Countries(context: context)
        entity.id = country.id
        entity.name = country.name.common
        entity.flag = country.flag
        return entity
    }
}
