import XCTest
@testable import CurlDSL

final class LexerptionsTests: XCTestCase {

	func testFull1() {
		let str = "curl --form=message=\" I like it \" -X POST --header=\"Accept: application/json\" https://httpbin.org/post"
        
        var lexer = CURL.Lexer(string: str)
        lexer.tokenize()
        
		do {
            try lexer.convertTokensToParameters()
            let options = lexer.parameters
            
			switch options[0] {
            case .body(let body):
                switch body {
                case .form(let key, let value):
                    XCTAssert(key == "message")
                    XCTAssert(value == .text(" I like it "))
                    
                default:
                    XCTFail()
                }
                
			default:
				XCTFail()
			}
            
			switch options[1] {
			case .requestMethod(let method):
                XCTAssert(method == .post)
			default:
				XCTFail()
			}
			switch options[2] {
			case .header(let key, let value):
				XCTAssert(key == "Accept")
				XCTAssert(value == "application/json", "-\(value)-")
			default:
				XCTFail()
			}
			switch options[3] {
			case .url(let url):
				XCTAssert(url == URL(string: "https://httpbin.org/post")!)
			default:
				XCTFail()
			}
		} catch {
			XCTFail()
		}
	}

	func testFull2() {
		let str = "curl --referer=\"http://zonble.net\" --request=POST --user-agent=\"CURL 12345\" https://httpbin.org/post"
        
        var lexer = CURL.Lexer(string: str)
        lexer.tokenize()
        
		do {
            try lexer.convertTokensToParameters()
            let options = lexer.parameters

			switch options[0] {
			case .referer(let value):
				XCTAssert(value == "http://zonble.net")
			default:
				XCTFail()
			}
			switch options[1] {
			case .requestMethod(let method):
                XCTAssert(method == .post)
			default:
				XCTFail()
			}
			switch options[2] {
			case .userAgent(let value):
				XCTAssert(value == "CURL 12345", "-\(value)-")
			default:
				XCTFail()
			}
			switch options[3] {
			case .url(let url):
				XCTAssert(url == URL(string: "https://httpbin.org/post")!)
			default:
				XCTFail()
			}
		} catch {
			XCTFail()
		}
	}
    
    func testFull3() {
        let str = "curl --data=\" I like it \" -X POST --header=\"Accept: application/json\" https://httpbin.org/post"
        
        var lexer = CURL.Lexer(string: str)
        lexer.tokenize()
        
        do {
            try lexer.convertTokensToParameters()
            let options = lexer.parameters
            
            switch options[0] {
            case .body(let body):
                switch body {
                case .data(let data):
                    switch data {
                    case .ascii(let text):
                        XCTAssert(text == " I like it ")
                        
                    default:
                        XCTFail()
                    }
                    
                default:
                    XCTFail()
                }
                
            default:
                XCTFail()
            }
            
            switch options[1] {
            case .requestMethod(let method):
                XCTAssert(method == .post)
            default:
                XCTFail()
            }
            switch options[2] {
            case .header(let key, let value):
                XCTAssert(key == "Accept")
                XCTAssert(value == "application/json", "-\(value)-")
            default:
                XCTFail()
            }
            switch options[3] {
            case .url(let url):
                XCTAssert(url == URL(string: "https://httpbin.org/post")!)
            default:
                XCTFail()
            }
        } catch {
            XCTFail()
        }
    }

	func testOptions1() {
		let str = ""
        
        var lexer = CURL.Lexer(string: str)
        lexer.tokenize()
        
		do {
            try lexer.convertTokensToParameters()
			XCTFail()
		} catch CURLError.invalidBegin {
		} catch {
			XCTFail()
		}
	}

	func testOptions1_1() {
		let str = " curl "
        
        var lexer = CURL.Lexer(string: str)
        lexer.tokenize()
        
		do {
            try lexer.convertTokensToParameters()
			XCTFail("\(lexer.tokens)")
		} catch CURLError.noURL {
		} catch {
			XCTFail()
		}
	}

	func testOptions2() {
		let str = "curl \"https://kkbox.com\""
        
        var lexer = CURL.Lexer(string: str)
        lexer.tokenize()
        
		do {
            try lexer.convertTokensToParameters()
            let options = lexer.parameters

			switch options[0] {
			case .url(let url):
				XCTAssert(url == URL(string: "https://kkbox.com")!)
			default:
				XCTFail()
			}
		} catch {
			XCTFail()
		}
	}

	func testInvalidOption1() {
		let str = "curl -F -F"
        
        var lexer = CURL.Lexer(string: str)
        lexer.tokenize()
        
		do {
            try lexer.convertTokensToParameters()
			XCTFail()
		} catch CURLError.inValidParameter {
		} catch {
			XCTFail()
		}
	}

	func testInvalidOption2() {
		let str = "curl -F"
        
        var lexer = CURL.Lexer(string: str)
        lexer.tokenize()
        
		do {
            try lexer.convertTokensToParameters()
			XCTFail()
		} catch CURLError.inValidParameter {
		} catch {
			XCTFail()
		}
	}

	func testInvalidOption3() {
		let str = "curl --form --form"
        
        var lexer = CURL.Lexer(string: str)
        lexer.tokenize()
        
		do {
            try lexer.convertTokensToParameters()
			XCTFail()
		} catch CURLError.inValidParameter {
		} catch {
			XCTFail()
		}
	}
}
