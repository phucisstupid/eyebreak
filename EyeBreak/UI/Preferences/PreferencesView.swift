import SwiftUI

@MainActor
struct PreferencesView: View {
    static let nativeWindowSize = CGSize(width: 480, height: 330)

    @FocusState private var focusedField: Field?
    @State private var settings: AppSettings
    @State private var activeIntervalText: String
    @State private var idleThresholdText: String
    @State private var shortBreakText: String
    @State private var longBreakText: String
    @State private var longBreakFrequencyText: String
    @State private var launchAtLoginMessage: String?

    let onSave: (AppSettings) -> Void
    let onLaunchAtLoginChange: @MainActor (Bool) -> String?

    init(
        settings: AppSettings,
        onSave: @escaping (AppSettings) -> Void,
        onLaunchAtLoginChange: @escaping @MainActor (Bool) -> String?
    ) {
        _settings = State(initialValue: settings)
        _activeIntervalText = State(initialValue: Self.text(for: Int(settings.activeInterval / 60)))
        _idleThresholdText = State(initialValue: Self.text(for: Int(settings.idleThreshold)))
        _shortBreakText = State(initialValue: Self.text(for: Int(settings.shortBreakDuration)))
        _longBreakText = State(initialValue: Self.text(for: Int(settings.longBreakDuration)))
        _longBreakFrequencyText = State(initialValue: Self.text(for: settings.longBreakFrequency))
        self.onSave = onSave
        self.onLaunchAtLoginChange = onLaunchAtLoginChange
    }

    var body: some View {
        Form {
            Section("Reminders") {
                numericFieldRow(
                    title: "Active interval", text: $activeIntervalText, unit: "minutes",
                    field: .activeInterval)
                numericFieldRow(
                    title: "Idle threshold", text: $idleThresholdText, unit: "seconds",
                    field: .idleThreshold)
            }

            Section("Breaks") {
                numericFieldRow(
                    title: "Short break", text: $shortBreakText, unit: "seconds",
                    field: .shortBreak)
                numericFieldRow(
                    title: "Long break", text: $longBreakText, unit: "seconds",
                    field: .longBreak)
                numericFieldRow(
                    title: "Long break frequency", text: $longBreakFrequencyText,
                    unit: "breaks", field: .longBreakFrequency)
            }

            Section("Startup") {
                Toggle("Launch at login", isOn: launchAtLoginBinding)

                if let launchAtLoginMessage {
                    Text(launchAtLoginMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .padding(.horizontal, 4)
        .padding(.vertical, 6)
        .frame(
            minWidth: Self.nativeWindowSize.width,
            minHeight: Self.nativeWindowSize.height,
            alignment: .topLeading
        )
        .onChange(of: focusedField) { previousField, nextField in
            guard let previousField, previousField != nextField else {
                return
            }

            commit(field: previousField)
        }
    }

    private func numericFieldRow(
        title: String,
        text: Binding<String>,
        unit: String,
        field: Field
    ) -> some View {
        LabeledContent(title) {
            HStack(spacing: 6) {
                TextField("", text: text)
                    .textFieldStyle(.roundedBorder)
                    .controlSize(.small)
                    .font(.body.monospacedDigit())
                    .multilineTextAlignment(.trailing)
                    .frame(width: 56)
                    .focused($focusedField, equals: field)
                    .onSubmit {
                        commit(field: field)
                    }

                Text(unit)
                    .foregroundStyle(.secondary)
                    .font(.callout)
            }
        }
    }

    private func commit(field: Field) {
        switch field {
        case .activeInterval:
            commitIntegerText(
                text: &activeIntervalText,
                fallback: Int(settings.activeInterval / 60),
                parser: PreferencesIntegerFieldParser(range: 1...120)
            ) { settings, value in
                settings.activeInterval = TimeInterval(value * 60)
            }
        case .idleThreshold:
            commitIntegerText(
                text: &idleThresholdText,
                fallback: Int(settings.idleThreshold),
                parser: PreferencesIntegerFieldParser(range: 1...60)
            ) { settings, value in
                settings.idleThreshold = TimeInterval(value)
            }
        case .shortBreak:
            commitIntegerText(
                text: &shortBreakText,
                fallback: Int(settings.shortBreakDuration),
                parser: PreferencesIntegerFieldParser(range: 5...300)
            ) { settings, value in
                settings.shortBreakDuration = TimeInterval(value)
            }
        case .longBreak:
            commitIntegerText(
                text: &longBreakText,
                fallback: Int(settings.longBreakDuration),
                parser: PreferencesIntegerFieldParser(range: 15...600)
            ) { settings, value in
                settings.longBreakDuration = TimeInterval(value)
            }
        case .longBreakFrequency:
            commitIntegerText(
                text: &longBreakFrequencyText,
                fallback: settings.longBreakFrequency,
                parser: PreferencesIntegerFieldParser(range: 1...10)
            ) { settings, value in
                settings.longBreakFrequency = value
            }
        }
    }

    private func commitIntegerText(
        text: inout String,
        fallback: Int,
        parser: PreferencesIntegerFieldParser,
        apply: (inout AppSettings, Int) -> Void
    ) {
        let normalizedValue = parser.normalizedValue(from: text, fallback: fallback)
        text = Self.text(for: normalizedValue)
        updateSettings { apply(&$0, normalizedValue) }
    }

    private static func text(for value: Int) -> String {
        String(value)
    }

    private enum Field: Hashable {
        case activeInterval
        case idleThreshold
        case shortBreak
        case longBreak
        case longBreakFrequency
    }

    var launchAtLoginBinding: Binding<Bool> {
        Binding(
            get: { settings.launchAtLogin },
            set: { newValue in
                settings.launchAtLogin = newValue
                launchAtLoginMessage = onLaunchAtLoginChange(newValue)
            }
        )
    }

    private func updateSettings(_ transform: (inout AppSettings) -> Void) {
        var nextSettings = settings
        transform(&nextSettings)
        settings = nextSettings
        onSave(nextSettings)
    }
}

struct PreferencesIntegerFieldParser {
    let range: ClosedRange<Int>

    func normalizedValue(from text: String, fallback: Int) -> Int {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)

        guard let parsedValue = Int(trimmedText) else {
            return clamped(fallback)
        }

        return clamped(parsedValue)
    }

    func normalizedText(from text: String, fallback: Int) -> String {
        String(normalizedValue(from: text, fallback: fallback))
    }

    private func clamped(_ value: Int) -> Int {
        min(max(value, range.lowerBound), range.upperBound)
    }
}
