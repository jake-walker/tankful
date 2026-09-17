//
//  SyncConfiguration.swift
//  tankful
//
//  Created by Jake Walker on 15/09/2026.
//

import Foundation

public struct SyncConfiguration: Sendable, Codable {
    public var type: BackendType
    public var baseURL: URL
    public var additionalHeaders: [String: String]
    public var authentication: Authentication?

    public enum Authentication: Sendable, Codable {
        case credentials(username: String, password: String)
        case header(name: String, value: String)
    }

    public init(
        type: BackendType,
        baseURL: URL,
        additionalHeaders: [String: String] = [:],
        authentication: Authentication? = nil
    ) {
        self.type = type
        self.baseURL = baseURL
        self.additionalHeaders = additionalHeaders
        self.authentication = authentication
    }
}

public enum BackendType: String, Sendable, Codable, CaseIterable {
    case tracktor
    case lubeLogger

    public var displayName: String {
        switch self {
        case .lubeLogger: NSLocalizedString("LubeLogger", comment: "LubeLogger backend name")
        case .tracktor: NSLocalizedString("Tracktor", comment: "Tracktor backend name")
        }
    }
}
