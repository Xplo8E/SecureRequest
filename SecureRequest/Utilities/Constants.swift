//
//  Constants.swift
//  SecureRequest
//
//  Created by APPLE on 13/09/24.
//

import Foundation

struct Constants {
    static var baseURL: String = "http://localhost:3000/api"
    // Use a 32-byte (256-bit) key for AES-256
    static let encryptionKey = "12345678901234567890123456789012"
    
    static func setBaseURL(_ url: String) {
        baseURL = url
    }
}
