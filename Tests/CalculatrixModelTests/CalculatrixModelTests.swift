import XCTest
import OSLog
import Foundation
@testable import CalculatrixModel

let logger: Logger = Logger(subsystem: "CalculatrixModel", category: "Tests")

@available(macOS 13, *)
final class CalculatrixModelTests: XCTestCase {

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

    // MARK: - Mode

    func testInitialMode() throws {
        let calc = CalculatorModel()
        XCTAssertEqual(calc.calculatorMode, .basic)
    }

    func testSetMode() throws {
        let calc = CalculatorModel()
        calc.setMode(.scientific)
        XCTAssertEqual(calc.calculatorMode, .scientific)
        calc.setMode(.convert)
        XCTAssertEqual(calc.calculatorMode, .convert)
        calc.setMode(.basic)
        XCTAssertEqual(calc.calculatorMode, .basic)
    }
}

// MARK: - Conversion Tests

@available(macOS 13, *)
final class ConversionTests: XCTestCase {

    private func assertConversion(_ value: Double, from source: ConversionUnit, to target: ConversionUnit, expected: Double, accuracy: Double = 1e-4) {
        let result = convertValue(value, from: source, to: target)
        XCTAssertEqual(result, expected, accuracy: accuracy, "\(value) \(source) -> \(target): expected \(expected), got \(result)")
    }

    // MARK: - Category Data Integrity

    func testAllCategoriesHaveUnits() throws {
        for category in ConversionCategory.allCases {
            let units = conversionUnits(for: category)
            XCTAssertGreaterThan(units.count, 1, "\(category) should have at least 2 units")
        }
    }

    func testDefaultUnitsExist() throws {
        for category in ConversionCategory.allCases {
            let source = defaultSourceUnit(for: category)
            let target = defaultTargetUnit(for: category)
            XCTAssertNotEqual(source, target, "\(category) default source and target should differ")
        }
    }

    // MARK: - Length

    func testLengthMetersToFeet() throws {
        assertConversion(1.0, from: .length(.meters), to: .length(.feet), expected: 3.28084)
    }

    func testLengthKilometersToMiles() throws {
        assertConversion(1.0, from: .length(.kilometers), to: .length(.miles), expected: 0.621371)
    }

    func testLengthInchesToCentimeters() throws {
        assertConversion(1.0, from: .length(.inches), to: .length(.centimeters), expected: 2.54)
    }

    func testLengthMilesToKilometers() throws {
        assertConversion(1.0, from: .length(.miles), to: .length(.kilometers), expected: 1.60934, accuracy: 0.001)
    }

    func testLengthYardsToMeters() throws {
        assertConversion(1.0, from: .length(.yards), to: .length(.meters), expected: 0.9144)
    }

    func testLengthNauticalMilesToKilometers() throws {
        assertConversion(1.0, from: .length(.nauticalMiles), to: .length(.kilometers), expected: 1.852)
    }

    // MARK: - Temperature

    func testTemperatureCelsiusToFahrenheit() throws {
        assertConversion(0.0, from: .temperature(.celsius), to: .temperature(.fahrenheit), expected: 32.0)
        assertConversion(100.0, from: .temperature(.celsius), to: .temperature(.fahrenheit), expected: 212.0)
        assertConversion(-40.0, from: .temperature(.celsius), to: .temperature(.fahrenheit), expected: -40.0)
    }

    func testTemperatureFahrenheitToCelsius() throws {
        assertConversion(32.0, from: .temperature(.fahrenheit), to: .temperature(.celsius), expected: 0.0)
        assertConversion(212.0, from: .temperature(.fahrenheit), to: .temperature(.celsius), expected: 100.0)
    }

    func testTemperatureCelsiusToKelvin() throws {
        assertConversion(0.0, from: .temperature(.celsius), to: .temperature(.kelvin), expected: 273.15)
        assertConversion(100.0, from: .temperature(.celsius), to: .temperature(.kelvin), expected: 373.15)
        assertConversion(-273.15, from: .temperature(.celsius), to: .temperature(.kelvin), expected: 0.0)
    }

    func testTemperatureKelvinToFahrenheit() throws {
        assertConversion(0.0, from: .temperature(.kelvin), to: .temperature(.fahrenheit), expected: -459.67)
    }

    func testTemperatureCelsiusToRankine() throws {
        assertConversion(0.0, from: .temperature(.celsius), to: .temperature(.rankine), expected: 491.67)
    }

