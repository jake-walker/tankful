// swiftformat:disable unusedArguments

import SwiftUI

#if SKIP
    import androidx.compose.material.icons.__
    import androidx.compose.material.icons.filled.__

    struct FabComposer: ContentComposer {
        let action: () -> Void
        let accessibilityLabel: String

        init(action: @escaping () -> Void, accessibilityLabel: String) {
            self.action = action
            self.accessibilityLabel = accessibilityLabel
        }

        @Composable func Compose(context: ComposeContext) {
            androidx.compose.material3.FloatingActionButton(onClick: action) {
                androidx.compose.material3.Icon(Icons.Filled.Add, accessibilityLabel)
            }
        }
    }
#endif

struct AndroidFab: View {
    let accessibilityLabel: String
    let onClick: () -> Void

    var body: some View {
        #if os(Android)
            ComposeView {
                FabComposer(action: onClick, accessibilityLabel: accessibilityLabel)
            }
            .frame(width: 56, height: 56)
        #else
            EmptyView()
        #endif
    }
}
