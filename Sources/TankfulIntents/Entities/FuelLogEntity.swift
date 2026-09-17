import AppIntents
import TankfulDomain

@available(anyAppleOS 26.0, *)
public struct FuelLogEntity: AppEntity {
    public static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(
            name: "Fuel Log",
            numericFormat: "\(placeholder: .int) fuel logs"
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

    internal init(_ fuelLog: FuelLog, vehicle: VehicleEntity) {
        self.id = fuelLog.id
        self.vehicle = vehicle
        self.date = fuelLog.date
        self.odometer = fuelLog.odometer
        self.volume = fuelLog.volume
        self.cost = NSDecimalNumber(decimal: fuelLog.cost.exactAmount).doubleValue
        self.notes = fuelLog.notes
    }
}
//  FuelLogEntity.swift
//  tankful
//
//  Created by Jake Walker on 17/09/2026.
//
