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
    @State private var birthDate = ContentView.defaultBirthDate
    @State private var showBreakdown = true
    @FocusState private var focusedField: Field?
    @Namespace private var segmentNamespace
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    fileprivate enum Field: Hashable {
        case quick
        case name
    }

    /// Opens on a plausible adult birth date instead of today.
    private static var defaultBirthDate: Date {
        Calendar.current.date(byAdding: .year, value: -25, to: Date()) ?? Date()
    }

    /// Spec §14: reduced motion falls back to a short opacity-only cross-fade.
    private var animation: Animation {
        reduceMotion ? .easeOut(duration: 0.2) : Theme.spring
    }

    var body: some View {
        ZStack(alignment: .top) {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                modePicker

                // Spec §7: both modes share one geometry; mode change is a
                // same-place cross-fade, never a positional slide.
                ZStack(alignment: .top) {
                    QuickCheckView(input: $quickInput, showBreakdown: $showBreakdown,
                                   focusedField: $focusedField, animation: animation)
                        .opacity(mode == .quick ? 1 : 0)
                        .allowsHitTesting(mode == .quick)
                    BirthCalculatorView(fullName: $fullName, birthDate: $birthDate,
                                        focusedField: $focusedField)
                        .opacity(mode == .birth ? 1 : 0)
                        .allowsHitTesting(mode == .birth)
                }
                .frame(maxHeight: .infinity)

                footer
            }
        }
        // Viewport sized exactly to content — no scroll view anywhere (hard rule).
        .frame(width: Theme.windowWidth, height: Theme.windowHeight)
        .animation(animation, value: mode)
        .onAppear { focusedField = .quick }
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
        HStack(alignment: .lastTextBaseline) {
            VStack(alignment: .leading, spacing: 6) {
                // Spec §15: sans display type, negative tracking, tight leading.
                Text("Numerica")
                    .font(.system(size: 34, weight: .semibold))
                    .tracking(-0.68)
                Text(mode.subtitle)
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.muted)
            }

            Spacer()

            if mode == .quick {
                Button(action: { showBreakdown.toggle() }) {
                    Text(showBreakdown ? "Hide breakdown" : "Show breakdown")
                        .font(.system(size: 12, weight: .medium))
                        .tracking(0.3)
                        .foregroundStyle(Theme.muted)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                        .background { CapsuleHairline() }
                }
                .buttonStyle(PressButtonStyle())
            }
        }
        .padding(.horizontal, 28)
        .padding(.top, 32) // clears the hidden-title-bar traffic lights
        .padding(.bottom, 14)
    }

    private var modePicker: some View {
        HStack(spacing: 0) {
            ForEach(CalculatorMode.allCases) { item in
                Button {
                    mode = item
                    focusedField = item == .quick ? .quick : .name
                } label: {
                    Text(item.rawValue)
                        .font(.system(size: 13, weight: .semibold))
                        .tracking(0.3)
                        .foregroundStyle(mode == item ? Theme.background : Theme.muted)
                        .padding(.vertical, 7)
                        .frame(maxWidth: .infinity)
                        .background {
                            if mode == item {
                                Capsule(style: .continuous)
                                    .fill(Theme.ink)
                                    .matchedGeometryEffect(id: "segment", in: segmentNamespace)
                            }
                        }
                        .contentShape(Capsule(style: .continuous))
                }
                .buttonStyle(PressButtonStyle())
            }
        }
        .padding(3)
        .background { CapsuleHairline() }
        .padding(.horizontal, 28)
        .padding(.bottom, 18)
    }

    /// Plain-language framing for whichever mode is showing.
    private var footerNote: String {
        mode == .quick
            ? "Live calculation. Digits contribute their face value; "
                + "spaces and punctuation are ignored."
            : "Date values are shared. Name values are shown in both systems."
    }

    private var footer: some View {
        VStack(spacing: 0) {
            Hairline()
            HStack {
                Text(footerNote)
                    .font(.system(size: 10.5, weight: .medium))
                    .tracking(0.3)
                    .foregroundStyle(Theme.muted)
                Spacer()
            }
            .padding(.horizontal, 28)
            .padding(.top, 12)
            .padding(.bottom, 16)
        }
    }
}

// MARK: - Quick Check

private struct QuickCheckView: View {
    @Binding var input: String
    @Binding var showBreakdown: Bool
    @FocusState.Binding var focusedField: ContentView.Field?
    var animation: Animation
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Hard cap so wrapped content can never exceed the fixed window (zero-scroll rule).
    private let maxInputLength = 60

