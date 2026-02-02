//
//  API.swift
//  ForgeTradePro
//
//  Created by Nasbeer Ahammed on 02/02/26.
//


import Foundation

class API {
    static let base = "http://127.0.0.1:8000"
    static var token: String? = Keychain.load()

    private static let session: URLSession = {
        let cfg = URLSessionConfiguration.default
        cfg.connectionProxyDictionary = [:]
        return URLSession(configuration: cfg)
    }()

    static func get(_ path: String, cb: @escaping (Any?) -> Void) {
        var req = URLRequest(url: URL(string: base + path)!)
        req.httpMethod = "GET"
        if let t = token {
            req.setValue(t, forHTTPHeaderField: "auth")
        }

        session.dataTask(with: req) { data, _, _ in
            DispatchQueue.main.async {
                cb(data.flatMap {
                    try? JSONSerialization.jsonObject(with: $0)
                })
            }
        }.resume()
    }

    static func post(_ path: String, body: Data?, cb: @escaping (Any?) -> Void) {
        var req = URLRequest(url: URL(string: base + path)!)
        req.httpMethod = "POST"
        req.httpBody = body
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let t = token {
            req.setValue(t, forHTTPHeaderField: "auth")
        }

        session.dataTask(with: req) { data, _, _ in
            DispatchQueue.main.async {
                cb(data.flatMap {
                    try? JSONSerialization.jsonObject(with: $0)
                })
            }
        }.resume()
    }
}
