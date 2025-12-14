struct Token {
    enum Kind {
        // Meta
        case eof, eol

        // Grouping
        case lpar, rpar, lbrac, rbrac, lcurl, rcurl
        
        // Arithmetic
        case plus, plusplus, pluseq
        case minus, minusminus, minuseq
        case star, starstar, stareq, starstareq
        case slash, slashslash, slasheq, slashslasheq
        case mod, modeq

        // Logical/Comparison
        case and, andand, bar, barbar
        case lt, lteq, gt, gteq
        case bang, bangeq, eq, eqeq

        // Misc
        case dot, comma, colon, semicolon, qmark, arrow

        // Literals
        case litSymbol, litInteger, litFloat, litString, litRawString, litTrue, litFalse
        
        // Keywords
        case kwLet, kwMutable, kwType
        case kwFor, kwIn, kwBreak, kwContinue, kwWhile
        case kwIf, kwElse, kwDo
    }

    let kind: Kind
    let pos: Position
    let indent: Int

    init(_ kind: Kind, _ pos: Position, _ indent: Int) {
        self.kind = kind
        self.pos = pos
        self.indent = indent
    }

    public static func getReservedWord(_ str: Substring) -> Kind? {
        return switch str {
        case "let"      : .kwLet
        case "mutable"  : .kwMutable
        case "type"     : .kwType
        case "for"      : .kwFor
        case "in"       : .kwIn
        case "break"    : .kwBreak
        case "continue" : .kwContinue
        case "while"    : .kwWhile
        case "if"       : .kwIf
        case "else"     : .kwElse
        case "do"       : .kwDo
        case "true"     : .litTrue
        case "false"    : .litFalse
        default         : nil
        }
    } 
}