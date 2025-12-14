import Testing
@testable import Zari

@Suite("Lexing/Lexer")
struct name {
    @Test func whitespaceAndOp() async throws {
        let source = Source(fromString: "+  ++ +=")
        let lexer = Lexer(source)
        #expect(lexer.token()!.kind == .plus)
        #expect(lexer.token()!.kind == .plusPlus)
        #expect(lexer.token()!.kind == .plusEq)
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
}