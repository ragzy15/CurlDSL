import Foundation
import NetworkKit

extension CURL {
    
    public enum FormValue: Equatable {
        case text(String)
        case file(URL?)
    }
    
    struct ParseResult: Equatable {
        var url: URL? = nil
        var user: String? = nil
        var password: String? = nil
        var headers: [String: String] = [:]
        var httpMethod: HTTPMethod? = nil
        
        var form: [String: FormValue] = [:]
        var urlEncoded: [String: String] = [:]
        var data: FormValue? = nil
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
            var result = ParseResult()
            
            parameters.forEach { (parameter) in
                switch parameter {
                case .url(let url):
                    result.url = url
                    
                case .header(let key, let value):
                    result.headers[key] = value
                    
                case .body(let body):
                    switch body {
                    case .form(let key, let value):
                        result.form[key] = value
                        
                    case .formEncoded(let key, let value):
                        result.urlEncoded[key] = value
                        
                    case .data(let data):
                        switch data {
                        case .raw(let text), .ascii(let text):
                            result.data = .text(text)
                            
                        case .binary(let url):
                            result.data = .file(url)
                        }
                    }
                    
                case .auth(let auth):
                    switch auth {
                    case .user(let username, let password):
                        result.user = username
                        result.password = password
                    }
                    
                case .referer(let referer):
                    result.headers["Referer"] = referer
                    
                case .userAgent(let agent):
                    result.headers["User-Agent"] = agent
                    
                case .requestMethod(let method):
                    result.httpMethod = method
                }
            }
            
            if result.httpMethod == nil {
                if !result.form.isEmpty || !result.urlEncoded.isEmpty || result.data != nil {
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
