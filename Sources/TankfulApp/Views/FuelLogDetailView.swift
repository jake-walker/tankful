//
//  FuelLogDetailView.swift
//  tankful
//
//  Created by Jake Walker on 15/09/2026.
//

import SwiftUI
import TankfulDomain

struct FuelLogDetailView: View {
    @Environment(AppEnvironment.self) internal var env
    
    let fuelLogID: FuelLog.ID
    
    @State internal var fuelLog: FuelLog?
    @State internal var vehicle: Vehicle?
    @State internal var isConfirmingDelete: Bool = false
    @State internal var isDeleting: Bool = false
    @State internal var isShowingError: Bool = false
    @State internal var errorMessage: String = ""
    
    var body: some View {
        Group {
            if let fuelLog {
                List {
                    LabeledContent {
                        if let vehicle {
                            Text(vehicle.displayName)
                        } else {
                            Text("-")
                        }
                    } label: {
                        Text("Vehicle")
                    }
                    
                    LabeledContent {
                        Text(fuelLog.date.formatted())
                    } label: {
                        Text("Date")
                    }
                    
                    LabeledContent {
                        if let odometer = fuelLog.odometer {
                            Text(env.formatter.odometer(odometer).description)
                        } else {
                            Text("-")
                        }
                    } label: {
                        Text("Odometer")
                    }
                    
                    Text(fillStatus(for: fuelLog))
                    
                    LabeledContent {
                        if let volume = fuelLog.volume {
                            Text(env.formatter.volume(volume).description)
                        } else {
                            Text("-")
                        }
                    } label: {
                        Text("Volume")
                    }
                    
                    LabeledContent {
                        if let unitCost = fuelLog.unitCost {
                            Text("\(unitCost.localizedString())/\(env.volumeUnit.unit.symbol)")
                        } else {
                            Text("-")
                        }
                    } label: {
                        Text("Unit Cost")
                    }
                    
                    LabeledContent {
                        Text(fuelLog.cost.localizedString())
                    } label: {
                        Text("Total Cost")
                    }
                    
                    if let notes = fuelLog.notes {
                        Text(notes)
                    }
                }
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .fuelLogEntity(id: fuelLog?.id)
        .navigationTitle(fuelLog?.date.formatted(date: .abbreviated, time: .omitted) ?? NSLocalizedString("Loading", comment: "Title shown while a fill-up is loading"))
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button("Delete Fill-Up", systemImage: "trash", role: .destructive) {
                        isConfirmingDelete = true
                    }
                    .disabled(fuelLog == nil || isDeleting)
                } label: {
                    Image(systemName: "ellipsis")
                }
            }
        }
        .confirmationDialog(
            "Delete this fill-up?",
            isPresented: $isConfirmingDelete,
            titleVisibility: .visible
        ) {
            Button("Delete Fill-Up", role: .destructive) {
                Task { await deleteFuelLog() }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This action cannot be undone.")
        }
        .alert("Unable to Delete Fill-Up", isPresented: $isShowingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .task {
            await load()
        }
    }
    
    private func fillStatus(for fuelLog: FuelLog) -> String {
        switch (fuelLog.filled, fuelLog.missedLast) {
        case (true, true):
            NSLocalizedString("Filled, Missed Last", comment: "Fill-up status")
        case (true, false):
            NSLocalizedString("Filled", comment: "Fill-up status")
        case (false, true):
            NSLocalizedString("Not filled, Missed Last", comment: "Fill-up status")
        case (false, false):
            NSLocalizedString("Not filled", comment: "Fill-up status")
        }
    }

    private func deleteFuelLog() async {
        guard !isDeleting else { return }

        isDeleting = true
        defer { isDeleting = false }

        do {
            try await env.fuelLogRepository.delete(id: fuelLogID)
            env.vehicleChangeVersion += 1
            env.router.pop()
        } catch {
            errorMessage = error.localizedDescription
            isShowingError = true
        }
    }

    private func load() async {
        fuelLog = try? await env.fuelLogRepository.fuelLog(id: fuelLogID)
        
        if let fuelLog {
            vehicle = try? await env.vehicleRepository.vehicle(id: fuelLog.vehicleID)
        }
    }
}

#if !os(Android)
#Preview {
    let env = AppEnvironment.preview()
    
    NavigationView {
        FuelLogDetailView(fuelLogID: env.previewFuelLogID)
            .environment(env)
    }
}
#endif
