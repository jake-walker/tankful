//
//  VehicleEntity.swift
//  tankful
//
//  Created by Jake Walker on 17/09/2026.
//

import AppIntents
import TankfulDomain

@available(anyAppleOS 26.0, *)
public struct VehicleEntity: IndexedEntity {
    public static var typeDisplayRepresentation: TypeDisplayRepresentation {
        return TypeDisplayRepresentation(
            name: LocalizedStringResource(
                "Vehicle",
                table: "AppIntents",
                comment: "The type name for the vehicle entity"
            ),
            numericFormat: "\(placeholder: .int) vehicles"
        )
    }

    public var displayRepresentation: DisplayRepresentation {
        if let description {
            DisplayRepresentation(
                title: "\(name)",
                subtitle: "\(description)"
            )
        } else {
            DisplayRepresentation(
                title: "\(name)"
            )
        }
    }

    public static let defaultQuery = VehicleEntityQuery()

    public let id: UUID

    @Property(indexingKey: \.displayName)
    public var name: String

    @Property(indexingKey: \.description)
    public var description: String?

    @Property
    public var year: Int?

    @Property
    public var make: String?

    @Property
    public var model: String?

    init(_ vehicle: Vehicle) {
        id = vehicle.id
        name = vehicle.displayName
        description = vehicle.description
        year = vehicle.year.map(Int.init)
        make = vehicle.make
        model = vehicle.model
    }
}
