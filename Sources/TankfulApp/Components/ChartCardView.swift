//
//  ChartCardView.swift
//  tankful
//
//  Created by Jake Walker on 10/11/2026.
//

import SwiftUI

struct ChartCardView<Content: View>: View {
    let title: LocalizedStringKey
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.headline)

            content
        }
        .cardStyle()
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
