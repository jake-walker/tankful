//
//  StubURLProtocol.swift
//  tankful
//
//  Created by Jake Walker on 25/11/2026.
//

import Foundation

final class StubURLProtocol: URLProtocol {
    static let state = State()

    final class State: @unchecked Sendable {
        private let lock = NSLock()
        private var responseJSON = ""
        private var statusCode = 200
        private var captured: URLRequest?
        private var capturedBody: Data?

        func prepare(responseJSON: String, statusCode: Int = 200) {
            lock.withLock {
                self.responseJSON = responseJSON
                self.statusCode = statusCode
                captured = nil
                capturedBody = nil
            }
        }

        func reply(for request: URLRequest) -> (statusCode: Int, data: Data) {
            lock.withLock {
                captured = request
                capturedBody = Self.bodyData(for: request)
                return (statusCode, Data(responseJSON.utf8))
            }
        }

        var request: URLRequest? {
            lock.withLock { captured }
        }

        var body: Data? {
            lock.withLock { capturedBody }
        }

        private static func bodyData(for request: URLRequest) -> Data? {
            if let body = request.httpBody {
                return body
            }
            guard let stream = request.httpBodyStream else {
                return nil
            }

            stream.open()
            defer { stream.close() }
            var body = Data()
            var buffer = [UInt8](repeating: 0, count: 4096)
            while true {
                let count = stream.read(&buffer, maxLength: buffer.count)
                if count <= 0 {
                    break
                }
                body.append(contentsOf: buffer[..<count])
            }
            return body
        }
    }

    override class func canInit(with _: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        let reply = Self.state.reply(for: request)
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: reply.statusCode,
            httpVersion: nil,
            headerFields: ["Content-Type": "application/json"]
        )!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: reply.data)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
