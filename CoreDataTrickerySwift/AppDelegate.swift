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
    
    var window: UIWindow?
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject : AnyObject]?) -> Bool {
        ToDoListConfiguration.defaultConfiguration(managedObjectContext).listMode = .Simple
        
        if let toDosController = (window?.rootViewController as? UINavigationController)?.topViewController as? ToDoViewController {
            toDosController.managedObjectContext = managedObjectContext
        }
        
        return true
    }
    
    func applicationDidEnterBackground(application: UIApplication) {
        saveContext()
    }
    
    func applicationWillTerminate(application: UIApplication) {
        saveContext()
    }
    
    func saveContext () {
        if !managedObjectContext.hasChanges {
            return
        }
        
        try! managedObjectContext.save()
    }
    
    // MARK: Core Data stack
    
    lazy var managedObjectContext: NSManagedObjectContext = {
        let context = NSManagedObjectContext()
        context.persistentStoreCoordinator = self.persistentStoreCoordinator
        return context
    }()
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        let modelURL = NSBundle.mainBundle().URLForResource("CoreDataTrickerySwift", withExtension: "momd")
        return NSManagedObjectModel(contentsOfURL: modelURL!)!
    }()
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        let storeURL = AppDelegate.applicationDocumentsDirectory.URLByAppendingPathComponent("CoreDataTrickerySwift.sqlite")
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let options = [NSMigratePersistentStoresAutomaticallyOption: true, NSInferMappingModelAutomaticallyOption: true]
        try! coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: storeURL, options: options)
        return coordinator
    }()
}

// MARK: Application's Documents directory

extension AppDelegate {
    
    class var applicationDocumentsDirectory: NSURL {
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls.last!
    }
}

