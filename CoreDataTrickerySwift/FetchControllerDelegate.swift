//
//  FetchControllerDelegate.swift
//  CoreDataTrickerySwift
//
//  Created by Alek Astrom on 2014-08-04.
//  Copyright (c) 2014 Apps and Wonders. All rights reserved.
//

import CoreData
import UIKit

open class FetchControllerDelegate: NSObject, NSFetchedResultsControllerDelegate {
    
    fileprivate var sectionsBeingAdded: [Int] = []
    fileprivate var sectionsBeingRemoved: [Int] = []
    fileprivate unowned let tableView: UITableView
    
    open var onUpdate: ((_ cell: UITableViewCell, _ object: AnyObject) -> Void)?
    open var ignoreNextUpdates: Bool = false
    
    init(tableView: UITableView) {
        self.tableView = tableView
    }
    
    open func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>)  {
        if ignoreNextUpdates {
            return
        }
        
        sectionsBeingAdded = []
        sectionsBeingRemoved = []
        tableView.beginUpdates()
    }
    
    open func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType)  {
        if ignoreNextUpdates {
            return
        }
        
        switch type {
        case .insert:
            sectionsBeingAdded.append(sectionIndex)
            tableView.insertSections(IndexSet(integer: sectionIndex), with: .fade)
        case .delete:
            sectionsBeingRemoved.append(sectionIndex)
            self.tableView.deleteSections(IndexSet(integer: sectionIndex), with: .fade)
        default:
            return
        }
    }
    
    
    open func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        if ignoreNextUpdates {
            return
        }
        
        switch type {
        case .insert:
            tableView.insertRows(at: [newIndexPath!], with: .automatic)
        case .delete:
            tableView.deleteRows(at: [indexPath!], with: .automatic)
        case .update:
            if let indexPath = indexPath, let cell = tableView.cellForRow(at: indexPath) {
                onUpdate?(cell, anObject as AnyObject)
            }
        case .move:
            // Stupid and ugly, rdar://17684030
            if !sectionsBeingAdded.contains(newIndexPath!.section) && !sectionsBeingRemoved.contains(indexPath!.section) {
                tableView.moveRow(at: indexPath!, to: newIndexPath!)
                onUpdate?(tableView.cellForRow(at: indexPath!)!, anObject as AnyObject)
            } else {
                tableView.deleteRows(at: [indexPath!], with: .fade)
                tableView.insertRows(at: [newIndexPath!], with: .fade)
            }
        @unknown default:
            break
        }
    }
    
    open func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>)  {
        if !ignoreNextUpdates {
            tableView.endUpdates()
        }
        
        ignoreNextUpdates = false
    }
}
