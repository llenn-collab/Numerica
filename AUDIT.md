# Numerica — Swift Audit

Scope: every Swift file in the project (`Numerica/*.swift`, `NumericaTests/*.swift`, plus
`Numerica.xcodeproj` build settings), reviewed against `SKILLS/swift_audit.md`.
Every finding marked **Fixed** is already applied on this branch.

## Summary

The project is small, well separated (pure model + SwiftUI views + design tokens), and the
numerology rules live in exactly one place — but it did not compile: the Quick Check results
grid referenced a `SystemPanel` view that was never declared, and one unit test asserted a
result the documented rules cannot produce. Both are fixed, along with the performance,
accessibility, and style issues listed below.

## Findings

### Critical

**1. `SystemPanel` is referenced but never declared — hard compile error**
- **File and line**: `Numerica/ContentView.swift:240` and `:242`
  (`SystemPanel(system: .pythagorean, input: input)` / `.chaldean`)
- **Category**: Build / §3 Swift Patterns (an identifier in view position with no declaration)
- **Issue**: Nothing in the project declared a type named `SystemPanel` (`grep -rn "struct SystemPanel"` returned
  no definition — the type had only these two call sites). The compiler reports
  `cannot find 'SystemPanel' in scope` for the snippet you posted, and the app cannot build.
- **Fix (Fixed)**: implemented `private struct SystemPanel: View` at `Numerica/ContentView.swift:294`,
  keeping the snippet exactly as written. It renders the 2pt accent border the code comment
  promises (`system.accent`), the system name in the text-safe accent token
  (`system.textAccent`), the live total with `.contentTransition(.numericText())` and the
  damped spring, the `→ reduced` root, and a caption. Empty input reads "Enter text or digits"
  instead of a bare `0`, punctuation-only input reads "No letters or digits found", and the
  panel exposes a VoiceOver label/value. It uses the same metrics as `StatPanel` so both modes
  share one visual system, and — because it lives in an existing target file — **no
  `project.pbxproj` change is needed**.

**2. A unit test contradicted the documented calculation rule**
- **File and line**: old `NumericaTests/NumericaTests.swift:24-27` (`testDigitsAreCalculated`)
- **Category**: §6 Testing
- **Issue**: it asserted `evaluate("A23").total == 8`. The README and `NumerologySystem.evaluate`
  both define digits as contributing their face value ("23" contributes `2 + 3`), so
  `A23 = 1 + 2 + 3 = 6`. The test was guaranteed to fail on the simulator, and it also
  contradicted the neighbouring `testBirthDestinyCanIncludeDigits` (`A2 == 3`).
- **Fix (Fixed)**: the suite was rewritten (see also finding 6) with the expectation corrected to
  `6` and a comment citing the rule, plus independent re-derivation of every expected value.

### Important

**3. The letter tables were rebuilt on every character lookup**
- **File and line**: `Numerica/Numerology.swift:17` (pre-fix `mapping`)
- **Category**: §4 Build Performance
- **Issue**: `mapping` returned a freshly allocated 26-entry dictionary literal on each access,
  and `evaluate`/`birthName` access it once **per character**, several times per keystroke.
- **Fix (Fixed)**: the tables are now `private static let pythagoreanTable` / `chaldeanTable`
  (`Numerica/Numerology.swift:74`, `:80`); each calculation reads the table once into a local.

**4. `FlowLayout.sizeThatFits` could return an infinite width**
- **File and line**: `Numerica/ContentView.swift:656` (pre-fix body)
- **Category**: §4 Build Performance / §3 Swift Patterns
- **Issue**: `CGSize(width: proposal.width ?? .infinity, height: …)` returns a non-finite size when
  SwiftUI proposes `nil` width — an invalid proposal result that can destabilise the parent
  layout of a window whose whole contract is "sized exactly to content, never scrolls".
- **Fix (Fixed)**: the layout now tracks the widest measured row and falls back to it
  (`width: proposal.width ?? widestRow`), and never returns infinity.

**5. `StatPanel.reduced` was stored but never read**
- **File and line**: `Numerica/ContentView.swift:474` (struct), call sites `:433`, `:437`
- **Category**: §3 Swift Patterns (dead state) / §2 Code Style
- **Issue**: the `reduced` property was passed at both call sites and used nowhere — the caption
  already carried the same arithmetic, so the parameter was pure duplication.
- **Fix (Fixed)**: parameter removed from the struct and from both call sites; captions unchanged.

**6. Screen-reader coverage was missing exactly where the app's meaning is numeric**
- **File and line**: `Numerica/ContentView.swift:355` (`LetterCell`), `:526` (`DualStat`),
  Quick Check grid (`:240`-`:243`)
- **Category**: §7 Documentation/Accessibility (see `SKILLS/apple_design.md` §14)
- **Issue**: `LetterCell` announced "A, 1, 1" with no system names; `DualStat` announced two bare
  numbers separated by an arrow for Destiny/Soul Urge/Personality, so the Pythagorean-vs-Chaldean
  distinction was carried by colour alone.
