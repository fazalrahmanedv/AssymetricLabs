import CoreData
import Combine
import QuizRepo
protocol QuizAppRepository {
    func fetchAppsList() async throws -> [QuizRepo.Countries]
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