    private var normalizedInput: String {
        // One normalization policy shared with the calculator, so what the grid
        // shows always matches what it summed.
        NumerologySystem.normalized(input)
    }

    /// Character positions double as stable identities for the grid.
    private var characters: [(offset: Int, element: Character)] {
        Array(normalizedInput.enumerated())
    }

    var body: some View {
        VStack(spacing: 0) {
            // Reference-style underline field: transparent, hairline bottom rule.
            VStack(spacing: 7) {
                HStack(alignment: .bottom, spacing: 12) {
                    TextField("Enter a name, word, phrase, or number…",
                              text: $input,
                              axis: .vertical)
                        .textFieldStyle(.plain)
                        .font(.system(size: 24))
                        .lineLimit(1...3)
                        .focused($focusedField, equals: .quick)
                        .onChange(of: input) { newValue in
                            if newValue.count > maxInputLength {
                                input = String(newValue.prefix(maxInputLength))
                            }
                        }

                    if !input.isEmpty {
                        Button { input = ""; focusedField = .quick } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(Theme.muted)
                        }
                        .buttonStyle(PressButtonStyle())
                        .accessibilityLabel("Clear input")
                        .padding(.bottom, 5)
                    }
                }
                FieldRule(focused: focusedField == .quick)
            }
            .padding(.horizontal, 28)

            Text("Letters use both systems; each digit contributes its own value.")
                .font(.system(size: 11))
                .tracking(0.3)
                .foregroundStyle(Theme.muted)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 28)
                .padding(.top, 8)

            // Reference hairline-ruled results grid with 2pt accent borders.
            VStack(spacing: 0) {
                Hairline()
                HStack(spacing: 0) {
                    SystemPanel(system: .pythagorean, input: input)
                    Hairline(vertical: true)
                    SystemPanel(system: .chaldean, input: input)
                }
                .fixedSize(horizontal: false, vertical: true)
                Hairline()
            }
            .padding(.top, 20)

            if showBreakdown {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Input breakdown")
                            .font(.system(size: 12))
                            .tracking(0.3)
                            .foregroundStyle(Theme.muted)
                        Spacer()
                        if !input.isEmpty {
                            Text("Pythagorean / Chaldean")
                                .font(.system(size: 10.5))
                                .tracking(0.3)
                                .foregroundStyle(Theme.muted.opacity(0.75))
                        }
                    }

                    if input.isEmpty {
                        Text("Letter and digit values will appear here.")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.muted)
                            .padding(.vertical, 8)
                    } else {
                        // Wraps in place — ScrollView removed per hard rule.
                        FlowLayout(hSpacing: 10, vSpacing: 12) {
                            ForEach(characters, id: \.offset) { _, character in
                                LetterCell(character: character)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 28)
                .padding(.top, 18)
                .transition(.opacity)
            }

            Spacer(minLength: 12)
        }
        .animation(animation, value: showBreakdown)
        .animation(reduceMotion ? nil : Theme.spring, value: input)
    }
}

/// One system's live readout in the Quick Check grid: a 2pt accent border,
/// the running total, its single-digit root, and how many characters counted.
private struct SystemPanel: View {
    let system: NumerologySystem
    let input: String
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let result = system.evaluate(input)
        let hasValues = result.count > 0

        VStack(spacing: 0) {
            Rectangle()
                .fill(system.accent)
                .frame(height: 2)

            VStack(alignment: .leading, spacing: 5) {
                Text(system.rawValue)
                    .font(.system(size: 12))
                    .tracking(0.3)
                    .foregroundStyle(system.textAccent)

                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text(hasValues ? "\(result.total)" : "—")
                        .font(.system(size: 38, weight: .semibold))
                        .tracking(-0.76)
                        .monospacedDigit()
                        .foregroundStyle(system.accent)
                        .contentTransition(.numericText())
                        .animation(reduceMotion ? nil : Theme.spring, value: result.total)

                    if hasValues {
                        Text("→ \(result.reduced)")
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundStyle(Theme.muted)
                    }
                }

                Text(caption(for: result))
                    .font(.system(size: 10.5))
                    .tracking(0.3)
                    .foregroundStyle(Theme.muted)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(system.rawValue))
        .accessibilityValue(Text(hasValues
                                 ? "\(result.total), root \(result.reduced)"
                                 : "No values"))
    }

    /// Empty and non-matching input read as guidance, never as a bare zero.
    private func caption(for result: NumerologyResult) -> String {
        guard result.count == 0 else {
            return result.count == 1 ? "1 character counted" : "\(result.count) characters counted"
        }
        return input.isEmpty ? "Enter text or digits" : "No letters or digits found"
    }
}

