//
//  PythonFuncs.swift
//  BitcoinPlayground
//
//  Created by Arutyun Enfendzhyan on 27.11.22.
//

import Foundation
import PythonKit

struct PyFuncs {
    static let shared = PyFuncs()

    static func setup() {
        PythonLibrary.useLibrary(at: "/Applications/Xcode.app/Contents/Developer/Library/Frameworks/Python3.framework/Versions/3.9/Python3")
        let sys = Python.import("sys")
        let path = Bundle.main.resourcePath!
        sys.path.append(path)
        sys.path.append("\(path)/.venv/lib/python3.9/site-packages")
    }

    let functionsModule = Python.import("functions")

    func createBtcWallet() -> Wallet {
        let obj = functionsModule.create_btc_address()
        return Wallet(address: obj["address"].description, publicKey: obj["public_key"].description, privateKey: obj["private_key"].description)
    }

    func getBalance(wallet: Wallet) async throws -> Double {
        let data = try functionsModule.get_address_data.throwing.dynamicallyCall(withArguments: wallet.address)
        let funded = Double(data["chain_stats"]["funded_txo_sum"])!
        let spent = Double(data["chain_stats"]["spent_txo_sum"])!
        return (funded - spent) * 0.00000001
    }

    let encoding = String.Encoding.ascii
    
    func encrypt(_ data: Data) -> Data {
        let str = String(data: data, encoding: encoding)!
        return functionsModule.encrypt(str).description.data(using: encoding)!
    }

    func decrypt(_ data: Data) -> Data {
        let str = functionsModule.decrypt(String(data: data, encoding: encoding)!)
        return str.description.data(using: encoding)!
    }
}

extension Wallet {
    init() {
        self = PyFuncs.shared.createBtcWallet()
    }
}
