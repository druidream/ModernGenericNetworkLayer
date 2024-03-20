//
//  ApiProtocol.swift
//  ModernGenericNetworkLayer
//
//  Created by Jun Gu on 3/16/24.
//

import Foundation
import Combine

protocol ApiProtocol {
    func asyncRequest<T: Decodable>(endpoint: EndpointProvider, responseModel: T.Type) async throws -> T
    func combineRequest<T: Decodable>(endpoint: EndpointProvider, responseModel: T.Type) -> AnyPublisher<T, ApiError>
}

final class ApiClient: ApiProtocol {
    var session: URLSession {
        let configuration = URLSessionConfiguration.default
        configuration.waitsForConnectivity = true
        configuration.timeoutIntervalForRequest = 60
        configuration.timeoutIntervalForResource = 300
        return URLSession(configuration: configuration)
    }

    func asyncRequest<T: Decodable>(endpoint: any EndpointProvider, responseModel: T.Type) async throws -> T {
        do {
            let (data, response) = try await session.data(for: endpoint.asURLRequest())
            return try self.manageResponse(data: data, response: response)
        } catch let error as ApiError {
            throw error
        } catch {
            throw ApiError(errorCode: "ERROR-0", message: "Unknown API error \(error.localizedDescription)")
        }
    }

    func combineRequest<T: Decodable>(endpoint: any EndpointProvider, responseModel: T.Type) -> AnyPublisher<T, ApiError> {
        do {
            return session
                .dataTaskPublisher(for: try endpoint.asURLRequest())
                .tryMap { output in
                    return try self.manageResponse(data: output.data, response: output.response)
                }
                .mapError {
                    $0 as? ApiError ?? ApiError(errorCode: "ERROR-0", message: "Unknown API error \($0.localizedDescription)")
                }
                .eraseToAnyPublisher()
        } catch let error as ApiError {
            return AnyPublisher<T, ApiError>(Fail(error: error))
        } catch {
            return AnyPublisher<T, ApiError>(Fail(error: ApiError(errorCode: "ERROR-0", message: "Unknown API error \(error.localizedDescription)")))
        }
    }

    private func manageResponse<T: Decodable>(data: Data, response: URLResponse) throws -> T {
        guard let response = response as? HTTPURLResponse else {
            throw ApiError(errorCode: "ERROR-0", message: "Invalid HTTP response")
        }
        switch response.statusCode {
        case 200...299:
            do {
                return try JSONDecoder().decode(T.self, from: data)
            } catch {
                print("‼️", error)
                throw ApiError(errorCode: KnownError.ErrorCode.decodingDataError.rawValue, message: "Error decoding data")
            }
        default:
            guard let decodedError = try? JSONDecoder().decode(ApiError.self, from: data) else {
                throw ApiError(statusCode: response.statusCode, errorCode: "ERROR-0", message: "Unknown backend error")
            }
            if response.statusCode == 403 && decodedError.errorCode == KnownError.ErrorCode.expiredToken.rawValue {
                NotificationCenter.default.post(name: Notification.Name("terminateSession"), object: self)
            }
            throw ApiError(statusCode: response.statusCode, errorCode: decodedError.errorCode, message: decodedError.message)
        }
    }
}

struct KnownError {
    enum ErrorCode: String {
        case decodingDataError
        case expiredToken
    }
}
