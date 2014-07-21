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
    case ToDo = 1
    case Done = 2
    
    func title() -> String {
        switch self {
        case ToDo:
            return "Left to do"
        case Done:
            return "Done"
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
    
    class func entityName()->NSString {return "ToDo"}

    @NSManaged var title: String
    @NSManaged var due: NSDate?
    @NSManaged var done: NSNumber
    @NSManaged var priority: NSNumber
    @NSManaged var internalOrder: NSNumber
    @NSManaged var sectionIdentifier: NSString
    
    class func newToDoInContext(context: NSManagedObjectContext, configurationBlock: ((toDo: ToDo)->Void)) -> ToDo {
        
        var toDo = NSEntityDescription.insertNewObjectForEntityForName(entityName(), inManagedObjectContext: context) as ToDo
        
        configurationBlock(toDo: toDo)
        toDo.sectionIdentifier = String(toDo.sectionForCurrentState().toRaw())
        
        return toDo;
    }
    
    func sectionForCurrentState() -> ToDoSection {
        if done.boolValue {
            return ToDoSection.Done
        } else {
            return ToDoSection.ToDo
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
        self.sectionIdentifier = String(self.sectionForCurrentState().toRaw())
    }

}
