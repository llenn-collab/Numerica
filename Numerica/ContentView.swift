import SwiftUI

private enum CalculatorMode: String, CaseIterable, Identifiable {
    case quick = "Quick Check"
    case birth = "Birth Calculator"

    var id: String { rawValue }

    var subtitle: String {
        switch self {
        case .quick:
            return "Type anything. Letters and numbers are calculated live."
        case .birth:
            return "Use a name and birth date for the core numerology numbers."
        }
    }
}

struct ContentView: View {
    @State private var mode: CalculatorMode = .quick
    @State private var quickInput = ""
    @State private var fullName = ""
    @State private var birthDate = Calendar.current.date(byAdding: .year, value: -25, to: Date()) ?? Date()
    @State private var showBreakdown = true
    @FocusState private var focusedField: Field?

    fileprivate enum Field: Hashable {
        case quick
        case name
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            modePicker

            if mode == .quick {
                QuickCheckView(input: $quickInput, showBreakdown: $showBreakdown, focusedField: $focusedField)
            } else {
                BirthCalculatorView(fullName: $fullName, birthDate: $birthDate, focusedField: $focusedField)
            }

            footer
        }
        .frame(minWidth: 760, idealWidth: 860, maxWidth: 980, minHeight: 560, idealHeight: 700)
        .background(Color(nsColor: .windowBackgroundColor))
        .animation(.easeOut(duration: 0.15), value: mode)
        .onAppear {
            focusedField = .quick
        }
        .onReceive(NotificationCenter.default.publisher(for: .clearNumericaInput)) { _ in
            if mode == .quick {
                quickInput = ""
                focusedField = .quick
            } else {
                fullName = ""
                focusedField = .name
            }
        }
    }

    private var header: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 5) {
                Text("NUMERICA")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .tracking(2.3)
                    .foregroundStyle(.secondary)

                Text(mode.subtitle)
                    .font(.system(size: 15.5, weight: .regular, design: .rounded))
                    .foregroundStyle(.primary)
            }

            Spacer()

            if mode == .quick {
                Button(action: { showBreakdown.toggle() }) {
                    HStack(spacing: 7) {
                        Image(systemName: showBreakdown ? "list.bullet.rectangle" : "rectangle")
                        Text(showBreakdown ? "Hide breakdown" : "Show breakdown")
                    }
                    .font(.system(size: 12, weight: .medium))
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 28)
        .padding(.top, 25)
        .padding(.bottom, 16)
    }

    private var modePicker: some View {
        HStack(spacing: 3) {
            ForEach(CalculatorMode.allCases) { item in
                Button {
                    mode = item
                    focusedField = item == .quick ? .quick : .name
                } label: {
                    Text(item.rawValue)
                        .font(.system(size: 12.5, weight: .semibold, design: .rounded))
                        .foregroundStyle(mode == item ? .primary : .secondary)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 14)
                        .frame(maxWidth: .infinity)
                        .background {
                            Capsule(style: .continuous)
                                .fill(mode == item ? Color.primary.opacity(0.075) : .clear)
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background {
            Capsule(style: .continuous)
                .fill(Color.primary.opacity(0.035))
        }
        .overlay {
            Capsule(style: .continuous)
                .stroke(Color.primary.opacity(0.07), lineWidth: 1)
        }
        .padding(.horizontal, 28)
        .padding(.bottom, 20)
    }

    private var footer: some View {
        HStack {
            Text(mode == .quick ? "Live calculation • digits contribute their face value" : "Date values are shared • name values are shown in both systems")
                .font(.system(size: 10.5, weight: .medium))
                .foregroundStyle(.tertiary)

            Spacer()

            HStack(spacing: 5) {
                Circle()
                    .fill(Color.green)
                    .frame(width: 6, height: 6)
                Text("Instant")
                    .font(.system(size: 10.5, weight: .medium, design: .rounded))
            }
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 28)
        .padding(.top, 18)
        .padding(.bottom, 20)
    }
}

private struct QuickCheckView: View {
    @Binding var input: String
    @Binding var showBreakdown: Bool
    @FocusState.Binding var focusedField: ContentView.Field?

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    TextField("Enter a name, word, phrase, or number…", text: $input, axis: .vertical)
                        .textFieldStyle(.plain)
                        .font(.system(size: 25, weight: .regular, design: .rounded))
                        .lineLimit(1...4)
                        .focused($focusedField, equals: .quick)
                        .padding(.vertical, 15)

                    if !input.isEmpty {
                        Button {
                            input = ""
                            focusedField = .quick
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(.tertiary)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Clear input")
                    }
                }
                .padding(.horizontal, 18)
                .background {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.primary.opacity(0.045))
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.primary.opacity(focusedField == .quick ? 0.18 : 0.08), lineWidth: 1)
                }

                Text("Letters use the selected system; each digit contributes its own value. Spaces and punctuation are ignored.")
                    .font(.system(size: 11.5))
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 3)
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 24)

            Divider()
                .overlay(Color.primary.opacity(0.08))

            VStack(spacing: 18) {
                HStack(spacing: 14) {
                    QuickResultCard(system: .pythagorean, input: input)
                    QuickResultCard(system: .chaldean, input: input)
                }
                .padding(.horizontal, 28)
                .padding(.top, 22)

                if showBreakdown {
                    QuickBreakdownView(input: input)
                        .padding(.horizontal, 28)
                }
            }
        }
    }
}

