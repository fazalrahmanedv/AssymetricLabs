import CoreData
import Combine
import QuizRepo
import UIKit

/// Abstraction for a repository that provides quiz and country data.
protocol QuizAppRepository {
    func fetchCountryList() async throws -> [Countries]
    func fetchQuizList() async throws -> [Quiz]
}

/// Repository implementation that fetches data from an API and Core Data.
class QuizAppRepositoryImpl: QuizAppRepository {
    private let apiManager: ApiManager
    private let coreDataStack: CoreDataStack

    init(apiManager: ApiManager = .shared, coreDataStack: CoreDataStack = .shared) {
        self.apiManager = apiManager
        self.coreDataStack = coreDataStack
    }

    // MARK: - Fetch Country List
    func fetchCountryList() async throws -> [Countries] {
        let savedCountries = await fetchSavedCountries()
        if !savedCountries.isEmpty {
            Logger.log("✅ Returning cached countries")
            return savedCountries
        }
        let result: Result<[Country], ApiManager.ApiError> = await apiManager.request(endPoint: .countriesList(method: .get))
        switch result {
        case .success(let countryList):
            try await saveCountriesToCoreData(countryList)
            return await fetchSavedCountries()
        case .failure(let error):
            Logger.log("❌ Failed to fetch countries: \(error)")
            throw error
        }
    }

    // MARK: - Fetch Quiz List
    func fetchQuizList() async throws -> [Quiz] {
        if !apiManager.isNetworkReachable {
            Logger.log("⚠️ No internet, using cached quizzes")
            return await fetchValidQuizzes()
        }
        let result: Result<[QuizResponse], ApiManager.ApiError> = await apiManager.request(endPoint: .quizList(method: .get))
        switch result {
        case .success(let quizList):
            try await saveQuizzesToCoreData(quizList)
            
            // Concurrently download images for quizzes and solutions.
            let imageQuizzes = await fetchImageQuizzes()
            let imageSolutions = await fetchImageSolutions()
            Logger.log("📷 Found \(imageQuizzes.count) quizzes & \(imageSolutions.count) solutions with images")
            
            await withTaskGroup(of: Void.self) { group in
                for quiz in imageQuizzes {
                    group.addTask { await self.cacheQuizImage(quiz) }
                }
                for solution in imageSolutions {
                    group.addTask { await self.cacheSolutionImage(solution) }
                }
            }
            return await fetchValidQuizzes()
        case .failure(let error):
            Logger.log("❌ Failed to fetch quizzes: \(error)")
            throw error
        }
    }