    func testTemperatureRankineToCelsius() throws {
        assertConversion(491.67, from: .temperature(.rankine), to: .temperature(.celsius), expected: 0.0, accuracy: 0.01)
    }

    // MARK: - Weight

    func testWeightKilogramsToPounds() throws {
        assertConversion(1.0, from: .weight(.kilograms), to: .weight(.pounds), expected: 2.20462, accuracy: 0.001)
    }

    func testWeightPoundsToKilograms() throws {
        assertConversion(1.0, from: .weight(.pounds), to: .weight(.kilograms), expected: 0.453592, accuracy: 0.001)
    }

    func testWeightOuncesToGrams() throws {
        assertConversion(1.0, from: .weight(.ounces), to: .weight(.grams), expected: 28.3495, accuracy: 0.01)
    }

    func testWeightMetricTonToKilograms() throws {
        assertConversion(1.0, from: .weight(.metricTons), to: .weight(.kilograms), expected: 1000.0)
    }

    func testWeightStonesToPounds() throws {
        assertConversion(1.0, from: .weight(.stones), to: .weight(.pounds), expected: 14.0, accuracy: 0.01)
    }

    // MARK: - Angles

    func testAngleDegreesToRadians() throws {
        assertConversion(180.0, from: .angle(.degrees), to: .angle(.radians), expected: Double.pi, accuracy: 1e-6)
    }

    func testAngleRadiansToDegrees() throws {
        assertConversion(Double.pi, from: .angle(.radians), to: .angle(.degrees), expected: 180.0, accuracy: 1e-6)
    }

    func testAngleDegreesToGradians() throws {
        assertConversion(90.0, from: .angle(.degrees), to: .angle(.gradians), expected: 100.0)
    }

    func testAngleRevolutionsToDegrees() throws {
        assertConversion(1.0, from: .angle(.revolutions), to: .angle(.degrees), expected: 360.0)
    }

    // MARK: - Area

    func testAreaSquareMetersToSquareFeet() throws {
        assertConversion(1.0, from: .area(.squareMeters), to: .area(.squareFeet), expected: 10.7639, accuracy: 0.01)
    }

    func testAreaHectaresToAcres() throws {
        assertConversion(1.0, from: .area(.hectares), to: .area(.acres), expected: 2.47105, accuracy: 0.001)
    }

    func testAreaSquareKilometersToSquareMiles() throws {
        assertConversion(1.0, from: .area(.squareKilometers), to: .area(.squareMiles), expected: 0.386102, accuracy: 0.001)
    }

    // MARK: - Data

    func testDataKilobytesToBytes() throws {
        assertConversion(1.0, from: .data(.kilobytes), to: .data(.bytes), expected: 1000.0)
    }

    func testDataKibibytesToBytes() throws {
        assertConversion(1.0, from: .data(.kibibytes), to: .data(.bytes), expected: 1024.0)
    }

    func testDataMegabytesToGigabytes() throws {
        assertConversion(1024.0, from: .data(.megabytes), to: .data(.gigabytes), expected: 1.024)
    }

    func testDataBitsToBytes() throws {
        assertConversion(8.0, from: .data(.bits), to: .data(.bytes), expected: 1.0)
    }

    // MARK: - Energy

    func testEnergyJoulesToKilocalories() throws {
        assertConversion(4184.0, from: .energy(.joules), to: .energy(.kilocalories), expected: 1.0, accuracy: 0.01)
    }

    func testEnergyKilowattHoursToJoules() throws {
        assertConversion(1.0, from: .energy(.kilowattHours), to: .energy(.joules), expected: 3_600_000.0, accuracy: 1.0)
    }

    func testEnergyCaloriesToJoules() throws {
        assertConversion(1.0, from: .energy(.calories), to: .energy(.joules), expected: 4.184)
    }

    // MARK: - Force

    func testForceNewtonsToLbf() throws {
        assertConversion(1.0, from: .force(.newtons), to: .force(.poundsForce), expected: 0.224809, accuracy: 0.001)
    }

    func testForceKgfToNewtons() throws {
        assertConversion(1.0, from: .force(.kilogramForce), to: .force(.newtons), expected: 9.80665, accuracy: 0.001)
    }

    // MARK: - Fuel

    func testFuelLPer100kmToMpg() throws {
        assertConversion(10.0, from: .fuel(.litersPer100km), to: .fuel(.milesPerGallonUS), expected: 23.5215, accuracy: 0.01)
    }

