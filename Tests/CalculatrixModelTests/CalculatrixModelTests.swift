import XCTest
import OSLog
import Foundation
@testable import CalculatrixModel

let logger: Logger = Logger(subsystem: "CalculatrixModel", category: "Tests")

@available(macOS 13, *)
final class CalculatrixModelTests: XCTestCase {

    func testCalculatrixModel() throws {
        logger.log("running testCalculatrixModel")
        XCTAssertEqual(1 + 2, 3, "basic test")
    }

    func testDecodeType() throws {
        // load the TestData.json file from the Resources folder and decode it into a struct
        let resourceURL: URL = try XCTUnwrap(Bundle.module.url(forResource: "TestData", withExtension: "json"))
        let testData = try JSONDecoder().decode(TestData.self, from: Data(contentsOf: resourceURL))
        XCTAssertEqual("CalculatrixModel", testData.testModuleName)
    }

    // MARK: - Initial State

    func testInitialState() throws {
        let calc = CalculatorModel()
        XCTAssertEqual(calc.displayText, "0")
        XCTAssertTrue(calc.isAllClear)
        XCTAssertNil(calc.activeOperation)
        XCTAssertEqual(calc.displayValue, 0)
    }

    // MARK: - Digit Input

    func testSingleDigit() throws {
        let calc = CalculatorModel()
        calc.inputDigit(5)
        XCTAssertEqual(calc.displayText, "5")
    }

    func testMultipleDigits() throws {
        let calc = CalculatorModel()
        calc.inputDigit(1)
        calc.inputDigit(2)
        calc.inputDigit(3)
        XCTAssertEqual(calc.displayText, "123")
    }

    func testLeadingZero() throws {
        let calc = CalculatorModel()
        calc.inputDigit(0)
        calc.inputDigit(0)
        calc.inputDigit(5)
        XCTAssertEqual(calc.displayText, "5")
    }

    func testMaxDigits() throws {
        let calc = CalculatorModel()
        for _ in 0..<20 {
            calc.inputDigit(1)
        }
        XCTAssertEqual(calc.displayText, "111111111") // 9 digits max
    }

    // MARK: - Decimal Input

    func testDecimalInput() throws {
        let calc = CalculatorModel()
        calc.inputDigit(3)
        calc.inputDecimal()
        calc.inputDigit(1)
        calc.inputDigit(4)
        XCTAssertEqual(calc.displayText, "3.14")
    }

    func testDecimalWithoutLeadingDigit() throws {
        let calc = CalculatorModel()
        calc.inputDecimal()
        calc.inputDigit(5)
        XCTAssertEqual(calc.displayText, "0.5")
    }

    func testMultipleDecimals() throws {
        let calc = CalculatorModel()
        calc.inputDigit(1)
        calc.inputDecimal()
        calc.inputDecimal()
        calc.inputDigit(5)
        XCTAssertEqual(calc.displayText, "1.5")
    }

    // MARK: - Basic Operations

    func testAddition() throws {
        let calc = CalculatorModel()
        calc.inputDigit(5)
        calc.inputOperation(.add)
        calc.inputDigit(3)
        calc.inputEquals()
        XCTAssertEqual(calc.displayText, "8")
    }

    func testSubtraction() throws {
        let calc = CalculatorModel()
        calc.inputDigit(9)
        calc.inputOperation(.subtract)
        calc.inputDigit(4)
        calc.inputEquals()
        XCTAssertEqual(calc.displayText, "5")
    }

    func testMultiplication() throws {
        let calc = CalculatorModel()
        calc.inputDigit(6)
        calc.inputOperation(.multiply)
        calc.inputDigit(7)
        calc.inputEquals()
        XCTAssertEqual(calc.displayText, "42")
    }

    func testDivision() throws {
        let calc = CalculatorModel()
        calc.inputDigit(1)
        calc.inputDigit(5)
        calc.inputOperation(.divide)
        calc.inputDigit(3)
        calc.inputEquals()
        XCTAssertEqual(calc.displayText, "5")
    }

    // MARK: - Division by Zero

    func testDivisionByZero() throws {
        let calc = CalculatorModel()
        calc.inputDigit(5)
        calc.inputOperation(.divide)
        calc.inputDigit(0)
        calc.inputEquals()
        XCTAssertEqual(calc.displayText, "Error")
    }

    func testDigitAfterError() throws {
        let calc = CalculatorModel()
        calc.inputDigit(5)
        calc.inputOperation(.divide)
        calc.inputDigit(0)
        calc.inputEquals()
        XCTAssertEqual(calc.displayText, "Error")
        calc.inputDigit(3)
        XCTAssertEqual(calc.displayText, "3")
    }

    // MARK: - Clear

