import XCTest
@testable import CalculatrixModel

@available(macOS 13, *)
final class BigIntTests: XCTestCase {

    // MARK: - Basic Construction

    func testFromInt() {
        let a = BigInt.fromInt(0)
        XCTAssertTrue(a.isZero)
        XCTAssertEqual(a.description, "0")

        let b = BigInt.fromInt(42)
        XCTAssertEqual(b.description, "42")

        let c = BigInt.fromInt(-99)
        XCTAssertEqual(c.description, "-99")
        XCTAssertTrue(c.isNeg)
    }

    func testFromString() {
        let a = BigInt.fromString("123456789012345678901234567890")
        XCTAssertEqual(a.description, "123456789012345678901234567890")

        let b = BigInt.fromString("-999999999999999999")
        XCTAssertTrue(b.isNeg)
        XCTAssertEqual(b.description, "-999999999999999999")
    }

    // MARK: - Arithmetic

    func testAddition() {
        let a = BigInt.fromInt(123)
        let b = BigInt.fromInt(456)
        XCTAssertEqual(a.add(b).description, "579")

        // Negative
        let c = BigInt.fromInt(-100)
        XCTAssertEqual(a.add(c).description, "23")

        // Large numbers
        let d = BigInt.fromString("999999999999999999")
        let e = BigInt.fromInt(1)
        XCTAssertEqual(d.add(e).description, "1000000000000000000")
    }

    func testSubtraction() {
        let a = BigInt.fromInt(456)
        let b = BigInt.fromInt(123)
        XCTAssertEqual(a.subtract(b).description, "333")

        // Result negative
        XCTAssertEqual(b.subtract(a).description, "-333")
    }

    func testMultiplication() {
        let a = BigInt.fromInt(123)
        let b = BigInt.fromInt(456)
        XCTAssertEqual(a.multiply(b).description, "56088")

        // Large multiply
        let c = BigInt.fromString("999999999")
        XCTAssertEqual(c.multiply(c).description, "999999998000000001")

        // Multiply by zero
        XCTAssertTrue(a.multiply(BigInt.zero).isZero)

        // Negative
        let d = BigInt.fromInt(-7)
        XCTAssertEqual(a.multiply(d).description, "-861")
    }

    func testDivision() {
        let a = BigInt.fromInt(17)
        let b = BigInt.fromInt(5)
        XCTAssertEqual(a.divide(b).description, "3")
        XCTAssertEqual(a.remainder(b).description, "2")

        // Exact division
        let c = BigInt.fromInt(100)
        let d = BigInt.fromInt(25)
        XCTAssertEqual(c.divide(d).description, "4")
        XCTAssertTrue(c.remainder(d).isZero)

        // Large division
        let e = BigInt.fromString("1000000000000000000")
        let f = BigInt.fromString("999999999999999999")
        XCTAssertEqual(e.divide(f).description, "1")
        XCTAssertEqual(e.remainder(f).description, "1")
    }

    func testPower() {
        let two = BigInt.fromInt(2)
        XCTAssertEqual(two.power(0).description, "1")
        XCTAssertEqual(two.power(1).description, "2")
        XCTAssertEqual(two.power(10).description, "1024")
        XCTAssertEqual(two.power(32).description, "4294967296")
    }

    func testGCD() {
        XCTAssertEqual(BigInt.gcd(BigInt.fromInt(12), BigInt.fromInt(8)).description, "4")
        XCTAssertEqual(BigInt.gcd(BigInt.fromInt(17), BigInt.fromInt(13)).description, "1")
        XCTAssertEqual(BigInt.gcd(BigInt.fromInt(100), BigInt.fromInt(75)).description, "25")
    }

    func testComparison() {
        let a = BigInt.fromInt(42)
        let b = BigInt.fromInt(43)
        XCTAssertTrue(a.compareTo(b) < 0)
        XCTAssertTrue(b.compareTo(a) > 0)
        XCTAssertTrue(a.compareTo(a) == 0)

        // Negative comparisons
        let c = BigInt.fromInt(-10)
        let d = BigInt.fromInt(10)
        XCTAssertTrue(c.compareTo(d) < 0)
    }

