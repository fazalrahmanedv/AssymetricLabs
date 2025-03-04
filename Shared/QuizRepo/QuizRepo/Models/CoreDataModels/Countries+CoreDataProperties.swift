//
//  Countries+CoreDataProperties.swift
//  QuizRepo
//
//  Created by Admin on 03/03/25.
//
//

import Foundation
import CoreData


extension Countries {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Countries> {
        return NSFetchRequest<Countries>(entityName: "Countries")
    }

    @NSManaged public var flag: String?
    @NSManaged public var id: UUID?
    @NSManaged public var isSelected: Bool
    @NSManaged public var name: String?

}

extension Countries : Identifiable {

}