    func testClearEntry() throws {
        let calc = CalculatorModel()
        calc.inputDigit(5)
        XCTAssertFalse(calc.isAllClear) // Shows "C"
        calc.inputClear() // First press: clear entry
        XCTAssertEqual(calc.displayText, "0")
        XCTAssertTrue(calc.isAllClear) // Now shows "AC"
    }

    func testAllClear() throws {
        let calc = CalculatorModel()
        calc.inputDigit(5)
        calc.inputOperation(.add)
        calc.inputDigit(3)
        calc.inputClear() // C: clear entry
        calc.inputClear() // AC: clear everything
        calc.inputDigit(2)
        calc.inputEquals()
        // After AC, the pending operation should be cleared
        XCTAssertEqual(calc.displayText, "2")
    }

    func testClearDuringOperation() throws {
        let calc = CalculatorModel()
        calc.inputDigit(5)
        calc.inputOperation(.add)
        calc.inputDigit(3)
        calc.inputClear() // Clear entry (shows 0, isAllClear = true)
        calc.inputDigit(7) // Enter new second operand
        calc.inputEquals()
        XCTAssertEqual(calc.displayText, "12") // 5 + 7
    }

    // MARK: - Negate

    func testNegatePositive() throws {
        let calc = CalculatorModel()
        calc.inputDigit(5)
        calc.inputNegate()
        XCTAssertEqual(calc.displayText, "-5")
    }

    func testNegateNegative() throws {
        let calc = CalculatorModel()
        calc.inputDigit(5)
        calc.inputNegate()
        calc.inputNegate()
        XCTAssertEqual(calc.displayText, "5")
    }

    func testNegateZero() throws {
        let calc = CalculatorModel()
        // From initial state (not entering)
        calc.inputNegate()
        XCTAssertEqual(calc.displayText, "-0")
        calc.inputDigit(5)
        XCTAssertEqual(calc.displayText, "-5")
    }

    func testNegateInOperation() throws {
        let calc = CalculatorModel()
        calc.inputDigit(1)
        calc.inputDigit(0)
        calc.inputOperation(.add)
        calc.inputDigit(3)
        calc.inputNegate()
        calc.inputEquals()
        XCTAssertEqual(calc.displayText, "7") // 10 + (-3) = 7
    }

    // MARK: - Percent

    func testPercentSimple() throws {
        let calc = CalculatorModel()
        calc.inputDigit(5)
        calc.inputDigit(0)
        calc.inputPercent()
        XCTAssertEqual(calc.displayText, "0.5")
    }

    func testPercentWithAddition() throws {
        let calc = CalculatorModel()
        calc.inputDigit(2)
        calc.inputDigit(0)
        calc.inputDigit(0)
        calc.inputOperation(.add)
        calc.inputDigit(1)
        calc.inputDigit(0)
        calc.inputPercent()
        // 10% of 200 = 20
        XCTAssertEqual(calc.displayText, "20")
        calc.inputEquals()
        // 200 + 20 = 220
        XCTAssertEqual(calc.displayText, "220")
    }

    func testPercentWithMultiplication() throws {
        let calc = CalculatorModel()
        calc.inputDigit(2)
        calc.inputDigit(0)
        calc.inputDigit(0)
        calc.inputOperation(.multiply)
        calc.inputDigit(5)
        calc.inputDigit(0)
        calc.inputPercent()
        // 50 / 100 = 0.5
        XCTAssertEqual(calc.displayText, "0.5")
        calc.inputEquals()
        // 200 * 0.5 = 100
        XCTAssertEqual(calc.displayText, "100")
    }

    // MARK: - Chained Operations

    func testChainedAddition() throws {
        let calc = CalculatorModel()
        calc.inputDigit(1)
        calc.inputOperation(.add)
        calc.inputDigit(2)
        calc.inputOperation(.add) // Should compute 1+2=3
        XCTAssertEqual(calc.displayText, "3")
        calc.inputDigit(3)
        calc.inputEquals()
        XCTAssertEqual(calc.displayText, "6") // 3+3=6
    }

    func testChainedMixedOperations() throws {
        let calc = CalculatorModel()
        calc.inputDigit(5)
        calc.inputOperation(.add)
        calc.inputDigit(3)
        calc.inputOperation(.multiply) // Should compute 5+3=8
        XCTAssertEqual(calc.displayText, "8")
        calc.inputDigit(2)
        calc.inputEquals()
        XCTAssertEqual(calc.displayText, "16") // 8*2=16
    }

    // MARK: - Repeated Equals

    func testRepeatedEquals() throws {
        let calc = CalculatorModel()
        calc.inputDigit(5)
        calc.inputOperation(.add)
        calc.inputDigit(3)
        calc.inputEquals()
        XCTAssertEqual(calc.displayText, "8") // 5+3=8
        calc.inputEquals()
        XCTAssertEqual(calc.displayText, "11") // 8+3=11
        calc.inputEquals()
        XCTAssertEqual(calc.displayText, "14") // 11+3=14
    }

