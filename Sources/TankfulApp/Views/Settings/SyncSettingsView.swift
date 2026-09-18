//
//  SyncSettingsView.swift
//  tankful
//
//  Created by Jake Walker on 16/09/2026.
//

import SwiftUI
import TankfulSync

struct SyncSettingsView: View {
    @Environment(AppEnvironment.self) var env

    @State var syncEnabled = false
    @State var serverURL = ""
    @State var username = ""
    @State var password = ""
    @State var headers = ""
    @State var validationMessage: String?
    @State var savedDraft = SyncSettingsDraft()
    @State var saveMessage: String?
    @State var isConfirmingDiscard = false

    var body: some View {
        Form {
            Section {
                HStack(spacing: 16) {
                    Image(
                        systemName: syncEnabled
                            ? "arrow.trianglehead.2.clockwise.rotate.90" : "circle.slash"
                    )
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .fontWeight(.semibold)
                    .frame(width: 32, height: 32)

                    VStack(alignment: .leading) {
                        Text(
                            syncEnabled
                                ? NSLocalizedString(
                                    "Sync Status", comment: "Sync status section heading"
                                )
                                : NSLocalizedString(
                                    "Sync Disabled", comment: "Sync status section heading"
                                )
                        )
                        .font(.headline)

                        if syncEnabled {
                            Text(syncText)
                        }
                    }
                }

                if let validationMessage {
                    Text(validationMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }

                if let saveMessage, !isDirty {
                    Text(saveMessage)
                        .font(.footnote)
                        .foregroundStyle(.green)
                }
            }

            Section {
                Toggle("Enable sync", isOn: $syncEnabled)

                if syncEnabled {
                    Picker("Backend", selection: .constant(BackendType.tracktor)) {
                        Text("Tracktor").tag(BackendType.tracktor)
                    }
                    .disabled(true)
                }
            }

            if syncEnabled {
                Section {
                    LabeledContent {
                        TextField(
                            "Server URL", text: $serverURL,
                            prompt: Text("https://tracktor.example.com")
                        )
                        .multilineTextAlignment(.trailing)
                        .autocorrectionDisabled()
                        #if !os(macOS)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.URL)
                        #endif
                    } label: {
                        Text("Server URL")
                    }

                    TextField("Username", text: $username)
                        .autocorrectionDisabled()
                    #if !os(macOS)
                        .textInputAutocapitalization(.never)
                    #endif

                    SecureField("Password", text: $password)
                } header: {
                    Text("Server")
                }

                Section {
                    TextEditor(text: $headers)
                        .frame(minHeight: 72)
                        .font(.body.monospaced())
                } header: {
                    Text("Headers")
                } footer: {
                    Text("Add one header per line, for example: `X-API-Key: abcdef`")
                }

                Section("Actions") {
                    Button("Sync Now") {
                        Task { await syncNow() }
                    }
                    .disabled(isSyncing || isDirty)

                    if isDirty {
                        Text("Save or discard your changes before syncing.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Sync Settings")
        .navigationBarBackButtonHidden(isDirty)
        .toolbar {
            if isDirty {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Back", systemImage: "chevron.left") {
                        isConfirmingDiscard = true
                    }
                }
            }

            ToolbarItem(placement: .primaryAction) {
                if #available(anyAppleOS 26.0, *) {
                    Button("Save Changes", systemImage: "checkmark", role: .confirm) {
                        saveSyncConfiguration()
                    }
                    .disabled(!isDirty)
                } else {
                    Button("Save Changes", systemImage: "checkmark") {
                        saveSyncConfiguration()
                    }
                    .disabled(!isDirty)
                }
            }
        }
        .confirmationDialog(
            "Discard unsaved changes?",
            isPresented: $isConfirmingDiscard,
            titleVisibility: .visible
        ) {
            Button("Discard Changes", role: .destructive) {
                env.router.pop()
            }
            Button("Keep Editing", role: .cancel) {}
        } message: {
            Text("Your sync settings will remain unchanged.")
        }
        .onAppear {
            loadSyncConfiguration()
        }
    }

    private var isSyncing: Bool {
        if case .syncing = env.syncStatus {
            return true
        }
        return false
    }

    private var draft: SyncSettingsDraft {
        SyncSettingsDraft(
            syncEnabled: syncEnabled,
            serverURL: serverURL,
            username: username,
            password: password,
            headers: headers
        )
    }

    private var isDirty: Bool {
        draft != savedDraft
    }

    private var syncText: String {
        switch env.syncStatus {
        case let .idle(lastSync):
            if let lastSync {
                return String(
                    format: NSLocalizedString(
                        "Last synced %@", comment: "Sync status followed by the last sync date"
                    ),
                    lastSync.formatted(date: .abbreviated, time: .shortened)
                )
            } else {
                return NSLocalizedString(
                    "Not yet synced", comment: "Sync status when no sync has completed"
                )
            }
        case .syncing:
            return NSLocalizedString("Syncing...", comment: "Sync status while a sync is running")
        case let .failed(_, message):
            return String(
                format: NSLocalizedString(
                    "Failed: %@", comment: "Sync failure status followed by an error message"
                ),
                message
            )
        }
    }

    private func syncNow() async {
        do {
            try await env.syncNow()
        } catch {
            print("Sync error: \(error.localizedDescription)")
        }
    }

    private func loadSyncConfiguration() {
        guard let configuration = env.syncConfiguration else {
            syncEnabled = false
            serverURL = ""
            username = ""
            password = ""
            headers = ""
            savedDraft = draft
            return
        }

        syncEnabled = true
        serverURL = configuration.baseURL.absoluteString
        headers = configuration.additionalHeaders
            .sorted { $0.key.localizedCaseInsensitiveCompare($1.key) == .orderedAscending }
            .map { "\($0.key): \($0.value)" }
            .joined(separator: "\n")

        if case let .credentials(savedUsername, savedPassword) = configuration.authentication {
            username = savedUsername
            password = savedPassword
        } else {
            username = ""
            password = ""
        }
        savedDraft = draft
    }

    private func saveSyncConfiguration() {
        guard syncEnabled else {
            env.syncConfiguration = nil
            savedDraft = draft
            validationMessage = nil
            saveMessage = NSLocalizedString(
                "Sync disabled.", comment: "Confirmation shown after disabling sync"
            )
            return
        }

        guard let baseURL = URL(string: serverURL),
              let scheme = baseURL.scheme?.lowercased(),
              ["http", "https"].contains(scheme),
              baseURL.host != nil
        else {
            validationMessage = NSLocalizedString(
                "Enter a valid HTTP or HTTPS server URL.",
                comment: "Validation error for an invalid sync server URL"
            )
            saveMessage = nil
            return
        }

        do {
            let additionalHeaders = try parseHeaders(headers)
            let authentication: SyncConfiguration.Authentication?

            if username.isEmpty && password.isEmpty {
                authentication = nil
            } else if username.isEmpty || password.isEmpty {
                validationMessage = NSLocalizedString(
                    "Enter both a username and password, or leave both blank.",
                    comment: "Validation error for incomplete sync credentials"
                )
                saveMessage = nil
                return
            } else {
                authentication = .credentials(username: username, password: password)
            }

            env.syncConfiguration = SyncConfiguration(
                type: .tracktor,
                baseURL: baseURL,
                additionalHeaders: additionalHeaders,
                authentication: authentication
            )
            savedDraft = draft
            validationMessage = nil
            saveMessage = NSLocalizedString(
                "Changes saved.", comment: "Confirmation shown after saving sync settings"
            )
        } catch {
            validationMessage = error.localizedDescription
            saveMessage = nil
        }
    }

    private func parseHeaders(_ text: String) throws -> [String: String] {
        var parsed: [String: String] = [:]

        for (index, rawLine) in text.split(whereSeparator: \.isNewline).enumerated() {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            guard !line.isEmpty else { continue }
            guard let separator = line.firstIndex(of: ":") else {
                throw HeaderParsingError.invalidLine(index + 1)
            }

            let name = line[..<separator].trimmingCharacters(in: .whitespaces)
            let value = line[line.index(after: separator)...].trimmingCharacters(in: .whitespaces)
            guard !name.isEmpty, !value.isEmpty else {
                throw HeaderParsingError.invalidLine(index + 1)
            }
            parsed[name] = value
        }

        return parsed
    }
}

struct SyncSettingsDraft: Equatable {
    var syncEnabled = false
    var serverURL = ""
    var username = ""
    var password = ""
    var headers = ""
}

private enum HeaderParsingError: LocalizedError {
    case invalidLine(Int)

    var errorDescription: String? {
        switch self {
        case let .invalidLine(line):
            String(
                format: NSLocalizedString(
                    "Custom header on line %lld must use \"Name: value\" format.",
                    comment:
                    "Validation error for a malformed custom HTTP header; argument is the line number"
                ),
                Int64(line)
            )
        }
    }
}

#if !os(Android) && DEBUG
    #Preview {
        NavigationStack {
            SyncSettingsView()
                .environment(AppEnvironment.preview())
        }
    }
#endif
