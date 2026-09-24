# Numerica

Native SwiftUI numerology calculator for macOS.

Two modes share one fixed window. The window sizes to content. Nothing scrolls.

## Quick Check

Type any text. Totals update as you type. Letters and digits both count.

- Pythagorean letter values
- Chaldean letter values
- Each decimal digit adds face value. Example: `23` adds `2 + 3`
- Spaces and punctuation are ignored
- Single-digit root sits next to the total
- Letter and digit breakdown
- Input stops at 60 characters so the window stays content-sized

Clear the field with **Clear Input** (`⌘K`).

## Birth Calculator

Full name plus birth date. Kept apart from the free-text checker.

- Birth Core: day of the month
- Life Path: sum of all birth-date digits
- Destiny: full name
- Soul Urge: vowels in the full name
- Personality: consonants in the full name
- Date numbers are shared. Name numbers show Pythagorean and Chaldean side by side.

## Build on a Mac

1. Open `Numerica.xcodeproj` in Xcode 15 or later.
2. Select the `Numerica` macOS target.
3. Choose **My Mac** as the run destination.
4. Press **Run** (`⌘R`).

Needs macOS 13 or later.

## Tests

In Xcode, press `⌘U`. Or:

```
xcodebuild test -project Numerica.xcodeproj -scheme Numerica
```

## License

MIT. See `LICENSE`.
