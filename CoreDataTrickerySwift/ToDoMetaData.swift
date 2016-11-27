//
//  ToDoMetaData.swift
//  CoreDataTrickerySwift
//
//  Created by Alek Åström on 2015-09-13.
//  Copyright © 2015 Apps and Wonders. All rights reserved.
//

import CoreData

@objc(ToDoMetaData)
class ToDoMetaData: NSManagedObject {
    
    @NSManaged var internalOrder: Int
    @NSManaged var sectionIdentifier: String
    @NSManaged var toDo: ToDo
    @NSManaged var listConfiguration: ToDoListConfiguration
    
    override func awakeFromInsert() {
        super.awakeFromInsert()
        listConfiguration = ToDoListConfiguration.defaultConfiguration(managedObjectContext!)
    }
    
    func updateSectionIdentifier() {
        sectionIdentifier = sectionForCurrentState().rawValue
    }
    
    func setSection(_ section: ToDoSection) {
        switch section {
        case .ToDo:
            toDo.done = false
        case .Done:
            toDo.done = true
        case .HighPriority:
            toDo.done = false
            toDo.priority = ToDoPriority.high.rawValue
        case .MediumPriority:
            toDo.done = false
            toDo.priority = ToDoPriority.medium.rawValue
        case .LowPriority:
            toDo.done = false
            toDo.priority = ToDoPriority.low.rawValue
        }
        sectionIdentifier = section.rawValue
    }
    
    fileprivate func sectionForCurrentState() -> ToDoSection {
        if toDo.done {
            return .Done
        } else if listConfiguration.listMode == ToDoListMode.simple {
            return .ToDo
        } else {
            switch ToDoPriority(rawValue: toDo.priority)! {
            case .low:      return .LowPriority
            case .medium:   return .MediumPriority
            case .high:     return .HighPriority
            }
        }
    }
}

//
// MARK: Class functions
//

extension ToDoMetaData {
    class var entityName: String {
        return "ToDoMetaData"
    }
    
    class func maxInternalOrder(_ context: NSManagedObjectContext) -> Int {
        
        let maxInternalOrderExpression = NSExpression(forFunction: "max:", arguments: [NSExpression(forKeyPath: "internalOrder")])
        
        let expressionDescription = NSExpressionDescription()
        expressionDescription.name = "maxInternalOrder"
        expressionDescription.expression = maxInternalOrderExpression
        expressionDescription.expressionResultType = .integer32AttributeType
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        fetchRequest.propertiesToFetch = [expressionDescription]
        fetchRequest.resultType = .dictionaryResultType
        
        guard let results = try? context.fetch(fetchRequest) else {
            return 0
        }
        
        if let toDoMetaData = results.first as? ToDoMetaData {
            return toDoMetaData.value(forKey: "maxInternalOrder") as! Int
        }
        
        return 0
    }
}