    func testBitLength() {
        XCTAssertEqual(BigInt.fromInt(0).bitLength, 0)
        XCTAssertEqual(BigInt.fromInt(1).bitLength, 1)
        XCTAssertEqual(BigInt.fromInt(255).bitLength, 8)
        XCTAssertEqual(BigInt.fromInt(256).bitLength, 9)
    }

    func testShiftLeft() {
        let a = BigInt.fromInt(1)
        XCTAssertEqual(a.shiftLeft(10).description, "1024")
        XCTAssertEqual(a.shiftLeft(20).description, "1048576")
    }

    func testShiftRight() {
        let a = BigInt.fromInt(1024)
        XCTAssertEqual(a.shiftRight(10).description, "1")
        XCTAssertEqual(a.shiftRight(5).description, "32")
    }
}

@available(macOS 13, *)
final class BoundedRationalTests: XCTestCase {

    // MARK: - Construction

    func testFromInt() {
        let r = BoundedRational.fromInt(42)
        XCTAssertEqual(r.num.description, "42")
        XCTAssertEqual(r.den.description, "1")
        XCTAssertTrue(r.isInteger)
    }

    func testFromDecimalString() {
        let r = BoundedRational.fromDecimalString("123.456")
        XCTAssertNotNil(r)
        // 123.456 = 123456/1000 = 15432/125
        XCTAssertEqual(r!.num.description, "15432")
        XCTAssertEqual(r!.den.description, "125")
    }

    func testReduction() {
        // 6/4 should reduce to 3/2
        let r = BoundedRational(BigInt.fromInt(6), BigInt.fromInt(4))
        XCTAssertEqual(r.num.description, "3")
        XCTAssertEqual(r.den.description, "2")
    }

    // MARK: - Exact Arithmetic

    func testOneThirdTimesThree() {
        // 1/3 * 3 = 1 (exact, unlike Double)
        let oneThird = BoundedRational(BigInt.one, BigInt.fromInt(3))
        let three = BoundedRational.fromInt(3)
        let result = BoundedRational.multiply(oneThird, three)
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.compareTo(BoundedRational.one), 0)
    }

    func testOneThirdPlusOneThirdPlusOneThird() {
        // 1/3 + 1/3 + 1/3 = 1 (exact)
        let oneThird = BoundedRational(BigInt.one, BigInt.fromInt(3))
        let twoThirds = BoundedRational.add(oneThird, oneThird)
        XCTAssertNotNil(twoThirds)
        let one = BoundedRational.add(twoThirds!, oneThird)
        XCTAssertNotNil(one)
        XCTAssertEqual(one!.compareTo(BoundedRational.one), 0)
    }

    func testOneSeventh() {
        // 1/7 * 7 = 1 (exact)
        let oneSeventh = BoundedRational(BigInt.one, BigInt.fromInt(7))
        let seven = BoundedRational.fromInt(7)
        let result = BoundedRational.multiply(oneSeventh, seven)
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.compareTo(BoundedRational.one), 0)
    }

    func testDivisionExact() {
        let a = BoundedRational.fromInt(10)
        let b = BoundedRational.fromInt(3)
        let r = BoundedRational.divide(a, b)
        XCTAssertNotNil(r)
        // 10/3 * 3 = 10
        let back = BoundedRational.multiply(r!, b)
        XCTAssertNotNil(back)
        XCTAssertEqual(back!.compareTo(a), 0)
    }

    func testDivisionByZero() {
        let result = BoundedRational.divide(BoundedRational.one, BoundedRational.zero)
        XCTAssertNil(result)
    }

    func testPerfectSquareRoot() {
        // sqrt(25) = 5
        let twentyFive = BoundedRational.fromInt(25)
        let result = BoundedRational.sqrt(twentyFive)
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.compareTo(BoundedRational.fromInt(5)), 0)

        // sqrt(4/9) = 2/3
        let fourNinths = BoundedRational(BigInt.fromInt(4), BigInt.fromInt(9))
        let sqrtResult = BoundedRational.sqrt(fourNinths)
        XCTAssertNotNil(sqrtResult)
        let expected = BoundedRational(BigInt.fromInt(2), BigInt.fromInt(3))
        XCTAssertEqual(sqrtResult!.compareTo(expected), 0)
    }

    func testNonPerfectSquareRoot() {
        // sqrt(2) is irrational — should return nil
        let result = BoundedRational.sqrt(BoundedRational.fromInt(2))
        XCTAssertNil(result)
    }

    func testToDecimalString() {
        let oneThird = BoundedRational(BigInt.one, BigInt.fromInt(3))
        let s = oneThird.toDecimalString(maxDigits: 10)
        XCTAssertEqual(s, "0.3333333333")

        let half = BoundedRational.half
        XCTAssertEqual(half.toDecimalString(maxDigits: 10), "0.5")
    }

    func testIntPower() {
        let two = BoundedRational.fromInt(2)
        let result = BoundedRational.intPow(two, 10)
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.compareTo(BoundedRational.fromInt(1024)), 0)

        // Negative exponent: 2^(-1) = 1/2
        let half = BoundedRational.intPow(two, -1)
        XCTAssertNotNil(half)
        XCTAssertEqual(half!.compareTo(BoundedRational.half), 0)
    }
}

