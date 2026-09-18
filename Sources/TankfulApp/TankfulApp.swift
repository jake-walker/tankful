// Licensed under the GNU General Public License v3.0 or later
// SPDX-License-Identifier: GPL-3.0-or-later
// swiftformat:disable all

import Foundation
import SkipFuse
import SwiftUI
import TankfulPersistence
import TankfulSync

#if canImport(TankfulIntents)
import TankfulIntents
#endif

/// A logger for the TankfulApp module.
let logger: Logger = Logger(subsystem: "xyz.jakewalker.tankful", category: "TankfulApp")

/// The shared top-level view for the app, loaded from the platform-specific App delegates below.
///
/// The default implementation merely loads the `ContentView` for the app and logs a message.
/* SKIP @bridge */public struct TankfulAppRootView : View {
    @Environment(\.scenePhase) internal var scenePhase

    @State internal var env: AppEnvironment

    /* SKIP @bridge */public init() {
        let directory = URL.applicationSupportDirectory.appendingPathComponent("Tankful", isDirectory: true)

        try! FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )

        let database = try! TankfulDatabase.live(at: directory.appendingPathComponent("Tankful.sqlite"))

        let vehicleRepository = SQLiteVehicleRepository(database: database)
        let fuelLogRepository = SQLiteFuelLogRepository(database: database)
        let router = AppRouter()

        _env = State(
            initialValue: AppEnvironment(
                router: router,
                vehicleRepository: vehicleRepository,
                fuelLogRepository: fuelLogRepository
            )
        )

        #if os(iOS) || os(macOS)
        TankfulIntentsEnvironment.configure(
            vehicleRepository: vehicleRepository,
            fuelLogRepository: fuelLogRepository,
            openFuelLog: { id in
                router.push(.fuelLog(id))
            },
            openVehicle: { id in
                router.push(.vehicle(id))
            }
        )
        #endif
    }

    public var body: some View {
        RootView()
            .environment(env)
            .task {
                try? await env.resolveCurrentVehicle()
                await env.refreshVehicleSpotlightIndex()
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    print("Running background sync")
                    Task { await env.backgroundSyncIfNeeded() }
                }
            }
    }
}

/// Global application delegate functions.
///
/// These functions can update a shared observable object to communicate app state changes to interested views.
/* SKIP @bridge */public final class TankfulAppAppDelegate : Sendable {
    /* SKIP @bridge */public static let shared = TankfulAppAppDelegate()

    private init() {
    }

    /* SKIP @bridge */public func onInit() {
        logger.debug("onInit")
    }

    /* SKIP @bridge */public func onLaunch() {
        logger.debug("onLaunch")
    }

    /* SKIP @bridge */public func onResume() {
        logger.debug("onResume")
    }

    /* SKIP @bridge */public func onPause() {
        logger.debug("onPause")
    }

    /* SKIP @bridge */public func onStop() {
        logger.debug("onStop")
    }

    /* SKIP @bridge */public func onDestroy() {
        logger.debug("onDestroy")
    }

    /* SKIP @bridge */public func onLowMemory() {
        logger.debug("onLowMemory")
    }
}
