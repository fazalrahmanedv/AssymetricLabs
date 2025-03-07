//
//  ResetButton.swift
//  QuizApp
//
//  Created by fazalulrahiman on 6.3.2025.
//

import SwiftUI

struct ResetButton: View {
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Image(systemName: "arrow.counterclockwise.circle.fill")
                .font(.title3)
                .foregroundColor(.red)
        }
    }
}

