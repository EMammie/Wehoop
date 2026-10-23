import Testing
@testable import LiveEngine

struct SequenceCheckTests {
    @Test("A change is next, a duplicate, or a gap relative to the last seq", arguments: [
        (6, 5, SequenceCheck.next),
        (5, 5, SequenceCheck.duplicate),
        (3, 5, SequenceCheck.duplicate),
        (7, 5, SequenceCheck.gap),
    ])
    func classifiesSequence(seq: Int, last: Int, expected: SequenceCheck) {
        #expect(checkSequence(seq, after: last) == expected)
    }
}
