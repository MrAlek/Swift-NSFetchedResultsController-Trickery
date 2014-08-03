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
    
    lazy var toDoListController: ToDoListController = {
        
        let controller = ToDoListController(managedObjectContext: self.managedObjectContext)
        controller.delegate = self
        
        return controller
    }()
    
    @IBOutlet weak var modeControl: UISegmentedControl!
    @IBOutlet var editBarButtonItem: UIBarButtonItem!
    @IBOutlet var doneBarButtonItem: UIBarButtonItem!
    
    private var ignoreUpdates: Bool = false
    
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
        
        ignoreUpdates = true
        
        // Get the moved toDo
        let toDo = toDoListController.toDoAtIndexPath(sourceIndexPath)
        
        // First check if it has moved section
        if sourceIndexPath.section != destinationIndexPath.section {
            
            // Get the new section
            let sectionInfo = toDoListController.sections[destinationIndexPath.section]
            
            // Update state
            switch sectionInfo.section {
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
            
            // Update cell
            NSOperationQueue.mainQueue().addOperationWithBlock { // Table view is in inconsistent state, gotta wait
                self.configureCell(tableView.cellForRowAtIndexPath(destinationIndexPath), toDo: toDo)
            }
        }
        
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
    // Fetched results controller delegate
    //
    
    var sectionsBeingAdded: [Int] = []
    var sectionsBeingRemoved: [Int] = []
    
    func controllerWillChangeContent(controller: NSFetchedResultsController!)  {
        if ignoreUpdates {
            return
        }
        
        sectionsBeingAdded = []
        sectionsBeingRemoved = []
        tableView.beginUpdates()
    }
    
    func controller(controller: NSFetchedResultsController!, didChangeSection sectionInfo: NSFetchedResultsSectionInfo!, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType)  {
        if ignoreUpdates {
            return
        }
        
        switch type {
        case .Insert:
            sectionsBeingAdded.append(sectionIndex)
            tableView.insertSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
        case .Delete:
            sectionsBeingRemoved.append(sectionIndex)
            self.tableView.deleteSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
        default:
            return
        }
    }
    
    func controller(controller: NSFetchedResultsController!, didChangeObject anObject: AnyObject!, atIndexPath indexPath: NSIndexPath!, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath!)  {
        if ignoreUpdates {
            return
        }
        
        switch type {
        case .Insert:
            tableView.insertRowsAtIndexPaths([newIndexPath], withRowAnimation: .Automatic)
        case .Delete:
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
        case .Update:
            configureCell(tableView.cellForRowAtIndexPath(indexPath), toDo: anObject as ToDo  )
        case .Move:
            if !contains(sectionsBeingAdded, newIndexPath.section) && !contains(sectionsBeingRemoved, indexPath.section) {
                tableView.moveRowAtIndexPath(indexPath, toIndexPath: newIndexPath)
                configureCell(tableView.cellForRowAtIndexPath(indexPath), toDo: anObject as ToDo)
            } else { // Stupid and ugly, rdar://17684030
                tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
                tableView.insertRowsAtIndexPaths([newIndexPath], withRowAnimation: .Fade)
            }
        default:
            return
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController!)  {
        if ignoreUpdates {
            ignoreUpdates = false
        } else {
            tableView.endUpdates()
        }
    }
    
    //
    // Private methods
    //
    
    func configureCell(cell: UITableViewCell, toDo: ToDo) {
        cell.textLabel.text = toDo.title
        if toDo.done.boolValue {
            cell.textLabel.textColor = UIColor.lightGrayColor()
        } else {
            cell.textLabel.textColor = UIColor.blackColor()
        }
    }
    
}
