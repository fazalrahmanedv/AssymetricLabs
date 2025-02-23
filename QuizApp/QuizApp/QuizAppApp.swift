//
//  QuizAppApp.swift
//  QuizApp
//
//  Created by Admin on 23/02/25.
//

import SwiftUI

@main
struct QuizAppApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
