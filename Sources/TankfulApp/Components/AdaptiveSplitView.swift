//
//  AdaptiveSplitView.swift
//  tankful
//
//  Created by Jake Walker on 10/11/2026.
//

import SwiftUI

struct AdaptiveSplitView<Primary: View, Secondary: View>: View {
    let breakpoint: CGFloat
    let ratio: CGFloat
    let spacing: CGFloat

    @ViewBuilder let primary: Primary
    @ViewBuilder let secondary: Secondary

    init(
        breakpoint: CGFloat = 700,
        ratio: CGFloat = 0.6,
        spacing: CGFloat = 16,
        @ViewBuilder primary: () -> Primary,
        @ViewBuilder secondary: () -> Secondary
    ) {
        self.breakpoint = breakpoint
        self.ratio = ratio
        self.spacing = spacing
        self.primary = primary()
        self.secondary = secondary()
    }

    var body: some View {
        GeometryReader { geometry in
            let padding: CGFloat = 16
            let width = max(0, geometry.size.width - padding * 2)
            let isExpanded = width >= breakpoint

            #if os(Android)
                let division: CGRect? = nil
            #else
                let division = activeDivision(geometry)
            #endif

            let availableWidth = max(0, width - spacing)

            let primaryWidth: CGFloat = {
                guard isExpanded, let division else {
                    return availableWidth * ratio
                }

                return max(0, division.minX - padding)
            }()

            let secondaryWidth: CGFloat = {
                guard isExpanded, let division else {
                    return availableWidth * (1 - ratio)
                }

                return max(0, geometry.size.width - division.maxX - padding)
            }()

            let columnSpacing: CGFloat = division == nil
                ? spacing
                : max(0, division!.width)

            ScrollView {
                Group {
                    if isExpanded {
                        HStack(alignment: .top, spacing: columnSpacing) {
                            primary
                                .frame(width: primaryWidth)

                            secondary
                                .frame(width: secondaryWidth)
                        }
                    } else {
                        VStack(alignment: .leading, spacing: spacing) {
                            primary
                                .frame(width: width)

                            secondary
                                .frame(width: width)
                        }
                    }
                }
                .padding()
            }
        }
    }

    #if !os(Android)
        private func activeDivision(_ proxy: GeometryProxy) -> CGRect? {
            if #available(anyAppleOS 27.1, *) {
                return proxy.reservedRegions(kind: .division)
                    .first {
                        $0.isActive &&
                            $0.frame.height > $0.frame.width
                    }?
                    .frame
            }

            return nil
        }
    #endif
}

#if !os(Android)
    #Preview {
        AdaptiveSplitView {
            Color.blue
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } secondary: {
            Color.red
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
#endif
