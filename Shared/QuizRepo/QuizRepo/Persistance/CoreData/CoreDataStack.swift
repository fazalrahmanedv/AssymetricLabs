import CoreData
public class CoreDataStack {
    // Singleton instance
    public static let shared = CoreDataStack()
    // NSPersistentContainer
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
    // Reuse a single background context to avoid memory issues
     public lazy var backgroundContext: NSManagedObjectContext = {
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
    // MARK: - Delete All Data
    public func deleteAllData<T: NSManagedObject>(for entityType: T.Type) {
        backgroundContext.perform { [weak self] in
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
    public func fetchEntities<T: NSManagedObject>(
        ofType entityType: T.Type,
        predicate: NSPredicate? = nil,
        sortDescriptors: [NSSortDescriptor]? = nil,
        fetchLimit: Int? = nil,
        fetchOffset: Int? = nil,
        context: NSManagedObjectContext? = nil
    ) async -> [T] {
        let context = context ?? backgroundContext

        if #available(iOS 15.0, *) {
            return await context.perform {
                self.executeFetch(entityType, predicate, sortDescriptors, fetchLimit, fetchOffset, in: context)
            }
        } else {
            return await withCheckedContinuation { continuation in
                context.perform {
                    let results = self.executeFetch(entityType, predicate, sortDescriptors, fetchLimit, fetchOffset, in: context)
                    continuation.resume(returning: results)
                }
            }
        }
    }
    // MARK: - Extracted Fetch Logic
    private func executeFetch<T: NSManagedObject>(
        _ entityType: T.Type,
        _ predicate: NSPredicate?,
        _ sortDescriptors: [NSSortDescriptor]?,
        _ fetchLimit: Int?,
        _ fetchOffset: Int?,
        in context: NSManagedObjectContext
    ) -> [T] {
        let fetchRequest = NSFetchRequest<T>(entityName: String(describing: entityType))
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = sortDescriptors
        if let fetchLimit = fetchLimit {
            fetchRequest.fetchLimit = fetchLimit
        }
        if let fetchOffset = fetchOffset {
            fetchRequest.fetchOffset = fetchOffset
        }
        do {
            let results = try context.fetch(fetchRequest)
            return results
        } catch {
            print("❌ Failed to fetch \(String(describing: entityType)): \(error.localizedDescription)")
            return []
        }
    }
}
