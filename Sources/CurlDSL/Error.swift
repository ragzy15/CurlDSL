import Foundation

/// Errors that could happen during parsing parameters.
public enum CURLError: Error, LocalizedError {
    /// Your command does not start with `curl`.
    case invalidBegin
    
    /// No URL given.
    case noURL
    
    /// The format of the URL is invalid.
    case invalidURL(String)
    
    /// No such option.
    case noSuchOption(String)
    
    /// The given paramater is invalid.
    case inValidParameter(String)
    
    /// Other syntax error.
    case otherSyntaxError
    
    /// Failed to read contents of file
    case unableToReadFileContent(String)

    public var errorDescription: String? {
        switch self {
        case .invalidBegin:
            return "Your command should start with \"curl\"."
            
        case .noURL:
            return "You did not specific a URL in your command."
            
        case .invalidURL(let url):
            return "The URL \(url) is invalid. We suppports only http and https protocol right now."
            
        case .noSuchOption(let option):
            return "\(option) is not supported."
            
        case .inValidParameter(let option):
            return "The parameter for \(option) is not supported."
            
        case .unableToReadFileContent(let filename):
            return "Unable to read contents of file \(filename)"
            
        case .otherSyntaxError:
            return "Unknown syntax error."
        }
    }
}
