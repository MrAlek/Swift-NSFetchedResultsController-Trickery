//
//  ToDoSection.swift
//  CoreDataTrickerySwift
//
//  Created by Alek Åström on 2015-09-13.
//  Copyright © 2015 Apps and Wonders. All rights reserved.
//

import Foundation

enum ToDoSection: String {
    case ToDo = "10"
    case HighPriority = "11"
    case MediumPriority = "12"
    case LowPriority = "13"
    case Done = "20"
    
    var title: String {
        switch self {
        case ToDo:              return "Left to do"
        case Done:              return "Done"
        case HighPriority:      return "High priority"
        case MediumPriority:    return "Medium priority"
        case LowPriority:       return "Low priority"
        }
    }
}
