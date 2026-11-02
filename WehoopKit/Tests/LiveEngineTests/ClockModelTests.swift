import Foundation
import Testing
@testable import LiveEngine

struct ClockModelTests {
    private let asOf = "2026-06-30T23:16:30.000Z"
    private var asOfDate: Date { ISODate.parse(asOf)! }

    private func model(_ clock: String?, running: Bool?, offset: TimeInterval = 0) -> ClockModel {
        ClockModel(
            observation: ClockObservation(clock: clock, clockDecimal: nil, running: running, asOf: asOf, observedAt: asOf),
            serverOffset: offset
        )
    }

    @Test("Provider clock strings parse to seconds", arguments: [
        ("10:00", 600.0), ("09:41", 581.0), ("6:48", 408.0), ("00:02", 2.0), ("0:00", 0.0), ("1:05.4", 65.4), ("7.3", 7.3),
    ])
    func parses(clock: String, seconds: Double) {
        #expect(abs((ClockModel.seconds(clock) ?? -1) - seconds) < 1e-9)
    }

    @Test("Malformed clocks parse to nil", arguments: ["", "abc", "1:75", "-1:00", "1:2:3"])
    func rejects(clock: String) {
        #expect(ClockModel.seconds(clock) == nil)
    }

    @Test("Running: counts down from asOf on the server clock; shows the observed value at asOf")
    func countsDown() {
        let m = model("09:41", running: true)
        #expect(m.isCounting)
        #expect(m.display(at: asOfDate) == "9:41")
        #expect(m.display(at: asOfDate.addingTimeInterval(0.4)) == "9:41") // seconds round up
        #expect(m.display(at: asOfDate.addingTimeInterval(1.0)) == "9:40")
        #expect(m.display(at: asOfDate.addingTimeInterval(61)) == "8:40")
        #expect(m.display(at: asOfDate.addingTimeInterval(600)) == "0.0") // never below zero
    }

    @Test("The server offset shifts the countdown: a device 5 s behind the server still shows the server's clock")
    func serverOffset() {
        let m = model("1:00", running: true, offset: 5)
        #expect(m.display(at: asOfDate) == "55.0")
        #expect(m.display(at: asOfDate.addingTimeInterval(-5)) == "1:00")
        #expect(ClockModel.format(59.95) == "1:00") // rounds up to 600 tenths: the minute display, never "60.0"
        #expect(ClockModel.format(59.9) == "59.9")
    }

    @Test("Below a minute the clock shows tenths")
    func tenths() {
        let m = model("00:02", running: true)
        #expect(m.display(at: asOfDate) == "2.0")
        #expect(m.display(at: asOfDate.addingTimeInterval(0.25)) == "1.8")
        #expect(m.display(at: asOfDate.addingTimeInterval(1.95)) == "0.1")
    }

    @Test("Unknown running (nil) freezes the observed clock however much time passes")
    func frozenWhenUnknown() {
        let m = model("5:00", running: nil)
        #expect(!m.isCounting)
        #expect(m.display(at: asOfDate) == "5:00")
        #expect(m.display(at: asOfDate.addingTimeInterval(3600)) == "5:00")
    }

    @Test("A stopped clock (false) is frozen too")
    func frozenWhenStopped() {
        let m = model("0:45", running: false)
        #expect(m.display(at: asOfDate.addingTimeInterval(30)) == "45.0")
    }

    @Test("No clock (Unrivaled's Elam ending) has no display, running or not")
    func noClock() {
        #expect(model(nil, running: true).display(at: asOfDate) == nil)
        #expect(!model(nil, running: true).isCounting)
    }

    @Test("A running clock without asOf cannot be anchored and stays frozen")
    func noAnchor() {
        let m = ClockModel(
            observation: ClockObservation(clock: "3:00", clockDecimal: nil, running: true, asOf: nil, observedAt: nil),
            serverOffset: 0
        )
        #expect(!m.isCounting && m.display(at: Date()) == "3:00")
    }

    @Test("ISO timestamps parse with Z or +00:00, with or without fractions")
    func isoDates() {
        let a = ISODate.parse("2026-06-30T23:16:33.000Z")
        #expect(a != nil)
        #expect(ISODate.parse("2026-06-30T23:16:33+00:00") == a)
        #expect(ISODate.parse("2026-06-30T23:16:33.000+00:00") == a)
        #expect(ISODate.parse("2026-06-30T23:16:33Z") == a)
    }
}
