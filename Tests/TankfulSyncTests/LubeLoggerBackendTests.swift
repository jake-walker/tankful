import Currency
import Foundation
import TankfulDomain
@testable import TankfulSync
import Testing

@Suite(.serialized)
@MainActor
struct LubeLoggerBackendTests {
    private let vehiclesResponse: String = """
    [
        {
            "dashboardMetrics": [],
            "extraFields": [],
            "hasOdometerAdjustment": false,
            "id": 7,
            "imageLocation": "/defaults/noimage.png",
            "isDiesel": false,
            "isElectric": false,
            "licensePlate": "ABC DEF",
            "make": "Volkswagen",
            "mapLocation": "",
            "model": "Golf",
            "odometerDifference": 0,
            "odometerMultiplier": 1,
            "odometerOptional": false,
            "purchaseDate": "",
            "purchasePrice": 0,
            "soldDate": "",
            "soldPrice": 0,
            "tags": [],
            "useHours": false,
            "vehicleIdentifier": "LicensePlate",
            "year": 2021
        }
    ]
    """

    private let fuelLogResponse: String = """
    [
        {
            "cost": 52.85,
            "date": "2026-11-25",
            "endingSoc": 0,
            "extraFields": [],
            "files": [],
            "fuelConsumed": 43.21,
            "fuelEconomy": 0,
            "id": 5,
            "isFillToFull": true,
            "missedFuelUp": false,
            "notes": "",
            "odometer": 12345,
            "startingSoc": 0,
            "tags": "",
            "vehicleId": 7
        }
    ]
    """

    private let currency: (any CurrencyDescriptor.Type) = GBP.self

    @Test func importsRepresentativeServerRecords() throws {
        let parsedVehicle = try JSONDecoder().decode([LubeLoggerVehicleRead].self, from: Data(vehiclesResponse.utf8))
        let actualVehicle = try #require(parsedVehicle.first).toDomain()
        #expect(actualVehicle.name == nil)
        #expect(actualVehicle.make == "Volkswagen")
        #expect(actualVehicle.model == "Golf")
        #expect(actualVehicle.year == 2021)
        #expect(actualVehicle.licensePlate == "ABC DEF")
        #expect(actualVehicle.fuelType == .petrol)
        #expect(actualVehicle.remoteID == "7")

        let parsedLog = try JSONDecoder().decode([LubeLoggerGasRecord].self, from: Data(fuelLogResponse.utf8))
        let actualLog = try #require(parsedLog.first).toDomain(units: .init(distance: .miles, volume: .liters, currency: currency))
        let expectedDate = try #require(Calendar.current.date(from: DateComponents(year: 2026, month: 11, day: 25)))
        #expect(actualLog.date == expectedDate)
        #expect(actualLog.odometer == .init(value: 12345, unit: .miles))
        #expect(actualLog.volume == .init(value: 43.21, unit: .liters))
        #expect(actualLog.cost.exactAmount == 52.85)
        #expect(actualLog.cost.descriptor.alphabeticCode == "GBP")
        #expect(actualLog.filled == true)
        #expect(actualLog.missedLast == false)
        #expect(actualLog.notes == "")
        #expect(actualLog.remoteID == "5")
    }

    @Test func sendsExpectedCreateAndUpdateRequests() async throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        let session = URLSession(configuration: configuration)
        defer { session.invalidateAndCancel() }

        let backend = try LubeLoggerBackend(
            client: HTTPClient(
                baseURL: #require(URL(string: "https://example.test")),
                headers: [:],
                session: session
            ),
            units: .init(distance: .miles, volume: .liters, currency: currency)
        )

        var vehicle = makeVehicle(syncState: .created)
        vehicle.make = "Volkswagen"
        vehicle.model = "Golf"
        vehicle.year = 2021
        vehicle.licensePlate = "ABC DEF"

        StubURLProtocol.state.prepare(
            responseJSON: #"{"success":true,"message":"OK","additionalData":{"vehicleId":7}}"#
        )
        #expect(try await backend.createVehicle(vehicle) == "7")

        var request = try #require(StubURLProtocol.state.request)
        #expect(request.httpMethod == "POST")
        #expect(request.url?.path == "/api/vehicles/add")
        #expect(request.value(forHTTPHeaderField: "culture-invariant") == "yes")
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
        var body = try capturedJSONBody()
        #expect(!body.keys.contains("id"))
        #expect(body["make"] as? String == "Volkswagen")
        #expect(body["model"] as? String == "Golf")
        #expect(body["year"] as? Int == 2021)
        #expect(body["licensePlate"] as? String == "ABC DEF")
        #expect(body["fuelType"] as? String == "Gasoline")
        var extraFields = try #require(body["extraFields"] as? [[String: Any]])
        #expect(extraFields.first?["name"] as? String == "name")
        #expect(extraFields.first?["value"] as? String == "Test car")

        var log = try makeFuelLog(vehicleID: vehicle.id, syncState: .created)
        log.date = try #require(Calendar.current.date(from: DateComponents(year: 2026, month: 11, day: 25)))
        log.odometer = Measurement(value: 12345, unit: UnitLength.miles)
        log.volume = Measurement(value: 43.21, unit: UnitVolume.liters)

        StubURLProtocol.state.prepare(
            responseJSON: #"{"success":true,"message":"OK","additionalData":{"recordId":5}}"#
        )
        #expect(try await backend.createFuelLog(log, remoteVehicleID: "7") == "5")

        request = try #require(StubURLProtocol.state.request)
        #expect(request.httpMethod == "POST")
        #expect(request.url?.path == "/api/vehicle/gasrecords/add")
        #expect(try URLComponents(url: #require(request.url), resolvingAgainstBaseURL: false)?
            .queryItems?.first(where: { $0.name == "vehicleId" })?.value == "7")
        body = try capturedJSONBody()
        #expect(!body.keys.contains("id"))
        #expect(body["date"] as? String == "2026-11-25")
        #expect(body["odometer"] as? Int == 12345)
        #expect(body["fuelConsumed"] as? Double == 43.21)
        #expect(body["cost"] as? Double == 60.50)
        #expect(body["isFillToFull"] as? Bool == true)
        #expect(body["missedFuelUp"] as? Bool == true)
        #expect(body["notes"] as? String == "First fill-up")

        vehicle.remoteID = "7"
        vehicle.name = "Updated name"
        StubURLProtocol.state.prepare(responseJSON: #"{"success":true,"message":"OK"}"#)
        try await backend.updateVehicle(vehicle)

        request = try #require(StubURLProtocol.state.request)
        #expect(request.httpMethod == "PUT")
        #expect(request.url?.path == "/api/vehicles/update")
        body = try capturedJSONBody()
        #expect(body["id"] as? Int == 7)
        extraFields = try #require(body["extraFields"] as? [[String: Any]])
        #expect(extraFields.first?["value"] as? String == "Updated name")

        log.remoteID = "5"
        log.notes = "Updated notes"
        StubURLProtocol.state.prepare(responseJSON: #"{"success":false,"message":"Rejected"}"#)
        await #expect(throws: LubeLoggerBackend.Error.badResponse) {
            try await backend.updateFuelLog(log, remoteVehicleID: "7")
        }

        request = try #require(StubURLProtocol.state.request)
        #expect(request.httpMethod == "PUT")
        #expect(request.url?.path == "/api/vehicle/gasrecords/update")
        body = try capturedJSONBody()
        #expect(body["id"] as? Int == 5)
        #expect(body["notes"] as? String == "Updated notes")
    }

    private func capturedJSONBody() throws -> [String: Any] {
        let data = try #require(StubURLProtocol.state.body)
        return try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
    }
}
