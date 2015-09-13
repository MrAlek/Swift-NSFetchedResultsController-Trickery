//
//  ToDo.swift
//  CoreDataTrickerySwift
//
//  Created by Alek Astrom on 2014-07-17.
//  Copyright (c) 2014 Apps and Wonders. All rights reserved.
//

import Foundation
import CoreData

enum ToDoPriority: Int {
    case Low = 1
    case Medium = 2
    case High = 3
}

@objc(ToDo)
class ToDo: NSManagedObject {
    class var entityName: String {
        return "ToDo"
    }

    @NSManaged var title: String
    @NSManaged var done: NSNumber
    @NSManaged var priority: NSNumber
    @NSManaged var metaData: ToDoMetaData
    
    override func awakeFromInsert() {
        super.awakeFromInsert()
        metaData = NSEntityDescription.insertNewObjectForEntityForName(ToDoMetaData.entityName, inManagedObjectContext: managedObjectContext!) as! ToDoMetaData
    }
}
