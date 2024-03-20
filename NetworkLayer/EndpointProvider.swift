//
//  EndpointProvider.swift
//  ModernGenericNetworkLayer
//
//  Created by Jun Gu on 3/16/24.
//

import Foundation

enum RequestMethod: String {
    case delete = "DELETE"
    case get = "GET"
    case pathc = "PATCH"
    case post = "POST"
    case put = "PUT"
}

protocol EndpointProvider {
    var scheme: String { get }
    var baseURL: String { get }
    var path: String { get }
    var method: RequestMethod { get }
    var token: String { get }
    var queryItems: [URLQueryItem]? { get }
    var body: [String: Any]? { get }
    var mockFile: String? { get }
}

extension EndpointProvider {

    var scheme: String {
        return "https"
    }

    var baseURL: String {
        return ApiConfig.shared.baseUrl
    }

    var token: String {
        return ApiConfig.shared.token
    }

    func asURLRequest() throws -> URLRequest {

        var urlComponents = URLComponents()
        urlComponents.scheme = scheme
        urlComponents.host = baseURL
        urlComponents.path = path
        if let queryItems = queryItems {
            urlComponents.queryItems = queryItems
        }
        guard let url = urlComponents.url else {
            throw ApiError(errorCode: "ERROR-0", message: "URL error")
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method.rawValue
        urlRequest.addValue("application/json", forHTTPHeaderField: "Accept")
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.addValue("true", forHTTPHeaderField: "X-Use-Cache")

        if !token.isEmpty {
            urlRequest.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if let body = body {
            do {
                urlRequest.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
            } catch {
                throw ApiError(errorCode: "ERROR-0", message: "Error encoding http body")
            }
        }
        return urlRequest
    }
}
