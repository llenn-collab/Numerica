import XCTest
@testable import Numerica

final class NumericaTests: XCTestCase {
    func testPythagorean() {
        let result = NumerologySystem.pythagorean.evaluate("ABC")
        XCTAssertEqual(result.total, 6)
        XCTAssertEqual(result.reduced, 6)
    }

    func testChaldean() {
        let result = NumerologySystem.chaldean.evaluate("ABC")
        XCTAssertEqual(result.total, 6)
        XCTAssertEqual(result.reduced, 6)
    }

    func testSystemsCanDiffer() {
        XCTAssertEqual(NumerologySystem.pythagorean.evaluate("J").total, 1)
        XCTAssertEqual(NumerologySystem.chaldean.evaluate("J").total, 1)
        XCTAssertEqual(NumerologySystem.pythagorean.evaluate("F").total, 6)
        XCTAssertEqual(NumerologySystem.chaldean.evaluate("F").total, 8)
    }

    func testChaldeanNineHasNoLetterAssignment() {
        let result = NumerologySystem.chaldean.evaluate("I")
        XCTAssertEqual(result.total, 1)
    }

    func testDigitsAreCalculated() {
        XCTAssertEqual(NumerologySystem.pythagorean.evaluate("A23").total, 8)
        XCTAssertEqual(NumerologySystem.chaldean.evaluate("A23").total, 8)
    }

    func testDigitsAndLettersNormalizeTogether() {
        let result = NumerologySystem.pythagorean.evaluate("Élan 2!")
        // E=5, L=3, A=1, N=5, 2=2 => 16 -> 7
        XCTAssertEqual(result.total, 16)
        XCTAssertEqual(result.reduced, 7)
    }

    func testBirthCoreAndLifePath() {
        var components = DateComponents()
        components.calendar = Calendar(identifier: .gregorian)
        components.timeZone = TimeZone(secondsFromGMT: 0)
        components.year = 1995
        components.month = 2
        components.day = 14
        let date = components.date!

        let result = NumerologySystem.birthDate(date, calendar: components.calendar!)
        XCTAssertEqual(result.birthCoreTotal, 14)
        XCTAssertEqual(result.birthCoreReduced, 5)
        XCTAssertEqual(result.lifePathTotal, 31)
        XCTAssertEqual(result.lifePathReduced, 4)
    }

    func testBirthNameSplitsVowelsAndConsonants() {
        let p = NumerologySystem.pythagorean.birthName("JOHN DOE")
        XCTAssertEqual(p.destiny.total, 35)
        XCTAssertEqual(p.soulUrge.total, 17)
        XCTAssertEqual(p.personality.total, 18)
    }

    func testBirthDestinyCanIncludeDigits() {
        let p = NumerologySystem.pythagorean.birthName("A2")
        XCTAssertEqual(p.destiny.total, 3)
        XCTAssertEqual(p.soulUrge.total, 1)
        XCTAssertEqual(p.personality.total, 0)
    }
}