    func testFuelMpgToLPer100km() throws {
        assertConversion(30.0, from: .fuel(.milesPerGallonUS), to: .fuel(.litersPer100km), expected: 7.8405, accuracy: 0.01)
    }

    func testFuelMpgToKmPerL() throws {
        assertConversion(30.0, from: .fuel(.milesPerGallonUS), to: .fuel(.kilometersPerLiter), expected: 12.7543, accuracy: 0.01)
    }

    func testFuelZero() throws {
        assertConversion(0.0, from: .fuel(.milesPerGallonUS), to: .fuel(.litersPer100km), expected: 0.0)
    }

    // MARK: - Power

    func testPowerWattsToHorsepower() throws {
        assertConversion(745.7, from: .power(.watts), to: .power(.horsepower), expected: 1.0, accuracy: 0.01)
    }

    func testPowerKilowattsToWatts() throws {
        assertConversion(1.0, from: .power(.kilowatts), to: .power(.watts), expected: 1000.0)
    }

    // MARK: - Pressure

    func testPressureAtmToPascals() throws {
        assertConversion(1.0, from: .pressure(.atmospheres), to: .pressure(.pascals), expected: 101325.0, accuracy: 1.0)
    }

    func testPressureBarToPsi() throws {
        assertConversion(1.0, from: .pressure(.bars), to: .pressure(.poundsPerSquareInch), expected: 14.5038, accuracy: 0.01)
    }

    func testPressurePsiToKpa() throws {
        assertConversion(1.0, from: .pressure(.poundsPerSquareInch), to: .pressure(.kilopascals), expected: 6.89476, accuracy: 0.01)
    }

    // MARK: - Speed

    func testSpeedKmhToMph() throws {
        assertConversion(100.0, from: .speed(.kilometersPerHour), to: .speed(.milesPerHour), expected: 62.1371, accuracy: 0.01)
    }

    func testSpeedMsToKmh() throws {
        assertConversion(1.0, from: .speed(.metersPerSecond), to: .speed(.kilometersPerHour), expected: 3.6)
    }

    func testSpeedKnotsToKmh() throws {
        assertConversion(1.0, from: .speed(.knots), to: .speed(.kilometersPerHour), expected: 1.852, accuracy: 0.01)
    }

    // MARK: - Time

    func testTimeHoursToMinutes() throws {
        assertConversion(1.0, from: .time(.hours), to: .time(.minutes), expected: 60.0)
    }

    func testTimeDaysToHours() throws {
        assertConversion(1.0, from: .time(.days), to: .time(.hours), expected: 24.0)
    }

    func testTimeWeeksTodays() throws {
        assertConversion(1.0, from: .time(.weeks), to: .time(.days), expected: 7.0)
    }

    func testTimeYearsToSeconds() throws {
        assertConversion(1.0, from: .time(.years), to: .time(.seconds), expected: 31_536_000.0)
    }

    // MARK: - Volume

    func testVolumeLitersToGallons() throws {
        assertConversion(1.0, from: .volume(.liters), to: .volume(.usGallons), expected: 0.264172, accuracy: 0.001)
    }

    func testVolumeGallonsToLiters() throws {
        assertConversion(1.0, from: .volume(.usGallons), to: .volume(.liters), expected: 3.78541, accuracy: 0.001)
    }

    func testVolumeCubicMetersToLiters() throws {
        assertConversion(1.0, from: .volume(.cubicMeters), to: .volume(.liters), expected: 1000.0)
    }

    func testVolumeFlOzToMilliliters() throws {
        assertConversion(1.0, from: .volume(.usFluidOunces), to: .volume(.milliliters), expected: 29.5735, accuracy: 0.01)
    }

    func testVolumeCupsToFlOz() throws {
        assertConversion(1.0, from: .volume(.usCups), to: .volume(.usFluidOunces), expected: 8.0, accuracy: 0.1)
    }

    // MARK: - Identity Conversions

    func testSameUnitConversion() throws {
        for category in ConversionCategory.allCases {
            let units = conversionUnits(for: category)
            let firstUnit = units[0]
            let result = convertValue(42.0, from: firstUnit, to: firstUnit)
            XCTAssertEqual(result, 42.0, "\(category): same-unit conversion should be identity")
        }
    }

    // MARK: - Round-Trip Conversions

