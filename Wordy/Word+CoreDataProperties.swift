//
//  Word+CoreDataProperties.swift
//  Wordy
//
//  Created by Jonathan Collins on 11/22/17.
//  Copyright © 2017 JC. All rights reserved.
//
//

import Foundation
import CoreData


extension Word {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Word> {
        return NSFetchRequest<Word>(entityName: "Word")
    }

    @NSManaged public var passed: Bool
    @NSManaged public var id: Double
    @NSManaged public var word: String?
    @NSManaged public var definition: String?

}
