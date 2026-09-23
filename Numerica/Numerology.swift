import Foundation

/// A single calculation's outcome: the raw total, its single-digit root, and
/// every character that contributed (kept for the breakdown grid).
struct NumerologyResult {
    let total: Int
    let reduced: Int
    let components: [(character: Character, value: Int)]

    var count: Int { components.count }
}

enum NumerologySystem: String, CaseIterable, Identifiable {
    case pythagorean = "Pythagorean"
    case chaldean = "Chaldean"

    var id: String { rawValue }

    /// Letter values for this system. Tables are static so a keypress never
    /// rebuilds a 26-entry dictionary per character.
    var mapping: [Character: Int] {
        switch self {
        case .pythagorean:
            return Self.pythagoreanTable
        case .chaldean:
            return Self.chaldeanTable
        }
    }

    /// Calculates a live value from letters and digits. Letters use the selected
    /// system; every decimal digit contributes its face value (e.g. "23" = 2 + 3).
    func evaluate(_ input: String) -> NumerologyResult {
        let normalized = Self.normalized(input)
        let table = mapping

        var components: [(character: Character, value: Int)] = []
        components.reserveCapacity(normalized.count)

        for character in normalized {
            if let value = table[character] {
                components.append((character, value))
            } else if let digit = Self.digitValue(of: character) {
                components.append((character, digit))
            }
        }

        let total = components.reduce(0) { $0 + $1.value }
        let reduced = Self.digitRoot(total)
        return NumerologyResult(total: total, reduced: reduced, components: components)
    }

    static func digitRoot(_ value: Int) -> Int {
        guard value > 0 else { return 0 }
        return 1 + ((value - 1) % 9)
    }

    /// The single normalization policy every calculation shares: folding away
    /// diacritics and width variants, then uppercasing.
    static func normalized(_ text: String) -> String {
        text.folding(options: [.diacriticInsensitive, .widthInsensitive], locale: .current)
            .uppercased()
    }

    /// Face value of a character when it is one of the decimal digits 0–9.
    /// `wholeNumberValue` also matches non-decimal numerals (e.g. "Ⅻ" is 12),
    /// which must not contribute.
    static func digitValue(of character: Character) -> Int? {
        guard let digit = character.wholeNumberValue, (0...9).contains(digit) else { return nil }
        return digit
    }

    // MARK: Letter tables

    private static let pythagoreanTable: [Character: Int] = [
        "A": 1, "B": 2, "C": 3, "D": 4, "E": 5, "F": 6, "G": 7, "H": 8, "I": 9,
        "J": 1, "K": 2, "L": 3, "M": 4, "N": 5, "O": 6, "P": 7, "Q": 8, "R": 9,
        "S": 1, "T": 2, "U": 3, "V": 4, "W": 5, "X": 6, "Y": 7, "Z": 8
    ]

    private static let chaldeanTable: [Character: Int] = [
        "A": 1, "I": 1, "J": 1, "Q": 1, "Y": 1,
        "B": 2, "K": 2, "R": 2,
        "C": 3, "G": 3, "L": 3, "S": 3,
        "D": 4, "M": 4, "T": 4,
        "E": 5, "H": 5, "N": 5, "X": 5,
        "U": 6, "V": 6, "W": 6,
        "O": 7, "Z": 7,
        "F": 8, "P": 8
    ]

    private static let vowels: Set<Character> = ["A", "E", "I", "O", "U"]
}

struct BirthDateResult {
    let birthCoreTotal: Int
    let birthCoreReduced: Int
    let lifePathTotal: Int
    let lifePathReduced: Int
}

struct BirthNameResult {
    let destiny: NumerologyResult
    let soulUrge: NumerologyResult
    let personality: NumerologyResult
}

struct BirthProfile {
    let date: BirthDateResult
    let pythagorean: BirthNameResult
    let chaldean: BirthNameResult
}

extension NumerologySystem {
    /// Date-derived values are independent of the letter-value system.
    /// Birth Core = day of month; Life Path = sum of all digits in the date.
    static func birthDate(_ date: Date, calendar: Calendar = .current) -> BirthDateResult {
        let parts = calendar.dateComponents([.day, .month, .year], from: date)
        let day = parts.day ?? 0
        let month = parts.month ?? 0
        let year = parts.year ?? 0

        let birthCoreTotal = day
        let dateDigitSum = digitSum(of: day) + digitSum(of: month) + digitSum(of: year)

        return BirthDateResult(
            birthCoreTotal: birthCoreTotal,
            birthCoreReduced: digitRoot(birthCoreTotal),
            lifePathTotal: dateDigitSum,
            lifePathReduced: digitRoot(dateDigitSum)
        )
    }

    /// Splits a name into the three letter-based numbers of the given system.
    func birthName(_ fullName: String) -> BirthNameResult {
        let normalized = Self.normalized(fullName)
        let table = mapping
        let isLetter: (Character) -> Bool = { table[$0] != nil }
        let contributes: (Character) -> Bool = { isLetter($0) || Self.digitValue(of: $0) != nil }

        // Destiny uses the full supplied name input, including any digits.
        // Soul Urge and Personality are letter-based, so only vowels/consonants
        // participate in those two calculations.
        let lettersOnly = String(normalized.filter(isLetter))
        let destinyInput = String(normalized.filter(contributes))
        let soul = String(lettersOnly.filter { Self.vowels.contains($0) })
        let personality = String(lettersOnly.filter { !Self.vowels.contains($0) })

        return BirthNameResult(
            destiny: evaluate(destinyInput),
            soulUrge: evaluate(soul),
            personality: evaluate(personality)
        )
    }

    static func birthProfile(
        fullName: String,
        date: Date,
        calendar: Calendar = .current
    ) -> BirthProfile {
        BirthProfile(
            date: birthDate(date, calendar: calendar),
            pythagorean: NumerologySystem.pythagorean.birthName(fullName),
            chaldean: NumerologySystem.chaldean.birthName(fullName)
        )
    }

    /// Sum of a number's decimal digits (1995 → 24).
    private static func digitSum(of value: Int) -> Int {
        String(value).compactMap { $0.wholeNumberValue }.reduce(0, +)
    }
}
