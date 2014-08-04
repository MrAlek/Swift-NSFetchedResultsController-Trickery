//
//  ToDoViewController.swift
//  CoreDataTrickerySwift
//
//  Created by Alek Astrom on 2014-07-16.
//  Copyright (c) 2014 Apps and Wonders. All rights reserved.
//

import UIKit
import CoreData

class ToDoViewController: UITableViewController, NSFetchedResultsControllerDelegate {
    
    var managedObjectContext: NSManagedObjectContext!
    lazy var fetchControllerDelegate: FetchControllerDelegate = {
        
        let delegate = FetchControllerDelegate(tableView: self.tableView)
        delegate.onUpdate = {
            (cell: UITableViewCell, object: AnyObject) in
            self.configureCell(cell, toDo: object as ToDo)
        }
        
        return delegate
    }()
    lazy var toDoListController: ToDoListController = {
        
        let controller = ToDoListController(managedObjectContext: self.managedObjectContext)
        controller.delegate = self.fetchControllerDelegate
        
        return controller
    }()
    
    @IBOutlet weak var modeControl: UISegmentedControl!
    @IBOutlet var editBarButtonItem: UIBarButtonItem!
    @IBOutlet var doneBarButtonItem: UIBarButtonItem!
    
    
    // 
    // View lifecycle
    //
    
    override func setEditing(editing: Bool, animated: Bool)  {
        super.setEditing(editing, animated: animated)
        
        if editing {
            navigationItem.leftBarButtonItem = doneBarButtonItem
        } else {
            navigationItem.leftBarButtonItem = editBarButtonItem
        }
        
        modeControl.enabled = !editing
        modeControl.userInteractionEnabled = !editing // Needs to set because of bug in iOS 8 beta 4 rdar://17881987
    }
    
    
    //
    // User interaction
    //
    
    @IBAction func toggleEditing() {
        setEditing(!editing, animated: true)
        toDoListController.showsEmptySections = editing
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue!, sender: AnyObject!) {
        if segue.identifier == "present new to do" {
            let navc = segue.destinationViewController as UINavigationController
            let newVC = navc.topViewController as NewToDoViewController
            
            newVC.managedObjectContext = self.managedObjectContext
        }
    }
    
    @IBAction func viewModeControlChanged(sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            ToDoListConfiguration.defaultConfiguration(managedObjectContext).setListMode(.Simple)
        default:
            ToDoListConfiguration.defaultConfiguration(managedObjectContext).setListMode(.Prioritized)
        }
    }
    
    
    //
    // Table view data source
    //
    
    override func numberOfSectionsInTableView(tableView: UITableView!) -> Int {
        return toDoListController.sections.count
    }
    
    override func tableView(tableView: UITableView!, numberOfRowsInSection section: Int) -> Int {
        return toDoListController.sections[section].numberOfObjects
    }
    
    override func tableView(tableView: UITableView!, cellForRowAtIndexPath indexPath: NSIndexPath!) -> UITableViewCell! {
        let cell = tableView.dequeueReusableCellWithIdentifier("cell") as UITableViewCell
        let toDo = toDoListController.toDoAtIndexPath(indexPath)
        configureCell(cell, toDo:toDo)
        return cell
    }
    
    override func tableView(tableView: UITableView!, moveRowAtIndexPath sourceIndexPath: NSIndexPath!, toIndexPath destinationIndexPath: NSIndexPath!) {
        if sourceIndexPath == destinationIndexPath {
            return
        }
        
        fetchControllerDelegate.ignoreNextUpdates = true // Don't let fetched results controller affect table view
        let toDo = toDoListController.toDoAtIndexPath(sourceIndexPath)
        
        if sourceIndexPath.section != destinationIndexPath.section {
            
            let sectionInfo = toDoListController.sections[destinationIndexPath.section]
            updateToDoForSection(toDo, section: sectionInfo.section)
            
            // Update cell
            NSOperationQueue.mainQueue().addOperationWithBlock { // Table view is in inconsistent state, gotta wait
                self.configureCell(tableView.cellForRowAtIndexPath(destinationIndexPath), toDo: toDo)
            }
        }
        
        updateInternalOrderForToDo(toDo, sourceIndexPath: sourceIndexPath, destinationIndexPath: destinationIndexPath)
        
        // Save
        toDo.managedObjectContext.save(nil)
    }
    
    
    //
    // Table view delegate
    //
    
    override func tableView(tableView: UITableView!, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath!)  {
        if editingStyle == .Delete {
            
            let toDo = toDoListController.toDoAtIndexPath(indexPath)
            toDo.managedObjectContext.deleteObject(toDo)
            
            managedObjectContext.save(nil)
        }
    }
    
    override func tableView(tableView: UITableView!, titleForHeaderInSection section: Int) -> String! {
        return toDoListController.sections[section].name
    }
    
    override func tableView(tableView: UITableView!, didSelectRowAtIndexPath indexPath: NSIndexPath!) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        let toDo = toDoListController.toDoAtIndexPath(indexPath)
        toDo.done = !toDo.done.boolValue
        toDo.metaData.updateSectionIdentifier()
        toDo.managedObjectContext.save(nil)
    }
    
    //
    // Private methods
    //
    
    private func configureCell(cell: UITableViewCell, toDo: ToDo) {
        cell.textLabel.text = toDo.title
        if toDo.done.boolValue {
            cell.textLabel.textColor = UIColor.lightGrayColor()
        } else {
            cell.textLabel.textColor = UIColor.blackColor()
        }
    }
    
    private func updateToDoForSection(toDo: ToDo, section: ToDoSection) {
        switch section {
        case .ToDo:
            toDo.done = false
        case .Done:
            toDo.done = true
        case .HighPriority:
            toDo.done = false
            toDo.priority = ToDoPriority.High.toRaw()
        case .MediumPriority:
            toDo.done = false
            toDo.priority = ToDoPriority.Medium.toRaw()
        case .LowPriority:
            toDo.done = false
            toDo.priority = ToDoPriority.Low.toRaw()
        }
        toDo.metaData.updateSectionIdentifier()
    }
    
    private func updateInternalOrderForToDo(toDo: ToDo, sourceIndexPath: NSIndexPath, destinationIndexPath: NSIndexPath) {
        
        // Now update internal order to reflect new position
        
        // First get all toDos, in sorted order
        var sortedToDos = toDoListController.fetchedToDos()
        sortedToDos = sortedToDos.filter() {$0 != toDo} // Remove current toDo
        
        // Insert toDo at new place in array
        var sortedIndex = destinationIndexPath.row
        for sectionIndex in 0..<destinationIndexPath.section {
            sortedIndex += toDoListController.sections[sectionIndex].numberOfObjects
            if sectionIndex == sourceIndexPath.section {
                sortedIndex -= 1 // Remember, controller still thinks this toDo is in the old section
            }
        }
        sortedToDos.insert(toDo, atIndex: sortedIndex)
        
        // Regenerate internal order for all toDos
        for (index, toDo) in enumerate(sortedToDos) {
            toDo.metaData.internalOrder = sortedToDos.count-index
        }

    }
    
}