@available(macOS 13, *)
final class ConstructiveRealTests: XCTestCase {

    // MARK: - Basic Operations

    func testIntCR() {
        let cr = CR.fromInt(42)
        let approx = cr.evaluate(precision: 0)
        XCTAssertEqual(approx.compareTo(BigInt.fromInt(42)), 0)
    }

    func testAddCR() {
        let a = CR.fromInt(100)
        let b = CR.fromInt(200)
        let sum = a.add(b)
        let approx = sum.evaluate(precision: 0)
        XCTAssertEqual(approx.compareTo(BigInt.fromInt(300)), 0)
    }

    func testMultCR() {
        let a = CR.fromInt(12)
        let b = CR.fromInt(13)
        let product = a.multiply(b)
        let approx = product.evaluate(precision: 0)
        XCTAssertEqual(approx.compareTo(BigInt.fromInt(156)), 0)
    }

    func testInverseCR() {
        let a = CR.fromInt(4)
        let inv = a.inverse()
        // 1/4 at precision -10 should be 2^10/4 = 256
        let approx = inv.evaluate(precision: -10)
        let expected = BigInt.fromInt(256)
        // Allow ±1 for rounding
        let diff = approx.subtract(expected).abs()
        XCTAssertTrue(diff.compareTo(BigInt.fromInt(2)) <= 0)
    }

    // MARK: - Transcendentals

    func testPiApproximation() {
        let pi = CR.pi
        let d = pi.toDouble()
        XCTAssertEqual(d, Double.pi, accuracy: 1e-10)
    }

    func testEApproximation() {
        let e = CR.e
        let d = e.toDouble()
        let expected = 2.718281828459045
        XCTAssertEqual(d, expected, accuracy: 1e-10)
    }

    func testSqrtTwo() {
        let two = CR.fromInt(2)
        let sqrt2 = two.crSqrt()
        let d = sqrt2.toDouble()
        XCTAssertEqual(d, sqrt(2.0), accuracy: 1e-10)
    }

    func testExpOne() {
        let one = CR.fromInt(1)
        let exp1 = CR.crExp(one)
        let d = exp1.toDouble()
        XCTAssertEqual(d, 2.718281828459045, accuracy: 1e-10)
    }

    func testLnE() {
        let e = CR.e
        let lnE = CR.crLn(e)
        let d = lnE.toDouble()
        XCTAssertEqual(d, 1.0, accuracy: 1e-10)
    }

    func testSinPi() {
        let pi = CR.pi
        let sinPi = CR.crSin(pi)
        let d = sinPi.toDouble()
        XCTAssertEqual(d, 0.0, accuracy: 1e-10)
    }

    func testCosPi() {
        let pi = CR.pi
        let cosPi = CR.crCos(pi)
        let d = cosPi.toDouble()
        XCTAssertEqual(d, -1.0, accuracy: 1e-10)
    }

