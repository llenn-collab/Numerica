# Numerica Swift Audit

Scope: every Swift file (`Numerica/*.swift`, `NumericaTests/*.swift`) plus `Numerica.xcodeproj` build settings, checked against `SKILLS/swift_audit.md`.

Every finding marked Fixed is already applied on this branch.

## Summary

Small project. Model, SwiftUI views, and design tokens sit in separate files. Numerology rules live in one place.

The app did not compile. Quick Check called a `SystemPanel` view with no declaration. One unit test expected a total the documented rules do not produce.

Both are fixed. Performance, accessibility, and style issues below are fixed too.

## Findings

### Critical

**1. `SystemPanel` is referenced but never declared. Hard compile error.**

- File and line: `Numerica/ContentView.swift:240` and `:242`
  (`SystemPanel(system: .pythagorean, input: input)` / `.chaldean`)
- Category: Build / §3 Swift Patterns
- Issue: No type named `SystemPanel` existed in the project. The compiler reports `cannot find 'SystemPanel' in scope`. The app does not build.
- Fix (Fixed): added `private struct SystemPanel: View` at `Numerica/ContentView.swift:294`. Call sites stay as written. The panel draws the 2pt accent border (`system.accent`), the system name in the text-safe accent token (`system.textAccent`), the live total with `.contentTransition(.numericText())` and the damped spring, the `→ reduced` root, and a caption. Empty input reads "Enter text or digits" instead of a bare `0`. Punctuation-only input reads "No letters or digits found". VoiceOver gets a label and value. Metrics match `StatPanel`. No `project.pbxproj` change.

**2. A unit test contradicted the documented calculation rule.**

- File and line: old `NumericaTests/NumericaTests.swift:24-27` (`testDigitsAreCalculated`)
- Category: §6 Testing
- Issue: asserted `evaluate("A23").total == 8`. README and `NumerologySystem.evaluate` both treat digits as face value (`23` contributes `2 + 3`), so `A23 = 1 + 2 + 3 = 6`. The test was guaranteed to fail. Neighbour `testBirthDestinyCanIncludeDigits` already used `A2 == 3`.
- Fix (Fixed): suite rewritten. Expectation is `6`, with a comment on the rule. Every expected value was re-derived.

### Important

**3. Letter tables were rebuilt on every character lookup.**

- File and line: `Numerica/Numerology.swift:17` (pre-fix `mapping`)
- Category: §4 Build Performance
- Issue: `mapping` allocated a fresh 26-entry dictionary on each access. `evaluate` and `birthName` hit the table once per character, several times per keystroke.
- Fix (Fixed): tables are `private static let pythagoreanTable` / `chaldeanTable` (`Numerica/Numerology.swift:74`, `:80`). Each calculation reads the table once into a local.

**4. `FlowLayout.sizeThatFits` returned an infinite width when SwiftUI proposed no width.**

- File and line: `Numerica/ContentView.swift:656` (pre-fix body)
- Category: §4 Build Performance / §3 Swift Patterns
- Issue: `CGSize(width: proposal.width ?? .infinity, height: …)` returns a non-finite size when SwiftUI proposes `nil` width. Invalid for a window sized exactly to content.
- Fix (Fixed): layout tracks the widest measured row and falls back to `width: proposal.width ?? widestRow`. Never returns infinity.

**5. `StatPanel.reduced` was stored but never read.**

- File and line: `Numerica/ContentView.swift:474` (struct), call sites `:433`, `:437`
- Category: §3 Swift Patterns / §2 Code Style
- Issue: `reduced` was passed at both call sites and used nowhere. The caption already carried the same arithmetic.
- Fix (Fixed): parameter removed from the struct and both call sites. Captions unchanged.

**6. Screen-reader coverage was missing where meaning is numeric.**

- File and line: `Numerica/ContentView.swift:355` (`LetterCell`), `:526` (`DualStat`), Quick Check grid (`:240`-`:243`)
- Category: §7 Documentation/Accessibility (`SKILLS/apple_design.md` §14)
- Issue: `LetterCell` announced "A, 1, 1" with no system names. `DualStat` announced two bare numbers for Destiny / Soul Urge / Personality, so Pythagorean vs Chaldean was colour only.
- Fix (Fixed): each `LetterCell` exposes the character plus "Pythagorean n, Chaldean m". `DualStat` and `SystemPanel` expose the system name as the label and "total, root n" as the value.

