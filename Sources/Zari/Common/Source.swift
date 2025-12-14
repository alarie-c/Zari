import Foundation

///////////////////////////////////////////////////////////////////////////////////////////////////
// MARK: Position
///////////////////////////////////////////////////////////////////////////////////////////////////

///
struct Position {
    /// Beginning index
    let index: String.Index
    /// Length, in characters
    var length: Int
    /// User-facing column and line numbers
    let x, y: Int

    init(_ index: String.Index, _ length: Int, x: Int, y: Int) {
        self.index = index
        self.length = length
        self.x = x
        self.y = y
    }

    public mutating func extend(_ k: Int) { length += k } 
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// MARK: Source
///////////////////////////////////////////////////////////////////////////////////////////////////

///
final class Source {
    /// The string representation of the file path
    let path: String
    /// The string data of the file or source code
    let data: String

    /// Create a `Source` from a path and read the file to a string
    /// 
    init(fromPath path: String) throws {
        self.path = path
        let url = URL(fileURLWithPath: path)
        self.data = try String(contentsOf: url, encoding: .utf8)
    }

    /// Create a `Source` from just a string (containing no path)
    /// 
    init(fromString data: String) {
        self.path = "<NoPath>"
        self.data = data
    }

    public func substring(_ pos: Position) -> Substring {
        assert(data.indices.contains(pos.index))
        let end: String.Index
        
        // Check if the distance puts the position outside of the string
        if data.distance(from: pos.index, to: data.endIndex) <= pos.length {
            // If so, cap it to the end index
            // (substring with non-inclusive range)
            end = data.endIndex
        } else {
            // Otherwise just set `end` using distance offset
            end = data.index(pos.index, offsetBy: pos.length)
        }

        return data[pos.index..<end]   
    }
}