    func testToStringPi() {
        let pi = CR.pi
        let s = pi.toStringTruncated(digits: 10)
        XCTAssertTrue(s.hasPrefix("3.14159265"))
    }
}

@available(macOS 13, *)
final class RealNumberTests: XCTestCase {

    // MARK: - Classic Floating Point Failures (Now Exact)

    func testPointOnePointTwoPointThree() {
        // 0.1 + 0.2 = 0.3 — the canonical floating-point failure
        let a = Real.fromDisplayString("0.1")
        let b = Real.fromDisplayString("0.2")
        let sum = a.add(b)
        let expected = Real.fromDisplayString("0.3")

        // Rational comparison should be exact
        XCTAssertTrue(sum.isRational)
        XCTAssertEqual(sum.toDisplayString(), "0.3")
        XCTAssertEqual(sum, expected)
    }

    func testOneThirdTimesThree() {
        // 1/3 * 3 = 1 (not 0.9999999...)
        let one = Real.fromInt(1)
        let three = Real.fromInt(3)
        let oneThird = one.divide(three)
        let result = oneThird.multiply(three)

        XCTAssertEqual(result.toDisplayString(), "1")
        XCTAssertTrue(result.isRational)
    }

    func testOneSeventh() {
        // 1/7 * 7 = 1 (exact)
        let one = Real.fromInt(1)
        let seven = Real.fromInt(7)
        let frac = one.divide(seven)
        let result = frac.multiply(seven)
        XCTAssertEqual(result.toDisplayString(), "1")
    }

    func testDecimalAdditionExact() {
        // 7.23 + 4.13 = 11.36 exactly
        let a = Real.fromDisplayString("7.23")
        let b = Real.fromDisplayString("4.13")
        let result = a.add(b)
        XCTAssertEqual(result.toDisplayString(), "11.36")
    }

    // MARK: - Trigonometric Exactness via Property Tags

    func testSinPiExactlyZero() {
        // sin(π) = 0 exactly (via property tag)
        let result = Real.sin(Real.piVal)
        XCTAssertTrue(result.isZero)
        XCTAssertEqual(result.toDisplayString(), "0")
    }

    func testSinTwoPiExactlyZero() {
        // sin(2π) = 0
        let twoPi = Real.piVal.multiply(Real.two)
        let result = Real.sin(twoPi)
        XCTAssertTrue(result.isZero)
    }

    func testCosPiExactlyMinusOne() {
        // cos(π) = -1
        let result = Real.cos(Real.piVal)
        XCTAssertTrue(!result.isZero)
        XCTAssertEqual(result.toDisplayString(), "-1")
    }

    func testCosTwoPiExactlyOne() {
        // cos(2π) = 1
        let twoPi = Real.piVal.multiply(Real.two)
        let result = Real.cos(twoPi)
        XCTAssertEqual(result.toDisplayString(), "1")
    }

    func testSinPiOver2ExactlyOne() {
        // sin(π/2) = 1
        let piOver2 = Real.piVal.divide(Real.two)
        let result = Real.sin(piOver2)
        XCTAssertEqual(result.toDisplayString(), "1")
    }

    func testCosPiOver2ExactlyZero() {
        // cos(π/2) = 0
        let piOver2 = Real.piVal.divide(Real.two)
        let result = Real.cos(piOver2)
        XCTAssertTrue(result.isZero)
    }

    func testTanPiOverFour() {
        // tan(π/4) = 1
        let piOver4 = Real.piVal.divide(Real.fromInt(4))
        let result = Real.tan(piOver4)
        let d = result.toDouble()
        XCTAssertEqual(d, 1.0, accuracy: 1e-10)
    }

    // MARK: - Square Root Exactness

    func testSqrtOfPerfectSquare() {
        // √4 = 2
        let result = Real.sqrt(Real.fromInt(4))
        XCTAssertEqual(result.toDisplayString(), "2")
        XCTAssertTrue(result.isRational)
    }

