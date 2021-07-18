import Foundation
import Combine
import SwiftUI

/// `CURL` converts a line of curl command into a `URLRequest` object. It helps
/// you to create HTTP clients for your iOS/macOS/tvOS apps easier once you have
/// a example curl command.
///
/// For example. if you want to fetch a file in JSON format from httpbin.org,
/// you can use only one line of Swift code:
///
/// ``` swift
/// try URL("https://httpbin.org/json").run { data, response, error in ... }
/// ```
public struct CURL {
	public var result: ParseResult
    public let combineIdentifier = CombineIdentifier()

	/// Creates a new instance.
	///
	/// Please note that the method throws errors if the syntax is invalid in your
	/// curl command.
	///
	/// - Parameter str: The command in string format.
	public init(_ str: String) throws {
		let paser = Parser(command: str)
		self.result = try paser.parse()
	}

	/// Builds a `URLRequest` object from the given command.
	public func buildRequest() -> URLRequest {
		var request = URLRequest(url: result.url)
        request.httpMethod = result.httpMethod.rawValue
        
		for header in result.headers {
			request.addValue(header.value, forHTTPHeaderField: header.key)
		}
        
        switch result.body {
        case .none:
            request.httpBody = nil
            
        case .raw(let text):
            request.httpBody = text.data(using: .utf8)
            
        case .form(let values):
            let joined = values.map { (key, value) in
                "\(key.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")=\(value.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
            }.joined(separator: "&")
            
            request.httpBody = joined.data(using: .utf8)
            
        case .formURLEncoded(let values):
            let joined = values.map { (key, value) in
                "\(key.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")=\(value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
            }.joined(separator: "&")
            
            request.httpBody = joined.data(using: .utf8)
            
        case .binary(let url):
            request.httpBody = FileManager.default.contents(atPath: url.path)
        }

        if case .basic(let username, let password) = result.auth {
			let loginData = String(format: "%@:%@", username, password ?? "").data(using: .utf8)!
			let base64LoginData = loginData.base64EncodedString()
			request.setValue("Basic \(base64LoginData)", forHTTPHeaderField: "Authorization")
		}
        
		return request
	}

	/// Runs the fetch command with a callback closure.
	///
	/// - Parameter completionHandler: The callback closure.
	public func run(completionHandler: @escaping (Data?, URLResponse?, Error?) -> ()) {
		let request = self.buildRequest()
		let task = URLSession.shared.dataTask(with: request, completionHandler: completionHandler)
		task.resume()
	}

	/// Runs the fetch command and handles the reponse with a handler object.
	///
	/// The handler should be a subclass of `Handler`.
	///
	/// - Parameter handler: The handler.
	public func run<T>(handler: Handler<T>) {
		let request = self.buildRequest()
		let task = URLSession.shared.dataTask(with: request) { data, response, error in
			handler.handle(data, response, error)
		}
		task.resume()
	}

	/// Runs the fetch command and you can receive the response from a
	/// publisher.
	func run() -> URLSession.DataTaskPublisher {
		let request = self.buildRequest()
		let publisher = URLSession.shared.dataTaskPublisher(for: request)
		return publisher
	}
}

extension CURL: Identifiable, CustomCombineIdentifierConvertible {
    
    public var id: CombineIdentifier {
        combineIdentifier
    }
}

extension CURL: Equatable {
    
}
