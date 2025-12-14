final class Lexer {
    let source: Source
    var x: Int = 1
    var y: Int = 1
    /// Tracks the current position of the lexer in the file
    var index: String.Index

    /// Various modes of indentation depending on
    /// what form is found first
    enum IndentMode {
        case unset
        case tabs
        case two
        case four
    }

    var indentMode = IndentMode.unset
    var indentLevel: Int = 0

    ///////////////////////////////////////////////////////////////////////////////////////////////////
    // MARK: Internal Static Helpers
    ///////////////////////////////////////////////////////////////////////////////////////////////////

    /// List of characters that are allowed to follow an escape sequence
    private static let escapableCharacters: [Character] = ["c", "n", "r", "b", "\\", "\"", "0"]

    private static func isSymbolStart(_ ch: Character) -> Bool { ch.isLetter || ch == "_" }
    private static func isSymbolFollow(_ ch: Character) -> Bool {
        ch.isLetter || ch == "_" || ch.isNumber
    }
    private static func isDigitStart(_ ch: Character) -> Bool { ch.isNumber }
    private static func isDigitFollow(_ ch: Character) -> Bool {
        ch.isNumber || ch == "." || ch == "_"
    }

    ///////////////////////////////////////////////////////////////////////////////////////////////////
    // MARK: Lexer API
    ///////////////////////////////////////////////////////////////////////////////////////////////////

    ///
    init(_ source: Source) {
        self.source = source
        self.index = source.data.startIndex
    }

    public func lex() {}

    ///////////////////////////////////////////////////////////////////////////////////////////////////
    // MARK: Helpers
    ///////////////////////////////////////////////////////////////////////////////////////////////////

    /// Returns the character at `k` places ahead of `index`.
    ///
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

    ///////////////////////////////////////////////////////////////////////////////////////////////////
    // MARK: Tokenizers
    ///////////////////////////////////////////////////////////////////////////////////////////////////

    ///
    internal func token() -> Token? {
        whitespace()
        var pos = Position(index, 1, x: x, y: y)
        if get() == "\n" { return newline(&pos) }
        if get() == "\"" && get(1) == "\"" && get(2) == "\"" { return rawString(&pos) }
        if get() == "\"" { return string(&pos) }
        if Lexer.isSymbolStart(get()) { return symbol(&pos) }
        if Lexer.isDigitStart(get()) { return digit(&pos) }
        return op(&pos)
    }

    internal func whitespace() { while get() == " " || get() == "\r" { move() } }

    internal func newline(_ pos: inout Position) -> Token {
        // Make the newline token and update state
        let token = Token(.eol, pos, indentLevel)
        indentLevel = 0
        move()

        // Check if the indent mode has been set yet, and if not, set it
        if indentMode == .unset {
            // Try each mode and set accordingly without consuming
            if get() == "\t" {
                indentMode = .tabs
            } else if get() == " " && get(1) == " " && get(2) == " " && get(3) == " " {
                // Maximal munch -> try 4 first so it doesn't get lost in the 2 case
                indentMode = .four
            } else if get() == " " && get(1) == " " {
                indentMode = .two
            }

            // Anything else is an actual token not an indentation,
            // so return the newline and lex the next thing
            else {
                return token
            }
        }

        // Now try to consume indents
        switch indentMode {
        case .unset: break  // unreachable
        case .four:
            while get() == " " && get(1) == " " && get(2) == " " && get(3) == " " {
                indentLevel += 1
                move(4)
            }
        case .two:
            while get() == " " && get(1) == " " {
                indentLevel += 1
                move(2)
            }
        case .tabs:
            while get() == "\t" {
                indentLevel += 1
                move()
            }
        }

        // Now return the newline token
        return token
    }

    internal func rawString(_ pos: inout Position) -> Token? {
        // Starting on the first QUOTE
        move(2)
        var length = 1

        // Consume while no triple quote ahead
        func check() -> Bool { get(1) == "\"" && get(2) == "\"" && get(3) == "\"" }
        while !check() {
            length += 1
            move()
        }

        // After a triple quote is found, consume the last char and the triple quote
        length += 4
        move(4)

        // Extend the position to the correct length
        pos.extend(length)

        // Advance the lexer for the next pass
        move()

        // Return the token
        return Token(.litRawString, pos, indentLevel)
    }

    internal func string(_ pos: inout Position) -> Token? {
        // Starting on the QUOTE
        var length = 1
        var char = get(1)

        while char != "\"" {
            // Look for escape sequences
            if char == "\\" {
                /// Assumes get(1) == "\" and looks for a valid escape sequence,
                /// otherwise will throw an error.
                if Lexer.escapableCharacters.contains(get(2)) {
                    // Consume backslash and the end call to move()
                    // will consume the the escaped character.
                    length += 1
                    move(1)
                } else {
                    // Otherwise emit and error
                    fatalError("Invalid escape sequence found!")
                }
            }

            // Look for EOF and throw an error
            if char == "\0" {
                fatalError("End of file reached!")
            }

            // Advance
            length += 1
            move()

            // Update the next check
            char = get(1)
        }

        // Consume the closing QUOTE
        length += 1
        move()

        // Extend the position to the correct length
        pos.extend(length - 1)

        // Advance the lexer for the next pass
        move()

        // Return the token
        return Token(.litString, pos, indentLevel)
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
