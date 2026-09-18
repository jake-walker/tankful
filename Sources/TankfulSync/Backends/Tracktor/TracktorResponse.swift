//
//  TracktorResponse.swift
//  tankful
//
//  Created by Jake Walker on 16/09/2026.
//

struct TracktorResponse<Data: Decodable & Sendable>: Decodable, Sendable {
    let success: Bool
    let data: Data
}
