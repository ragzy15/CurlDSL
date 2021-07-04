import Foundation
import NetworkKit

extension CURL {
    
    public enum Parameter: Equatable {
        case url(URL)
        case header(key: String, value: String)
        case body(Body)
        case auth(Auth)
        case referer(String)
        case userAgent(String)
        case requestMethod(HTTPMethod)
    }
    
    public enum Body: Equatable {
        
        case form(key: String, value: FormValue)
        case formEncoded(key: String, value: String)
        case data(Data)
        
        public enum Data: Equatable {
            case ascii(String)
            case binary(URL)
            case raw(String)
        }
    }
    
    public enum Auth: Equatable {
        case user(username: String, password: String?)
    }
}

extension CURL {
    
    struct Lexer {
        
        var string: String
        private(set) var tokens: [String] = []
        private(set) var parameters: [Parameter] = []
 
         mutating func tokenize() {
            let str = string.trimmingCharacters(in: .whitespacesAndNewlines)
            var slices = [String]()
            let scanner = Scanner(string: str)
            scanner.charactersToBeSkipped = nil
            var buffer = ""
            
            while scanner.isAtEnd == false {
                let result = scanner.scanUpToCharacters(from: CharacterSet(charactersIn: " \n\"\'") )
                
                if result == nil {
                    scanner.currentIndex = str.index(after: scanner.currentIndex)
                }
                
                if scanner.isAtEnd {
                    buffer += result ?? ""
                    slices.append(buffer)
                    break
                }
                
                let lastChar = String(str[scanner.currentIndex])
                if lastChar == "\"" || lastChar == "\'" {
                    let quote = lastChar
                    buffer += result ?? ""
                    scanner.currentIndex = str.index(after: scanner.currentIndex)
                    while true {
                        if let scannedString = scanner.scanUpToString(quote) {
                            buffer.append(scannedString)
                            
                            if scanner.isAtEnd {
                                if !buffer.isEmpty {
                                    slices.append(buffer)
                                }
                                buffer = ""
                                break
                            }
                            
                            if scannedString[scannedString.index(before: scannedString.endIndex)] != "\\" {
                                // Find matching quote mark.
                                scanner.currentIndex = str.index(after: scanner.currentIndex)
                                
                                if let _ = scanner.scanCharacters(from: CharacterSet(charactersIn: " \n") ) {
                                    if !buffer.isEmpty {
                                        slices.append(buffer)
                                        buffer = ""
                                    }
                                }
                                
                                break
                            } else {
                                // The quote mark is escaped. Continue.
                                scanner.currentIndex = str.index(after: scanner.currentIndex)
                                buffer.remove(at: buffer.index(before: buffer.endIndex))
                                buffer.append(quote)
                            }
                        } else {
                            if !buffer.isEmpty {
                                slices.append(buffer)
                                buffer = ""
                            }
                            
                            break
                        }
                    }
                    
                    if scanner.isAtEnd {
                        if !buffer.isEmpty {
                            slices.append(buffer)
                            buffer = ""
                        }
                        
                        break
                    }
                } else {
                    buffer += result ?? ""
                    if !buffer.isEmpty {
                        slices.append(buffer)
                    }
                    buffer = ""
                }
            }
            
            tokens = slices
        }
    }
}

extension CURL.Lexer {
    
    fileprivate mutating func handleShortCommands(index: Int, token: String) throws {
        let nextToken = tokens[index]
        switch token {
        case "-d":
            parameters.append(.body(.data(.ascii(nextToken))))
            
        case "-F":
            let components = nextToken.components(separatedBy: "=")
            
            if components.count < 2 {
                throw CURLError.inValidParameter(token)
            }
            
            let value: CURL.FormValue
            
            if components[1].first == "@" {
                value = .file(URL(string: "\(components[1].dropFirst())"))
            } else {
                value = .text(components[1])
            }
            
            parameters.append(.body(.form(key: components[0].trimmingCharacters(in: .whitespacesAndNewlines), value: value)))
            
        case "-H":
            let components = nextToken.components(separatedBy: ":")
            if components.count < 2 {
                throw CURLError.inValidParameter(token)
            }
            
            parameters.append(.header(key: components[0].trimmingCharacters(in: .whitespacesAndNewlines), value: components[1].trimmingCharacters(in: .whitespacesAndNewlines)))
            
        case "-e":
            parameters.append(.referer(nextToken))
            
        case "-A":
            parameters.append(.userAgent(nextToken))
            
        case "-X":
            parameters.append(.requestMethod(HTTPMethod(rawValue: nextToken) ?? .get))
            
        case "-u":
            let components = nextToken.components(separatedBy: ":")
            
            if components.count >= 2 {
                parameters.append(.auth(.user(username: components[0], password: components[1])))
            } else {
                parameters.append(.auth(.user(username: components[0], password: nil)))
            }
            
        default:
            throw CURLError.noSuchOption(token)
        }
    }
}

