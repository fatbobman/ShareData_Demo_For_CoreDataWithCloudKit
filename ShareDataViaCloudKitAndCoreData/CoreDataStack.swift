//
//  CoreDataStack.swift
//  CoreDataStack
//
//  Created by Yang Xu on 2021/9/9.
//

import CloudKit
import CoreData
import Foundation

final class CoreDataStack {
    static let shared = CoreDataStack()

    init() {}

    lazy var persistentContainer: NSPersistentCloudKitContainer = {
        let container = NSPersistentCloudKitContainer(name: "Model")

        let dbURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!

        let privateDesc = NSPersistentStoreDescription(url: dbURL.appendingPathComponent("model.sqlite"))
        privateDesc.configuration = "Private"
        privateDesc.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: ckContainerID)
        privateDesc.cloudKitContainerOptions?.databaseScope = .private

        guard let shareDesc = privateDesc.copy() as? NSPersistentStoreDescription else {
            fatalError("Create shareDesc error")
        }
        shareDesc.url = dbURL.appendingPathComponent("share.sqlite")
        let shareDescOption = NSPersistentCloudKitContainerOptions(containerIdentifier: ckContainerID)
        shareDescOption.databaseScope = .shared
        shareDesc.cloudKitContainerOptions = shareDescOption

        container.persistentStoreDescriptions = [privateDesc, shareDesc]

        container.loadPersistentStores(completionHandler: { desc, err in
            if let err = err as NSError? {
                fatalError("DB init error:\(err.localizedDescription)")
            } else if let cloudKitContiainerOptions = desc.cloudKitContainerOptions {
                switch cloudKitContiainerOptions.databaseScope {
                case .private:
                    self._privatePersistentStore = container.persistentStoreCoordinator.persistentStore(for: privateDesc.url!)
                case .shared:
                    self._sharedPersistentStore = container.persistentStoreCoordinator.persistentStore(for: shareDesc.url!)
                default:
                    break
                }
            }
        })

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        do {
            try container.viewContext.setQueryGenerationFrom(.current)
        } catch {
            fatalError("Fail to pin viewContext to the current generation:\(error)")
        }

        return container
    }()

    let ckContainerID = "iCloud.com.fatbobman.test.shareDB"

    var ckContainer: CKContainer {
        CKContainer(identifier: ckContainerID)
    }

    private var _privatePersistentStore: NSPersistentStore?
    var privatePersistentStore: NSPersistentStore {
        return _privatePersistentStore!
    }

    private var _sharedPersistentStore: NSPersistentStore?
    var sharedPersistentStore: NSPersistentStore {
        return _sharedPersistentStore!
    }

    var context: NSManagedObjectContext {
        persistentContainer.viewContext
    }
}

extension CoreDataStack {
    func isShared(objectID: NSManagedObjectID) -> Bool {
        var isShared = false
        if let persistentStore = objectID.persistentStore {
            if persistentStore == sharedPersistentStore {
                isShared = true
            } else {
                let container = persistentContainer
                do {
                    let shares = try container.fetchShares(matching: [objectID])
                    if shares.first != nil {
                        isShared = true
                    }
                } catch {
                    print("Failed to fetch share for \(objectID): \(error)")
                }
            }
        }
        return isShared
    }

    func isShared(object: NSManagedObject) -> Bool {
        isShared(objectID: object.objectID)
    }

    func canEdit(object: NSManagedObject) -> Bool {
        return persistentContainer.canUpdateRecord(forManagedObjectWith: object.objectID)
    }

    func canDelete(object: NSManagedObject) -> Bool {
        return persistentContainer.canDeleteRecord(forManagedObjectWith: object.objectID)
    }

    func isOwner(object:NSManagedObject) -> Bool{
        guard isShared(object: object) else {return false}
        guard let share = try? persistentContainer.fetchShares(matching: [object.objectID])[object.objectID] else {
            print("Get ckshare error")
            return false
        }
        if let currentUser = share.currentUserParticipant,currentUser == share.owner {
            return true
        }
        return false
    }

    func getShare(object:Note) -> CKShare?{
        guard isShared(object: object) else {return nil}
        guard let share = try? persistentContainer.fetchShares(matching: [object.objectID])[object.objectID] else {
            print("Get ckshare error")
            return nil
        }
        share[CKShare.SystemFieldKey.title] = object.name 
        return share
    }
}

extension CoreDataStack {
    func save() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("ViewContext save error:\(error)")
            }
        }
    }

    func addNote() {
        let note = Note(context: context)
        context.perform {
            note.name = "Note\(Int.random(in: 1000...2000))"
            note.timestamp = Date()
            self.save()
        }
    }

    func addMemo(_ note:Note) {
        let memo = Memo(context: context)
        context.perform {
            memo.note = note
            memo.text = Date().formatted()
            memo.timestamp = Date()
            self.save()
        }
    }

    func deleteNote(_ note:Note){
        context.perform {
            self.context.delete(note)
            self.save()
        }
    }

    func deleteMemo(_ memo:Memo){
        context.perform {
            self.context.delete(memo)
            self.save()
        }
    }

    func changeMemoText(_ memo:Memo) {
        context.perform {
            let text = memo.text ?? ""
            memo.text = text.appending(String(" \(Int.random(in: 0...9))"))
            self.save()
        }
    }
}
