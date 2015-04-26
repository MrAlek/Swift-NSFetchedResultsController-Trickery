//
//  ControllerSectionInfo.swift
//  CoreDataTrickerySwift
//
//  Created by Alek Åström on 2014-08-20.
//  Copyright (c) 2014 Apps and Wonders. All rights reserved.
//

import CoreData

@objc class ControllerSectionInfo {
    
    // ========================================
    // MARK: - Internal properties
    // ========================================
    
    let section: ToDoSection
    let fetchedIndex: Int?
    let fetchController: NSFetchedResultsController
    var fetchedInfo: NSFetchedResultsSectionInfo? {
        return (fetchedIndex != nil) ? fetchController.sections![fetchedIndex!] as? NSFetchedResultsSectionInfo : nil
    }
    
    // ========================================
    // MARK: - Internal methods
    // ========================================
    
    init(section: ToDoSection, fetchedIndex: Int?, fetchController: NSFetchedResultsController) {
        self.section = section
        self.fetchedIndex = fetchedIndex
        self.fetchController = fetchController
    }
    
}

extension ControllerSectionInfo: NSFetchedResultsSectionInfo {
    var name: String? { return section.title() }
    var indexTitle: String { return "" }
    var numberOfObjects: Int { return fetchedInfo?.numberOfObjects ?? 0 }
    var objects: [AnyObject] { return fetchedInfo?.objects ?? [] }
}
