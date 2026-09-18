//
//  TracktorBackend.swift
//  tankful
//

import Foundation
import TankfulDomain

@MainActor
public final class TracktorBackend: SyncBackend {
    public enum Error: Swift.Error, Equatable, Sendable, LocalizedError {
        case unsuccessfulResponse(endpoint: String)
        case requiredConfigKeyMissing
        case unsupportedUnit(unit: String)
        case unsupportedFuelType(fuelType: String)
        case missingID
        case invalidDate(date: String)
        case unsupportedCurrency(currencyCode: String)
        case missingRemoteID
        case currencyMismatch(logCurrency: String, remoteCurrency: String)

        public var errorDescription: String? {
            switch self {
            case let .unsuccessfulResponse(endpoint):
                String(
                    format: NSLocalizedString("Request to Tracktor was unsuccessful (%@)", comment: "Tracktor sync error; argument is an API endpoint"),
                    endpoint
                )
            case .requiredConfigKeyMissing:
                NSLocalizedString(
                    "Tracktor config is missing one or more required config keys",
                    comment: "Tracktor sync configuration error"
                )
            case let .unsupportedUnit(unit):
                String(
                    format: NSLocalizedString("Unsupported unit %@", comment: "Tracktor sync error; argument is a measurement unit"),
                    unit
                )
            case let .unsupportedFuelType(fuelType):
                String(
                    format: NSLocalizedString("Unsupported fuel type %@", comment: "Tracktor sync error; argument is a fuel type"),
                    fuelType
                )
            case .missingID:
                NSLocalizedString("Tracktor did not give an ID for a model", comment: "Tracktor sync response error")
            case let .invalidDate(date):
                String(
                    format: NSLocalizedString("Failed to parse date from Tracktor (%@)", comment: "Tracktor sync error; argument is a date value"),
                    date
                )
            case let .unsupportedCurrency(currency):
                String(
                    format: NSLocalizedString("Unsupported currency %@", comment: "Tracktor sync error; argument is a currency code"),
                    currency
                )
            case .missingRemoteID:
                NSLocalizedString("Local entity is missing remote ID", comment: "Tracktor sync error")
            case let .currencyMismatch(local, remote):
                String(
                    format: NSLocalizedString("This fill-up uses %$1@, but Tracktor is configured to use %$2@", comment: "Tracktor sync error; arguments are currency codes"),
                    local,
                    remote
                )
            }
        }
    }

    private let client: HTTPClient
    private let credentials: SyncConfiguration.Authentication?

    private var sessionToken: String?
    private var configuration: TracktorUnits?

    public init(
        client: HTTPClient,
        credentials: SyncConfiguration.Authentication?
    ) {
        self.client = client
        self.credentials = credentials
    }

    public func fetchVehicles() async throws -> [Vehicle] {
        let response: TracktorResponse<[TracktorVehicle]> = try await authenticatedRequest(
            .get,
            path: "/api/vehicles"
        )

        guard response.success else {
            throw Error.unsuccessfulResponse(endpoint: "/api/vehicles")
        }

        return try response.data
            .map { try $0.toDomain() }
    }

    public func fetchFuelLogs(remoteVehicleID: String) async throws -> [FuelLog] {
        let config = try await configuration()

        let response: TracktorResponse<[TracktorFuelLog]> = try await authenticatedRequest(
            .get,
            path: "/api/fuel-logs",
            query: [URLQueryItem(name: "vehicleId", value: remoteVehicleID)]
        )

        guard response.success else {
            throw Error.unsuccessfulResponse(endpoint: "/api/fuel-logs")
        }

        return try response.data
            .map { try $0.toDomain(units: config) }
    }

    public func createVehicle(_ vehicle: Vehicle) async throws -> String {
        let response: TracktorResponse<TracktorVehicle> = try await authenticatedRequest(
            .post,
            path: "/api/vehicles",
            body: TracktorVehicle(vehicle)
        )

        guard response.success else {
            throw Error.unsuccessfulResponse(endpoint: "/api/vehicles")
        }

        guard let id = response.data.id else {
            throw Error.missingID
        }

        return id
    }

    public func updateVehicle(_ vehicle: Vehicle) async throws {
        guard let remoteID = vehicle.remoteID else {
            throw Error.missingRemoteID
        }

        let response: TracktorResponse<TracktorVehicle> = try await authenticatedRequest(
            .put,
            path: "/api/vehicles",
            body: TracktorVehicle(vehicle)
        )

        guard response.success else {
            throw Error.unsuccessfulResponse(endpoint: "/api/vehicles")
        }
    }

    public func deleteVehicle(remoteID: String) async throws {
        let response: TracktorResponse<Data> = try await authenticatedRequest(
            .delete,
            path: "/api/vehicles/\(remoteID)"
        )

        guard response.success else {
            throw Error.unsuccessfulResponse(endpoint: "/api/vehicles/\(remoteID)")
        }
    }

