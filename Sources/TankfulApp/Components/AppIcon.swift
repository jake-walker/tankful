// swiftformat:disable unusedArguments,docComments
import SwiftUI

// SKIP @bridge
enum AppSymbol: String {
    case add, save, delete, more, settings, vehicle, fuel, selected, unselected
    case back, forward, chevron, sync, syncDisabled

    var systemName: String {
        switch self {
        case .add: "plus"
        case .save: "checkmark"
        case .delete: "trash"
        case .more: "ellipsis"
        case .settings: "gear"
        case .vehicle: "car"
        case .fuel: "fuelpump"
        case .selected: "checkmark.circle"
        case .unselected: "circle"
        case .back: "chevron.left"
        case .forward: "chevron.right.circle.fill"
        case .chevron: "chevron.right"
        case .sync: "arrow.trianglehead.2.clockwise.rotate.90"
        case .syncDisabled: "circle.slash"
        }
    }
}

struct AppIcon: View {
    let symbol: AppSymbol
    var size: CGFloat = 24

    var body: some View {
        #if os(Android)
            ComposeView { MaterialIconComposer(symbol: symbol) }
                .frame(width: size, height: size)
        #else
            Image(systemName: symbol.systemName)
        #endif
    }
}

struct AppIconLabel: View {
    let title: LocalizedStringKey
    let icon: AppSymbol

    var body: some View {
        Label {
            Text(title)
        } icon: {
            AppIcon(symbol: icon)
        }
    }
}

extension Button where Label == AppIconLabel {
    @MainActor
    init(
        _ title: LocalizedStringKey, appIcon: AppSymbol, role: ButtonRole? = nil,
        action: @escaping @MainActor @Sendable () -> Void
    ) {
        self.init(role: role, action: action) {
            AppIconLabel(title: title, icon: appIcon)
        }
    }
}

#if SKIP
    import androidx.compose.material.icons.__
    import androidx.compose.material.icons.outlined.__
    import androidx.compose.ui.graphics.vector.rememberVectorPainter

    struct MaterialIconComposer: ContentComposer {
        let symbol: AppSymbol

        init(symbol: AppSymbol) {
            self.symbol = symbol
        }

        @Composable func Compose(context: ComposeContext) {
            let vector =
                switch symbol {
                case .add: Icons.Outlined.Add
                case .save: Icons.Outlined.Check
                case .delete: Icons.Outlined.Delete
                case .more: Icons.Outlined.MoreVert
                case .settings: Icons.Outlined.Settings
                case .vehicle: Icons.Outlined.DirectionsCar
                case .fuel: Icons.Outlined.LocalGasStation
                case .selected: Icons.Outlined.CheckCircle
                case .unselected: Icons.Outlined.RadioButtonUnchecked
                case .back: Icons.Outlined.ArrowBack
                case .forward: Icons.Outlined.ArrowForward
                case .chevron: Icons.Outlined.KeyboardArrowRight
                case .sync: Icons.Outlined.Sync
                case .syncDisabled: Icons.Outlined.SyncDisabled
                }
            // Preserve inherited styling, including destructive and secondary colors.
            let tint =
                ForegroundStyle().asColor(opacity: 1.0, animationContext: context)
                    ?? Color.primary.asComposeColor()
            Image(painter: rememberVectorPainter(vector), scale: 1.0)
                .renderingMode(.template)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundStyle(Color(colorImpl: { tint }))
                .Compose(context: context)
        }
    }
#endif
