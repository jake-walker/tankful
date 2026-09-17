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
        DisplayRepresentation(
            title: "\(name)"
        )
    }
    
    public static let defaultQuery = VehicleEntityQuery()
    
    public let id: UUID
    
    @Property(indexingKey: \.displayName)
    public var name: String
    
    @Property
    public var make: String?
    
    @Property
    public var model: String?
    
    internal init(_ vehicle: Vehicle) {
        self.id = vehicle.id
        self.name = vehicle.displayName
        self.make = vehicle.make
        self.model = vehicle.model
    }
}
