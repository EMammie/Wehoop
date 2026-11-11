import Foundation
import Testing
@testable import Domain

struct GameTextTests {
    private let q4 = GamePeriod(number: 4, kind: .quarter, sequence: 4)

    @Test("Period labels: quarters, halves, overtimes, Elam, and an unknown kind by number")
    func periodLabels() {
        #expect(GamePeriod(number: 3, kind: .quarter, sequence: 3).shortLabel == "Q3")
        #expect(GamePeriod(number: 2, kind: .half, sequence: 2).shortLabel == "H2")
        #expect(GamePeriod(number: 1, kind: .overtime, sequence: 5).shortLabel == "OT")
        #expect(GamePeriod(number: 2, kind: .overtime, sequence: 6).shortLabel == "2OT")
        #expect(GamePeriod(number: 1, kind: .elam, sequence: 5).shortLabel == "Elam")
        #expect(GamePeriod(number: 5, kind: .unknown("shootout"), sequence: 5).shortLabel == "P5")
    }

    @Test("Status line: tip-off or Scheduled, period or Live, Halftime, unofficial before validation, Final/OT")
    func statusText() {
        let tip = Date(timeIntervalSince1970: 1_800_000_000)
        #expect(GameStatus.scheduled.text(scheduledAt: tip, period: nil) == tip.formatted(date: .omitted, time: .shortened))
        #expect(GameStatus.created.text(scheduledAt: nil, period: nil) == "Scheduled")
        #expect(GameStatus.timeTBD.text(scheduledAt: tip, period: nil) == "Time TBD")
        #expect(GameStatus.inProgress.text(scheduledAt: tip, period: q4) == "Q4")
        #expect(GameStatus.inProgress.text(scheduledAt: tip, period: nil) == "Live")
        #expect(GameStatus.halftime.text(scheduledAt: tip, period: q4) == "Halftime")
        #expect(GameStatus.complete.text(scheduledAt: tip, period: q4) == "Final · unofficial")
        #expect(GameStatus.closed.text(scheduledAt: tip, period: q4) == "Final")
        #expect(GameStatus.closed.text(scheduledAt: tip, period: GamePeriod(number: 1, kind: .overtime, sequence: 5)) == "Final/OT")
        #expect(GameStatus.unnecessary.text(scheduledAt: tip, period: nil) == "Not needed")
        #expect(GameStatus.unknown("suspended").text(scheduledAt: tip, period: nil) == "suspended")
    }
}
