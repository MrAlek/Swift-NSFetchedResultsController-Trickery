//
//  ToDoListController.swift
//  CoreDataTrickerySwift
//
//  Created by Alek Astrom on 2014-07-30.
//  Copyright (c) 2014 Apps and Wonders. All rights reserved.
//

import CoreData

/// Class used to display ToDo's in a table view
class ToDoListController: NSObject {
    
    //
    // MARK: - Internal properties
    //
    
    /// Array of ControllerSectionInfo objects, each object representing a section in a table view
    fileprivate(set) var sections: [ControllerSectionInfo] = []
    
    /// Set to true to enable empty sections to be shown, delegate will be noticed of these changes
    var showsEmptySections: Bool = false {
        didSet {
            if showsEmptySections == oldValue { return }
        
            delegate!.controllerWillChangeContent!(toDosController as! NSFetchedResultsController<NSFetchRequestResult>)
        
            let changedEmptySections = sectionInfoWithEmptySections(true)
            notifyDelegateOfChangedEmptySections(changedEmptySections,
                changeType: showsEmptySections ? .insert : .delete)
            
            sections = sectionInfoWithEmptySections(showsEmptySections)
            delegate?.controllerDidChangeContent?(toDosController as! NSFetchedResultsController<NSFetchRequestResult>)
        }
    }
    
    /// Used to receive updates about changes in sections and rows
    var delegate: NSFetchedResultsControllerDelegate?
    
    //
    // MARK: - Private properties
    //
    
    fileprivate var oldSectionsDuringFetchUpdate: [ControllerSectionInfo] = []
    fileprivate lazy var toDosController: NSFetchedResultsController<ToDoMetaData> = {
        
        let fetchRequest = NSFetchRequest<ToDoMetaData>(entityName: ToDoMetaData.entityName)
        fetchRequest.relationshipKeyPathsForPrefetching = ["toDo"]
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(key: "sectionIdentifier", ascending: true),
            NSSortDescriptor(key: "internalOrder", ascending: false)]
        
        let controller = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext, sectionNameKeyPath: "sectionIdentifier", cacheName: nil)
        
        try! controller.performFetch()
        controller.delegate = self
        
        return controller
    }()
    fileprivate var managedObjectContext: NSManagedObjectContext
    fileprivate var listConfiguration: ToDoListConfiguration
    
    //
    // MARK: - Internal methods
    //

    /** Initializes a ToDoListController with a given managed object context
        - parameter managedObjectContext: The context to fetch ToDo's from
    */
    init(managedObjectContext: NSManagedObjectContext) {
        self.managedObjectContext = managedObjectContext
        self.listConfiguration = ToDoListConfiguration.defaultConfiguration(managedObjectContext)
        
        super.init()
        sections = sectionInfoWithEmptySections(false)
    }
    
    /** Used to get all the fetched ToDo's
        - returns: All fetched ToDo's in provided managed object context
    */
    func fetchedToDos() -> [ToDo] {
        return toDosController.fetchedObjects?.map { $0.toDo } ?? []
    }
    
    /** Used to get a single ToDo for a given index path
        - parameter indexPath: The index path for a ToDo in the table view
        - returns: An optional ToDo if a ToDo was found at the provided index path
    */
    func toDoAtIndexPath(_ indexPath: IndexPath) -> ToDo? {
        let sectionInfo = sections[indexPath.section]
        
        guard let section = sectionInfo.fetchedIndex else {
            return nil
        }
        
        let indexPath = IndexPath(row: indexPath.row, section: section)
        return toDosController.object(at: indexPath).toDo
    }
    
    /// Reloads all data internally, does not notify delegate of eventual changes in sections or rows
    func reloadData() {
        try! toDosController.performFetch()
        sections = sectionInfoWithEmptySections(showsEmptySections)
    }
    
    //
    // MARK: - Private methods
    //
    
    fileprivate func sectionInfoWithEmptySections(_ includeEmptySections: Bool) -> [ControllerSectionInfo] {
        guard let fetchedSectionNames = toDosController.sections?.map({$0.name}) else {
            return []
        }
        
        if includeEmptySections {
            let configuration = ToDoListConfiguration.defaultConfiguration(managedObjectContext)
            
            // Map sections to sectionInfo structs with each section and its fetched index
            return configuration.sections.map {
                section in
                let fetchedIndex = fetchedSectionNames.index(of: section.rawValue)
                return ControllerSectionInfo(section: section, fetchedIndex: fetchedIndex, fetchController: (toDosController as! NSFetchedResultsController<NSFetchRequestResult>) )
            }
        } else {
            // Just get all the sections from the fetched results controller
            let rawSectionValuesIndexes = fetchedSectionNames.map { ($0, fetchedSectionNames.index(of: $0)) }
            return rawSectionValuesIndexes.map {
                ControllerSectionInfo(section: ToDoSection(rawValue: $0.0)!, fetchedIndex: $0.1, fetchController: (toDosController as! NSFetchedResultsController<NSFetchRequestResult>))
            }
        }
    }

    fileprivate func notifyDelegateOfChangedEmptySections(_ changedSections: [ControllerSectionInfo], changeType: NSFetchedResultsChangeType) {
        for (index, sectionInfo) in changedSections.enumerated() {
            if sectionInfo.fetchedIndex == nil {
                delegate?.controller?((toDosController as! NSFetchedResultsController<NSFetchRequestResult>), didChange: sectionInfo, atSectionIndex: index, for: changeType)
            }
        }
    }
    
    fileprivate func displayedIndexPathForFetchedIndexPath(_ fetchedIndexPath: IndexPath, sections: [ControllerSectionInfo]) -> IndexPath? {
        
        // Ugh, I hate this implementation but as of Swift 2, other options are just less intuitive and needs more code
        for (sectionIndex, sectionInfo) in sections.enumerated() {
            if sectionInfo.fetchedIndex == fetchedIndexPath.section {
                return IndexPath(row: fetchedIndexPath.row, section: sectionIndex)
            }
        }
        return nil
    }
}

//
// MARK: - NSFetchedResultsControllerDelegate extension
//

extension ToDoListController: NSFetchedResultsControllerDelegate {
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>)  {
        oldSectionsDuringFetchUpdate = sections // Backup
        delegate?.controllerWillChangeContent?(controller)
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType)  {
        
        // Regenerate section info
        sections = sectionInfoWithEmptySections(showsEmptySections)
        
        // When we show empty sections, fetched section changes don't affect our delegate
        if !showsEmptySections {
            delegate?.controller?(controller, didChange: sectionInfo, atSectionIndex: sectionIndex, for: type)
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        let metaData = anObject as! ToDoMetaData
        
        // Convert fetched indexpath to displayed index paths
        let displayedOldIndexPath = indexPath.flatMap { displayedIndexPathForFetchedIndexPath($0, sections: oldSectionsDuringFetchUpdate) }
        let displayedNewIndexPath = newIndexPath.flatMap { displayedIndexPathForFetchedIndexPath($0, sections: sections) }
        
        delegate?.controller?(controller, didChange: metaData.toDo, at: displayedOldIndexPath, for: type, newIndexPath: displayedNewIndexPath)
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>)  {
        delegate?.controllerDidChangeContent?(controller)
    }
}