    func testSqrtTwoSquared() {
        // √2 * √2 should be very close to 2
        let sqrt2 = Real.sqrt(Real.fromInt(2))
        let result = sqrt2.multiply(sqrt2)
        let d = result.toDouble()
        XCTAssertEqual(d, 2.0, accuracy: 1e-10)
    }

    func testSqrtOfRationalFraction() {
        // √(9/16) = 3/4
        let nine = Real.fromInt(9)
        let sixteen = Real.fromInt(16)
        let frac = nine.divide(sixteen)
        let result = Real.sqrt(frac)
        XCTAssertTrue(result.isRational)
        XCTAssertEqual(result.toDisplayString(), "0.75")
    }

    // MARK: - Exponential/Logarithm

    func testExpZero() {
        // e^0 = 1
        let result = Real.exp_(Real.zero)
        XCTAssertEqual(result.toDisplayString(), "1")
    }

    func testLnOne() {
        // ln(1) = 0
        let result = Real.ln(Real.one)
        XCTAssertTrue(result.isZero)
    }

    func testLnE() {
        // ln(e) ≈ 1
        let result = Real.ln(Real.eVal)
        let d = result.toDouble()
        XCTAssertEqual(d, 1.0, accuracy: 1e-10)
    }

    func testExpLnRoundtrip() {
        // e^(ln(5)) = 5
        let five = Real.fromInt(5)
        let result = Real.exp_(Real.ln(five))
        let d = result.toDouble()
        XCTAssertEqual(d, 5.0, accuracy: 1e-10)
    }

    func testLog10Of1000() {
        // log10(1000) = 3
        let result = Real.log10(Real.fromInt(1000))
        let d = result.toDouble()
        XCTAssertEqual(d, 3.0, accuracy: 1e-10)
    }

    func testLog2Of1024() {
        // log2(1024) = 10
        let result = Real.log2(Real.fromInt(1024))
        let d = result.toDouble()
        XCTAssertEqual(d, 10.0, accuracy: 1e-10)
    }

    // MARK: - Power

    func testIntegerPower() {
        // 2^10 = 1024
        let result = Real.pow(Real.fromInt(2), Real.fromInt(10))
        XCTAssertEqual(result.toDisplayString(), "1024")
        XCTAssertTrue(result.isRational)
    }

    func testNegativeIntegerPower() {
        // 2^(-3) = 0.125
        let result = Real.pow(Real.fromInt(2), Real.fromInt(-3))
        XCTAssertEqual(result.toDisplayString(), "0.125")
        XCTAssertTrue(result.isRational)
    }

    func testZeroPower() {
        // x^0 = 1 for any x
        let result = Real.pow(Real.fromInt(42), Real.zero)
        XCTAssertEqual(result.toDisplayString(), "1")
    }

    // MARK: - Factorial

    func testFactorialSmall() {
        // 5! = 120
        let result = Real.factorial(Real.fromInt(5))
        XCTAssertEqual(result.toDisplayString(), "120")
    }

    func testFactorialLarger() {
        // 10! = 3628800
        let result = Real.factorial(Real.fromInt(10))
        XCTAssertEqual(result.toDisplayString(), "3628800")
    }

    func testFactorialZero() {
        // 0! = 1
        let result = Real.factorial(Real.zero)
        XCTAssertEqual(result.toDisplayString(), "1")
    }

    func testFactorialLargeNoOverflow() {
        // 170! should compute without Int64 overflow (was a bug before)
        let result = Real.factorial(Real.fromInt(170))
        XCTAssertFalse(result.isError)
        XCTAssertFalse(result.isZero)
    }

    // MARK: - Error Handling

    func testDivisionByZero() {
        let result = Real.one.divide(Real.zero)
        XCTAssertTrue(result.isError)
        XCTAssertEqual(result.toDisplayString(), "Error")
    }

    func testSqrtOfNegative() {
        let result = Real.sqrt(Real.fromInt(-1))
        XCTAssertTrue(result.isError)
    }

    func testLnOfZero() {
        let result = Real.ln(Real.zero)
        XCTAssertTrue(result.isError)
    }

    func testLnOfNegative() {
        let result = Real.ln(Real.fromInt(-5))
        XCTAssertTrue(result.isError)
    }

