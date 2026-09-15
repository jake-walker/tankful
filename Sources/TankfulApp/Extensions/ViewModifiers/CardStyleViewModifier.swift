//
//  CardStyleViewModifier.swift
//  tankful
//
//  Created by Jake Walker on 15/09/2026.
//

import SwiftUI

struct CardStyle: ViewModifier {
    @Environment(\.defaultMinListRowHeight) var listRowHeight
    
    let withPadding: Bool
    
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(withPadding ? 18 : 0)
            .background(.regularMaterial)
            .containerShape(.rect(cornerRadius: listRowHeight / 2))
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardStyle(withPadding: true))
    }
    
    func cardStyle(padding: Bool) -> some View {
        modifier(CardStyle(withPadding: padding))
    }
}

#Preview {
    VStack(alignment: .leading) {
        Text("Card Title")
    }
    .cardStyle()
    .padding()
}
