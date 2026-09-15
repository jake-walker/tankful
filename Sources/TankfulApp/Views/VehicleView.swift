//
//  VehicleView.swift
//  tankful
//
//  Created by Jake Walker on 15/09/2026.
//

import SwiftUI
import TankfulDomain

struct VehicleView: View {
    @Environment(AppEnvironment.self) internal var env

    let vehicleID: Vehicle.ID?
    
    // TODO: improve this
    @State internal var remoteID: String?
    @State internal var syncState: SyncState = .created

    @State internal var make: String = ""
    @State internal var model: String = ""
    @State internal var year: String = ""
    @State internal var fuelType: FuelType = .petrol
    @State internal var isLoading: Bool = false
    @State internal var isSaving: Bool = false
    @State internal var isDeleting: Bool = false
    @State internal var isConfirmingDelete: Bool = false
    @State internal var isShowingError: Bool = false
    @State internal var errorMessage: String = ""

    init(vehicleID: Vehicle.ID? = nil) {
        self.vehicleID = vehicleID
    }

    var body: some View {
        Form {
            LabeledContent {
                TextField("Make", text: $make)
                    .multilineTextAlignment(.trailing)
            } label: {
                Text("Make")
            }

            LabeledContent {
                TextField("Model", text: $model)
                    .multilineTextAlignment(.trailing)
            } label: {
                Text("Model")
            }

            LabeledContent {
                TextField("Year", text: $year)
                    .multilineTextAlignment(.trailing)
            } label: {
                Text("Year")
            }

            Picker("Fuel Type", selection: $fuelType) {
                ForEach(FuelType.allCases) { fuelType in
                    Text(fuelType.name).tag(fuelType)
                }
            }
        }
        .navigationTitle(vehicleID == nil ? "Add Vehicle" : "Vehicle Settings")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                if #available(iOS 26.0, *) {
                    Button("Save", systemImage: "checkmark", role: .confirm) {
                        Task { await save() }
                    }
                    .disabled(isLoading || isSaving || !hasValidYear)
                } else {
                    Button("Save", systemImage: "checkmark") {
                        Task { await save() }
                    }
                    .disabled(isLoading || isSaving || !hasValidYear)
                }
            }
            
            if vehicleID != nil {
                ToolbarItem(placement: .secondaryAction) {
                    Button("Delete Vehicle", systemImage: "trash", role: .destructive) {
                        isConfirmingDelete = true
                    }
                    .disabled(isLoading || isSaving || isDeleting)
                }
            }
        }
        .task(id: vehicleID) {
            await loadVehicle()
        }
        .confirmationDialog(
            "Delete this vehicle?",
            isPresented: $isConfirmingDelete,
            titleVisibility: .visible
        ) {
            Button("Delete Vehicle", role: .destructive) {
                Task { await deleteVehicle() }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("All fill-ups for this vehicle will also be deleted. This action cannot be undone.")
        }
        .alert("Unable to Update Vehicle", isPresented: $isShowingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }

    private var hasValidYear: Bool {
        year.isEmpty || Int64(year) != nil
    }

    private func loadVehicle() async {
        guard let vehicleID else {
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            guard let vehicle = try await env.vehicleRepository.vehicle(id: vehicleID) else {
                throw VehicleViewError.vehicleNotFound
            }

            make = vehicle.make ?? ""
            model = vehicle.model ?? ""
            year = vehicle.year.map(String.init) ?? ""
            fuelType = vehicle.fuelType
            remoteID = vehicle.remoteID
            syncState = vehicle.syncState
        } catch {
            showError(error)
        }
    }

    private func save() async {
        guard !isSaving, hasValidYear else {
            return
        }

        isSaving = true
        defer { isSaving = false }

        let vehicle = Vehicle(
            id: vehicleID ?? Vehicle.ID(),
            make: make.isEmpty ? nil : make,
            model: model.isEmpty ? nil : model,
            year: Int64(year),
            fuelType: fuelType,
            remoteID: remoteID,
            syncState: syncState
        )

        do {
            if vehicleID != nil {
                try await env.vehicleController.update(vehicle)
            } else {
                try await env.vehicleController.create(vehicle)
            }
           
            env.selectVehicle(id: vehicle.id)
            env.router.pop()
        } catch {
            showError(error)
        }
    }

    private func deleteVehicle() async {
        guard let vehicleID, !isDeleting else { return }

        isDeleting = true
        defer { isDeleting = false }

        do {
            try await env.vehicleRepository.delete(id: vehicleID)
            try await env.resolveCurrentVehicle()
            env.vehicleChangeVersion += 1
            env.router.popToRoot()
        } catch {
            showError(error)
        }
    }

    private func showError(_ error: any Error) {
        errorMessage = error.localizedDescription
        isShowingError = true
    }
}

private enum VehicleViewError: LocalizedError {
    case vehicleNotFound

    var errorDescription: String? {
        switch self {
        case .vehicleNotFound:
            "The vehicle could not be found."
        }
    }
}

#Preview("Add Vehicle") {
    NavigationStack {
        VehicleView()
            .environment(AppEnvironment.preview())
    }
}

#Preview("Edit Vehicle") {
    let env = AppEnvironment.preview()

    NavigationStack {
        VehicleView(vehicleID: env.currentVehicleID)
            .environment(env)
    }
}
