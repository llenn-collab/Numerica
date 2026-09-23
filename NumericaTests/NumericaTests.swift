import XCTest
@testable import Numerica

final class NumericaTests: XCTestCase {
    // MARK: - Letter values

    func test_evaluate_pythagoreanSumsLetterValues() {
        let result = NumerologySystem.pythagorean.evaluate("ABC")
        XCTAssertEqual(result.total, 6)
        XCTAssertEqual(result.reduced, 6)
    }

    func test_evaluate_chaldeanSumsLetterValues() {
        let result = NumerologySystem.chaldean.evaluate("ABC")
        XCTAssertEqual(result.total, 6)
        XCTAssertEqual(result.reduced, 6)
    }

    func test_evaluate_systemsDisagreeForSameLetter() {
        XCTAssertEqual(NumerologySystem.pythagorean.evaluate("J").total, 1)
        XCTAssertEqual(NumerologySystem.chaldean.evaluate("J").total, 1)
        XCTAssertEqual(NumerologySystem.pythagorean.evaluate("F").total, 6)
        XCTAssertEqual(NumerologySystem.chaldean.evaluate("F").total, 8)
    }

    func test_evaluate_chaldeanNeverAssignsNine() {
        XCTAssertFalse(NumerologySystem.chaldean.mapping.values.contains(9))
        XCTAssertTrue(NumerologySystem.pythagorean.mapping.values.contains(9))
        XCTAssertEqual(NumerologySystem.chaldean.evaluate("I").total, 1)
    }

    // MARK: - Digits and normalization

    func test_evaluate_digitsContributeFaceValue() {
        // README: "23" contributes 2 + 3, so A23 is 1 + 2 + 3.
        XCTAssertEqual(NumerologySystem.pythagorean.evaluate("A23").total, 6)
        XCTAssertEqual(NumerologySystem.chaldean.evaluate("A23").total, 6)
    }

    func test_evaluate_zeroStillCountsAsACharacter() {
        let result = NumerologySystem.pythagorean.evaluate("0")
        XCTAssertEqual(result.total, 0)
        XCTAssertEqual(result.count, 1)
    }

    func test_evaluate_normalizesDiacriticsAndPunctuation() {
        let result = NumerologySystem.pythagorean.evaluate("Élan 2!")
        // E=5, L=3, A=1, N=5, 2=2 => 16 -> 7
        XCTAssertEqual(result.total, 16)
        XCTAssertEqual(result.reduced, 7)
        XCTAssertEqual(result.count, 5)
    }

    func test_evaluate_treatsFullWidthLettersAsAscii() {
        XCTAssertEqual(NumerologySystem.pythagorean.evaluate("ＡＢＣ").total, 6)
    }

    func test_evaluate_isCaseInsensitive() {
        XCTAssertEqual(NumerologySystem.pythagorean.evaluate("abc").total,
                       NumerologySystem.pythagorean.evaluate("ABC").total)
    }

    func test_evaluate_emptyInputYieldsZero() {
        let result = NumerologySystem.pythagorean.evaluate("")
        XCTAssertEqual(result.total, 0)
        XCTAssertEqual(result.reduced, 0)
        XCTAssertEqual(result.count, 0)
    }

    func test_evaluate_ignoresWhitespaceAndPunctuation() {
        let result = NumerologySystem.pythagorean.evaluate("  !!! ---  ")
        XCTAssertEqual(result.total, 0)
        XCTAssertEqual(result.count, 0)
    }

    func test_evaluate_keepsBreakdownOrder() {
        let result = NumerologySystem.pythagorean.evaluate("AB1")
        XCTAssertEqual(result.components.map { $0.character }, Array("AB1"))
        XCTAssertEqual(result.components.map { $0.value }, [1, 2, 1])
    }

    func test_digitValue_rejectsNonDecimalNumerals() {
        // "Ⅻ" is the single character U+216B; it is not a decimal digit.
        XCTAssertNil(NumerologySystem.digitValue(of: "Ⅻ"))
        XCTAssertEqual(NumerologySystem.digitValue(of: "5"), 5)
        XCTAssertNil(NumerologySystem.digitValue(of: "A"))
    }

    func test_digitRoot_reducesToASingleDigit() {
        XCTAssertEqual(NumerologySystem.digitRoot(0), 0)
        XCTAssertEqual(NumerologySystem.digitRoot(9), 9)
        XCTAssertEqual(NumerologySystem.digitRoot(10), 1)
        XCTAssertEqual(NumerologySystem.digitRoot(18), 9)
        XCTAssertEqual(NumerologySystem.digitRoot(19), 1)
        XCTAssertEqual(NumerologySystem.digitRoot(31), 4)
    }

    // MARK: - Birth date

    func test_birthDate_birthCoreIsDayOfMonth() {
        let result = NumerologySystem.birthDate(Self.makeDate(1995, 2, 14),
                                                calendar: Self.gregorian)
        XCTAssertEqual(result.birthCoreTotal, 14)
        XCTAssertEqual(result.birthCoreReduced, 5)
    }

    func test_birthDate_lifePathSumsEveryDateDigit() {
        let result = NumerologySystem.birthDate(Self.makeDate(1995, 2, 14),
                                                calendar: Self.gregorian)
        // 1+4 (day) + 0+2 (month) + 1+9+9+5 (year) = 31 -> 4
        XCTAssertEqual(result.lifePathTotal, 31)
        XCTAssertEqual(result.lifePathReduced, 4)
    }

    // MARK: - Birth name

    func test_birthName_splitsVowelsFromConsonants() {
        let result = NumerologySystem.pythagorean.birthName("JOHN DOE")
        XCTAssertEqual(result.destiny.total, 35)
        XCTAssertEqual(result.soulUrge.total, 17)
        XCTAssertEqual(result.personality.total, 18)
    }

    func test_birthName_usesSystemSpecificLetterValues() {
        let result = NumerologySystem.chaldean.birthName("JOHN DOE")
        XCTAssertEqual(result.destiny.total, 34)
        XCTAssertEqual(result.soulUrge.total, 19)
        XCTAssertEqual(result.personality.total, 15)
    }

    func test_birthName_destinyCountsDigitsThatVowelsAndConsonantsIgnore() {
        let result = NumerologySystem.pythagorean.birthName("A2")
        XCTAssertEqual(result.destiny.total, 3)
        XCTAssertEqual(result.soulUrge.total, 1)
        XCTAssertEqual(result.personality.total, 0)
    }

    func test_birthProfile_combinesDateAndBothSystems() {
        let profile = NumerologySystem.birthProfile(fullName: "JOHN DOE",
                                                    date: Self.makeDate(1995, 2, 14),
                                                    calendar: Self.gregorian)
        XCTAssertEqual(profile.date.lifePathReduced, 4)
        XCTAssertEqual(profile.pythagorean.destiny.total, 35)
        XCTAssertEqual(profile.chaldean.destiny.total, 34)
    }

    // MARK: - Fixtures

    private static let gregorian: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }()

    private static func makeDate(_ year: Int, _ month: Int, _ day: Int) -> Date {
        var components = DateComponents()
        components.calendar = gregorian
        components.timeZone = gregorian.timeZone
        components.year = year
        components.month = month
        components.day = day
        return components.date!
    }
}
