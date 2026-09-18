//
//  HTTPClient.swift
//  tankful
//
//  Created by Jake Walker on 15/09/2026.
//

import Foundation
#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

public struct HTTPClient: Sendable {
    private let baseURL: URL
    private let headers: [String: String]
    private let authentication: SyncConfiguration.Authentication?
    private let session: URLSession

    public init(
        baseURL: URL,
        headers: [String: String],
        authentication: SyncConfiguration.Authentication? = nil,
        session: URLSession = .shared
    ) {
        self.baseURL = baseURL
        self.headers = headers
        self.authentication = authentication
        self.session = session
    }

    public init(
        configuration: SyncConfiguration,
        session: URLSession = .shared
    ) {
        self.init(
            baseURL: configuration.baseURL,
            headers: configuration.additionalHeaders,
            authentication: configuration.authentication,
            session: session
        )
    }
}

private extension HTTPClient {
    func makeRequest(
        _ method: HTTPMethod,
        path: String,
        query: [URLQueryItem],
        headers: [String: String]? = nil
    ) throws -> URLRequest {
        let url = baseURL.appending(path: path)

        guard var components = URLComponents(
            url: url,
            resolvingAgainstBaseURL: false
        ) else {
            throw URLError(.badURL)
        }

        if !query.isEmpty {
            components.queryItems = query
        }

        guard let url = components.url else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue(
            "application/json",
            forHTTPHeaderField: "Accept"
        )

        for (name, value) in self.headers {
            request.setValue(value, forHTTPHeaderField: name)
        }

        if let headers {
            for (name, value) in headers {
                request.setValue(value, forHTTPHeaderField: name)
            }
        }

        applyAuthentication(to: &request)

        return request
    }

    func applyAuthentication(to request: inout URLRequest) {
        switch authentication {
        case .none:
            break

        case let .header(name: name, value: value):
            request.setValue(
                value,
                forHTTPHeaderField: name
            )

        case .credentials:
            // Backends exchange application credentials themselves
            break
        }
    }

    func perform<Response: Decodable>(
        _ request: URLRequest
    ) async throws -> Response {
        let (data, response) = try await session.data(for: request)

        guard let response = response as? HTTPURLResponse else {
            throw HTTPError.invalidResponse
        }

        guard 200 ..< 300 ~= response.statusCode else {
            throw HTTPError.unsuccessfulStatusCode(
                response.statusCode,
                data
            )
        }

        return try JSONDecoder().decode(Response.self, from: data)
    }
}

public extension HTTPClient {
    func request<Response: Decodable>(
        _ method: HTTPMethod,
        path: String,
        query: [URLQueryItem] = [],
        headers: [String: String]? = nil,
        response _: Response.Type = Response.self
    ) async throws -> Response {
        let request = try makeRequest(
            method,
            path: path,
            query: query,
            headers: headers
        )

        return try await perform(request)
    }

    func request<Body: Encodable, Response: Decodable>(
        _ method: HTTPMethod,
        path: String,
        query: [URLQueryItem] = [],
        headers: [String: String]? = nil,
        body: Body,
        response _: Response.Type = Response.self
    ) async throws -> Response {
        var request = try makeRequest(
            method,
            path: path,
            query: query,
            headers: headers
        )

        request.httpBody = try JSONEncoder().encode(body)
        request.setValue(
            "application/json",
            forHTTPHeaderField: "Content-Type"
        )

        return try await perform(request)
    }
}

public enum HTTPMethod: String, Sendable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

public enum HTTPError: Error, LocalizedError {
    case invalidResponse
    case unsuccessfulStatusCode(Int, Data)

    public var errorDescription: String? {
        switch self {
        case .invalidResponse:
            NSLocalizedString("The server returned an invalid HTTP response.", comment: "HTTP response error")
        case let .unsuccessfulStatusCode(statusCode, _):
            String(
                format: NSLocalizedString(
                    "The server returned HTTP status %lld.",
                    comment: "HTTP response error; argument is the numeric status code"
                ),
                Int64(statusCode)
            )
        }
    }
}
