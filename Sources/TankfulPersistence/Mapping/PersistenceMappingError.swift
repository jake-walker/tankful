//
//  PersistenceMappingError.swift
//  tankful
//
//  Created by Jake Walker on 14/09/2026.
//

public enum PersistenceMappingError: Error {
    case invalidUUID
    case invalidEnumValue(type: Any.Type, value: String)
    case invalidDate
}
