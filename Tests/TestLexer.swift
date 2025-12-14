import Testing
@testable import Zari

@Suite("Lexing/Lexer")
struct name {
    @Test func whitespaceAndOp() async throws {
        let source = Source(fromString: "+  ++ +=")
        let lexer = Lexer(source)
        #expect(lexer.token()!.kind == .plus)
        #expect(lexer.token()!.kind == .plusplus)
        #expect(lexer.token()!.kind == .pluseq)
        #expect(lexer.index == source.data.endIndex)
    }

    @Test func symbols() async throws {
        let source = Source(fromString: "let main")
        let lexer = Lexer(source)
        let a = lexer.token()!
        let b = lexer.token()!
        print(a)
        print(b)
        #expect(a.kind == .kwLet)
        #expect(b.kind == .litSymbol)
        #expect(lexer.index == source.data.endIndex)
    }

    @Test func strings() async throws {
        let source = Source(fromString: "\"Hello, world!\\n\"")
        let lexer = Lexer(source)
        print(source.data)

        let a = lexer.token()!
        print(a)
        #expect(a.kind == .litString)
        #expect(lexer.index == source.data.endIndex)

        let str = source.substring(a.pos)
        #expect(str == "\"Hello, world!\\n\"")
    }

    @Test func rawStrings() async throws {
        let text = "\"\"\"Hello, world!\n   I love Zari!\"\"\""
        let source = Source(fromString: text)
        let lexer = Lexer(source)
        print(source.data)

        let a = lexer.token()!
        print(a)
        #expect(a.kind == .litRawString)
        #expect(lexer.index == source.data.endIndex)

        let str = source.substring(a.pos)
        print("'\(str)'")
    }

    @Test func digits() async throws {
        let source = Source(fromString: "123 123.5 123.add")
        let lexer = Lexer(source)
        let a = lexer.token()!
        let b = lexer.token()!
        let c = lexer.token()!
        let d = lexer.token()!
        let e = lexer.token()!
        print(a)
        print(b)
        print(c)
        print(d)
        print(e)
        #expect(a.kind == .litInteger)
        #expect(b.kind == .litFloat)
        #expect(c.kind == .litInteger)
        #expect(d.kind == .dot)
        #expect(e.kind == .litSymbol)
        #expect(lexer.index == source.data.endIndex)

        #expect(source.substring(a.pos) == "123")
        #expect(source.substring(b.pos) == "123.5")
        #expect(source.substring(c.pos) == "123")
    }

    @Test func indents() async throws {
        repeat {
            let source = Source(fromString: "let main\n    4")
            let lexer = Lexer(source)
            let a = lexer.token()!
            let b = lexer.token()!
            let c = lexer.token()!
            let d = lexer.token()!
            print(a)
            print(b)
            print(c)
            print(d)
            #expect(a.kind == .kwLet)
            #expect(b.kind == .litSymbol)
            #expect(c.kind == .eol)
            #expect(d.kind == .litInteger)
            #expect(d.indent == 1)
            #expect(lexer.index == source.data.endIndex)
        } while(false)

        repeat {
            let source = Source(fromString: "let main\n  2")
            let lexer = Lexer(source)
            let a = lexer.token()!
            let b = lexer.token()!
            let c = lexer.token()!
            let d = lexer.token()!
            print(a)
            print(b)
            print(c)
            print(d)
            #expect(a.kind == .kwLet)
            #expect(b.kind == .litSymbol)
            #expect(c.kind == .eol)
            #expect(d.kind == .litInteger)
            #expect(d.indent == 1)
            #expect(lexer.index == source.data.endIndex)
        } while(false)
    }

    @Test func fullFile() async throws {
        let source = try Source(fromPath: "Tests/Test.zari")
        let lexer = Lexer(source)

        let tokens = lexer.lex()
        for i in 0..<tokens.count { print("\(i): \(tokens[i])") }
        #expect(lexer.index == source.data.endIndex)
        #expect(lexer.indentMode == .four)
    }
}