//
//  SyncState.swift
//  tankful
//
//  Created by Jake Walker on 15/09/2026.
//

public enum SyncState: String, Codable, Sendable {
    case synced
    case created
    case modified
}