extension CURL.Lexer {
    
    fileprivate mutating func handleLongCommands(token: String) throws {
        let components = token.components(separatedBy: "=")
        
        switch components[0] {
        case "--data", "--data-ascii":
            if components.count < 2 {
                throw CURLError.inValidParameter(components[0])
            }
            
            parameters.append(.body(.data(.ascii(components[1]))))
            
        case "--data-binary":
            if components.count < 2 {
                throw CURLError.inValidParameter(components[0])
            }
            
            let value: CURL.Body.Data
            
            if components[1].hasPrefix("@") {
                value = .binary(URL(fileURLWithPath: "\(components[2].dropFirst())"))
            } else {
                value = .ascii(components[2])
            }
            
            parameters.append(.body(.data(value)))
            
        case "--data-raw":
            if components.count < 2 {
                throw CURLError.inValidParameter(components[0])
            }
            
            if components[1].hasPrefix("@") {
                let url = URL(fileURLWithPath: "\(components[2].dropFirst())")
                
                do {
                    let fileContent = try String(contentsOf: url)
                    parameters.append(.body(.data(.raw(fileContent))))
                } catch {
                    throw CURLError.unableToReadFileContent(url.absoluteString)
                }
                
            } else {
                parameters.append(.body(.data(.raw(components[1]))))
            }
            
        case "--data-urlencode":
            if components.count < 3 {
                throw CURLError.inValidParameter(components[0])
            }
            
            parameters.append(.body(.formEncoded(key: components[1].trimmingCharacters(in: .whitespacesAndNewlines), value: components[2])))
            
        case "--form", "-form-string":
            if components.count < 3 {
                throw CURLError.inValidParameter(components[0])
            }
            
            let value: CURL.FormValue
            
            if components[1].hasPrefix("@") {
                value = .file(URL(fileURLWithPath: "\(components[2].dropFirst())"))
            } else {
                value = .text(components[2])
            }
            
            parameters.append(.body(.form(key: components[1].trimmingCharacters(in: .whitespacesAndNewlines), value: value)))
            
        case "--header":
            if components.count < 2 {
                throw CURLError.inValidParameter(components[0])
            }
            
            let keyValue = components[1].components(separatedBy: ":")
            
            if keyValue.count < 2 {
                throw CURLError.inValidParameter(components[0])
            }
            
            parameters.append(.header(key: keyValue[0].trimmingCharacters(in: .whitespacesAndNewlines), value: keyValue[1].trimmingCharacters(in: .whitespacesAndNewlines)))
            
        case "--referer":
            if components.count < 2 {
                throw CURLError.inValidParameter(components[0])
            }
            
            parameters.append(.referer(components[1]))
            
        case "--user-agent":
            if components.count < 2 {
                throw CURLError.inValidParameter(components[0])
            }
            
            parameters.append(.userAgent(components[1]))
            
        case "--request":
            if components.count < 2 {
                throw CURLError.inValidParameter(components[0])
            }
            
            parameters.append(.requestMethod(HTTPMethod(rawValue: components[1]) ?? .get))
            
        case "--user":
            if components.count < 2 {
                throw CURLError.inValidParameter(components[0])
            }
            
            let userPassword = components[1].components(separatedBy: ":")
            
            if userPassword.count >= 2 {
                parameters.append(.auth(.user(username: userPassword[0], password: userPassword[1])))
            } else {
                parameters.append(.auth(.user(username: userPassword[0], password: nil)))
            }
            
        default:
            throw CURLError.noSuchOption(components[0])
        }
    }
}

extension CURL.Lexer {
    
    mutating func convertTokensToParameters() throws {
        switch tokens.first {
        case "curl":
            break
            
        default:
            throw CURLError.invalidBegin
        }
        
        if tokens.count < 2 {
            throw CURLError.noURL
        }
        
        var index = 1
        
        while index < tokens.count {
            let token = tokens[index]
            
            if token.hasPrefix("--") {
                try handleLongCommands(token: token)
            } else if token.hasPrefix("-") {
                index += 1
                
                if index >= tokens.count {
                    throw CURLError.inValidParameter(token)
                }
                
                try handleShortCommands(index: index, token: token)
            } else {
                if !token.hasPrefix("https://") && !token.hasPrefix("http://") {
                    throw CURLError.invalidURL(token)
                }
                
                if let url = URL(string: token) {
                    parameters.append(.url(url))
                } else {
                    throw CURLError.invalidURL(token)
                }
                
            }
            
            index += 1
        }
    }
}
