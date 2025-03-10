import CoreData
import Combine
import QuizRepo
import UIKit
protocol QuizAppRepository {
    func fetchCountryList() async throws -> [Countries]
    func fetchQuizList() async throws -> [Quiz]
}
class QuizAppRepositoryImpl: QuizAppRepository {
    private let apiManager: ApiManager
    private let coreDataStack: CoreDataStack
    init(apiManager: ApiManager = .shared, coreDataStack: CoreDataStack = .shared) {
        self.apiManager = apiManager
        self.coreDataStack = coreDataStack
    }
    // MARK: - Fetch Countries List
    func fetchCountryList() async throws -> [Countries] {
        let savedCountries = await fetchSavedCountries()
        if !savedCountries.isEmpty {
            Logger.log("✅ Returning countries from Core Data")
            return savedCountries
        }
        let result: Result<[Country], ApiManager.ApiError> = await apiManager.request(endPoint: .countriesList(method: .get))
        switch result {
        case .success(let countryList):
            try await saveCountriesToCoreData(countryList)
            return await fetchSavedCountries()
        case .failure(let error):
            throw error
        }
    }
    // MARK: - Fetch Quiz List
    func fetchQuizList() async throws -> [Quiz] {
        // In offline mode, return the cached quizzes filtered for validity
        let savedQuizzes = await fetchSavedQuizzes()
        if !apiManager.isNetworkReachable {
            Logger.log("❌ No internet connection, returning cached quizzes")
            return await fetchValidQuizzes()
        }
        
        let result: Result<[QuizResponse], ApiManager.ApiError> = await apiManager.request(endPoint: .quizList(method: .get))
        switch result {
        case .success(let quizList):
            try await saveQuizzesToCoreData(quizList)
            let allQuizzes = await fetchSavedQuizzes()
            let imageQuizzes = await fetchImageQuizzes()
            let imageSolutions = await fetchImageSolutions()
            Logger.log("✅ Fetched \(imageQuizzes.count) image quizzes and \(imageSolutions.count) image solutions")
            
            await withTaskGroup(of: Void.self) { group in
                for quiz in imageQuizzes {
                    group.addTask {
                        await self.downloadAndCacheImage(forQuiz: quiz)
                    }
                }
                for solution in imageSolutions {
                    group.addTask {
                        await self.downloadAndCacheImage(forSolution: solution)
                    }
                }
            }
            return  await fetchValidQuizzes()
            
        case .failure(let error):
            throw error
        }
    }
    // MARK: - Core Data Saving / Fetching
    @MainActor
    private func saveCountriesToCoreData(_ countries: [Country]) async throws {
        for country in countries {
            _ = Countries.from(country, context: coreDataStack.mainContext)
        }
        try coreDataStack.mainContext.save()
        Logger.log("✅ Countries saved to Core Data")
    }
    @MainActor
    private func saveQuizzesToCoreData(_ quizzes: [QuizResponse]) async throws {
        await coreDataStack.deleteAllData(for: Quiz.self)
        await coreDataStack.deleteAllData(for: QuizSolution.self)
        for quiz in quizzes {
            _ = Quiz.from(quiz, context: coreDataStack.mainContext)
        }
        try coreDataStack.mainContext.save()
        Logger.log("✅ Quizzes saved to Core Data")
    }
    private func fetchSavedCountries() async -> [Countries] {
        return await coreDataStack.fetchEntities(ofType: Countries.self, sortDescriptors: [NSSortDescriptor(key: "name", ascending: true)])
    }
    private func fetchSavedQuizzes() async -> [Quiz] {
        return await coreDataStack.fetchEntities(ofType: Quiz.self, fetchLimit: 20)
    }
    private func fetchImageQuizzes() async -> [Quiz] {
        let predicate = NSPredicate(format: "questiionType == %@", "image")
        return await coreDataStack.fetchEntities(ofType: Quiz.self, predicate: predicate )
    }
    private func fetchImageSolutions() async -> [QuizSolution] {
        let predicate = NSPredicate(format: "contentType == %@", "image")
        return await coreDataStack.fetchEntities(ofType: QuizSolution.self, predicate: predicate)
    }
    // MARK: - Downloading and Caching Images
    private func downloadAndCacheImage(from url: URL) async throws -> UIImage {
        let request = URLRequest(url: url)
        if let cachedResponse = URLCache.shared.cachedResponse(for: request),
           let image = UIImage(data: cachedResponse.data) {
            return image
        }
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let image = UIImage(data: data) else {
            throw URLError(.badServerResponse)
        }
        let cachedData = CachedURLResponse(response: response, data: data)
        URLCache.shared.storeCachedResponse(cachedData, for: request)
        return image
    }
    private func downloadAndCacheImage(forQuiz quiz: Quiz) async {
        guard let urlString = quiz.question, let url = URL(string: urlString) else { return }
        do {
            let image = try await downloadAndCacheImage(from: url)
            ImageCache.shared.setImage(image, forKey: urlString)
        } catch {
            Logger.log("❌ Failed to download image for quiz: \(error)")
        }
    }
    private func downloadAndCacheImage(forSolution solution: QuizSolution) async {
        guard let urlString = solution.contentData, let url = URL(string: urlString) else { return }
        do {
            let image = try await downloadAndCacheImage(from: url)
            ImageCache.shared.setImage(image, forKey: urlString)
        } catch {
            Logger.log("❌ Failed to download image for solution: \(error)")
        }
    }
    private func fetchValidQuizzes() async -> [Quiz] {
        let predicates: [NSPredicate] = [
            // Question should not be nil or empty
            NSPredicate(format: "question != nil AND question != ''"),
            // All 4 options must be provided and nonempty
            NSPredicate(format: "option1 != nil AND option1 != ''"),
            NSPredicate(format: "option2 != nil AND option2 != ''"),
            NSPredicate(format: "option3 != nil AND option3 != ''"),
            NSPredicate(format: "option4 != nil AND option4 != ''"),
            // Correct option should be between 1 and 4
            NSPredicate(format: "correctOption >= %d AND correctOption <= %d", 1, 4),
            // The related solution's contentData should not be nil or empty
            NSPredicate(format: "solution.contentData != nil AND solution.contentData != ''")
        ]
        let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        return await coreDataStack.fetchEntities(ofType: Quiz.self, predicate: compoundPredicate)
    }
}
// MARK: - Image Cache
public final class ImageCache {
    static let shared = ImageCache()
    private let cache = NSCache<NSString, UIImage>()
    private init() {
        cache.countLimit = 100
        cache.totalCostLimit = 50 * 1024 * 1024
    }
    func image(forKey key: String) -> UIImage? {
        return cache.object(forKey: key as NSString)
    }
    func setImage(_ image: UIImage, forKey key: String) {
        cache.setObject(image, forKey: key as NSString, cost: image.pngData()?.count ?? 0)
    }
}
// MARK: - Core Data Model Extensions
extension Quiz {
    static func from(_ quiz: QuizResponse, context: NSManagedObjectContext) -> Quiz {
        let entity = Quiz(context: context)
        entity.uuidIdentifier = UUID(uuidString: quiz.uuidIdentifier ?? "")
        entity.correctOption = Int16(quiz.correctOption ?? 0)
        entity.option1 = quiz.option1
        entity.option2 = quiz.option2
        entity.option3 = quiz.option3
        entity.option4 = quiz.option4
        entity.question = quiz.question
        entity.questiionType = quiz.questionType?.rawValue ?? "text"
        let solution = QuizSolution(context: context)
        solution.contentData = quiz.solution?.first?.contentData
        solution.contentType = quiz.solution?.first?.contentType?.rawValue
        solution.ofQuiz = entity
        entity.solution = solution
        return entity
    }
}
extension Countries {
    static func from(_ country: Country, context: NSManagedObjectContext) -> Countries {
        let entity = Countries(context: context)
        entity.id = country.id
        entity.name = country.name.common
        entity.flag = country.flag
        return entity
    }
}

// MARK: - Logger Utility
struct Logger {
    static func log(_ message: String) {
        print(message) // Replace with file logging if needed
    }
}
