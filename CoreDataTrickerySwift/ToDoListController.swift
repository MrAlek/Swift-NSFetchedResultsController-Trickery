//
//  ToDoListController.swift
//  CoreDataTrickerySwift
//
//  Created by Alek Astrom on 2014-07-30.
//  Copyright (c) 2014 Apps and Wonders. All rights reserved.
//

import CoreData

class ToDoListController: NSFetchedResultsControllerDelegate {
    
    struct ControllerSectionInfo {
        var section: ToDoSection!
        var fetchedIndex: Int?
    }
    
    var delegate: NSFetchedResultsControllerDelegate?
    
    var showsEmptySections: Bool = false {
    didSet {
        if showsEmptySections == oldValue { return }
        
        // Notify delegate that sections will be changed
    }
    }
    
    private var sectionsInfo: [ControllerSectionInfo] = []
    var sections: [ToDoSection] { return sectionsInfo.map() { $0.section } }
    
    private lazy var toDosController: NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest(entityName: ToDo.entityName())
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "sectionIdentifier", ascending: true), NSSortDescriptor(key: "internalOrder", ascending: false)]
        
        let controller = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext, sectionNameKeyPath: "sectionIdentifier", cacheName: nil)
        
        controller.performFetch(nil)
        controller.delegate = self
        
        return controller
        }()
    
    private var managedObjectContext: NSManagedObjectContext
    private var listConfiguration: ToDoListConfiguration
    
    init(managedObjectContext: NSManagedObjectContext) {
        self.managedObjectContext = managedObjectContext
        self.listConfiguration = ToDoListConfiguration.defaultConfiguration(managedObjectContext)
        generateSectionInfoWithEmptySections(false)
    }
    
    func fetchedToDos() -> [ToDo] {
        return toDosController.fetchedObjects as [ToDo]
    }
    
    func toDoAtIndexPath(indexPath: NSIndexPath) -> ToDo {
        return toDosController.objectAtIndexPath(indexPath) as ToDo
    }
    
    func numberOfToDosInSection(section: Int) -> Int {
        let sectionInfo = toDosController.sections[section] as NSFetchedResultsSectionInfo
        return sectionInfo.numberOfObjects
    }
    
    func reloadData() {
        toDosController.performFetch(nil)
    }
    
    //
    // Fetched results controller delegate
    //
    
    // Start by just forwarding all calls
    
    func controllerWillChangeContent(controller: NSFetchedResultsController!)  {
        delegate?.controllerWillChangeContent?(controller)
    }
    
    func controller(controller: NSFetchedResultsController!, didChangeSection sectionInfo: NSFetchedResultsSectionInfo!, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType)  {
        
        // Regenerate all section info (I know this isn't Über-effective but it shouldn't take too much time)
        generateSectionInfoWithEmptySections(showsEmptySections)
        
        delegate?.controller?(controller, didChangeSection: sectionInfo, atIndex: sectionIndex, forChangeType: type)
    }
    
    func controller(controller: NSFetchedResultsController!, didChangeObject anObject: AnyObject!, atIndexPath indexPath: NSIndexPath!, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath!)  {
        delegate?.controller?(controller, didChangeObject: anObject, atIndexPath: indexPath, forChangeType: type, newIndexPath: newIndexPath)
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController!)  {
        delegate?.controllerDidChangeContent?(controller)
    }
    
    //
    // Private methods
    //
    
    private func generateSectionInfoWithEmptySections(emptySections: Bool) {
        
        sectionsInfo = []
        
        // Just get all the sections from the fetched results controller
        for (fetchedIndex, sectionInfo) in enumerate(toDosController.sections as [NSFetchedResultsSectionInfo]) {
            let section = ToDoSection.fromRaw(sectionInfo.name.toInt()!)
            sectionsInfo.append(ControllerSectionInfo(section: section, fetchedIndex: fetchedIndex))
        }
        
    }
}