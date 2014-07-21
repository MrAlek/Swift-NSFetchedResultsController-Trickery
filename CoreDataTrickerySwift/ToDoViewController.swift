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
    
    @lazy var toDosController: NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest(entityName: "ToDo")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "sectionIdentifier", ascending: true), NSSortDescriptor(key: "internalOrder", ascending: false)]
        
        let controller = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext, sectionNameKeyPath: "sectionIdentifier", cacheName: nil)
        
        controller.performFetch(nil)
        
        controller.delegate = self
        if self.isViewLoaded() {
            self.tableView.reloadData()
        }
        
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
    
    
    //
    // Table view data source
    //
    
    override func numberOfSectionsInTableView(tableView: UITableView!) -> Int {
        return toDosController.sections.count
    }
    
    override func tableView(tableView: UITableView!, numberOfRowsInSection section: Int) -> Int {
        let section = toDosController.sections[section] as NSFetchedResultsSectionInfo
        return section.numberOfObjects
    }
    
    override func tableView(tableView: UITableView!, cellForRowAtIndexPath indexPath: NSIndexPath!) -> UITableViewCell! {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("cell") as UITableViewCell
        configureCell(cell, indexPath: indexPath)
        return cell
    }
    
    //
    // Table view delegate
    //
    
    override func tableView(tableView: UITableView!, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath!)  {
        if editingStyle == .Delete {
            
            let object = toDosController.objectAtIndexPath(indexPath) as NSManagedObject
            toDosController.managedObjectContext.deleteObject(object)
            
            managedObjectContext.save(nil)
        }
    }
    
    override func tableView(tableView: UITableView!, titleForHeaderInSection section: Int) -> String! {
        
        let sectionInfo = toDosController.sections[section] as NSFetchedResultsSectionInfo
        if let toDoSection = ToDoSection.fromRaw(sectionInfo.name.toInt()!) {
            return toDoSection.title()
        } else {
            return nil
        }
    }
    
    override func tableView(tableView: UITableView!, didSelectRowAtIndexPath indexPath: NSIndexPath!) {
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        let toDo = toDosController.objectAtIndexPath(indexPath) as ToDo
        
        
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
        case NSFetchedResultsChangeInsert:
            sectionsBeingAdded.append(sectionIndex)
            self.tableView.insertSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
        case NSFetchedResultsChangeDelete:
            sectionsBeingRemoved.append(sectionIndex)
            self.tableView.deleteSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
        default:
            return
        }
    }
    
    func controller(controller: NSFetchedResultsController!, didChangeObject anObject: AnyObject!, atIndexPath indexPath: NSIndexPath!, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath!)  {
        
        switch type {
        case NSFetchedResultsChangeInsert:
            tableView.insertRowsAtIndexPaths([newIndexPath], withRowAnimation: .Automatic)
        case NSFetchedResultsChangeDelete:
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
        case NSFetchedResultsChangeUpdate:
            configureCell(tableView.cellForRowAtIndexPath(indexPath), indexPath: indexPath  )
        case NSFetchedResultsChangeMove:
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
    
    func configureCell(cell: UITableViewCell, indexPath: NSIndexPath) {
        
        let toDo = toDosController.objectAtIndexPath(indexPath) as ToDo
        cell.textLabel.text = toDo.title
    }
    
}
