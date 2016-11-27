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

    fileprivate lazy var fetchControllerDelegate: FetchControllerDelegate = {
        
        let delegate = FetchControllerDelegate(tableView: self.tableView)
        delegate.onUpdate = {
            (cell: UITableViewCell, object: AnyObject) in
            self.configureCell(cell, toDo: object as! ToDo)
        }
        
        return delegate
    }()
    fileprivate lazy var toDoListController: ToDoListController = {
        
        let controller = ToDoListController(managedObjectContext: self.managedObjectContext)
        controller.delegate = self.fetchControllerDelegate
        
        return controller
    }()
    
    @IBOutlet fileprivate weak var modeControl: UISegmentedControl!
    @IBOutlet fileprivate var editBarButtonItem: UIBarButtonItem!
    @IBOutlet fileprivate var doneBarButtonItem: UIBarButtonItem!
    
    
    // ========================================
    // MARK: - Internal methods
    // ========================================
    
    // MARK: View lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        modeControl.selectedSegmentIndex = ToDoListConfiguration.defaultConfiguration(managedObjectContext).listMode.rawValue
    }

    override func setEditing(_ editing: Bool, animated: Bool)  {
        super.setEditing(editing, animated: animated)
        
        navigationItem.leftBarButtonItem = editing ? doneBarButtonItem : editBarButtonItem
        
        modeControl.isEnabled = !editing
        modeControl.isUserInteractionEnabled = !editing // Needs to set because of bug in iOS 8 & 9 rdar://17881987
    }
    
    // MARK: User interaction
    
    @IBAction func toggleEditing() {
        setEditing(!isEditing, animated: true)
        toDoListController.showsEmptySections = isEditing
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any!) {
        if segue.identifier == "present new to do" {
            let navc = segue.destination as! UINavigationController
            let newVC = navc.topViewController as! NewToDoViewController
            
            newVC.managedObjectContext = self.managedObjectContext
        }
    }
    
    @IBAction func viewModeControlChanged(_ sender: UISegmentedControl) {
        let configuration = ToDoListConfiguration.defaultConfiguration(managedObjectContext)
        configuration.listMode = sender.selectedSegmentIndex == 0 ? .simple : .prioritized
    }
    
    // MARK: Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return toDoListController.sections.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return toDoListController.sections[section].numberOfObjects
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "cell"), let toDo = toDoListController.toDoAtIndexPath(indexPath) else {
            return UITableViewCell()
        }
        
        configureCell(cell, toDo: toDo)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        if sourceIndexPath == destinationIndexPath {
            return
        }
        
        fetchControllerDelegate.ignoreNextUpdates = true // Don't let fetched results controller affect table view
        let toDo = toDoListController.toDoAtIndexPath(sourceIndexPath)! // Trust that we will get a toDo back
        
        if sourceIndexPath.section != destinationIndexPath.section {
            
            let sectionInfo = toDoListController.sections[destinationIndexPath.section]
            toDo.metaData.setSection(sectionInfo.section)
            
            // Update cell
            OperationQueue.main.addOperation { // Table view is in inconsistent state, gotta wait
                if let cell = tableView.cellForRow(at: destinationIndexPath) {
                    self.configureCell(cell, toDo: toDo)
                }
            }
        }
        
        updateInternalOrderForToDo(toDo, sourceIndexPath: sourceIndexPath, destinationIndexPath: destinationIndexPath)
        
        // Save
        try! toDo.managedObjectContext!.save()
    }
    
    // MARK: Table view delegate
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath)  {
        if editingStyle == .delete {
            
            let toDo = toDoListController.toDoAtIndexPath(indexPath)
            toDo?.managedObjectContext!.delete(toDo!)
            
            try! managedObjectContext.save()
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String {
        return toDoListController.sections[section].name
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if let toDo = toDoListController.toDoAtIndexPath(indexPath) {
            toDo.done = !toDo.done
            toDo.metaData.updateSectionIdentifier()
            try! toDo.managedObjectContext!.save()
        }
    }
    
    // ========================================
    // MARK: - Private methods
    // ========================================
    
    fileprivate func configureCell(_ cell: UITableViewCell, toDo: ToDo) {
        cell.textLabel?.text = toDo.title
        let textColor = toDo.done ? UIColor.lightGray : UIColor.black
        cell.textLabel?.textColor = textColor
    }
    
    fileprivate func updateInternalOrderForToDo(_ toDo: ToDo, sourceIndexPath: IndexPath, destinationIndexPath: IndexPath) {
        
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
        sortedToDos.insert(toDo, at: sortedIndex)
        
        // Regenerate internal order for all toDos
        for (index, toDo) in sortedToDos.enumerated() {
            toDo.metaData.internalOrder = sortedToDos.count-index
        }
    }
}
