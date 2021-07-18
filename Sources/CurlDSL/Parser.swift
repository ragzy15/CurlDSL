import Foundation
import NetworkKit

extension CURL {
    
    public enum FormValue: Equatable {
        case text(String)
        case file(URL?)
        
        public var value: String {
            switch self {
            case .text(let text):
                return text
            case .file(let url):
                if let url = url, let contents = try? String(contentsOfFile: url.path) {
                    return contents
                } else {
                    return ""
                }
            }
        }
    }
    
    public struct ParseResult: Equatable {
        public var httpMethod: HTTPMethod
        public var url: URL
        public var headers: [String: String]
        
        public enum Auth: Equatable {
            case basic(username: String, password: String?)
        }
        
        public var auth: Auth?
        
        public enum Body: Equatable {
            case form([String: FormValue])
            case formURLEncoded([String: String])
            case binary(URL)
            case raw(String)
        }
        
        public var body: Body?
    }

    struct Parser {
        
        public let command: String
        
        init(command: String) {
            self.command = command
        }
        
        func parse() throws -> ParseResult {
            let command = command.trimmingCharacters(in: .whitespaces)
            
            var lexer = Lexer(string: command)
            lexer.tokenize()
            try lexer.convertTokensToParameters()
            
            return try compile(parameters: lexer.parameters)
        }

        private func compile(parameters: [Parameter]) throws -> ParseResult {
            var result = ParseResult(httpMethod: .get, url: URL(string: "https://example.com")!, headers: [:], auth: nil, body: nil)
            
            var httpMethod: HTTPMethod? = nil
            
            parameters.forEach { (parameter) in
                switch parameter {
                case .url(let url):
                    result.url = url
                    
                case .header(let key, let value):
                    result.headers[key] = value
                    
                case .body(let body):
                    switch body {
                    case .form(let key, let value):
                        if result.body == nil {
                            result.body = .form([key: value])
                        } else if case .form(var values) = result.body {
                            values[key] = value
                            result.body = .form(values)
                        }
                        
                    case .formEncoded(let key, let value):
                        if result.body == nil {
                            result.body = .formURLEncoded([key: value])
                        } else if case .formURLEncoded(var values) = result.body {
                            values[key] = value
                            result.body = .formURLEncoded(values)
                        }
                        
                    case .data(let data):
                        switch data {
                        case .raw(let text), .ascii(let text):
                            result.body = .raw(text)
                            
                        case .binary(let url):
                            result.body = .binary(url)
                        }
                    }
                    
                case .auth(let auth):
                    switch auth {
                    case .user(let username, let password):
                        result.auth = .basic(username: username, password: password)
                    }
                    
                case .referer(let referer):
                    result.headers["Referer"] = referer
                    
                case .userAgent(let agent):
                    result.headers["User-Agent"] = agent
                    
                case .requestMethod(let method):
                    httpMethod = method
                }
            }
            
            if let httpMethod = httpMethod {
                result.httpMethod = httpMethod
            } else {
                if result.body != nil {
                    result.httpMethod = .post
                } else {
                    result.httpMethod = .get
                }
            }
//
//            do {
//                let pattern = "https?://(.*)@(.*)"
//                let regex = try NSRegularExpression(pattern: pattern, options: [])
//                let matches = regex.matches(in: url, options: [], range: NSMakeRange(0, url.count))
//                if matches.count > 0 {
//                    let usernameRange = matches[0].range(at: 1)
//                    let start = url.index(url.startIndex, offsetBy: usernameRange.location)
//                    let end = url.index(url.startIndex, offsetBy: usernameRange.location + usernameRange.length)
//                    let substring = url[start..<end]
//                    let components = substring.components(separatedBy: ":")
//                    if user == nil {
//                        user = components[0]
//                        if components.count >= 2 {
//                            password = components[1]
//                        }
//                    }
//                    url.removeSubrange(start...end)
//                }
//            } catch {
//            }
//
//            guard let finalUrl = URL(string: url) else {
//                throw CURLError.invalidURL(url)
//            }
            
            return result
        }
    }
}
