import Testing
@testable import Zari

@Suite("Common/*")
struct Common {
    @Test func sourceSubstrings() async throws {
        let source = Source(fromString: "hello world")
        let pos = Position(source.data.startIndex, 5, x: 1, y: 1)
        #expect(source.substring(pos) == "hello")
    }
}