    // MARK: - Arithmetic Identity Properties

    func testAddZero() {
        let x = Real.fromInt(42)
        XCTAssertEqual(x.add(Real.zero).toDisplayString(), "42")
    }

    func testMultiplyOne() {
        let x = Real.fromInt(42)
        XCTAssertEqual(x.multiply(Real.one).toDisplayString(), "42")
    }

    func testMultiplyZero() {
        let x = Real.fromInt(42)
        XCTAssertTrue(x.multiply(Real.zero).isZero)
    }

    func testSubtractSelf() {
        let x = Real.fromInt(42)
        let result = x.subtract(x)
        XCTAssertTrue(result.isZero)
    }

    func testNegate() {
        let x = Real.fromInt(42)
        let neg = x.negate()
        XCTAssertTrue(neg.isNegative)
        XCTAssertEqual(neg.add(x).toDisplayString(), "0")
    }

    // MARK: - Display Formatting

    func testPiDisplay() {
        let s = Real.piVal.toDisplayString()
        XCTAssertTrue(s.hasPrefix("3.1415926"), "pi display: \(s)")
    }

    func testEDisplay() {
        let s = Real.eVal.toDisplayString()
        XCTAssertTrue(s.hasPrefix("2.7182818"), "e display: \(s)")
    }

    func testIntegerDisplay() {
        XCTAssertEqual(Real.fromInt(1000000).toDisplayString(), "1000000")
        XCTAssertEqual(Real.fromInt(0).toDisplayString(), "0")
        XCTAssertEqual(Real.fromInt(-5).toDisplayString(), "-5")
    }

    func testDecimalDisplay() {
        let r = Real.fromDisplayString("0.5")
        XCTAssertEqual(r.toDisplayString(), "0.5")
    }

    // MARK: - Hyperbolic Functions

    func testSinhZero() {
        let result = Real.sinh(Real.zero)
        XCTAssertTrue(result.isZero)
    }

    func testCoshZero() {
        let result = Real.cosh(Real.zero)
        XCTAssertEqual(result.toDisplayString(), "1")
    }

    func testTanhZero() {
        let result = Real.tanh(Real.zero)
        XCTAssertTrue(result.isZero)
    }

    // MARK: - Inverse Trig Functions

    func testAsinZero() {
        let result = Real.asin(Real.zero)
        let d = result.toDouble()
        XCTAssertEqual(d, 0.0, accuracy: 1e-10)
    }

    func testAcosOne() {
        let result = Real.acos(Real.one)
        let d = result.toDouble()
        XCTAssertEqual(d, 0.0, accuracy: 1e-10)
    }

    func testAtanOne() {
        // atan(1) = π/4
        let result = Real.atan(Real.one)
        let d = result.toDouble()
        XCTAssertEqual(d, Double.pi / 4.0, accuracy: 1e-10)
    }

    // MARK: - Percent

    func testPercent() {
        // 50% = 0.5
        let fifty = Real.fromInt(50)
        let result = fifty.percent(base: nil)
        XCTAssertEqual(result.toDisplayString(), "0.5")
    }

    func testPercentWithBase() {
        // 10% of 200 = 20
        let ten = Real.fromInt(10)
        let twoHundred = Real.fromInt(200)
        let result = ten.percent(base: twoHundred)
        XCTAssertEqual(result.toDisplayString(), "20")
    }

    // MARK: - Property Tag Propagation

    func testPiTimesRationalKeepsPiTag() {
        // 2 * π should keep the pi property
        let twoPi = Real.two.multiply(Real.piVal)
        // The property should be .pi since rational * pi = pi
        XCTAssertEqual(twoPi.property, .pi)
    }

    func testSinOfPiMultipleExact() {
        // sin(3π) = 0 (property tag: pi, rational 3 is integer)
        let threePi = Real.fromInt(3).multiply(Real.piVal)
        let result = Real.sin(threePi)
        XCTAssertTrue(result.isZero)
    }

