//
//  QuizSolution+CoreDataProperties.swift
//  QuizRepo
//
//  Created by Admin on 04/03/25.
//
//

import Foundation
import CoreData


extension QuizSolution {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<QuizSolution> {
        return NSFetchRequest<QuizSolution>(entityName: "QuizSolution")
    }

    @NSManaged public var contentType: String?
    @NSManaged public var contentData: String?
    @NSManaged public var uuid: UUID?
    @NSManaged public var isDownloaded: Bool
    @NSManaged public var ofQuiz: Quiz?

}

extension QuizSolution : Identifiable {

}
