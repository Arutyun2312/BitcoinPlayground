//
//  ContentView.swift
//  BitcoinPlayground
//
//  Created by Arutyun Enfendzhyan on 27.11.22.
//

import SwiftUI

struct ContentView: View {
    @State var showGenerator = false
    @State var selection: Wallet?
    @EnvironmentObject var walletsObj: WalletsObj

    var body: some View {
        VStack {
            HStack {
                List {
                    ForEach(walletsObj.wallets.wallets) { wallet in
                        let selected = selection == wallet
                        Text("Address: \(wallet.address)")
                            .onTapGesture { selection = selection == wallet ? nil : wallet }
                            .background(selected ? Color.blue : nil)
                    }
                }
                .frame(width: 400)
                if let wallet = selection {
                    Divider()
                    WalletOverview(wallet: wallet)
                }
            }
            Button { showGenerator.toggle() } label: {
                Image(systemName: "globe")
                    .imageScale(.large)
                    .foregroundColor(.accentColor)
                Text("Generate BTC address!")
            }
        }
        .padding()
        .sheet(isPresented: $showGenerator) {
            WalletGenerator()
        }
    }
}

struct WalletOverview: View {
    let wallet: Wallet
    @EnvironmentObject var walletsObj: WalletsObj
    @State var error: (any Error)?

    var body: some View {
        VStack(alignment: .leading) {
            CopyableTextField(label: "Public key", text: wallet.publicKey)
            CopyableTextField(label: "Private key", text: wallet.privateKey)
            CopyableTextField(label: "Address", text: wallet.address)
                .padding(.bottom, 32)
            HStack {
                if let balanceState = walletsObj.balances[wallet] {
                    Text("Balance: ")
                    if let balance = balanceState {
                        Text("\(balance)")
                            .bold()
                    } else {
                        ProgressView()
                    }
                } else {
                    Button("Get Balance") {
                        Task {
                            do {
                                try await walletsObj.getBalance(wallet: wallet)
                            } catch {
                                self.error = error
                            }
                        }
                    }
                }
            }
        }
        .alert(isPresented: .init { error != nil } set: { _ in error = nil }) {
            Alert(title: .init("Error"), message: .init("\(error)" as String))
        }
    }
}

struct WalletGenerator: View {
    @State var wallet = Wallet()
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var walletsObj: WalletsObj

    var body: some View {
        VStack {
            CopyableTextField(label: "Public key", text: wallet.publicKey)
            CopyableTextField(label: "Private key", text: wallet.privateKey)
            CopyableTextField(label: "Address", text: wallet.address)
            HStack {
                Spacer()
                Button("Done") { dismiss() }
                Spacer()
                Button("Add to wallets") { walletsObj.wallets.wallets.append(wallet); dismiss() }
            }
            .padding(.top)
        }
        .padding()
    }
}

struct CopyableTextField: View {
    let label, text: String

    var body: some View {
        HStack {
            Text(label)
            TextField("", text: .constant(text))
                .frame(width: 200)
            Button("Copy") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(text, forType: .string)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
