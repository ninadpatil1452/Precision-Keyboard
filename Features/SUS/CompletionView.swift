//
//  CompletionView.swift
//  Precision Keyboard
//
//  Created by Ninad Patil on 24/09/25.
//

import SwiftUI

struct CompletionView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.seal.fill").font(.system(size: 64)).foregroundStyle(.green)
            Text("Testing Complete").font(.title2).fontWeight(.semibold)
            Text("Thank you for participating. Your responses have been recorded.")
                .foregroundStyle(.secondary).multilineTextAlignment(.center).padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}
