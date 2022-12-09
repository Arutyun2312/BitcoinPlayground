//
//  BitcoinPlaygroundApp.swift
//  BitcoinPlayground
//
//  Created by Arutyun Enfendzhyan on 27.11.22.
//

import SwiftUI
import UniformTypeIdentifiers

@main
struct BitcoinPlaygroundApp: App {
    init() {
        PyFuncs.setup()
    }

    @StateObject var walletsObj = WalletsObj.shared

    var body: some Scene {
        DocumentGroup(newDocument: { () -> Wallets in
            Task { @MainActor in WalletsObj.shared.wallets = Wallets() }
            return WalletsObj.shared.wallets
        }()) { doc in
            ContentView()
                .environmentObject(walletsObj)
                .onReceive(walletsObj.$wallets) {
                    guard $0 != doc.document else { return } // setting doc.document even without changes will mark as 'edited', so set only when changed
                    doc.document = $0
                }
        }
    }
}

extension Wallets: FileDocument {
    static var readableContentTypes: [UTType] { [.data] }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else { throw CocoaError(.fileReadCorruptFile) }
        let value = try JSONDecoder().decode(Self.self, from: PyFuncs.shared.decrypt(data))
        self = value
        Task { @MainActor in WalletsObj.shared.wallets = value }
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = try JSONEncoder().encode(self)
        return .init(regularFileWithContents: PyFuncs.shared.encrypt(data))
    }
}
