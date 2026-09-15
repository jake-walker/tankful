//
//  FuelType.swift
//  tankful
//
//  Created by Jake Walker on 14/09/2026.
//

public enum FuelType: String, Codable, CaseIterable, Identifiable, Sendable {
    case petrol
    case diesel
    
    public var id: Self { self }
    
    public var name: String {
        self.rawValue.capitalized
    }
}
