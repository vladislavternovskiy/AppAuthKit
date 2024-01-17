//
//  Request.swift
//  CheckInRebornDataProviders
//
//  Created by Vladyslav Ternovskyi on 08.01.2024.
//

import Foundation
import Combine

protocol Requestable {
    associatedtype ResultType
    associatedtype ErrorType: FusionAuthAPIError

    func start(_ callback: @escaping (Result<ResultType, ErrorType>) -> Void)
}

public enum ContentType: String {
    case json = "application/json"
    case urlEncoded = "application/x-www-form-urlencoded"
}

public struct FusionRequest<T, E: FusionAuthAPIError>: Requestable {
    /**
     The callback closure type for the request.
     */
    public typealias Callback = (Result<T, E>) -> Void

    let session: URLSession
    let url: URL
    let method: String
    let handle: (FusionResponse<E>, Callback) -> Void
    let parameters: [String: Any]
    let headers: [String: String]
    let contentType: ContentType

    init(session: URLSession, url: URL, method: String, handle: @escaping (FusionResponse<E>, Callback) -> Void, parameters: [String: Any] = [:], headers: [String: String] = [:], contentType: ContentType) {
        self.session = session
        self.url = url
        self.method = method
        self.handle = handle
        self.parameters = parameters
        self.headers = headers
        self.contentType = contentType
    }

    var request: URLRequest {
        let request = NSMutableURLRequest(url: url)
        request.httpMethod = method
        if !parameters.isEmpty {
            if method.caseInsensitiveCompare("GET") == .orderedSame {
                var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true)
                var queryItems = urlComponents?.queryItems ?? []
                let newQueryItems = parameters.map { URLQueryItem(name: $0.key, value: String(describing: $0.value)) }
                queryItems.append(contentsOf: newQueryItems)
                urlComponents?.queryItems = queryItems
                request.url = urlComponents?.url ?? url
            } else {
                switch contentType {
                case .json:
                    request.httpBody = try? JSONSerialization.data(withJSONObject: parameters, options: [])
                case .urlEncoded:
                    request.httpBody = parameters.percentEncoded()
                }
            }
        }
        request.setValue(contentType.rawValue, forHTTPHeaderField: "Content-Type")
        headers.forEach { name, value in request.setValue(value, forHTTPHeaderField: name) }
        return request as URLRequest
    }

    public func start(_ callback: @escaping Callback) {
        let handler = self.handle
        let request = self.request
        
        if let headers = request.allHTTPHeaderFields?.debugDescription {
            debugPrint("🟢 Request Headers: " + headers)
        }
        if let httpBody = request.httpBody, let requestBody = String(data: httpBody, encoding: .utf8) {
            debugPrint("🟢 Request Body: " + requestBody)
        }
        let task = session.dataTask(with: request, completionHandler: { data, response, error in
            if let data = data, let responseBody = String(data: data, encoding: .utf8) {
                debugPrint("🔵 Response Body: " + responseBody)
            }
            handler(FusionResponse(data: data, response: response as? HTTPURLResponse, error: error), callback)
        })
        task.resume()
    }

    public func parameters(_ extraParameters: [String: Any], contentType: ContentType) -> Self {
        let parameters = extraParameters.merging(self.parameters) {(current, _) in current}

        return FusionRequest(
            session: self.session,
            url: self.url,
            method: self.method,
            handle: self.handle,
            parameters: parameters,
            headers: self.headers, 
            contentType: contentType
        )
    }

    public func headers(_ extraHeaders: [String: String], contentType: ContentType) -> Self {
        let headers = extraHeaders.merging(self.headers) {(current, _) in current}

        return FusionRequest(
            session: self.session,
            url: self.url,
            method: self.method,
            handle: self.handle,
            parameters: self.parameters,
            headers: headers,
            contentType: contentType
        )
    }
}

// MARK: - Combine

public extension FusionRequest {

    func start() -> AnyPublisher<T, E> {
        return Deferred { Future(self.start) }.eraseToAnyPublisher()
    }
}

// MARK: - Async/Await

#if canImport(_Concurrency)
public extension FusionRequest {

    func start() async throws -> T {
        return try await withCheckedThrowingContinuation { continuation in
            self.start(continuation.resume)
        }
    }
}
#endif