    func testCosOfEvenPiMultiple() {
        // cos(4π) = 1
        let fourPi = Real.fromInt(4).multiply(Real.piVal)
        let result = Real.cos(fourPi)
        XCTAssertEqual(result.toDisplayString(), "1")
    }

    func testCosOfOddPiMultiple() {
        // cos(3π) = -1
        let threePi = Real.fromInt(3).multiply(Real.piVal)
        let result = Real.cos(threePi)
        XCTAssertEqual(result.toDisplayString(), "-1")
    }

    // MARK: - Calculator Workflow Simulations

    func testCalculatorSequence_0_1_plus_0_2() {
        // Simulates: user enters 0.1, presses +, enters 0.2, presses =
        let calc = CalculatorModel()
        calc.inputDigit(0)
        calc.inputDecimal()
        calc.inputDigit(1)
        calc.inputOperation(.add)
        calc.inputDigit(0)
        calc.inputDecimal()
        calc.inputDigit(2)
        calc.inputEquals()
        XCTAssertEqual(calc.displayText, "0.3")
    }

    func testCalculatorSequence_1_div_3_times_3() {
        // Simulates: 1 ÷ 3 × 3 = should show 1
        let calc = CalculatorModel()
        calc.inputDigit(1)
        calc.inputOperation(.divide)
        calc.inputDigit(3)
        calc.inputOperation(.multiply)
        calc.inputDigit(3)
        calc.inputEquals()
        XCTAssertEqual(calc.displayText, "1")
    }

    func testCalculatorSequence_SinPi() {
        // Simulates: press π, then sin — should be 0 even in degrees mode
        // because π is inherently a radian quantity
        let calc = CalculatorModel()
        calc.inputConstant("π")
        calc.inputScientificUnary("sin")
        XCTAssertEqual(calc.displayText, "0")
    }

    func testCalculatorSequence_CosPi() {
        // Simulates: press π, then cos — should be -1 even in degrees mode
        let calc = CalculatorModel()
        calc.inputConstant("π")
        calc.inputScientificUnary("cos")
        XCTAssertEqual(calc.displayText, "-1")
    }

    func testCalculatorSequence_SinPiRadians() {
        // Same test in explicit radians mode
        let calc = CalculatorModel()
        calc.toggleRadDeg()
        calc.inputConstant("π")
        calc.inputScientificUnary("sin")
        XCTAssertEqual(calc.displayText, "0")
    }

    func testCalculatorSequence_Sin90Degrees() {
        // sin(90°) = 1 in degrees mode
        let calc = CalculatorModel()
        calc.inputDigit(9)
        calc.inputDigit(0)
        calc.inputScientificUnary("sin")
        XCTAssertEqual(calc.displayText, "1")
    }

    func testCalculatorSequence_Cos180Degrees() {
        // cos(180°) = -1 in degrees mode
        let calc = CalculatorModel()
        calc.inputDigit(1)
        calc.inputDigit(8)
        calc.inputDigit(0)
        calc.inputScientificUnary("cos")
        XCTAssertEqual(calc.displayText, "-1")
    }

    func testCalculatorSequence_FactorialOf10() {
        // 10! = 3628800
        let calc = CalculatorModel()
        calc.inputDigit(1)
        calc.inputDigit(0)
        calc.inputScientificUnary("x!")
        XCTAssertEqual(calc.displayText, "3628800")
    }

    func testCalculatorSequence_10pow100_plus1_minus_10pow100() {
        // 10^100 + 1 - 10^100 = 1 (catastrophic cancellation test)
        // With Double this gives 0 due to loss of precision.
        let calc = CalculatorModel()
        calc.inputDigit(1)
        calc.inputDigit(0)
        calc.inputScientificUnary("x²") // 100
        calc.inputScientificUnary("10ˣ") // 10^100
        calc.inputOperation(.add)
        calc.inputDigit(1)
        calc.inputOperation(.subtract)
        calc.inputDigit(1)
        calc.inputDigit(0)
        calc.inputScientificUnary("x²") // 100
        calc.inputScientificUnary("10ˣ") // 10^100
        calc.inputEquals()
        XCTAssertEqual(calc.displayText, "1")
    }
}
