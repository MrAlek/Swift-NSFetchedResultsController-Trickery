//
//  ToDoListController.swift
//  CoreDataTrickerySwift
//
//  Created by Alek Astrom on 2014-07-30.
//  Copyright (c) 2014 Apps and Wonders. All rights reserved.
//

import CoreData

public class ToDoListController {
    
    var delegate: NSFetchedResultsControllerDelegate?
    
    var showsEmptySections: Bool = false {
        didSet {
            if showsEmptySections == oldValue { return }
        
            delegate?.controllerWillChangeContent?(toDosController)
        
            let changedEmptySections = sectionInfoWithEmptySections(true)
            notifyDelegateOfChangedEmptySections(changedEmptySections,
                changeType: showsEmptySections ? .Insert : .Delete)
            
            sections = sectionInfoWithEmptySections(showsEmptySections)
            delegate?.controllerDidChangeContent?(toDosController)
        }
    }
    
    private(set) var sections: [ControllerSectionInfo] = []
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
    
    init(managedObjectContext: NSManagedObjectContext) {
        self.managedObjectContext = managedObjectContext
        self.listConfiguration = ToDoListConfiguration.defaultConfiguration(managedObjectContext)
        sections = sectionInfoWithEmptySections(false)
    }

    //
    // Public methods
    //
    
    func fetchedToDos() -> [ToDo] {
        let metaData = toDosController.fetchedObjects as [ToDoMetaData]
        return metaData.map {$0.toDo}
    }
    
    func toDoAtIndexPath(indexPath: NSIndexPath) -> ToDo {
        let sectionInfo = sections[indexPath.section]
        let metaData = toDosController.objectAtIndexPath(NSIndexPath(forRow: indexPath.row, inSection: sectionInfo.fetchedIndex!)) as ToDoMetaData
        return metaData.toDo
    }
    
    func reloadData() {
        toDosController.performFetch(nil)
        sections = sectionInfoWithEmptySections(showsEmptySections)
    }
    
    //
    // Private methods
    //
    
    private func sectionInfoWithEmptySections(includeEmptySections: Bool) -> [ControllerSectionInfo] {
        
        if includeEmptySections {
            let fetchedSections = (toDosController.sections as [NSFetchedResultsSectionInfo]).map {$0.name!}
            
            let configuration = ToDoListConfiguration.defaultConfiguration(managedObjectContext)
            // Map sections to sectionInfo structs with each section and its fetched index
            return configuration.sectionsForCurrentConfiguration().map {
                let fetchedIndex = find(fetchedSections, $0.toRaw())
                return ControllerSectionInfo(section: $0, fetchedIndex: fetchedIndex, fetchController: self.toDosController)
            }
            
        } else {
            // Just get all the sections from the fetched results controller
            var tempSections = [] as [ControllerSectionInfo]
            for (fetchedIndex, sectionInfo) in enumerate(toDosController.sections as [NSFetchedResultsSectionInfo]) {
                let section = ToDoSection.fromRaw(sectionInfo.name!)!
                tempSections.append(ControllerSectionInfo(section: section, fetchedIndex: fetchedIndex, fetchController: self.toDosController))
            }
            return tempSections;
        }
    }

    private func notifyDelegateOfChangedEmptySections(changedSections: [ControllerSectionInfo], changeType: NSFetchedResultsChangeType) {
        for (index, sectionInfo) in enumerate(changedSections) {
            if !sectionInfo.fetchedIndex.hasValue {
                delegate?.controller?(toDosController, didChangeSection: sectionInfo, atIndex: index, forChangeType: changeType)
            }
        }
    }
    
    private func displayedIndexPathForFetchedIndexPath(fetchedIndexPath: NSIndexPath?, sections: [ControllerSectionInfo]) -> NSIndexPath? {
        // Ugh, I hate this implementation but as of beta 5, find() doesn't work on arrays with optionals
        if fetchedIndexPath.hasValue {
            for (sectionIndex, sectionInfo) in enumerate(sections) {
                if sectionInfo.fetchedIndex == fetchedIndexPath!.section {
                    return NSIndexPath(forRow: fetchedIndexPath!.row, inSection: sectionIndex)
                }
            }
        }
        return nil
    }
}

extension ToDoListController: NSFetchedResultsControllerDelegate {
    
    public func controllerWillChangeContent(controller: NSFetchedResultsController!)  {
        oldSectionsDuringFetchUpdate = sections // Backup
        delegate?.controllerWillChangeContent?(controller)
    }
    
    public func controller(controller: NSFetchedResultsController!, didChangeSection sectionInfo: NSFetchedResultsSectionInfo!, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType)  {
        
        // Regenerate section info
        sections = sectionInfoWithEmptySections(showsEmptySections)
        
        // When we show empty sections, fetched changes don't affect our delegate
        if !showsEmptySections {
            delegate?.controller?(controller, didChangeSection: sectionInfo, atIndex: sectionIndex, forChangeType: type)
        }
    }
    
    public func controller(controller: NSFetchedResultsController!, didChangeObject anObject: AnyObject!, atIndexPath indexPath: NSIndexPath!, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath!)  {
        
        let displayedOldIndexPath = displayedIndexPathForFetchedIndexPath(indexPath, sections: oldSectionsDuringFetchUpdate)
        let displayedNewIndexPath = displayedIndexPathForFetchedIndexPath(newIndexPath, sections: sections)
        
        let metaData = anObject as ToDoMetaData
        
        delegate?.controller?(controller, didChangeObject: metaData.toDo, atIndexPath: displayedOldIndexPath, forChangeType: type, newIndexPath: displayedNewIndexPath)
    }
    
    public func controllerDidChangeContent(controller: NSFetchedResultsController!)  {
        delegate?.controllerDidChangeContent?(controller)
    }
}

public class ControllerSectionInfo: NSFetchedResultsSectionInfo {
    let section: ToDoSection
    private let fetchedIndex: Int?
    private let fetchController: NSFetchedResultsController
    
    public var name: String! { return section.title() }
    public var indexTitle: String! { return nil }
    public var numberOfObjects: Int {
        return fetchedInfo?.numberOfObjects ?? 0
    }
    public var objects: [AnyObject]! { return fetchedInfo?.objects }
    public var fetchedInfo: NSFetchedResultsSectionInfo? {
        return fetchedIndex.hasValue ? fetchController.sections[fetchedIndex!] as? NSFetchedResultsSectionInfo : nil
    }
    
    init(section: ToDoSection, fetchedIndex: Int?, fetchController: NSFetchedResultsController) {
        self.section = section
        self.fetchedIndex = fetchedIndex
        self.fetchController = fetchController
    }
}
