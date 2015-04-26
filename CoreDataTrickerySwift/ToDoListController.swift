//
//  ToDoListController.swift
//  CoreDataTrickerySwift
//
//  Created by Alek Astrom on 2014-07-30.
//  Copyright (c) 2014 Apps and Wonders. All rights reserved.
//

import CoreData

/// Class used to display ToDo's in a table view
@objc class ToDoListController {
    
    //
    // MARK: - Internal properties
    //
    
    /// Array of ControllerSectionInfo objects, each object representing a section in a table view
    private(set) var sections: [ControllerSectionInfo] = []
    
    /// Set to true to enable empty sections to be shown, delegate will be noticed of these changes
    var showsEmptySections: Bool = false {
        didSet {
            if showsEmptySections == oldValue { return }
        
            delegate!.controllerWillChangeContent!(toDosController)
        
            let changedEmptySections = sectionInfoWithEmptySections(true)
            notifyDelegateOfChangedEmptySections(changedEmptySections,
                changeType: showsEmptySections ? .Insert : .Delete)
            
            sections = sectionInfoWithEmptySections(showsEmptySections)
            delegate?.controllerDidChangeContent?(toDosController)
        }
    }
    
    /// Used to receive updates about changes in sections and rows
    var delegate: NSFetchedResultsControllerDelegate?
    
    //
    // MARK: - Private properties
    //
    
    private var oldSectionsDuringFetchUpdate: [ControllerSectionInfo] = []
    private lazy var toDosController: NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest(entityName: ToDoMetaData.entityName)
        fetchRequest.relationshipKeyPathsForPrefetching = ["toDo"]
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "sectionIdentifier", ascending: true),
            NSSortDescriptor(key: "internalOrder", ascending: false)]
        
        let controller = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext, sectionNameKeyPath: "sectionIdentifier", cacheName: nil)
        
        controller.performFetch(nil)
        controller.delegate = self
        
        return controller
    }()
    private var managedObjectContext: NSManagedObjectContext
    private var listConfiguration: ToDoListConfiguration
    
    //
    // MARK: - Internal methods
    //

    /** Initializes a ToDoListController with a given managed object context
        :param: managedObjectContext The context to fetch ToDo's from
    */
    init(managedObjectContext: NSManagedObjectContext) {
        self.managedObjectContext = managedObjectContext
        self.listConfiguration = ToDoListConfiguration.defaultConfiguration(managedObjectContext)
        sections = sectionInfoWithEmptySections(false)
    }
    
    /** Used to get all the fetched ToDo's
        :returns: All fetched ToDo's in provided managed object context
    */
    func fetchedToDos() -> [ToDo] {
        let metaData = toDosController.fetchedObjects as! [ToDoMetaData]
        return metaData.map {$0.toDo}
    }
    
    /** Used to get a single ToDo for a given index path
        :param: indexPath The index path for a ToDo in the table view
        :returns: An optional ToDo if a ToDo was found at the provided index path
    */
    func toDoAtIndexPath(indexPath: NSIndexPath) -> ToDo? {
        let sectionInfo = sections[indexPath.section]
        
        if let section = sectionInfo.fetchedIndex {
            let indexPath = NSIndexPath(forRow: indexPath.row, inSection: section)
            let metaData = toDosController.objectAtIndexPath(indexPath) as! ToDoMetaData
            return metaData.toDo
        } else {
            return nil
        }
    }
    
    /// Reloads all data internally, does not notify delegate of eventual changes in sections or rows
    func reloadData() {
        toDosController.performFetch(nil)
        sections = sectionInfoWithEmptySections(showsEmptySections)
    }
    
    //
    // MARK: - Private methods
    //
    
    private func sectionInfoWithEmptySections(includeEmptySections: Bool) -> [ControllerSectionInfo] {
        
        if includeEmptySections {
            let fetchedSections = (toDosController.sections as! [NSFetchedResultsSectionInfo]).map {$0.name!}
            
            let configuration = ToDoListConfiguration.defaultConfiguration(managedObjectContext)
            // Map sections to sectionInfo structs with each section and its fetched index
            return configuration.sectionsForCurrentConfiguration().map {
                section in
                let fetchedIndex = find(fetchedSections, section.rawValue)
                return ControllerSectionInfo(section: section, fetchedIndex: fetchedIndex, fetchController: self.toDosController)
            }
            
        } else {
            // Just get all the sections from the fetched results controller
            var tempSections = [] as [ControllerSectionInfo]
            for (fetchedIndex, sectionInfo) in enumerate(toDosController.sections as! [NSFetchedResultsSectionInfo]) {
                let section = ToDoSection(rawValue: sectionInfo.name!)!
                tempSections.append(ControllerSectionInfo(section: section, fetchedIndex: fetchedIndex, fetchController: self.toDosController))
            }
            return tempSections;
        }
    }

    private func notifyDelegateOfChangedEmptySections(changedSections: [ControllerSectionInfo], changeType: NSFetchedResultsChangeType) {
        for (index, sectionInfo) in enumerate(changedSections) {
            if sectionInfo.fetchedIndex == nil {
                delegate?.controller?(toDosController, didChangeSection: sectionInfo, atIndex: index, forChangeType: changeType)
            }
        }
    }
    
    private func displayedIndexPathForFetchedIndexPath(fetchedIndexPath: NSIndexPath, sections: [ControllerSectionInfo]) -> NSIndexPath? {
        // Ugh, I hate this implementation but as of beta 5, find() doesn't work on arrays with optionals
        for (sectionIndex, sectionInfo) in enumerate(sections) {
            if sectionInfo.fetchedIndex == fetchedIndexPath.section {
                return NSIndexPath(forRow: fetchedIndexPath.row, inSection: sectionIndex)
            }
        }
        return nil
    }
}

//
// MARK: - NSFetchedResultsControllerDelegate extension
//

extension ToDoListController: NSFetchedResultsControllerDelegate {
    
    func controllerWillChangeContent(controller: NSFetchedResultsController)  {
        oldSectionsDuringFetchUpdate = sections // Backup
        delegate?.controllerWillChangeContent?(controller)
    }
    
    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType)  {
        
        // Regenerate section info
        sections = sectionInfoWithEmptySections(showsEmptySections)
        
        // When we show empty sections, fetched changes don't affect our delegate
        if !showsEmptySections {
            delegate?.controller?(controller, didChangeSection: sectionInfo, atIndex: sectionIndex, forChangeType: type)
        }
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?)  {
        
        let displayedOldIndexPath = (indexPath != nil) ? displayedIndexPathForFetchedIndexPath(indexPath!, sections: oldSectionsDuringFetchUpdate) : nil
        let displayedNewIndexPath = (newIndexPath != nil) ? displayedIndexPathForFetchedIndexPath(newIndexPath!, sections: sections) : nil
        
        let metaData = anObject as! ToDoMetaData
        
        delegate?.controller?(controller, didChangeObject: metaData.toDo, atIndexPath: displayedOldIndexPath, forChangeType: type, newIndexPath: displayedNewIndexPath)
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController)  {
        delegate?.controllerDidChangeContent?(controller)
    }
}

