//
//  ToDo.swift
//  CoreDataTrickerySwift
//
//  Created by Alek Astrom on 2014-07-17.
//  Copyright (c) 2014 Apps and Wonders. All rights reserved.
//

import Foundation
import CoreData

enum ToDoSection: String {
    case ToDo = "10"
    case HighPriority = "11"
    case MediumPriority = "12"
    case LowPriority = "13"
    case Done = "20"
    
    func title() -> String {
        switch self {
        case ToDo:              return "Left to do"
        case Done:              return "Done"
        case HighPriority:      return "High priority"
        case MediumPriority:    return "Medium priority"
        case LowPriority:       return "Low priority"
        }
    }
}

enum ToDoPriority: Int {
    case Low = 1
    case Medium = 2
    case High = 3
}

@objc(ToDo)
class ToDo: NSManagedObject {
    class var entityName: NSString {return "ToDo"}

    @NSManaged var title: String
    @NSManaged var done: NSNumber
    @NSManaged var priority: NSNumber
    @NSManaged var metaData: ToDoMetaData
    
    override func awakeFromInsert() {
        super.awakeFromInsert()
        metaData = NSEntityDescription.insertNewObjectForEntityForName(ToDoMetaData.entityName, inManagedObjectContext: managedObjectContext!) as ToDoMetaData
    }
}

@objc(ToDoMetaData)
class ToDoMetaData: NSManagedObject {
    class var entityName: NSString {return "ToDoMetaData"}

    @NSManaged var internalOrder: NSNumber
    @NSManaged var sectionIdentifier: NSString
    @NSManaged var toDo: ToDo
    @NSManaged var listConfiguration: ToDoListConfiguration

    class func maxInternalOrder(context: NSManagedObjectContext) -> Int {
        
        let maxInternalOrderExpression = NSExpression(forFunction: "max:", arguments: [NSExpression(forKeyPath: "internalOrder")])
        
        let expressionDescription = NSExpressionDescription()
        expressionDescription.name = "maxInternalOrder"
        expressionDescription.expression = maxInternalOrderExpression
        expressionDescription.expressionResultType = .Integer32AttributeType
        
        let fetchRequest = NSFetchRequest(entityName: entityName)
        fetchRequest.propertiesToFetch = [expressionDescription]
        fetchRequest.resultType = .DictionaryResultType
        
        if let results = context.executeFetchRequest(fetchRequest, error: nil){
            if results.count > 0 {
                return results[0].valueForKey("maxInternalOrder") as Int
            }
        }
        
        return 0
    }
    
    override func awakeFromInsert() {
        super.awakeFromInsert()
        listConfiguration = ToDoListConfiguration.defaultConfiguration(managedObjectContext!)
    }

    func setSection(section: ToDoSection) {
        switch section {
        case .ToDo:
            toDo.done = false
        case .Done:
            toDo.done = true
        case .HighPriority:
            toDo.done = false
            toDo.priority = ToDoPriority.High.rawValue
        case .MediumPriority:
            toDo.done = false
            toDo.priority = ToDoPriority.Medium.rawValue
        case .LowPriority:
            toDo.done = false
            toDo.priority = ToDoPriority.Low.rawValue
        }
        sectionIdentifier = section.rawValue
    }
    
    func updateSectionIdentifier() {
        sectionIdentifier = sectionForCurrentState().rawValue
    }
    
    private func sectionForCurrentState() -> ToDoSection {
        if toDo.done.boolValue {
            return .Done
        } else if listConfiguration.listMode == ToDoListMode.Simple {
            return .ToDo
        } else {
            switch ToDoPriority(rawValue: toDo.priority.integerValue)! {
            case .Low:      return .LowPriority
            case .Medium:   return .MediumPriority
            case .High:     return .HighPriority
            }
        }
    }
}

enum ToDoListMode: Int {
    case Simple = 1
    case Prioritized = 2
}

@objc(ToDoListConfiguration)
class ToDoListConfiguration: NSManagedObject {
    class var entityName: NSString {return "ToDoListConfiguration"}
    
    @NSManaged private var listModeValue: NSNumber
    @NSManaged var toDoMetaData: NSSet
    
    var listMode: ToDoListMode {
        get {
            return ToDoListMode(rawValue: listModeValue.integerValue)!
        }
        set {
            listModeValue = newValue.rawValue
            for metaData in toDoMetaData.allObjects as [ToDoMetaData] {
                metaData.updateSectionIdentifier()
            }
        }
    }
    
    class func defaultConfiguration(context: NSManagedObjectContext) -> ToDoListConfiguration {
        
        let fetchRequest = NSFetchRequest(entityName: entityName)
        let results = context.executeFetchRequest(fetchRequest, error: nil) as [ToDoListConfiguration]
        
        if results.count > 0 {
            return results[0]
        } else {
            return NSEntityDescription.insertNewObjectForEntityForName(entityName, inManagedObjectContext: context) as ToDoListConfiguration
        }
    }

    func sectionsForCurrentConfiguration() -> [ToDoSection] {
        switch listMode {
        case .Simple:
            return [.ToDo, .Done]
        case .Prioritized:
            return [.HighPriority, .MediumPriority, .LowPriority, .Done]
        }
    }
}