    // MARK: - Operation Change

    func testOperationChange() throws {
        let calc = CalculatorModel()
        calc.inputDigit(5)
        calc.inputOperation(.add)
        calc.inputOperation(.subtract) // Change to subtract
        calc.inputDigit(3)
        calc.inputEquals()
        XCTAssertEqual(calc.displayText, "2") // 5-3=2
    }

    // MARK: - Active Operation Highlighting

    func testActiveOperationHighlight() throws {
        let calc = CalculatorModel()
        calc.inputDigit(5)
        XCTAssertNil(calc.activeOperation)
        calc.inputOperation(.add)
        XCTAssertEqual(calc.activeOperation, .add)
        calc.inputDigit(3)
        XCTAssertEqual(calc.activeOperation, .add) // Still highlighted during entry
        calc.inputEquals()
        XCTAssertNil(calc.activeOperation) // Cleared after equals
    }

    // MARK: - Decimal Operations

    func testDecimalAddition() throws {
        let calc = CalculatorModel()
        calc.inputDigit(1)
        calc.inputDecimal()
        calc.inputDigit(5)
        calc.inputOperation(.add)
        calc.inputDigit(2)
        calc.inputDecimal()
        calc.inputDigit(3)
        calc.inputEquals()
        XCTAssertEqual(calc.displayText, "3.8")
    }

    // MARK: - Number Formatting

    func testFormatWholeNumber() throws {
        XCTAssertEqual(CalculatorModel.formatNumber(42), "42")
    }

    func testFormatNegativeNumber() throws {
        XCTAssertEqual(CalculatorModel.formatNumber(-7), "-7")
    }

    func testFormatZero() throws {
        XCTAssertEqual(CalculatorModel.formatNumber(0), "0")
    }

    func testFormatDecimal() throws {
        XCTAssertEqual(CalculatorModel.formatNumber(3.14), "3.14")
    }

    func testFormatInfinity() throws {
        XCTAssertEqual(CalculatorModel.formatNumber(Double.infinity), "Error")
    }

    func testFormatNaN() throws {
        XCTAssertEqual(CalculatorModel.formatNumber(Double.nan), "Error")
    }

    // MARK: - Large Numbers

    func testLargeMultiplication() throws {
        let calc = CalculatorModel()
        // 99999 * 99999 = 9999800001
        calc.inputDigit(9)
        calc.inputDigit(9)
        calc.inputDigit(9)
        calc.inputDigit(9)
        calc.inputDigit(9)
        calc.inputOperation(.multiply)
        calc.inputDigit(9)
        calc.inputDigit(9)
        calc.inputDigit(9)
        calc.inputDigit(9)
        calc.inputDigit(9)
        calc.inputEquals()
        XCTAssertEqual(calc.displayText, "9999800001")
    }

    // MARK: - Edge Cases

    func testEqualsWithoutOperation() throws {
        let calc = CalculatorModel()
        calc.inputDigit(5)
        calc.inputEquals()
        XCTAssertEqual(calc.displayText, "5")
    }

    func testOperationWithEqualsNoSecondOperand() throws {
        // 5 + = should give 10 (5 + 5)
        let calc = CalculatorModel()
        calc.inputDigit(5)
        calc.inputOperation(.add)
        calc.inputEquals()
        XCTAssertEqual(calc.displayText, "10")
    }

    func testNegateAfterResult() throws {
        let calc = CalculatorModel()
        calc.inputDigit(3)
        calc.inputOperation(.add)
        calc.inputDigit(2)
        calc.inputEquals()
        XCTAssertEqual(calc.displayText, "5")
        calc.inputNegate()
        XCTAssertEqual(calc.displayText, "-5")
    }

    func testNewNumberAfterEquals() throws {
        let calc = CalculatorModel()
        calc.inputDigit(5)
        calc.inputOperation(.add)
        calc.inputDigit(3)
        calc.inputEquals()
        XCTAssertEqual(calc.displayText, "8")
        calc.inputDigit(2)
        XCTAssertEqual(calc.displayText, "2")
    }

    func testClearShowsC() throws {
        let calc = CalculatorModel()
        XCTAssertTrue(calc.isAllClear) // Initially AC
        calc.inputDigit(5)
        XCTAssertFalse(calc.isAllClear) // Now C
        calc.inputClear()
        XCTAssertTrue(calc.isAllClear) // Back to AC
    }

    func testSubtractionNegativeResult() throws {
        let calc = CalculatorModel()
        calc.inputDigit(3)
        calc.inputOperation(.subtract)
        calc.inputDigit(8)
        calc.inputEquals()
        XCTAssertEqual(calc.displayText, "-5")
    }
}

struct TestData : Codable, Hashable {
    var testModuleName: String
}