    // MARK: - Core Data Operations
    @MainActor
    private func saveCountriesToCoreData(_ countries: [Country]) async throws {
        let context = coreDataStack.backgroundContext
        
        if #available(iOS 15.0, *) {
            try await context.perform(schedule: .immediate) {
                countries.forEach { _ = Countries.from($0, context: context) }
                try context.save()
                Logger.log("✅ Countries saved to Core Data")
            }
        } else {
            try await withCheckedThrowingContinuation { continuation in
                context.perform {
                    do {
                        countries.forEach { _ = Countries.from($0, context: context) }
                        try context.save()
                        Logger.log("✅ Countries saved to Core Data")
                        continuation.resume()
                    } catch {
                        Logger.log("❌ Failed to save countries: \(error)")
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }
    @MainActor
    private func saveQuizzesToCoreData(_ quizzes: [QuizResponse]) async throws {
        let context = coreDataStack.backgroundContext
        await coreDataStack.deleteAllData(for: Quiz.self)
        await coreDataStack.deleteAllData(for: QuizSolution.self)
        
        if #available(iOS 15.0, *) {
            try await context.perform(schedule: .immediate) {
                quizzes.forEach { _ = Quiz.from($0, context: context) }
                try context.save()
                Logger.log("✅ Quizzes saved to Core Data")
            }
        } else {
            try await withCheckedThrowingContinuation { continuation in
                context.perform {
                    do {
                        quizzes.forEach { _ = Quiz.from($0, context: context) }
                        try context.save()
                        Logger.log("✅ Quizzes saved to Core Data")
                        continuation.resume()
                    } catch {
                        Logger.log("❌ Failed to save quizzes: \(error)")
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }
    private func fetchSavedCountries() async -> [Countries] {
        await coreDataStack.fetchEntities(
            ofType: Countries.self,
            sortDescriptors: [NSSortDescriptor(key: "name", ascending: true)]
        )
    }

    private func fetchImageQuizzes() async -> [Quiz] {
        await coreDataStack.fetchEntities(
            ofType: Quiz.self,
            predicate: NSPredicate(format: "questiionType == %@", "image")
        )
    }

    private func fetchImageSolutions() async -> [QuizSolution] {
        await coreDataStack.fetchEntities(
            ofType: QuizSolution.self,
            predicate: NSPredicate(format: "contentType == %@", "image")
        )
    }

    private func fetchValidQuizzes() async -> [Quiz] {
        let predicates: [NSPredicate] = [
            NSPredicate(format: "question != nil AND question != ''"),
            NSPredicate(format: "option1 != nil AND option1 != ''"),
            NSPredicate(format: "option2 != nil AND option2 != ''"),
            NSPredicate(format: "option3 != nil AND option3 != ''"),
            NSPredicate(format: "option4 != nil AND option4 != ''"),
            NSPredicate(format: "correctOption BETWEEN {0, 3}"),
            NSPredicate(format: "solution.contentData != nil AND solution.contentData != ''")
        ]
        return await coreDataStack.fetchEntities(ofType: Quiz.self, predicate: NSCompoundPredicate(andPredicateWithSubpredicates: predicates))
    }

    // MARK: - Image Download & Cache
    private func cacheQuizImage(_ quiz: Quiz) async {
        await cacheImage(urlString: quiz.question)
    }

    private func cacheSolutionImage(_ solution: QuizSolution) async {
        await cacheImage(urlString: solution.contentData)
    }

    private func cacheImage(urlString: String?) async {
        guard let urlString = urlString, let url = URL(string: urlString) else { return }
        if ImageCache.shared.image(forKey: urlString) != nil {
            Logger.log("✅ Cached: \(urlString)")
            return
        }
        do {
            let image = try await downloadAndCacheImage(from: url)
            ImageCache.shared.setImage(image, forKey: urlString)
        } catch {
            Logger.log("❌ Image download failed: \(error)")
        }
    }

    private func downloadAndCacheImage(from url: URL) async throws -> UIImage {
        let urlString = url.absoluteString
        if let cachedImage = ImageCache.shared.image(forKey: urlString) {
            return cachedImage
        }
        let request = URLRequest(url: url)
        if let cachedResponse = URLCache.shared.cachedResponse(for: request),
           let image = UIImage(data: cachedResponse.data) {
            ImageCache.shared.setImage(image, forKey: urlString)
            return image
        }
        Logger.log("⬇️ Downloading: \(urlString)")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let image = UIImage(data: data) else {
            throw URLError(.badServerResponse)
        }
        let cachedData = CachedURLResponse(response: response, data: data)
        URLCache.shared.storeCachedResponse(cachedData, for: request)
        ImageCache.shared.setImage(image, forKey: urlString)
        Logger.log("✅ Image cached: \(urlString)")
        return image
    }
}
import UIKit

/// In-memory image cache using NSCache.
public final class ImageCache {
    static let shared = ImageCache()
    private let cache = NSCache<NSString, UIImage>()

    private init() {
        cache.countLimit = 100
        cache.totalCostLimit = 50 * 1024 * 1024 // 50MB
    }

    func image(forKey key: String) -> UIImage? {
        cache.object(forKey: key as NSString)
    }

    func setImage(_ image: UIImage, forKey key: String) {
        let cost = image.pngData()?.count ?? 0
        cache.setObject(image, forKey: key as NSString, cost: cost)
    }
}
import Foundation

/// Utility for logging messages.
struct Logger {
    static func log(_ message: String) {
        print("[LOG] \(message)")
    }
}
extension Countries {
    /// Converts an API `Country` model into a `Countries` managed object.
    static func from(_ country: Country, context: NSManagedObjectContext) -> Countries {
        let countryEntity = Countries(context: context)
        countryEntity.id = country.id
        countryEntity.name = country.name.common
        countryEntity.flag = country.flag
        return countryEntity
    }
}
extension Quiz {
    /// Converts an API `QuizResponse` model into a `Quiz` managed object.
    static func from(_ quiz: QuizResponse, context: NSManagedObjectContext) -> Quiz {
        let quizEntity = Quiz(context: context)
        // Safely unwrap UUID string; adjust as needed for your model.
        if let uuidString = quiz.uuidIdentifier, let uuid = UUID(uuidString: uuidString) {
            quizEntity.uuidIdentifier = uuid
        }
        quizEntity.correctOption = Int16((quiz.correctOption ?? 0) - 1)
        quizEntity.option1 = quiz.option1
        quizEntity.option2 = quiz.option2
        quizEntity.option3 = quiz.option3
        quizEntity.option4 = quiz.option4
        quizEntity.question = quiz.question
        // Assume quiz.questionType is an enum with a rawValue of String.
        quizEntity.questiionType = quiz.questionType?.rawValue ?? "text"
        
        // Map solution if available.
        if let solutionResponse = quiz.solution?.first {
            let solutionEntity = QuizSolution(context: context)
            solutionEntity.contentData = solutionResponse.contentData
            solutionEntity.contentType = solutionResponse.contentType?.rawValue
            solutionEntity.ofQuiz = quizEntity
            quizEntity.solution = solutionEntity
        }
        
        return quizEntity
    }
}
