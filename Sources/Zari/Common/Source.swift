///////////////////////////////////////////////////////////////////////////////////////////////////
// MARK: Position
///////////////////////////////////////////////////////////////////////////////////////////////////

///

///////////////////////////////////////////////////////////////////////////////////////////////////
// MARK: Source
///////////////////////////////////////////////////////////////////////////////////////////////////

///

import Foundation

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
        var str = try String(contentsOf: url, encoding: .utf8)

        // Normalize newlines to remove carriage returns
        str = str.replacingOccurrences(of: "\r\n", with: "\n")
        str = str.replacingOccurrences(of: "\r", with: "\n")

        // Set the string
        self.data = str
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
        if !contains(i: pos.index, length: pos.length) {
            // If so, cap it to the end index
            // (substring with non-inclusive range)
            end = data.endIndex
        } else {
            // Otherwise just set `end` using distance offset
            end = data.index(pos.index, offsetBy: pos.length)
        }

        return data[pos.index..<end]
    }

    public func contains(i: String.Index, length: Int) -> Bool {
        data.distance(from: i, to: data.endIndex) >= length
    }

    public func lines(in pos: Position) -> [(Int, Substring)] {
        assert(data.indices.contains(pos.index))

        // Check if the distance puts the position outside of the string
        guard contains(i: pos.index, length: pos.length) else {
            assert(false, "Position is outside of data!")
        }

        let end = data.index(pos.index, offsetBy: pos.length)
        var y = pos.y
        var lines: [(Int, Substring)] = []
        var start = pos.index
        var complete = false

        for index in data[pos.index..<data.endIndex].indices {
            // This condition will break the loop after the NEXT newline or eof
            if index >= end { complete = true }

            // Catch EOL
            if data[index] == "\n" {
                // Create the substring and push
                let str = data[start..<index]
                lines.append((y, str))

                if complete {
                    // Stop looking for stuff if we've already passed the
                    // pos end index.
                    start = data.index(after: index)
                    break
                } else {
                    // Otherwise, repare for the next line
                    start = data.index(after: index)
                    y += 1
                }
            }
        }

        // Push 1 line if we didn't actually find any newlines
        if start < end { lines.append((y, data[start..<min(end, data.endIndex)])) }
        return lines
    }

    // public func line(of pos: Position) -> [(Int, Substring)] {
    //     assert(data.indices.contains(pos.index))

    //     /// Star the line number at the current line, increment manually,
    //     /// always the line number for `trackedIndex``.
    //     var y = pos.y
    //     var lines: [(Int, Substring)] = []

    //     /// The absolute index that we're looking through,
    //     /// always points to the start of a line.
    //     var trackedIndex = pos.index

    //     while true {
    //         // Get the tail of the source data
    //         let tail = data[trackedIndex..<data.endIndex]

    //         // If there exists a EOL
    //         if let end = tail.firstIndex(of: "\n") {
    //             // Get the substring from the currently tracked index
    //             // to the index of that EOL (not including the EOL)
    //             let str = data[trackedIndex..<end]

    //             // Append that string with it's corresponding line number
    //             lines.append((y, str))

    //             // Increment the line number that we're on and update the index
    //             // Substring indicies are absolute, so no need to worry about using
    //             // end here, even though it was taken from `tail`.
    //             trackedIndex = data.index(end, offsetBy: 1)
    //             y += 1
    //         } else {
    //             // If there is not EOL, then just return the rest of the file
    //             // with whatever line number we're at right now
    //             lines.append((y, tail))

    //             // Quit looking for more newline (there are none, we're at EOF)
    //             break
    //         }
    //     }

    //     return lines
    // }
}
