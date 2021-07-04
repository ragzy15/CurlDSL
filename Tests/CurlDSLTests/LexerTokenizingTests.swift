import XCTest
@testable import CurlDSL

final class LexerTokenizingTests: XCTestCase {
    func testTokenize1() {
        let str = "curl"
        
        var lexer = CURL.Lexer(string: str)
        lexer.tokenize()
        
        XCTAssert(lexer.tokens == ["curl"])
    }

    func testTokenize2() {
        let str = ""
        
        var lexer = CURL.Lexer(string: str)
        lexer.tokenize()
        
        XCTAssert(lexer.tokens == [])
    }

    func testTokenize3() {
        let str = "  "
        
        var lexer = CURL.Lexer(string: str)
        lexer.tokenize()
        
        XCTAssert(lexer.tokens == [], "\(lexer.tokens)")
    }

    func testTokenize4() {
        let str = "curl http://kkbox.com"
        
        var lexer = CURL.Lexer(string: str)
        lexer.tokenize()
        
        XCTAssert(lexer.tokens == ["curl", "http://kkbox.com"])
    }

    func testTokenize5() {
        let str = "curl \"http://kkbox.com\""
        
        var lexer = CURL.Lexer(string: str)
        lexer.tokenize()
        
        XCTAssert(lexer.tokens == ["curl", "http://kkbox.com"], "\(lexer.tokens)")
    }

    func testTokenize5_1() {
        let str = "curl \'http://kkbox.com\'"
        
        var lexer = CURL.Lexer(string: str)
        lexer.tokenize()
        
        XCTAssert(lexer.tokens == ["curl", "http://kkbox.com"], "\(lexer.tokens)")
    }

    func testTokenize6() {
        let str = "curl http\"://kkbox.com\""
        
        var lexer = CURL.Lexer(string: str)
        lexer.tokenize()
        
        XCTAssert(lexer.tokens == ["curl", "http://kkbox.com"], "\(lexer.tokens)")
    }

    func testTokenize6_1() {
        let str = "curl http\'://kkbox.com\'"
        
        var lexer = CURL.Lexer(string: str)
        lexer.tokenize()
        
        XCTAssert(lexer.tokens == ["curl", "http://kkbox.com"], "\(lexer.tokens)")
    }

    func testTokenize7() {
        let str = "curl http\"  ://kkbox.com  \""
        
        var lexer = CURL.Lexer(string: str)
        lexer.tokenize()
        
        XCTAssert(lexer.tokens == ["curl", "http  ://kkbox.com  "], "\(lexer.tokens)")
    }

    func testTokenize7_1() {
        let str = "curl http\'  ://kkbox.com  \'"
        
        var lexer = CURL.Lexer(string: str)
        lexer.tokenize()
        
        XCTAssert(lexer.tokens == ["curl", "http  ://kkbox.com  "], "\(lexer.tokens)")
    }

    func testTokenize8() {
        let str = "curl \"  \'http://kkbox.com\'  \""
        
        var lexer = CURL.Lexer(string: str)
        lexer.tokenize()
        
        XCTAssert(lexer.tokens == ["curl", "  \'http://kkbox.com\'  "], "\(lexer.tokens)")
    }

    func testTokenize8_1() {
        let str = "curl \'  \"http://kkbox.com\"  \'"
        
        var lexer = CURL.Lexer(string: str)
        lexer.tokenize()
        
        XCTAssert(lexer.tokens == ["curl", "  \"http://kkbox.com\"  "], "\(lexer.tokens)")
    }

    func testTokenize9() {
        let str = #"curl -F "{ \"name\"=\"name\" }" "http://kkbox.com""#
        
        var lexer = CURL.Lexer(string: str)
        lexer.tokenize()
        
        XCTAssert(lexer.tokens == ["curl", "-F", "{ \"name\"=\"name\" }", "http://kkbox.com"], "\(lexer.tokens)")
    }

    func testTokenize10() {
        let str = #"curl "http://kkbox.com"#
        
        var lexer = CURL.Lexer(string: str)
        lexer.tokenize()
        
        XCTAssert(lexer.tokens == ["curl", "http://kkbox.com"], "\(lexer.tokens)")
    }

    func testTokenize11() {
        let str = #"curl http://kkbox.com""#
        
        var lexer = CURL.Lexer(string: str)
        lexer.tokenize()
        
        XCTAssert(lexer.tokens == ["curl", "http://kkbox.com"], "\(lexer.tokens)")
    }

    func testTokenize12() {
        let str = #"curl "http:"//kkbox."com""#
        
        var lexer = CURL.Lexer(string: str)
        lexer.tokenize()
        
        XCTAssert(lexer.tokens == ["curl", "http://kkbox.com"], "\(lexer.tokens)")
    }

    func testTokenize13() {
        let str = #"curl "ht"tp://kkbox."com""#
        
        var lexer = CURL.Lexer(string: str)
        lexer.tokenize()
        
        XCTAssert(lexer.tokens == ["curl", "http://kkbox.com"], "\(lexer.tokens)")
    }



    //    static var allTests = [
    //        ("testExample", testExample),
    //    ]
}
