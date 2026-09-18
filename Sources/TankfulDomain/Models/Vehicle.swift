//
//  Vehicle.swift
//  tankful
//
//  Created by Jake Walker on 14/09/2026.
//

import Foundation

public struct Vehicle: Identifiable, Equatable, Codable, Sendable {
    public var id: UUID
    public var name: String?
    public var make: String?
    public var model: String?
    public var year: Int64?
    public var fuelType: FuelType

    public var remoteID: String?
    public var syncState: SyncState

    public init(id: UUID, name: String? = nil, make: String? = nil, model: String? = nil, year: Int64? = nil, fuelType: FuelType, remoteID: String? = nil, syncState: SyncState = .synced) {
        self.id = id
        self.name = name
        self.make = make
        self.model = model
        self.year = year
        self.fuelType = fuelType
        self.remoteID = remoteID
        self.syncState = syncState
    }

    public var displayName: String {
        if let name, !name.isEmpty {
            return name
        }

        let components = [
            make,
            model,
        ]
        .compactMap { $0 }
        .filter { !$0.isEmpty }

        if !components.isEmpty {
            return components.joined(separator: " ")
        }

        return String(
            format: NSLocalizedString("Vehicle %@", comment: "Fallback vehicle name followed by a short identifier"),
            String(id.uuidString.suffix(6)).uppercased()
        )
    }

    public var description: String? {
        let components = [
            year.map(String.init),
            make,
            model,
        ]
        .compactMap { $0 }
        .filter { !$0.isEmpty }

        if components.isEmpty {
            return nil
        }

        return components.joined(separator: " ")
    }

    public func with(id newUUID: UUID) -> Self {
        .init(id: newUUID, name: name, make: make, model: model, year: year, fuelType: fuelType, remoteID: remoteID, syncState: syncState)
    }
}
