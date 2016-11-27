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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        textField.becomeFirstResponder()
    }
    
    @IBAction func cancelButtonPressed() {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func saveButtonPressed() {
        guard let title = textField.text else {
            present(UIAlertController(title: "Can't create ToDo", message: "Title can't be blank", preferredStyle: .alert), animated: true, completion: nil)
            return
        }
        
        let toDo = NSEntityDescription.insertNewObject(forEntityName: ToDo.entityName, into: managedObjectContext) as! ToDo
        toDo.title = title
        toDo.priority = selectedPriority().rawValue
        toDo.metaData.internalOrder = ToDoMetaData.maxInternalOrder(managedObjectContext)+1
        toDo.metaData.updateSectionIdentifier()
        try! managedObjectContext.save()
        
        dismiss(animated: true, completion: nil)
    }
    
    func selectedPriority() -> ToDoPriority {
        switch self.priorityControl.selectedSegmentIndex {
        case 0:  return .low
        case 1:  return .medium
        case 2:  return .high
        default: return .medium
        }
    }
}
