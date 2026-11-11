import SwiftUI

/// Marks a demo replay (backend rev 4.15) on a score card or the game header, so it is
/// never read as a game happening now. The feature chooses the text ("Replay",
/// "Simulated replay"); the badge looks the same everywhere.
public struct ReplayBadge: View {
    private let text: String

    public init(text: String) {
        self.text = text
    }

    public var body: some View {
        Label(text, systemImage: "play.rectangle.fill")
            .wehoopFont(.eyebrow)
            .textCase(.uppercase)
            .foregroundStyle(Color.wehoopOnAccent)
            .padding(.horizontal, Spacing.s)
            .padding(.vertical, Spacing.xs)
            .background(Color.wehoopHighlight, in: Capsule())
    }
}

/// Game clock text, the same on every screen.
nonisolated public enum ClockText {
    /// `M:SS` from a minute up (rounded up, so the observed value shows until a full second
    /// has passed), `S.T` below a minute (tenths rounded up). Matches LiveEngine's `ClockModel`.
    public static func format(_ seconds: Double) -> String {
        if seconds >= 60 {
            let whole = Int(seconds.rounded(.up))
            return "\(whole / 60):" + String(format: "%02d", whole % 60)
        }
        let tenths = max(0, Int((seconds * 10 - 1e-9).rounded(.up)))
        // Just under a minute rounds up to 600 tenths: that is the minute display.
        if tenths >= 600 { return "1:00" }
        return "\(tenths / 10).\(tenths % 10)"
    }
}

/// A row of days to pick one from (the Scores tab's date strip). It scrolls sideways and
/// opens on the selected day; `today` is marked so it can be found again.
public struct WeekStrip: View {
    private let days: [Date]
    private let today: Date
    private let calendar: Calendar
    @Binding private var selection: Date

    public init(days: [Date], today: Date, calendar: Calendar = .current, selection: Binding<Date>) {
        self.days = days
        self.today = today
        self.calendar = calendar
        _selection = selection
    }

    public var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.xs) {
                    ForEach(days, id: \.self) { day in
                        cell(day)
                            .id(day)
                    }
                }
                .padding(.horizontal, Spacing.l)
            }
            .onAppear { proxy.scrollTo(selection, anchor: .center) }
            .onChange(of: selection) { _, day in
                withAnimation(.snappy) { proxy.scrollTo(day, anchor: .center) }
            }
        }
    }

    private func cell(_ day: Date) -> some View {
        let selected = calendar.isDate(day, inSameDayAs: selection)
        let isToday = calendar.isDate(day, inSameDayAs: today)
        return Button {
            selection = day
        } label: {
            VStack(spacing: Spacing.xxs) {
                Text(isToday ? String(localized: "Today") : day.formatted(.dateTime.weekday(.abbreviated)))
                    .wehoopFont(.eyebrow)
                    .textCase(.uppercase)
                Text(day.formatted(.dateTime.day()))
                    .wehoopFont(.headline)
                    .monospacedDigit()
            }
            .foregroundStyle(selected ? Color.wehoopOnAccent : Color.wehoopTextPrimary)
            .frame(minWidth: 48, minHeight: 48)
            .padding(.horizontal, Spacing.xs)
            .padding(.vertical, Spacing.xs)
            .background(selected ? Color.wehoopAccent : Color.clear, in: RoundedRectangle(cornerRadius: Radius.medium))
            .contentShape(RoundedRectangle(cornerRadius: Radius.medium))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isToday
            ? String(localized: "Today, \(day.formatted(date: .complete, time: .omitted))")
            : day.formatted(date: .complete, time: .omitted))
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

/// A sideways row of choices, one selected (the league switch). It shows exactly the items
/// it is given, in their order.
public struct ChipPicker<ID: Hashable>: View {
    public struct Item: Identifiable {
        public let id: ID
        public let title: String
        public init(id: ID, title: String) {
            self.id = id
            self.title = title
        }
    }

    private let items: [Item]
    @Binding private var selection: ID?

    public init(items: [Item], selection: Binding<ID?>) {
        self.items = items
        _selection = selection
    }

    public var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.s) {
                ForEach(items) { item in
                    let selected = item.id == selection
                    Button {
                        selection = item.id
                    } label: {
                        Text(item.title)
                            .wehoopFont(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(selected ? Color.wehoopOnAccent : Color.wehoopTextPrimary)
                            .padding(.horizontal, Spacing.m)
                            .padding(.vertical, Spacing.s)
                            .background(selected ? Color.wehoopHighlight : Color.wehoopSurface, in: Capsule())
                            .overlay(Capsule().strokeBorder(Color.wehoopSeparator, lineWidth: selected ? 0 : 1))
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(selected ? .isSelected : [])
                }
            }
            .padding(.horizontal, Spacing.l)
        }
    }
}
