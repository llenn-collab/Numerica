# Numerica — macOS

A native SwiftUI macOS numerology calculator with two modes:

## Quick Check

Designed for rapid, live checks of arbitrary text. Both letters and numbers are included:

- Pythagorean letter values
- Chaldean letter values
- Each decimal digit contributes its face value (for example, `23` contributes `2 + 3`)
- Spaces and punctuation are ignored
- Single-digit root shown alongside the total
- Letter/digit-by-digit breakdown

## Birth Calculator

Designed for a proper name + birth-date calculation, kept separate from the fast arbitrary-input checker.

- Birth Core — birth day of month
- Life Path — sum of all birth-date digits
- Destiny — full name
- Soul Urge — vowels in the full name
- Personality — consonants in the full name
- Date-derived values are shared; name-derived values are shown in both Pythagorean and Chaldean systems

## Build on a Mac

1. Open `Numerica.xcodeproj` in Xcode 15 or later.
2. Select the `Numerica` macOS target.
3. Choose **My Mac** as the run destination.
4. Press **Run (⌘R)**.

The project targets macOS 13+.
