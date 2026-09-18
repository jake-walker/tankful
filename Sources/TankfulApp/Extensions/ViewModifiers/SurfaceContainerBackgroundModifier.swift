//
//  SurfaceContainerBackgroundModifier.swift
//  tankful
//
//  Created by Jake Walker on 18/09/2026.
//

#if SKIP
    import androidx.compose.material3.MaterialTheme
    import SkipUI

    struct SurfaceContainerBackgroundModifier: ContentModifier {
        func modify(view: any View) -> any View {
            // Resolve the Material theme color during Compose rendering.
            view.background(SkipUI.Color(colorImpl: {
                MaterialTheme.colorScheme.surfaceContainer
            }))
        }
    }
#endif
