//
//  AppDelegate.swift
//  CoreDataTrickerySwift
//
//  Created by Alek Astrom on 2014-07-16.
//  Copyright (c) 2014 Apps and Wonders. All rights reserved.
//

import UIKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
                            
    var window: UIWindow!

    func application(application: UIApplication!, didFinishLaunchingWithOptions launchOptions: NSDictionary!) -> Bool {
        
            ToDoListConfiguration.defaultConfiguration(managedObjectContext).listMode = .Simple
        
        if let toDosController = (window.rootViewController as? UINavigationController)?.topViewController as? ToDoViewController {
            toDosController.managedObjectContext = managedObjectContext
        }
        
        return true
    }
    
    func applicationDidEnterBackground(application: UIApplication!) {
        self.saveContext()
    }
    
    func applicationWillTerminate(application: UIApplication!) {
        self.saveContext()
    }
    
    func saveContext () {
        var error: NSError? = nil
        if self.managedObjectContext.hasChanges && !self.managedObjectContext.save(&error) {
            abort()
        }
    }

    // #pragma mark - Core Data stack

    // Returns the managed object context for the application.
    // If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
    var managedObjectContext: NSManagedObjectContext {
        if _managedObjectContext == nil {
            _managedObjectContext = NSManagedObjectContext()
            _managedObjectContext!.persistentStoreCoordinator = self.persistentStoreCoordinator
        }
        return _managedObjectContext!
    }
    var _managedObjectContext: NSManagedObjectContext? = nil

    // Returns the managed object model for the application.
    // If the model doesn't already exist, it is created from the application's model.
    var managedObjectModel: NSManagedObjectModel {
        if _managedObjectModel == nil {
            let modelURL = NSBundle.mainBundle().URLForResource("CoreDataTrickerySwift", withExtension: "momd")
            _managedObjectModel = NSManagedObjectModel(contentsOfURL: modelURL!)
        }
        return _managedObjectModel!
    }
    var _managedObjectModel: NSManagedObjectModel? = nil

    // Returns the persistent store coordinator for the application.
    // If the coordinator doesn't already exist, it is created and the application's store added to it.
    var persistentStoreCoordinator: NSPersistentStoreCoordinator {
        if _persistentStoreCoordinator == nil {
            let storeURL = self.applicationDocumentsDirectory.URLByAppendingPathComponent("CoreDataTrickerySwift.sqlite")
            var error: NSError? = nil
            _persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
            let options = [NSMigratePersistentStoresAutomaticallyOption: true, NSInferMappingModelAutomaticallyOption: true]
            if _persistentStoreCoordinator!.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: storeURL, options: options, error: &error) == nil {
                abort()
            }
        }
        return _persistentStoreCoordinator!
    }
    var _persistentStoreCoordinator: NSPersistentStoreCoordinator? = nil

    // #pragma mark - Application's Documents directory
                                    
    // Returns the URL to the application's Documents directory.
    var applicationDocumentsDirectory: NSURL {
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls[urls.count-1] as NSURL
    }

}

