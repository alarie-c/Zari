final class Lexer {
    let source: Source
    var x: Int = 1
    var y: Int = 1
    var index: String.Index

    enum IndentMode {
        case unset
        case tabs
        case two
        case four
    }

    var indentMode = IndentMode.unset
    var indentLevel: Int = 0

    private static func isSymbolStart(_ ch: Character) -> Bool { ch.isLetter || ch == "_" }
    private static func isSymbolFollow(_ ch: Character) -> Bool {
        ch.isLetter || ch == "_" || ch.isNumber
    }
    private static func isDigitStart(_ ch: Character) -> Bool { ch.isNumber }
    private static func isDigitFollow(_ ch: Character) -> Bool {
        ch.isNumber || ch == "." || ch == "_"
    }

    init(_ source: Source) {
        self.source = source
        self.index = source.data.startIndex
    }

    internal func get(_ k: Int = 0) -> Character {
        guard source.data.distance(from: index, to: source.data.endIndex) > k
        else { return "\0" }

        // Return the actual character at the position offset by k
        let target = source.data.index(index, offsetBy: k)
        return source.data[target]
    }

    /// Moves the lexer `k` places.
    ///
    internal func move(_ k: Int = 1) {
        guard source.data.distance(from: index, to: source.data.endIndex) > k
        else {
            index = source.data.endIndex
            return
        }

        // Update the index
        index = source.data.index(index, offsetBy: k)
        x += k
    }

    /// Moves the lexer `k` places and extends the position `k-1` places.
    ///
    internal func move(_ k: Int = 1, extend pos: inout Position) {
        move(k)
        pos.extend(k - 1)
    }

    internal func token() -> Token? {
        whitespace()
        var pos = Position(index, 1, x: x, y: y)
        if Lexer.isSymbolStart(get()) { return symbol(&pos) }
        if Lexer.isDigitStart(get()) { return digit(&pos) }
        return op(&pos)
    }

    internal func whitespace() {
        while get() == " " || get() == "\r" { move() }
    }

    internal func digit(_ pos: inout Position) -> Token {
        var length = 1
        var kind = Token.Kind.litInteger
        while Lexer.isDigitFollow(get(1)) {
            if get(1) == "." && kind == .litInteger {
                // Check if the dot is actually part of this token
                // or if it's its own thing
                if !Lexer.isDigitStart(get(2)) {
                    // If it isn't then break here
                    break
                } else {
                    // If it IS, then consume it
                    kind = .litFloat
                    length += 2
                    move(2)
                }
            } else {
                length += 1
                move()
            }
        }

        // Extend the position to the correct length
        pos.extend(length - 1)

        // Advance the lexer for the next pass
        move()

        // Return the token
        return Token(kind, pos, indentLevel)
    }

    internal func symbol(_ pos: inout Position) -> Token {
        var length = 1
        while Lexer.isSymbolFollow(get(1)) {
            move()
            length += 1
        }

        // Extend the position to the correct length
        pos.extend(length - 1)

        // Get the substring with this position
        let lexeme = source.substring(pos)

        // Advance the lexer for the next pass
        move()

        // Look for keywords in the lexeme
        let kind = Token.getKeyword(lexeme) ?? .litSymbol

        // Return the final token
        return Token(kind, pos, indentLevel)
    }

    internal func op(_ pos: inout Position) -> Token? {
        switch get() {
        case ".":
            move()
            return Token(.dot, pos, indentLevel)
        case "+":
            if get(1) == "=" {
                move(2, extend: &pos)
                return Token(.plusEq, pos, indentLevel)
            } else if get(1) == "+" {
                move(2, extend: &pos)
                return Token(.plusPlus, pos, indentLevel)
            } else {
                move()
                return Token(.plus, pos, indentLevel)
            }
        default:
            move()
            return nil
        }
    }
}
