//
//  TracktorAuth.swift
//  tankful
//
//  Created by Jake Walker on 16/09/2026.
//

internal struct TracktorAuthRequest: Encodable, Sendable {
    let username: String
    let password: String
}

internal struct TracktorAuthResponse: Decodable, Sendable {
    let sessionToken: String
}
