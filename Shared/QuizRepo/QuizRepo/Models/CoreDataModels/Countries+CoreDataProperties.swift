//
//  Countries+CoreDataProperties.swift
//  QuizRepo
//
//  Created by Admin on 28/02/25.
//
//

import Foundation
import CoreData


extension Countries {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Countries> {
        return NSFetchRequest<Countries>(entityName: "Countries")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var flag: String?
    @NSManaged public var isSelected: Bool

}

extension Countries : Identifiable {

}
