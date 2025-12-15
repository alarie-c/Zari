struct Error {
    enum Issue: String {
        // Misc/Internal
        case internalError = "Internal Error"
        
        // Lexing errors
        case invalidString    = "Invalid String Literal"
        case invalidCharacter = "Invalid Character"

        // Parsing errors
    }

    enum Level: String {
        case error   = "Error"
        case warning = "Warning"
        case info    = "Info"
    }

    private static func getLevel(_ issue: Issue) -> Level {
        return switch (issue) {
        default: .error
        }
    }

    let source: Source
    let issue: Issue
    let level: Level
    let pos: Position
    let msg: String

    init(src: Source, _ issue: Issue, at pos: Position, _ msg: String) {
        self.source = src
        self.issue  = issue
        self.level  = Error.getLevel(issue)
        self.pos    = pos
        self.msg    = msg
    }
    
    /*
    Error: Unknown Identifier
    --> src/Main.zari:5:20  
      | 
    5 | let index = str.find("hello")   
      |             ^~~ 
    Note: This identifier has not been defined yet. 
    */
    public func render() -> String {
        var result = String()

        // Check if the distance puts the position outside of the string
        guard source.contains(i: pos.index, length: pos.length) else {
            assert(false, "Error position is outside of data!")
        }

        let lines = source.lines(in: pos)
        // let endIndex = source.data.index(pos.index, offsetBy: pos.length)

        // Write the header: <Level>: <Issue> @ <Path>:<y>:<x>:\n
        result += "\(level.rawValue): \(issue.rawValue) @ \(source.path):\(pos.y):\(pos.x):\n"

        // Determine gutter size from max line number
        let gutterLen = String(pos.y + lines.count).count + 1
        let gutterFull = String(repeating: " ", count: gutterLen)
        result += "\(gutterFull)|\n"

        // Track the remaining span length
        var remainingLength = pos.length
        var spanStartIndex = pos.index

        // Now print the actual lines
        for (y, line) in lines {
            // Line number + gutter
            let yCount = String(y).count
            let gutter = String(repeating: " ", count: gutterLen - yCount)
            result += "\(y)\(gutter)| \(line)\n"

            // Marker line
            result += "\(gutterFull)| "
            for i in line.indices {
                if remainingLength == 0 { break }

                if i >= spanStartIndex {
                    if i == spanStartIndex {
                        result += "^"
                    } else {
                        result += "~"
                    }
                    remainingLength -= 1
                } else {
                    // preserve alignment for characters before the span
                    result += " "
                }
            }
            result += "\n"

            // Update spanStartIndex for the next line
            spanStartIndex = line.endIndex
        }

        result += "Note: \(msg)"
        return result
    }
}