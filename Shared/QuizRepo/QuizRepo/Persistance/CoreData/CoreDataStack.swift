import CoreData
public class CoreDataStack {
    // MARK: - Singleton instance
    public static let shared = CoreDataStack()
    // MARK: - NSPersistentContainer
    public let persistentContainer: NSPersistentContainer
    private init() {
        persistentContainer = NSPersistentContainer(name: "QuizApp")
        persistentContainer.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                fatalError("Failed to load persistent store: \(error), \(error.userInfo)")
            } else {
                print("✅ Persistent store loaded: \(storeDescription)")
            }
        }
        let context = persistentContainer.viewContext
        context.automaticallyMergesChangesFromParent = true
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        context.undoManager = nil
        context.shouldDeleteInaccessibleFaults = false
    }
    @MainActor
    public var mainContext: NSManagedObjectContext {
        persistentContainer.viewContext
    }
    // ✅ Reuse a single background context to avoid memory issues
    private lazy var backgroundContext: NSManagedObjectContext = {
        let context = persistentContainer.newBackgroundContext()
        context.automaticallyMergesChangesFromParent = true
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }()
    // MARK: - Save Context
    @MainActor
    public func saveContext() {
        guard mainContext.hasChanges else { return }
        do {
            try mainContext.save()
        } catch {
            print("❌ Failed to save main context: \(error.localizedDescription)")
        }
    }
    public func deleteAllData<T: NSManagedObject>(for entityType: T.Type) async {
        await backgroundContext.perform { [weak self] in
            guard let self = self else { return }
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: String(describing: entityType))
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            do {
                try self.backgroundContext.execute(deleteRequest)
                try self.backgroundContext.save()
                print("✅ Successfully deleted all data for \(String(describing: entityType)) in background")
            } catch {
                print("❌ Failed to delete all data for \(String(describing: entityType)): \(error.localizedDescription)")
            }
        }
    }
}
