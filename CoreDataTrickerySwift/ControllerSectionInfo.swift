//
//  ControllerSectionInfo.swift
//  CoreDataTrickerySwift
//
//  Created by Alek Åström on 2014-08-20.
//  Copyright (c) 2014 Apps and Wonders. All rights reserved.
//

import CoreData

class ControllerSectionInfo {
    
    // ========================================
    // MARK: - Internal properties
    // ========================================
    
    let section: ToDoSection
    let fetchedIndex: Int?
    let fetchController: NSFetchedResultsController<NSFetchRequestResult>
    var fetchedInfo: NSFetchedResultsSectionInfo? {
        guard let index = fetchedIndex else {
            return nil
        }
        return fetchController.sections![index]
    }
    
    // ========================================
    // MARK: - Internal methods
    // ========================================
    
    init(section: ToDoSection, fetchedIndex: Int?, fetchController: NSFetchedResultsController<NSFetchRequestResult>) {
        self.section = section
        self.fetchedIndex = fetchedIndex
        self.fetchController = fetchController
    }
}

extension ControllerSectionInfo: NSFetchedResultsSectionInfo {
    @objc var name: String { return section.title }
    @objc var indexTitle: String? { return "" }
    @objc var numberOfObjects: Int { return fetchedInfo?.numberOfObjects ?? 0 }
    @objc var objects: [Any]? { return fetchedInfo?.objects as [AnyObject]?? ?? [] }
}
