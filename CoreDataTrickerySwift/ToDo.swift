//
//  ToDo.swift
//  CoreDataTrickerySwift
//
//  Created by Alek Astrom on 2014-07-17.
//  Copyright (c) 2014 Apps and Wonders. All rights reserved.
//

import Foundation
import CoreData

enum ToDoSection: Int {
    case ToDo = 10
    case HighPriority = 11
    case MediumPriority = 12
    case LowPriority = 13
    case Done = 20
    
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
    
    class func entityName() -> NSString {return "ToDo"}

    @NSManaged var title: String
    @NSManaged var done: NSNumber
    @NSManaged var priority: NSNumber
    @NSManaged var internalOrder: NSNumber
    @NSManaged var sectionIdentifier: NSString
    
    @NSManaged var listConfiguration: ToDoListConfiguration
    
    class func newToDoInContext(context: NSManagedObjectContext, configurationBlock: ((toDo: ToDo)->Void)) -> ToDo {
        
        var toDo = NSEntityDescription.insertNewObjectForEntityForName(entityName(), inManagedObjectContext: context) as ToDo
        
        configurationBlock(toDo: toDo)
        toDo.listConfiguration = ToDoListConfiguration.defaultConfiguration(context)
        toDo.updateSectionIdentifier()
        
        return toDo;
    }
    
    func updateSectionIdentifier() {
        sectionIdentifier = String(sectionForCurrentState().toRaw())
    }
    
    func sectionForCurrentState() -> ToDoSection {
        if done.boolValue {
            return .Done
        } else if ToDoListMode.fromRaw(listConfiguration.listMode) == ToDoListMode.Simple {
            return .ToDo
        } else {
            switch ToDoPriority.fromRaw(priority) as ToDoPriority {
            case .Low:      return .LowPriority
            case .Medium:   return .MediumPriority
            case .High:     return .HighPriority
            }
        }
    }
    
    class func maxInternalOrder(context: NSManagedObjectContext) -> Int {
        
        var maxInternalOrder = 0
        
        let maxInternalOrderExpression = NSExpression(forFunction: "max:", arguments: [NSExpression(forKeyPath: "internalOrder")])
        
        let expressionDescription = NSExpressionDescription()
        expressionDescription.name = "maxInternalOrder"
        expressionDescription.expression = maxInternalOrderExpression
        expressionDescription.expressionResultType = .Integer32AttributeType
        
        let fetchRequest = NSFetchRequest(entityName: entityName())
        fetchRequest.propertiesToFetch = [expressionDescription]
        fetchRequest.resultType = .DictionaryResultType
        
        let results = context.executeFetchRequest(fetchRequest, error: nil)
        if results.count > 0 {
            maxInternalOrder = results[0].valueForKey("maxInternalOrder").integerValue
        }
        
        return maxInternalOrder
    }
    
    func edit(configurationBlock: ((toDo: ToDo)->Void)) {
        configurationBlock(toDo: self)
        updateSectionIdentifier()
    }

}

enum ToDoListMode: Int {
    case Simple = 1
    case Prioritized = 2
}

@objc(ToDoListConfiguration)
class ToDoListConfiguration: NSManagedObject {
    
    @NSManaged private var listMode: NSNumber
    @NSManaged var toDos: NSSet
    
    class func entityName() -> NSString {return "ToDoListConfiguration"}
    
    class func defaultConfiguration(context: NSManagedObjectContext) -> ToDoListConfiguration {
        
        let fetchRequest = NSFetchRequest(entityName: entityName())
        let results = context.executeFetchRequest(fetchRequest, error: nil) as [ToDoListConfiguration]
        
        if results.count > 0 {
            return results[0]
        } else {
            return NSEntityDescription.insertNewObjectForEntityForName(entityName(), inManagedObjectContext: context) as ToDoListConfiguration
        }
    }
    
    func setListMode(mode: ToDoListMode) {
        listMode = mode.toRaw()
        for toDo in toDos.allObjects as [ToDo] {
            toDo.updateSectionIdentifier()
        }
    }

    func sectionsForCurrentConfiguration() -> [ToDoSection] {
        switch ToDoListMode.fromRaw(listMode)! {
        case .Simple:
            return [.ToDo, .Done]
        case .Prioritized:
            return [.HighPriority, .MediumPriority, .LowPriority, .Done]
        }
    }
}
