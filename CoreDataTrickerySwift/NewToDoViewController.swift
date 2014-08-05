//
//  NewToDoViewController.swift
//  CoreDataTrickerySwift
//
//  Created by Alek Astrom on 2014-07-21.
//  Copyright (c) 2014 Apps and Wonders. All rights reserved.
//

import UIKit
import CoreData

class NewToDoViewController: UIViewController {
    
    @IBOutlet var textField: UITextField!
    @IBOutlet var priorityControl: UISegmentedControl!
    
    var managedObjectContext: NSManagedObjectContext!
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        textField.becomeFirstResponder()
    }
    
    @IBAction func cancelButtonPressed() {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func saveButtonPresse() {
        
        let toDo = NSEntityDescription.insertNewObjectForEntityForName(ToDo.entityName, inManagedObjectContext: managedObjectContext) as ToDo
        toDo.title = self.textField.text
        toDo.priority = self.selectedPriority().toRaw()
        toDo.metaData.internalOrder = ToDoMetaData.maxInternalOrder(managedObjectContext)+1
        toDo.metaData.updateSectionIdentifier()
        managedObjectContext.save(nil)
        
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func selectedPriority() -> ToDoPriority {
        switch self.priorityControl.selectedSegmentIndex {
        case 0:  return .Low
        case 1:  return .Medium
        case 2:  return .High
        default: return .Medium
        }
    }
}
