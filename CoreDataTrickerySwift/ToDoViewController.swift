//
//  ToDoViewController.swift
//  CoreDataTrickerySwift
//
//  Created by Alek Astrom on 2014-07-16.
//  Copyright (c) 2014 Apps and Wonders. All rights reserved.
//

import UIKit
import CoreData

class ToDoViewController: UITableViewController {
    
    // ========================================
    // MARK: - Internal properties
    // ========================================
    
    var managedObjectContext: NSManagedObjectContext!

    // ========================================
    // MARK: - Private properties
    // ========================================

    private lazy var fetchControllerDelegate: FetchControllerDelegate = {
        
        let delegate = FetchControllerDelegate(tableView: self.tableView)
        delegate.onUpdate = {
            (cell: UITableViewCell, object: AnyObject) in
            self.configureCell(cell, toDo: object as! ToDo)
        }
        
        return delegate
    }()
    private lazy var toDoListController: ToDoListController = {
        
        let controller = ToDoListController(managedObjectContext: self.managedObjectContext)
        controller.delegate = self.fetchControllerDelegate
        
        return controller
    }()
    
    @IBOutlet private weak var modeControl: UISegmentedControl!
    @IBOutlet private var editBarButtonItem: UIBarButtonItem!
    @IBOutlet private var doneBarButtonItem: UIBarButtonItem!
    
    
    // ========================================
    // MARK: - Internal methods
    // ========================================
    
    // MARK: View lifecycle

    override func setEditing(editing: Bool, animated: Bool)  {
        super.setEditing(editing, animated: animated)
        
        navigationItem.leftBarButtonItem = editing ? doneBarButtonItem : editBarButtonItem
        
        modeControl.enabled = !editing
        modeControl.userInteractionEnabled = !editing // Needs to set because of bug in iOS 8 & 9 rdar://17881987
    }
    
    // MARK: User interaction
    
    @IBAction func toggleEditing() {
        setEditing(!editing, animated: true)
        toDoListController.showsEmptySections = editing
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        if segue.identifier == "present new to do" {
            let navc = segue.destinationViewController as! UINavigationController
            let newVC = navc.topViewController as! NewToDoViewController
            
            newVC.managedObjectContext = self.managedObjectContext
        }
    }
    
    @IBAction func viewModeControlChanged(sender: UISegmentedControl) {
        let configuration = ToDoListConfiguration.defaultConfiguration(managedObjectContext)
        configuration.listMode = sender.selectedSegmentIndex == 0 ? .Simple : .Prioritized
    }
    
    // MARK: Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return toDoListController.sections.count
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return toDoListController.sections[section].numberOfObjects
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCellWithIdentifier("cell"), toDo = toDoListController.toDoAtIndexPath(indexPath) else {
            return UITableViewCell()
        }
        
        configureCell(cell, toDo: toDo)
        return cell
    }
    
    override func tableView(tableView: UITableView, moveRowAtIndexPath sourceIndexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath) {
        if sourceIndexPath == destinationIndexPath {
            return
        }
        
        fetchControllerDelegate.ignoreNextUpdates = true // Don't let fetched results controller affect table view
        let toDo = toDoListController.toDoAtIndexPath(sourceIndexPath)! // Trust that we will get a toDo back
        
        if sourceIndexPath.section != destinationIndexPath.section {
            
            let sectionInfo = toDoListController.sections[destinationIndexPath.section]
            toDo.metaData.setSection(sectionInfo.section)
            
            // Update cell
            NSOperationQueue.mainQueue().addOperationWithBlock { // Table view is in inconsistent state, gotta wait
                if let cell = tableView.cellForRowAtIndexPath(destinationIndexPath) {
                    self.configureCell(cell, toDo: toDo)
                }
            }
        }
        
        updateInternalOrderForToDo(toDo, sourceIndexPath: sourceIndexPath, destinationIndexPath: destinationIndexPath)
        
        // Save
        try! toDo.managedObjectContext!.save()
    }
    
    // MARK: Table view delegate
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath)  {
        if editingStyle == .Delete {
            
            let toDo = toDoListController.toDoAtIndexPath(indexPath)
            toDo?.managedObjectContext!.deleteObject(toDo!)
            
            try! managedObjectContext.save()
        }
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String {
        return toDoListController.sections[section].name
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        if let toDo = toDoListController.toDoAtIndexPath(indexPath) {
            toDo.done = !toDo.done.boolValue
            toDo.metaData.updateSectionIdentifier()
            try! toDo.managedObjectContext!.save()
        }
    }
    
    // ========================================
    // MARK: - Private methods
    // ========================================
    
    private func configureCell(cell: UITableViewCell, toDo: ToDo) {
        cell.textLabel?.text = toDo.title
        let textColor = toDo.done.boolValue ? UIColor.lightGrayColor() : UIColor.blackColor()
        cell.textLabel?.textColor = textColor
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
        for (index, toDo) in sortedToDos.enumerate() {
            toDo.metaData.internalOrder = sortedToDos.count-index
        }
    }
}
