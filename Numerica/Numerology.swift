import Foundation

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

    var mapping: [Character: Int] {
        switch self {
        case .pythagorean:
            return [
                "A": 1, "B": 2, "C": 3, "D": 4, "E": 5, "F": 6, "G": 7, "H": 8, "I": 9,
                "J": 1, "K": 2, "L": 3, "M": 4, "N": 5, "O": 6, "P": 7, "Q": 8, "R": 9,
                "S": 1, "T": 2, "U": 3, "V": 4, "W": 5, "X": 6, "Y": 7, "Z": 8
            ]
        case .chaldean:
            return [
                "A": 1, "I": 1, "J": 1, "Q": 1, "Y": 1,
                "B": 2, "K": 2, "R": 2,
                "C": 3, "G": 3, "L": 3, "S": 3,
                "D": 4, "M": 4, "T": 4,
                "E": 5, "H": 5, "N": 5, "X": 5,
                "U": 6, "V": 6, "W": 6,
                "O": 7, "Z": 7,
                "F": 8, "P": 8
            ]
        }
    }

    /// Calculates a live value from letters and digits. Letters use the selected
    /// system; every decimal digit contributes its face value (e.g. "23" = 2 + 3).
    func evaluate(_ input: String) -> NumerologyResult {
        let normalized = input.folding(options: [.diacriticInsensitive, .widthInsensitive], locale: .current)
            .uppercased()

        var components: [(Character, Int)] = []
        components.reserveCapacity(normalized.count)

        for character in normalized {
            if let value = mapping[character] {
                components.append((character, value))
            } else if let digit = character.wholeNumberValue, digit <= 9 {
                components.append((character, digit))
            }
        }

        let total = components.reduce(0) { $0 + $1.1 }
        return NumerologyResult(total: total, reduced: Self.digitRoot(total), components: components)
    }

    static func digitRoot(_ value: Int) -> Int {
        guard value > 0 else { return 0 }
        return 1 + ((value - 1) % 9)
    }
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
        let dateDigitSum = digits(of: day) + digits(of: month) + digits(of: year)

        return BirthDateResult(
            birthCoreTotal: birthCoreTotal,
            birthCoreReduced: digitRoot(birthCoreTotal),
            lifePathTotal: dateDigitSum,
            lifePathReduced: digitRoot(dateDigitSum)
        )
    }

    func birthName(_ fullName: String) -> BirthNameResult {
        let normalized = fullName.folding(options: [.diacriticInsensitive, .widthInsensitive], locale: .current)
            .uppercased()

        let lettersOnly = String(normalized.filter { mapping[$0] != nil })
        let destinyInput = String(normalized.filter { mapping[$0] != nil || $0.wholeNumberValue != nil })
        let vowels: Set<Character> = ["A", "E", "I", "O", "U"]

        // Destiny uses the full supplied name input, including any digits.
        // Soul Urge and Personality are letter-based, so only vowels/consonants
        // participate in those two calculations.
        let soul = String(lettersOnly.filter { vowels.contains($0) })
        let personality = String(lettersOnly.filter { !vowels.contains($0) })

        return BirthNameResult(
            destiny: evaluate(destinyInput),
            soulUrge: evaluate(soul),
            personality: evaluate(personality)
        )
    }

    static func birthProfile(fullName: String, date: Date, calendar: Calendar = .current) -> BirthProfile {
        BirthProfile(
            date: birthDate(date, calendar: calendar),
            pythagorean: NumerologySystem.pythagorean.birthName(fullName),
            chaldean: NumerologySystem.chaldean.birthName(fullName)
        )
    }

    private static func digits(of value: Int) -> Int {
        String(value).compactMap { $0.wholeNumberValue }.reduce(0, +)
    }
}

