//
//  UserEndpoints.swift
//  ModernGenericNetworkLayer
//
//  Created by Jun Gu on 3/16/24.
//

import Foundation

struct Password: Encodable {
    let password: String
}

enum UserEndpoints: EndpointProvider {

    case createPassword(password: Password)

    var path: String {
        switch self {
        case .createPassword(let password):
            return "/api/v2/user"
        }
    }

    var method: RequestMethod {
        switch self {
        case .createPassword(let password):
            return .put
        }
    }

    var queryItems: [URLQueryItem]? {
        switch self {
        case .createPassword(let password):
            return [URLQueryItem(name: "password", value: password.password)]
        }
    }

    var body: [String : Any]? {
        switch self {
        case .createPassword(let password):
            return password.toDictionary
        }
    }

    var mockFile: String? {
        switch self {
        case .createPassword(let password):
            return "_getUserMockResponse"
        }
    }
}