private struct LetterCell: View {
    let character: Character

    private func value(_ system: NumerologySystem) -> Int? {
        if let v = system.mapping[character] { return v }
        return NumerologySystem.digitValue(of: character)
    }

    var body: some View {
        if let p = value(.pythagorean), let c = value(.chaldean) {
            VStack(spacing: 2) {
                Text(String(character))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                Text("\(p)")
                    .foregroundStyle(Theme.brassText)
                Text("\(c)")
                    .foregroundStyle(Theme.verdigrisText)
            }
            .font(.system(size: 10, weight: .medium, design: .monospaced))
            .frame(minWidth: 26)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(String(character)))
            .accessibilityValue(Text("Pythagorean \(p), Chaldean \(c)"))
        } else {
            // Spaces and punctuation participate in nothing — dimmed glyph.
            Text(character.isWhitespace ? "·" : String(character))
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Theme.muted.opacity(0.5))
                .frame(width: 26, height: 44)
                .accessibilityLabel(Text(character.isWhitespace ? "space" : String(character)))
        }
    }
}

// MARK: - Birth Calculator

private struct BirthCalculatorView: View {
    @Binding var fullName: String
    @Binding var birthDate: Date
    @FocusState.Binding var focusedField: ContentView.Field?

    var body: some View {
        // Derived once per render rather than on every panel and row that reads it.
        let profile = NumerologySystem.birthProfile(fullName: fullName, date: birthDate)
        let birthDay = Calendar.current.component(.day, from: birthDate)
        // Captions state the arithmetic behind each panel's headline number.
        let birthCoreCaption = "day \(birthDay) → \(profile.date.birthCoreReduced)"
        let lifePathCaption =
            "\(profile.date.lifePathTotal) reduces to \(profile.date.lifePathReduced)"

        VStack(spacing: 0) {
            HStack(alignment: .bottom, spacing: 24) {
                VStack(alignment: .leading, spacing: 7) {
                    FieldLabel("Full name")
                    TextField("Enter full name", text: $fullName)
                        .textFieldStyle(.plain)
                        .font(.system(size: 20))
                        .focused($focusedField, equals: .name)
                    FieldRule(focused: focusedField == .name)
                }
                .frame(maxWidth: .infinity)

                VStack(alignment: .leading, spacing: 7) {
                    FieldLabel("Birth date")
                    DatePicker("", selection: $birthDate, displayedComponents: .date)
                        .labelsHidden()
                        .datePickerStyle(.field)
                    FieldRule(focused: false) // DatePicker renders its own focus ring
                }
                .frame(width: 220)
            }
            .padding(.horizontal, 28)

            GroupSection(title: "From your birth date") {
                VStack(spacing: 0) {
                    Hairline()
                    HStack(spacing: 0) {
                        StatPanel(label: "Birth core",
                                  total: profile.date.birthCoreTotal,
                                  caption: birthCoreCaption)
                        Hairline(vertical: true)
                        StatPanel(label: "Life path",
                                  total: profile.date.lifePathTotal,
                                  caption: lifePathCaption)
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    Hairline()
                }
                .padding(.top, 4)
            }

            GroupSection(title: "From your name") {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 16) {
                        LegendDot(color: Theme.brass, label: "Pythagorean")
                        LegendDot(color: Theme.verdigris, label: "Chaldean")
                    }
                    .padding(.bottom, 12)

                    Hairline()
                    NameRow(title: "Destiny", pythagorean: profile.pythagorean.destiny,
                            chaldean: profile.chaldean.destiny)
                    Hairline()
                    NameRow(title: "Soul urge", pythagorean: profile.pythagorean.soulUrge,
                            chaldean: profile.chaldean.soulUrge)
                    Hairline()
                    NameRow(title: "Personality", pythagorean: profile.pythagorean.personality,
                            chaldean: profile.chaldean.personality)
                    Hairline()
                }
                .padding(.top, 4)
            }

            Spacer(minLength: 12)
        }
    }
}

