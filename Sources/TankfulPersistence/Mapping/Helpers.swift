//
//  Helpers.swift
//  tankful
//
//  Created by Jake Walker on 14/09/2026.
//

func decodeEnum<T>(_ type: T.Type, from value: String) throws -> T
where T: RawRepresentable, T.RawValue == String
{
    guard let result = T(rawValue: value) else {
        throw PersistenceMappingError.invalidEnumValue(type: type, value: value)
    }
    
    return result
}
