//
//  Quiz+CoreDataProperties.swift
//  QuizRepo
//
//  Created by Admin on 04/03/25.
//
//

import Foundation
import CoreData


extension Quiz {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Quiz> {
        return NSFetchRequest<Quiz>(entityName: "Quiz")
    }

    @NSManaged public var uuidIdentifier: UUID?
    @NSManaged public var question: String?
    @NSManaged public var option1: String?
    @NSManaged public var option2: String?
    @NSManaged public var option3: String?
    @NSManaged public var option4: String?
    @NSManaged public var correctOption: Int16
    @NSManaged public var sort: Int16
    @NSManaged public var hasAnswered: Bool
    @NSManaged public var hasBookmarked: Bool
    @NSManaged public var hasSkipped: Bool
    @NSManaged public var selectedOption: Int16
    @NSManaged public var questiionType: String?
    @NSManaged public var solution: QuizSolution?

}

extension Quiz : Identifiable {

}
