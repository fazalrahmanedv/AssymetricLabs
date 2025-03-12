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

            // Fetch required data
            let imageQuizzes = await fetchImageQuizzes()
            let imageSolutions = await fetchImageSolutions()

            Logger.log("📷 Found \(imageQuizzes.count) quizzes & \(imageSolutions.count) solutions with images")

            // Concurrent Image Downloads
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
        try await context.perform {
            countries.forEach { _ = Countries.from($0, context: context) }
            try context.save()
        }
        Logger.log("✅ Countries saved to Core Data")
    }

    @MainActor
    private func saveQuizzesToCoreData(_ quizzes: [QuizResponse]) async throws {
        let context = coreDataStack.backgroundContext
        await coreDataStack.deleteAllData(for: Quiz.self)
        await coreDataStack.deleteAllData(for: QuizSolution.self)

        try await context.perform {
            quizzes.forEach { _ = Quiz.from($0, context: context) }
            try context.save()
        }
        Logger.log("✅ Quizzes saved to Core Data")
    }

    private func fetchSavedCountries() async -> [Countries] {
        return await coreDataStack.fetchEntities(
            ofType: Countries.self,
            sortDescriptors: [NSSortDescriptor(key: "name", ascending: true)]
        )
    }

    private func fetchImageQuizzes() async -> [Quiz] {
        return await coreDataStack.fetchEntities(
            ofType: Quiz.self,
            predicate: NSPredicate(format: "questiionType == %@", "image")
        )
    }

    private func fetchImageSolutions() async -> [QuizSolution] {
        return await coreDataStack.fetchEntities(
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

// MARK: - Image Cache
public final class ImageCache {
    static let shared = ImageCache()
    private let cache = NSCache<NSString, UIImage>()

    private init() {
        cache.countLimit = 100
        cache.totalCostLimit = 50 * 1024 * 1024 // 50MB
    }

    func image(forKey key: String) -> UIImage? {
        return cache.object(forKey: key as NSString)
    }

    func setImage(_ image: UIImage, forKey key: String) {
        cache.setObject(image, forKey: key as NSString, cost: image.pngData()?.count ?? 0)
    }
}
struct Logger {
    static func log(_ message: String) {
        print("[LOG] \(message)") // Replace with file logging if needed
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
extension Quiz {
    static func from(_ quiz: QuizResponse, context: NSManagedObjectContext) -> Quiz {
        let entity = Quiz(context: context)
        entity.uuidIdentifier = UUID(uuidString: quiz.uuidIdentifier ?? "")
        entity.correctOption = Int16(quiz.correctOption ?? 0) - 1
        entity.option1 = quiz.option1
        entity.option2 = quiz.option2
        entity.option3 = quiz.option3
        entity.option4 = quiz.option4
        entity.question = quiz.question
        entity.questiionType = quiz.questionType?.rawValue ?? "text"

        // Create and assign a QuizSolution entity
        let solution = QuizSolution(context: context)
        solution.contentData = quiz.solution?.first?.contentData
        solution.contentType = quiz.solution?.first?.contentType?.rawValue
        solution.ofQuiz = entity
        entity.solution = solution

        return entity
    }
}
