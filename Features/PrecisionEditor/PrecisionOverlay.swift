//
//  PrecisionOverlay.swift
//  Precision Keyboard
//
//  Created by Ninad Patil on 24/09/25.
//

import SwiftUI

struct PrecisionOverlay: View {
    @ObservedObject var vm: EditorViewModel
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .frame(height: 160)
                    .overlay(
                        Group {
                            if let img = vm.loupeImage {
                                Image(uiImage: img)
                                    .resizable()
                                    .scaledToFill()
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                            } else {
                                ProgressView().controlSize(.large)
                            }
                        }
                    )
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(.secondary.opacity(0.6), lineWidth: 1))
            }
            Text("Precision mode • long-press to engage")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(radius: 8, y: 2)
        .padding(.bottom)
    }
}
