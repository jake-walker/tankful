//
//  FuelLogController.swift
//  tankful
//
//  Created by Jake Walker on 16/09/2026.
//

import TankfulDomain

@MainActor
final class FuelLogController {
    private let repository: any FuelLogRepository
    
    init(repository: any FuelLogRepository) {
        self.repository = repository
    }
    
    func create(_ fuelLog: FuelLog) async throws {
        var fuelLog = fuelLog
        fuelLog.syncState = .created
        
        try await repository.save(fuelLog)
    }
    
    func update(_ fuelLog: FuelLog) async throws {
        var fuelLog = fuelLog
        
        if fuelLog.syncState != .created {
            fuelLog.syncState = .modified
        }
        
        try await repository.save(fuelLog)
    }
}
