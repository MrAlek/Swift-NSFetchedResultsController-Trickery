//
//  OptionalHasValue.swift
//  CoreDataTrickerySwift
//
//  Created by Alek Åström on 2014-09-10.
//  Copyright (c) 2014 Apps and Wonders. All rights reserved.
//

import Foundation

extension Optional {
    public var hasValue: Bool {
        return (self != nil)
    }
}
