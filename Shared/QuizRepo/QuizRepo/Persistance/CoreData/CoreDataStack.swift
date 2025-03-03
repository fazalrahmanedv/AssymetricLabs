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
                print("Persistent store loaded: \(storeDescription)")
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
    private lazy var privateContext: NSManagedObjectContext = {
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
            print("Failed to save main context: \(error.localizedDescription)")
        }
    }
}
