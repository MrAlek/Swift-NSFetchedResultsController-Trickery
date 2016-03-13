//
//  ToDoListConfiguration.swift
//  CoreDataTrickerySwift
//
//  Created by Alek Åström on 2015-09-13.
//  Copyright © 2015 Apps and Wonders. All rights reserved.
//

import CoreData

enum ToDoListMode: Int {
    case Simple = 0
    case Prioritized = 1
}

@objc(ToDoListConfiguration)
class ToDoListConfiguration: NSManagedObject {
    class var entityName: String {
        return "ToDoListConfiguration"
    }
    
    @NSManaged private var listModeValue: NSNumber
    @NSManaged var toDoMetaData: NSSet
    
    var listMode: ToDoListMode {
        get {
            return ToDoListMode(rawValue: listModeValue.integerValue)!
        }
        set {
            guard newValue != listMode else { return }
            
            listModeValue = newValue.rawValue
            for metaData in toDoMetaData.allObjects as! [ToDoMetaData] {
                metaData.updateSectionIdentifier()
            }
        }
    }
    
    var sections: [ToDoSection] {
        switch listMode {
        case .Simple:
            return [.ToDo, .Done]
        case .Prioritized:
            return [.HighPriority, .MediumPriority, .LowPriority, .Done]
        }
    }
}

//
// MARK: Class functions
//

extension ToDoListConfiguration {
    class func defaultConfiguration(context: NSManagedObjectContext) -> ToDoListConfiguration {
        
        let fetchRequest = NSFetchRequest(entityName: entityName)
        let configurations = try! context.executeFetchRequest(fetchRequest)
        return configurations.first as? ToDoListConfiguration ?? NSEntityDescription.insertNewObjectForEntityForName(entityName, inManagedObjectContext: context) as! ToDoListConfiguration
    }
}