    public func createFuelLog(_ log: FuelLog, remoteVehicleID: String) async throws -> String {
        let config = try await configuration()

        let response: TracktorResponse<TracktorFuelLog> = try await authenticatedRequest(
            .post,
            path: "/api/vehicles/\(remoteVehicleID)/fuel-logs",
            body: TracktorFuelLog(
                log,
                remoteUnits: config,
                remoteVehicleID: remoteVehicleID
            )
        )

        guard response.success else {
            throw Error.unsuccessfulResponse(endpoint: "/api/vehicles/\(remoteVehicleID)/fuel-logs")
        }

        guard let id = response.data.id else {
            throw Error.missingID
        }

        return id
    }

    public func updateFuelLog(_ log: FuelLog, remoteVehicleID: String) async throws {
        guard let remoteID = log.remoteID else {
            throw Error.missingRemoteID
        }

        let config = try await configuration()

        let response: TracktorResponse<TracktorFuelLog> = try await authenticatedRequest(
            .put,
            path: "/api/vehicles/\(remoteVehicleID)/fuel-logs/\(remoteID)",
            body: TracktorFuelLog(
                log,
                remoteUnits: config,
                remoteVehicleID: remoteVehicleID
            )
        )

        guard response.success else {
            throw Error.unsuccessfulResponse(endpoint: "/api/vehicles/\(remoteVehicleID)/fuel-logs/\(remoteID)")
        }
    }

    public func deleteFuelLog(remoteID: String, remoteVehicleID: String) async throws {
        let response: TracktorResponse<Data> = try await authenticatedRequest(
            .delete,
            path: "/api/vehicles/\(remoteVehicleID)/fuel-logs/\(remoteID)"
        )

        guard response.success else {
            throw Error.unsuccessfulResponse(endpoint: "/api/vehicles/\(remoteVehicleID)/fuel-logs/\(remoteID)")
        }
    }
}

private extension TracktorBackend {
    private func configuration() async throws -> TracktorUnits {
        if let configuration {
            return configuration
        }

        let response: TracktorResponse<[TracktorConfigItem]> = try await authenticatedRequest(
            .get,
            path: "/api/config"
        )

        guard response.success else {
            throw Error.unsuccessfulResponse(endpoint: "/api/config")
        }

        guard let unitOfDistance = response.data.first(where: { $0.key == "unitOfDistance" }),
              let unitOfVolume = response.data.first(where: { $0.key == "unitOfVolume" }),
              let currency = response.data.first(where: { $0.key == "currency" })
        else {
            throw Error.requiredConfigKeyMissing
        }

        let lengthUnit: UnitLength
        let volumeUnit: UnitVolume

        switch unitOfDistance.value {
        case "mile": lengthUnit = .miles
        case "kilometer", "kilometre": lengthUnit = .kilometers
        case "meter", "metre": lengthUnit = .meters
        case let value: throw Error.unsupportedUnit(unit: value)
        }

        switch unitOfVolume.value {
        case "liter", "litre": volumeUnit = .liters
        case "gallon": volumeUnit = .gallons
        case let value: throw Error.unsupportedUnit(unit: value)
        }

        let units = TracktorUnits(
            distance: lengthUnit,
            volume: volumeUnit,
            currency: currency.value
        )
        configuration = units

        return units
    }

    private func sessionToken() async throws -> String? {
        // no authentication setup
        guard case let .credentials(username: username, password: password) = credentials else {
            return nil
        }

        if let sessionToken {
            return sessionToken
        }

        let response: TracktorResponse<TracktorAuthResponse> = try await client.request(
            .post,
            path: "/api/auth",
            body: TracktorAuthRequest(
                username: username,
                password: password
            )
        )

        guard response.success else {
            throw Error.unsuccessfulResponse(endpoint: "/api/auth")
        }

        sessionToken = response.data.sessionToken

        return response.data.sessionToken
    }

    func authenticatedRequest<Response: Decodable & Sendable>(
        _ method: HTTPMethod,
        path: String,
        query _: [URLQueryItem] = [],
        response: Response.Type = Response.self
    ) async throws -> Response {
        var headers: [String: String] = [:]

        if let token = try await sessionToken() {
            headers["Cookie"] = "session=\(token)"
        }

        return try await client.request(
            method,
            path: path,
            headers: headers,
            response: response
        )
    }

    func authenticatedRequest<Body: Encodable & Sendable, Response: Decodable & Sendable>(
        _ method: HTTPMethod,
        path: String,
        query _: [URLQueryItem] = [],
        body: Body,
        response: Response.Type = Response.self
    ) async throws -> Response {
        var headers: [String: String] = [:]

        if let token = try await sessionToken() {
            headers["Cookie"] = "session=\(token)"
        }

        return try await client.request(
            method,
            path: path,
            headers: headers,
            body: body,
            response: response
        )
    }
}
