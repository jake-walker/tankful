//
//  TracktorAuth.swift
//  tankful
//
//  Created by Jake Walker on 16/09/2026.
//

struct TracktorAuthRequest: Encodable, Sendable {
    let username: String
    let password: String
}

struct TracktorAuthResponse: Decodable, Sendable {
    let sessionToken: String
}
