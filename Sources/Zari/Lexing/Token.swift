struct Token {
    enum Kind {
        case eof, eol
        case lpar, rpar
        case plus, plusPlus, plusEq
        case dot
        case litSymbol, litInteger, litFloat
        case kwLet
    }

    let kind: Kind
    let pos: Position
    let indent: Int

    init(_ kind: Kind, _ pos: Position, _ indent: Int) {
        self.kind = kind
        self.pos = pos
        self.indent = indent
    }

    public static func getKeyword(_ str: Substring) -> Kind? {
        return switch str {
        case "let": .kwLet
        default: nil
        }
    } 
}