private struct QuickResultCard: View {
    let system: NumerologySystem
    let input: String

    private var result: NumerologyResult { system.evaluate(input) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(system.rawValue.uppercased())
                    .font(.system(size: 10.5, weight: .semibold, design: .rounded))
                    .tracking(1.5)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(result.count) inputs")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.tertiary)
            }

            Spacer(minLength: 14)

            Text("\(result.total)")
                .font(.system(size: 54, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .contentTransition(.numericText())

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("Total")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.tertiary)
                Text("→")
                    .foregroundStyle(.quaternary)
                Text("\(result.reduced)")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                Text("root")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            }
            .padding(.top, 3)
        }
        .frame(maxWidth: .infinity, minHeight: 154, alignment: .topLeading)
        .padding(22)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.primary.opacity(0.035))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        }
    }
}

private struct QuickBreakdownView: View {
    let input: String

    private var normalizedInput: String {
        input.folding(options: [.diacriticInsensitive, .widthInsensitive], locale: .current).uppercased()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("INPUT BREAKDOWN")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .tracking(1.4)
                    .foregroundStyle(.secondary)
                Spacer()
                if !input.isEmpty {
                    Text("Pythagorean / Chaldean")
                        .font(.system(size: 10.5, weight: .medium))
                        .foregroundStyle(.tertiary)
                }
            }

