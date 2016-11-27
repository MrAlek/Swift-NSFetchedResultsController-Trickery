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
    case low = 1
    case medium = 2
    case high = 3
}

@objc(ToDo)
class ToDo: NSManagedObject {
    class var entityName: String {
        return "ToDo"
    }

    @NSManaged var title: String
    @NSManaged var done: Bool
    @NSManaged var priority: Int
    @NSManaged var metaData: ToDoMetaData
    
    override func awakeFromInsert() {
        super.awakeFromInsert()
        metaData = NSEntityDescription.insertNewObject(forEntityName: ToDoMetaData.entityName, into: managedObjectContext!) as! ToDoMetaData
    }
}
