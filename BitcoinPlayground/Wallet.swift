//
//  Wallet.swift
//  BitcoinPlayground
//
//  Created by Arutyun Enfendzhyan on 27.11.22.
//

import Foundation

struct Wallets: Codable, Hashable {
    init() {
        wallets = []
    }

    var wallets: [Wallet]
}

struct Wallet: Codable, Hashable {
    init(address: String, publicKey: String, privateKey: String) {
        self.address = address
        self.publicKey = publicKey
        self.privateKey = privateKey
        createdAt = .init()
    }

    let address, publicKey, privateKey: String
    let createdAt: Date
}

extension Wallet: Identifiable {
    var id: String { address }
}

@MainActor
final class WalletsObj: ObservableObject {
    nonisolated static let shared = WalletsObj()

    private nonisolated init() {}

    @Published var wallets = Wallets()
    @Published var balances: [Wallet: Double?] = [:]

    @discardableResult
    func getBalance(wallet: Wallet) async throws -> Double {
        balances[wallet] = nil
        do {
            let balance = try await PyFuncs.shared.getBalance(wallet: wallet)
            balances[wallet] = balance
            return balance
        } catch {
            balances.removeValue(forKey: wallet)
            throw error
        }
    }

    func load(url: URL) throws {
        let data = try Data(contentsOf: url)
        wallets = try JSONDecoder().decode(Wallets.self, from: data)
    }

    func save(url: URL) throws {
        let data = try JSONEncoder().encode(wallets)
        try data.write(to: url)
    }
}
