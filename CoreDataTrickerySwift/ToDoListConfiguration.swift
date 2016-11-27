//
//  ToDoListConfiguration.swift
//  CoreDataTrickerySwift
//
//  Created by Alek Åström on 2015-09-13.
//  Copyright © 2015 Apps and Wonders. All rights reserved.
//

import CoreData

enum ToDoListMode: Int {
    case simple = 0
    case prioritized = 1
}

@objc(ToDoListConfiguration)
class ToDoListConfiguration: NSManagedObject {
    class var entityName: String {
        return "ToDoListConfiguration"
    }
    
    @NSManaged fileprivate var listModeValue: Int
    @NSManaged var toDoMetaData: NSSet
    
    var listMode: ToDoListMode {
        get {
            return ToDoListMode(rawValue: listModeValue)!
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
        case .simple:
            return [.ToDo, .Done]
        case .prioritized:
            return [.HighPriority, .MediumPriority, .LowPriority, .Done]
        }
    }
}

//
// MARK: Class functions
//

extension ToDoListConfiguration {
    class func defaultConfiguration(_ context: NSManagedObjectContext) -> ToDoListConfiguration {
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        let configurations = try! context.fetch(fetchRequest)
        return configurations.first as? ToDoListConfiguration ?? NSEntityDescription.insertNewObject(forEntityName: entityName, into: context) as! ToDoListConfiguration
    }
}