- **Fix (Fixed)**: each `LetterCell` now exposes the character plus "Pythagorean n, Chaldean m";
  `DualStat` and the new `SystemPanel` expose the system name as the label and "total, root n"
  as the value.

**7. The birth profile was recalculated on every read**
- **File and line**: `Numerica/ContentView.swift:399` (`BirthCalculatorView`)
- **Category**: §4 Build Performance
- **Issue**: `profile` was a computed property read eight times in `body`; each read re-evaluated
  the full name in both systems.
- **Fix (Fixed)**: the profile, birth day, and both captions are computed once per render as
  local constants.

**8. Style pass: line length, declarations per line, duplicated normalization**
- **File and line**: `Numerica/ContentView.swift:658` (`var x, y, rowHeight`), `:273`
  (`ForEach(Array(normalizedInput.enumerated())…)`), plus ten lines over 100 columns across
  `ContentView.swift` / `Numerology.swift`
- **Category**: §2 Code Style
- **Issue**: the 100-column limit was exceeded (two long string literals and one wrapped
  protocol signature among them), multiple variables shared one `let`/`var`, and
  `QuickCheckView` re-implemented the model's normalization policy.
- **Fix (Fixed)**: all lines are ≤ 100 columns (verified by scan) with long string literals split
  by concatenation and copies moved into `footerNote`/`birthCoreCaption`/`lifePathCaption`;
  one declaration per statement (`FlowLayout`, `placeSubviews`); `normalized` is now a single
  shared policy (`Numerology.swift:59`) used by the model, the view, and `LetterCell`, which
  also replaces its ad-hoc `wholeNumberValue` check with `digitValue(of:)` so the grid's display
  can never disagree with what was summed.

### Suggestions

9. **`NumerologyResult.components` is a tuple array** (`Numerology.swift:8`) — labeled tuples
   cannot carry protocol conformances, so the result type cannot be `Equatable`/`Hashable` and
   key paths can't address the elements. A three-line `struct Component { let character; let value }`
   would make the model comparable if you ever snapshot-test or diff results.
10. **`onChange(of:perform:)`** (`ContentView.swift:207`) is deprecated as of macOS 14. It is
    warning-free against the current macOS 13 target, but migrate to `onChange(of:) { old, new in }`
    when the deployment target moves (then wrap the two cases in `if #available` or raise the target).
11. **`FlowLayout` has no `Cache`** (`ContentView.swift:656`): both layout passes call
    `sizeThatFits(.unspecified)` per subview. Irrelevant at the 60-character cap; consider a cache
    if the grid ever grows.
12. **No UI tests and no `#Preview`s** — the "zero scroll" rule, the fixed 880×700 window, and the
    new results grid are contractual behaviour with no automated check. A UI test that types 60
    characters and asserts the window does not scroll would lock the rule in.
13. **Model members are mostly undocumented** (`Numerology.swift:93-105`: `BirthDateResult`,
    `BirthNameResult`, `BirthProfile` fields). The rules worth stating are non-obvious: digit root
    of `0` is `0`, and Chaldean never assigns `9`.

## What's Done Well

- **One calculation core, zero duplication.** All numerology — folding, digits, roots,
  vowel/consonant splitting — lives in a Foundation-only `NumerologySystem`; the views only
  render. That separation is why the broken build was a one-line structural mistake rather than a
  logic bug, and it made the model independently verifiable.
- **The design tokens are genuinely systematic.** `Theme.swift` encodes an intentional palette,
  size-specific tracking, monospaced digits, hairline structure instead of shadows, and explicit
  `colorSchemeContrast` / `accessibilityReduceMotion` branches — the views rarely invent values.
- **The "no scrolling" rule is enforced structurally**, not hoped for: a content-sized window,
  a 60-character input cap, `FlowLayout` replacing the removed `ScrollView`, and an empty state
  that guides instead of showing a bare zero.
- **The model tests are broad and readable** — case, width and diacritic folding, the digit rule,
  the vowel/consonant split, both systems, and the date math — and after this pass they agree with
  the documented rules.

## Verification Notes

- No Swift toolchain exists in this environment (Linux sandbox; `swift`/`xcodebuild` unavailable),
  so nothing here was machine-compiled. Verification was: full static read of every file, an
  automated undefined-symbol scan of all types, `Theme` and `NumerologySystem` members, and a
  line-length/whitespace scan.
- Every numeric expectation in the rewritten tests was re-derived independently (Python port of the
  tables and rules), including `A23 = 6`, `À`-style folding, `F = 6/8`, `JOHN DOE = 35/17/18`
  (Pythagorean) and `34/19/15` (Chaldean), and `14 Feb 1995 → 14 → 5`, life path `31 → 4`.
- Please confirm on a Mac with `xcodebuild test -project Numerica.xcodeproj -scheme Numerica`
  (or ⌘U in Xcode 15+); that is the one check this environment cannot perform.
