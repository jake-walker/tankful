//
//  FuelType.swift
//  tankful
//
//  Created by Jake Walker on 14/09/2026.
//

import Foundation

public enum FuelType: String, Codable, CaseIterable, Identifiable, Sendable {
    case petrol
    case diesel

    public var id: Self {
        self
    }

    public var name: String {
        switch self {
        case .petrol:
            NSLocalizedString("Petrol", comment: "Fuel type")
        case .diesel:
            NSLocalizedString("Diesel", comment: "Fuel type")
        }
    }
}
