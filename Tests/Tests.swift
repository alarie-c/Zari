import Testing
@testable import Zari

@Suite("Common/*")
struct Common {
    @Test func sourceSubstrings() async throws {
        let source = Source(fromString: "hello world")
        let pos = Position(source.data.startIndex, 5, x: 1, y: 1)
        #expect(source.substring(pos) == "hello")
    }

    @Test func sourceLines() async throws {
        let source = Source(fromString: "line 1\nline 2\nline 3")
        let pos = Position(source.data.startIndex, 10, x: 1, y: 1)
        let lines = source.lines(in: pos)
        print(lines)
        #expect(lines.count == 2)
        #expect(lines[0] == (1, "line 1"))
        #expect(lines[1] == (2, "line 2"))
    }

    @Test func renderInvalidString() async throws {
        let src = Source(fromString: "\"hello\nworld\"")
        
        // The invalid string literal spans the first 7 characters "\"hello
        let pos = Position(src.data.startIndex, 7, x: 1, y: 1)
        
        let error = Error(src: src, .invalidString, at: pos, "Unterminated string literal")
        
        let output = error.render()
        print(output)
        #expect(output.contains("Invalid String Literal"))
        #expect(output.contains("^~~~~~"))
    }

    @Test func renderInvalidCharacter() async throws {
        let src = Source(fromString: "let x = 9$ + 1")
        
        // The invalid character is the "$" at offset 8
        let startIndex = src.data.index(src.data.startIndex, offsetBy: 8)
        let pos = Position(startIndex, 1, x: 9, y: 1)
        
        let error = Error(src: src, .invalidCharacter, at: pos, "Unexpected character '$'")
        
        let output = error.render()
        print(output)
        #expect(output.contains("Invalid Character"))
        #expect(output.contains("^"))
    }

    @Test func renderMultiLineError() async throws {
        let src = Source(fromString: "line 1\nline 2\nline 3")
        
        // Span covers the last 3 characters of line 1 and first 2 of line 2
        let startIndex = src.data.index(src.data.startIndex, offsetBy: 5)
        let pos = Position(startIndex, 5, x: 6, y: 1)
        
        let error = Error(src: src, .internalError, at: pos, "Example multi-line error")
        
        let output = error.render()
        print(output)
        #expect(output.contains("^"))
        #expect(output.contains("~~~~"))
        #expect(output.contains("multi-line error"))
    }
}