            if input.isEmpty {
                Text("Letter and digit values will appear here.")
                    .font(.system(size: 12))
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 16)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 7) {
                        ForEach(Array(normalizedInput.enumerated()), id: \.offset) { _, character in
                            let pValue = componentValue(for: character, system: .pythagorean)
                            let cValue = componentValue(for: character, system: .chaldean)

                            if let pValue, let cValue {
                                VStack(spacing: 4) {
                                    Text(String(character))
                                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                                    HStack(spacing: 4) {
                                        Text("\(pValue)")
                                        Text("/")
                                            .foregroundStyle(.quaternary)
                                        Text("\(cValue)")
                                    }
                                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                                    .foregroundStyle(.secondary)
                                }
                                .frame(width: 42, height: 48)
                                .background {
                                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                                        .fill(Color.primary.opacity(0.04))
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private func componentValue(for character: Character, system: NumerologySystem) -> Int? {
        if let value = system.mapping[character] { return value }
        if let digit = character.wholeNumberValue { return digit }
        return nil
    }
}

private struct BirthCalculatorView: View {
    @Binding var fullName: String
    @Binding var birthDate: Date
    @FocusState.Binding var focusedField: ContentView.Field?

    private var profile: BirthProfile {
        NumerologySystem.birthProfile(fullName: fullName, date: birthDate)
    }

    var body: some View {
        VStack(spacing: 0) {
            inputSection
            Divider()
                .overlay(Color.primary.opacity(0.08))

            VStack(spacing: 18) {
                dateCards
                nameCards
            }
            .padding(.horizontal, 28)
            .padding(.top, 22)
        }
    }

    private var inputSection: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(alignment: .leading, spacing: 8) {
                Text("FULL NAME")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .tracking(1.4)
                    .foregroundStyle(.secondary)

                TextField("Enter full name", text: $fullName)
                    .textFieldStyle(.plain)
                    .font(.system(size: 19, weight: .regular, design: .rounded))
                    .focused($focusedField, equals: .name)
                    .padding(.vertical, 11)
                    .padding(.horizontal, 13)
                    .background {
                        RoundedRectangle(cornerRadius: 11, style: .continuous)
                            .fill(Color.primary.opacity(0.045))
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 11, style: .continuous)
                            .stroke(Color.primary.opacity(focusedField == .name ? 0.18 : 0.08), lineWidth: 1)
                    }
            }
            .frame(maxWidth: .infinity)

            VStack(alignment: .leading, spacing: 8) {
                Text("BIRTH DATE")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .tracking(1.4)
                    .foregroundStyle(.secondary)

                DatePicker("", selection: $birthDate, displayedComponents: .date)
                    .labelsHidden()
                    .datePickerStyle(.field)
                    .frame(height: 40)
                    .padding(.horizontal, 9)
                    .background {
                        RoundedRectangle(cornerRadius: 11, style: .continuous)
                            .fill(Color.primary.opacity(0.045))
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 11, style: .continuous)
                            .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                    }
            }
            .frame(width: 230)
        }
        .padding(.horizontal, 28)
        .padding(.bottom, 24)
    }

    private var dateCards: some View {
        HStack(spacing: 14) {
            BirthDateCard(title: "BIRTH CORE", subtitle: "day of month", total: profile.date.birthCoreTotal, reduced: profile.date.birthCoreReduced)
            BirthDateCard(title: "LIFE PATH", subtitle: "full birth date", total: profile.date.lifePathTotal, reduced: profile.date.lifePathReduced)
        }
    }

    private var nameCards: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("NAME NUMBERS")
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .tracking(1.4)
                .foregroundStyle(.secondary)

            HStack(spacing: 14) {
                NameNumberCard(title: "DESTINY", subtitle: "full name", pythagorean: profile.pythagorean.destiny, chaldean: profile.chaldean.destiny)
                NameNumberCard(title: "SOUL URGE", subtitle: "vowels", pythagorean: profile.pythagorean.soulUrge, chaldean: profile.chaldean.soulUrge)
                NameNumberCard(title: "PERSONALITY", subtitle: "consonants", pythagorean: profile.pythagorean.personality, chaldean: profile.chaldean.personality)
            }
        }
    }
}

private struct BirthDateCard: View {
    let title: String
    let subtitle: String
    let total: Int
    let reduced: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(.system(size: 10.5, weight: .semibold, design: .rounded))
                .tracking(1.4)
                .foregroundStyle(.secondary)

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("\(total)")
                    .font(.system(size: 38, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                Text("→ \(reduced)")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }

            Text(subtitle)
                .font(.system(size: 10.5))
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.primary.opacity(0.035))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        }
    }
}

private struct NameNumberCard: View {
    let title: String
    let subtitle: String
    let pythagorean: NumerologyResult
    let chaldean: NumerologyResult

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 10.5, weight: .semibold, design: .rounded))
                    .tracking(1.3)
                Text(subtitle)
                    .font(.system(size: 10.5))
                    .foregroundStyle(.tertiary)
            }

            SystemValueLine(label: "Pythagorean", result: pythagorean)
            SystemValueLine(label: "Chaldean", result: chaldean)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(17)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.primary.opacity(0.035))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        }
    }
}

private struct SystemValueLine: View {
    let label: String
    let result: NumerologyResult

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .font(.system(size: 10.5, weight: .medium))
                .foregroundStyle(.secondary)
            Spacer()
            Text("\(result.total)")
                .font(.system(size: 23, weight: .semibold, design: .rounded))
                .monospacedDigit()
            Text("→ \(result.reduced)")
                .font(.system(size: 10.5, weight: .medium, design: .monospaced))
                .foregroundStyle(.tertiary)
        }
    }
}
