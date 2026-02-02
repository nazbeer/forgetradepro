//
//  Keychain.swift
//  ForgeTradePro
//
//  Created by Nasbeer Ahammed on 02/02/26.
//


import Security
import Foundation

class Keychain {
    static func save(_ value: String) {
        let data = value.data(using: .utf8)!
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "jwt",
            kSecValueData as String: data
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    static func delete() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "jwt"
        ]
        SecItemDelete(query as CFDictionary)
    }

    static func load() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "jwt",
            kSecReturnData as String: true
        ]
        var data: AnyObject?
        SecItemCopyMatching(query as CFDictionary, &data)
        let token = (data as? Data).flatMap { String(data: $0, encoding: .utf8) }
        if let token, token.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return nil
        }
        return token
    }
}
