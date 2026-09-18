import AppIntents
import TankfulDomain

@available(anyAppleOS 26.0, *)
public struct FuelLogEntity: AppEntity {
    public static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(
            name: "Fill-Up",
            numericFormat: "\(placeholder: .int) fill-ups"
        )
    }

    public var displayRepresentation: DisplayRepresentation {
        let formattedDate = date.formatted(date: .abbreviated, time: .omitted)

        return DisplayRepresentation(
            title: "\(formattedDate)",
            subtitle: "\(vehicle.name)"
        )
    }

    public static let defaultQuery = FuelLogEntityQuery()

    public let id: UUID

    @Property(title: "Vehicle")
    public var vehicle: VehicleEntity

    @Property(title: "Date")
    public var date: Date

    @Property(title: "Odometer")
    public var odometer: Measurement<UnitLength>?

    @Property(title: "Volume")
    public var volume: Measurement<UnitVolume>?

    @Property(title: "Cost")
    public var cost: Double

    @Property(title: "Notes")
    public var notes: String?

    init(_ fuelLog: FuelLog, vehicle: VehicleEntity) {
        id = fuelLog.id
        self.vehicle = vehicle
        date = fuelLog.date
        odometer = fuelLog.odometer
        volume = fuelLog.volume
        cost = NSDecimalNumber(decimal: fuelLog.cost.exactAmount).doubleValue
        notes = fuelLog.notes
    }
}

//  FuelLogEntity.swift
//  tankful
//
//  Created by Jake Walker on 17/09/2026.
//