**7. Birth profile was recalculated on every read.**

- File and line: `Numerica/ContentView.swift:399` (`BirthCalculatorView`)
- Category: §4 Build Performance
- Issue: `profile` was a computed property read eight times in `body`. Each read re-evaluated the full name in both systems.
- Fix (Fixed): profile, birth day, and both captions are computed once per render as local constants.

**8. Style pass: line length, declarations per line, duplicated normalization.**

- File and line: `Numerica/ContentView.swift:658` (`var x, y, rowHeight`), `:273` (`ForEach(Array(normalizedInput.enumerated())…)`), plus ten lines over 100 columns across `ContentView.swift` / `Numerology.swift`
- Category: §2 Code Style
- Issue: 100-column limit exceeded. Multiple variables shared one `let`/`var`. `QuickCheckView` re-implemented the model's normalization policy.
- Fix (Fixed): all lines are ≤ 100 columns. Long string literals split by concatenation. Copies moved into `footerNote` / `birthCoreCaption` / `lifePathCaption`. One declaration per statement. `normalized` is a single shared policy (`Numerology.swift:59`) used by the model, the view, and `LetterCell`. `LetterCell` uses `digitValue(of:)` so the grid cannot disagree with the sum.

### Suggestions

9. **`NumerologyResult.components` is a tuple array** (`Numerology.swift:8`). Labeled tuples cannot carry protocol conformances, so the result type cannot be `Equatable` / `Hashable`. A small `struct Component { let character; let value }` would make the model comparable for snapshot tests or diffs.

10. **`onChange(of:perform:)`** (`ContentView.swift:207`) is deprecated as of macOS 14. Warning-free against the current macOS 13 target. Migrate to `onChange(of:) { old, new in }` when the deployment target moves.

11. **`FlowLayout` has no `Cache`** (`ContentView.swift:656`). Both layout passes call `sizeThatFits(.unspecified)` per subview. Fine at the 60-character cap. Add a cache if the grid grows.

12. **No UI tests and no `#Preview`s.** The zero-scroll rule, the fixed 880×700 window, and the results grid have no automated check. A UI test typing 60 characters and asserting the window does not scroll would lock the rule in.

13. **Model members are mostly undocumented** (`Numerology.swift:93-105`: `BirthDateResult`, `BirthNameResult`, `BirthProfile` fields). Two rules worth stating: digit root of `0` is `0`, and Chaldean never assigns `9`.

## What holds up

- One calculation core. Folding, digits, roots, vowel and consonant splits all live in a Foundation-only `NumerologySystem`. Views only render. The model is independently testable.
- Design tokens are systematic. `Theme.swift` holds the palette, size-specific tracking, monospaced digits, hairline structure, and explicit `colorSchemeContrast` / `accessibilityReduceMotion` branches. Views rarely invent values.
- The no-scroll rule is structural: content-sized window, 60-character input cap, `FlowLayout` instead of `ScrollView`, empty state instead of a bare zero.
- Model tests cover case, width and diacritic folding, the digit rule, the vowel/consonant split, both systems, and date math. After this pass they agree with the documented rules.

## Verification notes

- No Swift toolchain in this environment (Linux sandbox; `swift` / `xcodebuild` unavailable). Nothing here was machine-compiled. Check was a full static read of every file, an undefined-symbol scan of all types, `Theme` and `NumerologySystem` members, and a line-length / whitespace scan.
- Every numeric expectation in the rewritten tests was re-derived independently (Python port of the tables and rules), including `A23 = 6`, `À`-style folding, `F = 6/8`, `JOHN DOE = 35/17/18` (Pythagorean) and `34/19/15` (Chaldean), and `14 Feb 1995 → 14 → 5`, life path `31 → 4`.
- Confirm on a Mac with `xcodebuild test -project Numerica.xcodeproj -scheme Numerica` (or `⌘U` in Xcode 15+). This environment cannot run the suite.
