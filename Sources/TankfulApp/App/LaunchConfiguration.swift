//
//  LaunchConfiguration.swift
//  tankful
//
//  Created by Jake Walker on 26/11/2026.
//

import Foundation
import SwiftUI

#if os(Android)
    import SkipFuse
#endif

enum LaunchConfiguration {
    @MainActor
    static var isPreviewMode: Bool {
        #if DEBUG
            #if os(Android)
                guard let activity = UIApplication.shared.dynamicAndroidActivity(),
                      let intent: AnyDynamicObject = activity.intent
                else {
                    return false
                }

                let enabled: Bool? = try? intent.getBooleanExtra(
                    "previewMode",
                    false
                )
                return enabled ?? false
            #else
                return ProcessInfo.processInfo.arguments.contains("previewMode")
            #endif
        #else
            return false
        #endif
    }

    static var isDebug: Bool {
        #if DEBUG
            true
        #else
            false
        #endif
    }
}
