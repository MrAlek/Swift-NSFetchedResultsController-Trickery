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
    
    //
    // User interaction
    //
    
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
        return toDoListController.numberOfSections()
    }
    
    override func tableView(tableView: UITableView!, numberOfRowsInSection section: Int) -> Int {
        return toDoListController.numberOfToDosInSection(section)
    }
    
    override func tableView(tableView: UITableView!, cellForRowAtIndexPath indexPath: NSIndexPath!) -> UITableViewCell! {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("cell") as UITableViewCell
        let toDo = toDoListController.toDoAtIndexPath(indexPath)
        configureCell(cell, toDo:toDo)
        return cell
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
        
        return toDoListController.toDoSectionforSectionIndex(section)?.title()
    }
    
    override func tableView(tableView: UITableView!, didSelectRowAtIndexPath indexPath: NSIndexPath!) {
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        let toDo = toDoListController.toDoAtIndexPath(indexPath)
        toDo.edit() { $0.done = !$0.done.boolValue }
        toDo.managedObjectContext.save(nil)
    }
    
    //
    // Fetched results controller delegate
    //
    
    var sectionsBeingAdded: [Int] = []
    var sectionsBeingRemoved: [Int] = []
    
    func controllerWillChangeContent(controller: NSFetchedResultsController!)  {
        sectionsBeingAdded = []
        sectionsBeingRemoved = []
        tableView.beginUpdates()
    }
    
    func controller(controller: NSFetchedResultsController!, didChangeSection sectionInfo: NSFetchedResultsSectionInfo!, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType)  {
        
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
            } else {
                tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
                tableView.insertRowsAtIndexPaths([newIndexPath], withRowAnimation: .Fade)
            }
        default:
            return
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController!)  {
        tableView.endUpdates()
    }
    
    //
    // Private methods
    //
    
    func configureCell(cell: UITableViewCell, toDo: ToDo) {
        cell.textLabel.text = toDo.title
    }
    
}