private struct StatPanel: View {
    let label: String
    let total: Int
    let caption: String
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label)
                .font(.system(size: 12))
                .tracking(0.3)
                .foregroundStyle(Theme.muted)
            Text("\(total)")
                .font(.system(size: 38, weight: .semibold))
                .tracking(-0.76)
                .monospacedDigit()
                .foregroundStyle(Theme.ink)
                .contentTransition(.numericText())
                .animation(reduceMotion ? nil : Theme.spring, value: total)
            Text(caption)
                .font(.system(size: 10.5))
                .tracking(0.3)
                .foregroundStyle(Theme.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
    }
}

private struct NameRow: View {
    let title: String
    let pythagorean: NumerologyResult
    let chaldean: NumerologyResult

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 12.5))
                .tracking(0.3)
                .foregroundStyle(Theme.muted)
                .frame(width: 120, alignment: .leading)

            DualStat(result: pythagorean, system: .pythagorean)
            Spacer()
            DualStat(result: chaldean, system: .chaldean)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
    }
}

private struct DualStat: View {
    let result: NumerologyResult
    let system: NumerologySystem
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text("\(result.total)")
                .font(.system(size: 24, weight: .semibold))
                .tracking(-0.48)
                .monospacedDigit()
                .foregroundStyle(system.accent)
                .contentTransition(.numericText())
                .animation(reduceMotion ? nil : Theme.spring, value: result.total)
            Text("→ \(result.reduced)")
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(Theme.muted)
        }
        .frame(minWidth: 120, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(system.rawValue))
        .accessibilityValue(Text("\(result.total), root \(result.reduced)"))
    }
}

// MARK: - Shared components

/// Press feedback on pointer-down, instant — spec §1. No fixed-duration
/// transitions; release settles on a critically damped spring (§4).
private struct PressButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.65 : 1)
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.97 : 1)
            .animation(reduceMotion ? nil : Theme.press, value: configuration.isPressed)
    }
}

/// 1px rule; opacity rises under prefers-contrast: more (spec §14).
private struct Hairline: View {
    var vertical = false
    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        Rectangle()
            .fill(contrast == .increased ? Theme.hairlineStrong : Theme.hairline)
            .frame(width: vertical ? 1 : nil, height: vertical ? nil : 1)
    }
}

private struct CapsuleHairline: View {
    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        Capsule(style: .continuous)
            .stroke(contrast == .increased ? Theme.hairlineStrong : Theme.hairline, lineWidth: 1)
    }
}

/// Underline focus indicator for text fields — brass rule doubles in weight
/// on focus, mirroring the reference and giving a visible keyboard focus cue.
private struct FieldRule: View {
    let focused: Bool
    @Environment(\.colorSchemeContrast) private var contrast

    private var ruleColor: Color {
        guard !focused else { return Theme.brass }
        return contrast == .increased ? Theme.hairlineStrong : Theme.hairline
    }

    var body: some View {
        Rectangle()
            .fill(ruleColor)
            .frame(height: focused ? 2 : 1)
    }
}

private struct FieldLabel: View {
    let text: String

    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .medium))
            .tracking(0.3)
            .foregroundStyle(Theme.muted)
    }
}

private struct LegendDot: View {
    let color: Color
    let label: String

    var body: some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label)
                .font(.system(size: 10.5))
                .tracking(0.3)
                .foregroundStyle(Theme.muted)
        }
    }
}

private struct GroupSection<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 12))
                .tracking(0.3)
                .foregroundStyle(Theme.muted)
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 28)
        .padding(.top, 22)
    }
}

/// Wrapping layout — replaces the removed horizontal ScrollView.
private struct FlowLayout: Layout {
    var hSpacing: CGFloat = 8
    var vSpacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var widestRow: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0, x + size.width > maxWidth {
                widestRow = max(widestRow, x - hSpacing)
                x = 0
                y += rowHeight + vSpacing
                rowHeight = 0
            }
            rowHeight = max(rowHeight, size.height)
            x += size.width + hSpacing
        }
        widestRow = max(widestRow, x - hSpacing)

        // Never return an infinite width: fall back to the measured content.
        return CGSize(width: proposal.width ?? widestRow, height: y + rowHeight)
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > bounds.minX, x + size.width > bounds.maxX {
                x = bounds.minX
                y += rowHeight + vSpacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y),
                          anchor: .topLeading,
                          proposal: ProposedViewSize(size))
            rowHeight = max(rowHeight, size.height)
            x += size.width + hSpacing
        }
    }
}