    func testRoundTripLength() throws {
        let original = 123.456
        let converted = convertValue(original, from: .length(.meters), to: .length(.feet))
        let roundTrip = convertValue(converted, from: .length(.feet), to: .length(.meters))
        XCTAssertEqual(roundTrip, original, accuracy: 1e-6)
    }

    func testRoundTripTemperature() throws {
        let original = 37.0
        let converted = convertValue(original, from: .temperature(.celsius), to: .temperature(.fahrenheit))
        let roundTrip = convertValue(converted, from: .temperature(.fahrenheit), to: .temperature(.celsius))
        XCTAssertEqual(roundTrip, original, accuracy: 1e-6)
    }

    func testRoundTripWeight() throws {
        let original = 75.0
        let converted = convertValue(original, from: .weight(.kilograms), to: .weight(.pounds))
        let roundTrip = convertValue(converted, from: .weight(.pounds), to: .weight(.kilograms))
        XCTAssertEqual(roundTrip, original, accuracy: 1e-6)
    }

    func testRoundTripFuel() throws {
        let original = 8.5
        let converted = convertValue(original, from: .fuel(.litersPer100km), to: .fuel(.milesPerGallonUS))
        let roundTrip = convertValue(converted, from: .fuel(.milesPerGallonUS), to: .fuel(.litersPer100km))
        XCTAssertEqual(roundTrip, original, accuracy: 1e-6)
    }

    // MARK: - Edge Cases

    func testConvertZero() throws {
        XCTAssertEqual(convertValue(0.0, from: .length(.meters), to: .length(.feet)), 0.0)
    }

    func testConvertZeroTemperature() throws {
        XCTAssertEqual(convertValue(0.0, from: .temperature(.celsius), to: .temperature(.fahrenheit)), 32.0)
    }

    func testConvertNegativeValues() throws {
        assertConversion(-40.0, from: .temperature(.celsius), to: .temperature(.fahrenheit), expected: -40.0)
        assertConversion(-10.0, from: .length(.meters), to: .length(.feet), expected: -32.8084, accuracy: 0.001)
    }

    func testConvertLargeValues() throws {
        assertConversion(1.0, from: .length(.lightYears), to: .length(.kilometers), expected: 9.461e+12, accuracy: 1e+9)
    }

    func testConvertSmallValues() throws {
        assertConversion(1.0, from: .length(.nanometers), to: .length(.meters), expected: 1e-9, accuracy: 1e-15)
    }

    // MARK: - Model Integration

    func testConversionModeDigitInput() throws {
        let calc = CalculatorModel()
        calc.setMode(.convert)
        XCTAssertEqual(calc.sourceText, "0")
        XCTAssertEqual(calc.targetText, "0")

        calc.inputDigit(5)
        XCTAssertEqual(calc.sourceText, "5")
        let sourceValue = Double(calc.sourceText) ?? 0
        XCTAssertEqual(sourceValue, 5.0)
    }

    func testConversionModeClear() throws {
        let calc = CalculatorModel()
        calc.setMode(.convert)
        calc.inputDigit(1)
        calc.inputDigit(2)
        calc.inputDigit(3)
        XCTAssertEqual(calc.sourceText, "123")
        calc.inputClear()
        XCTAssertEqual(calc.sourceText, "0")
        XCTAssertEqual(calc.targetText, "0")
    }

    func testCategorySwitchResetsUnits() throws {
        let calc = CalculatorModel()
        calc.setMode(.convert)
        let initialCategory = calc.conversionCategory
        let initialSource = calc.sourceUnit

        let newCategory: ConversionCategory = initialCategory == .length ? .weight : .length
        calc.selectCategory(newCategory)
        XCTAssertEqual(calc.conversionCategory, newCategory)
        XCTAssertNotEqual(calc.sourceUnit, initialSource)
    }

    func testUnitSwap() throws {
        let calc = CalculatorModel()
        calc.setMode(.convert)
        let originalSource = calc.sourceUnit
        let originalTarget = calc.targetUnit
        calc.inputDigit(1)
        calc.inputDigit(0)
        let originalSourceText = calc.sourceText
        let originalTargetText = calc.targetText

        calc.swapUnits()

        XCTAssertEqual(calc.sourceUnit, originalTarget)
        XCTAssertEqual(calc.targetUnit, originalSource)
        XCTAssertEqual(calc.sourceText, originalTargetText)
        XCTAssertEqual(calc.targetText, originalSourceText)
    }
}

struct TestData : Codable, Hashable {
    var testModuleName: String
}
