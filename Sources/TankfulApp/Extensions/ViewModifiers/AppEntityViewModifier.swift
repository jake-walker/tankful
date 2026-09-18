//
//  AppEntityViewModifier.swift
//  tankful
//
//  Created by Jake Walker on 17/09/2026.
//

import SwiftUI
import TankfulDomain

#if canImport(AppIntents) && canImport(TankfulIntents)
    import AppIntents
    import TankfulIntents
#endif

struct VehicleEntityModifier: ViewModifier {
    let id: Vehicle.ID?

    func body(content: Content) -> some View {
        #if canImport(AppIntents) && canImport(TankfulIntents)
            if #available(anyAppleOS 26.0, *), let id {
                content.appEntityIdentifier(
                    EntityIdentifier(
                        for: VehicleEntity.self,
                        identifier: id
                    )
                )
            } else {
                content
            }
        #else
            content
        #endif
    }
}

struct FuelLogEntityModifier: ViewModifier {
    let id: FuelLog.ID?

    func body(content: Content) -> some View {
        #if canImport(AppIntents) && canImport(TankfulIntents)
            if #available(anyAppleOS 26.0, *), let id {
                content.appEntityIdentifier(
                    EntityIdentifier(
                        for: FuelLogEntity.self,
                        identifier: id
                    )
                )
            } else {
                content
            }
        #else
            content
        #endif
    }
}

extension View {
    func vehicleEntity(id: Vehicle.ID?) -> some View {
        modifier(VehicleEntityModifier(id: id))
    }

    func fuelLogEntity(id: FuelLog.ID?) -> some View {
        modifier(FuelLogEntityModifier(id: id))
    }
}
