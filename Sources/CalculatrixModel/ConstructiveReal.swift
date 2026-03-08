import Foundation

// MARK: - Constructive Real (CR)

/// A constructive (computable) real number.
///
/// Each CR represents a real number `x` via a function `approximate(precision:) -> BigInt`
/// where the result `a` satisfies `|a - x * 2^(-precision)| < 1`.
/// Computation is lazy — creating a CR is O(1), evaluation happens on demand.
///
/// Based on Boehm's crcalc library (Google Android Calculator).
open class CR: @unchecked Sendable {
    /// Cached approximation value.
    private var cachedApprox: BigInt? = nil
    /// Precision at which cachedApprox was computed.
    private var cachedPrecision: Int = Int.min

    /// Subclasses override this to compute the approximation.
    /// Must return a BigInt `a` such that `|a - trueValue * 2^(-precision)| < 1`.
    open func approximate(precision: Int) -> BigInt {
        return BigInt.zero // Base class returns 0
    }

    /// Evaluate at the given precision, using cache if possible.
    public func evaluate(precision: Int) -> BigInt {
        if let cached = cachedApprox, cachedPrecision <= precision {
            // We have a result at equal or better (lower) precision
            // Scale: cached ≈ value * 2^(-cachedPrecision), want value * 2^(-precision)
            // result = cached / 2^(precision - cachedPrecision)
            let scaledResult = cached.shiftRight(precision - cachedPrecision)
            return scaledResult
        }
        let result = approximate(precision: precision)
        cachedApprox = result
        cachedPrecision = precision
        return result
    }

    /// Most significant digit position (floor(log2(|value|))).
    /// Returns Int.min if the value appears to be zero.
    public func msd(precision: Int) -> Int {
        var prec = 0
        while prec > precision {
            let approx = evaluate(precision: prec)
            let len = approx.abs().bitLength
            if len > 1 {
                return prec + len - 1
            }
            prec = prec - 16
        }
        return Int.min
    }

    /// Convert to Double (compute at ~53 bits of precision).
    public func toDouble() -> Double {
        let prec = -60
        let approx = evaluate(precision: prec)
        return approx.toDouble() * pow(2.0, Double(prec))
    }

    /// Convert to a decimal string with `digits` significant digits.
    public func toStringTruncated(digits: Int) -> String {
        let d = toDouble()
        if d.isNaN || d.isInfinite { return "Error" }
        if d == 0.0 { return "0" }
        var str = String(format: "%.\(digits)g", d)
        // Remove trailing zeros after decimal point
        if str.contains(".") && !str.lowercased().contains("e") {
            while str.hasSuffix("0") {
                str = String(str.dropLast())
            }
            if str.hasSuffix(".") {
                str = String(str.dropLast())
            }
        }
        return str
    }

    // MARK: - Factory Methods

    public static func fromInt(_ n: Int) -> CR {
        return IntCR(BigInt.fromInt(n))
    }

    public static func fromBigInt(_ n: BigInt) -> CR {
        return IntCR(n)
    }

    public static func fromBoundedRational(_ r: BoundedRational) -> CR {
        if r.den.compareTo(BigInt.one) == 0 {
            return IntCR(r.num)
        }
        // a/b as CR: evaluate a * 2^(-p) / b
        return RationalCR(r)
    }

    // MARK: - Operations (return lazy CR objects)

    public func add(_ other: CR) -> CR {
        return AddCR(self, other)
    }

    public func subtract(_ other: CR) -> CR {
        return AddCR(self, NegCR(other))
    }

    public func negate() -> CR {
        return NegCR(self)
    }

    public func multiply(_ other: CR) -> CR {
        return MultCR(self, other)
    }

    public func inverse() -> CR {
        return InvCR(self)
    }

    public func shiftLeftCR(_ n: Int) -> CR {
        return ShiftCR(self, n)
    }

    public func crSqrt() -> CR {
        return SqrtCR(self)
    }

    // MARK: - Transcendental Functions

    public static let pi: CR = GLPiCR()

    public static let e: CR = PrescaledExpCR(fromInt(1))

    public static func crExp(_ x: CR) -> CR {
        // Argument reduction: e^x = (e^(x/2^k))^(2^k) where |x/2^k| <= 1
        let xMsd = x.msd(precision: -100)
        if xMsd == Int.min {
            // x ≈ 0, e^0 = 1
            return fromInt(1)
        }
        let k = xMsd > 0 ? xMsd + 1 : 0
        let reduced = x.shiftLeftCR(-k) // x / 2^k
        var result: CR = PrescaledExpCR(reduced)
        // Square k times
        var i = 0
        while i < k {
            result = result.multiply(result)
            i += 1
        }
        return result
    }

    public static func crLn(_ x: CR) -> CR {
        // Use ln(x) = 2 * atanh((x-1)/(x+1))
        // First, argument reduction: x = m * 2^k, ln(x) = ln(m) + k*ln(2)
        let xMsd = x.msd(precision: -100)
        if xMsd == Int.min {
            // x ≈ 0, ln(0) is undefined. Return a large negative number.
            return fromInt(-1000000)
        }

        // Reduce to [0.5, 1)
        let reduced = x.shiftLeftCR(-xMsd - 1) // x / 2^(xMsd+1), should be in [0.5, 1)
        let k = xMsd + 1

        // ln(reduced) using atanh series
        // ln(r) = 2 * atanh((r-1)/(r+1))
        let rMinus1 = reduced.subtract(fromInt(1))
        let rPlus1 = reduced.add(fromInt(1))
        let ratio = rMinus1.multiply(rPlus1.inverse())
        let lnReduced = PrescaledAtanhLnCR(ratio)

        if k == 0 {
            return lnReduced
        }

        // ln(x) = lnReduced + k * ln(2)
        let ln2 = computeLn2()
        let kLn2 = ln2.multiply(fromInt(k))
        return lnReduced.add(kLn2)
    }

    /// Compute ln(2) via 2*atanh(1/3): ln(2) = 2*atanh(1/3)
    private static func computeLn2() -> CR {
        // atanh(1/3) = sum of (1/3)^(2k+1)/(2k+1) for k=0,1,...
        // ln(2) = 2 * atanh(1/3)
        let oneThird = fromInt(1).multiply(fromInt(3).inverse())
        return PrescaledAtanhLnCR(oneThird)
    }

    public static func crSin(_ x: CR) -> CR {
        return SinCosCR(x, isCos: false)
    }

    public static func crCos(_ x: CR) -> CR {
        return SinCosCR(x, isCos: true)
    }

    public static func crAtan(_ x: CR) -> CR {
        let xMsd = x.msd(precision: -100)
        if xMsd == Int.min {
            return fromInt(0) // atan(0) = 0
        }
        if xMsd < -1 {
            // |x| < 0.5, Taylor series converges well
            return PrescaledAtanCR(x)
        }
        // Argument reduction: atan(x) = 2*atan(x/(1+sqrt(1+x²)))
        // This halves the argument, converging quickly to the small-x regime
        let x2 = x.multiply(x)
        let sqrt1plusx2 = fromInt(1).add(x2).crSqrt()
        let reduced = x.multiply(fromInt(1).add(sqrt1plusx2).inverse())
        return crAtan(reduced).shiftLeftCR(1) // multiply by 2
    }

    public static func crAsin(_ x: CR) -> CR {
        // asin(x) = atan(x / sqrt(1 - x^2))
        let x2 = x.multiply(x)
        let oneMinusX2 = fromInt(1).subtract(x2)
        let denominator = oneMinusX2.crSqrt()
        return crAtan(x.multiply(denominator.inverse()))
    }

    public static func crAcos(_ x: CR) -> CR {
        // acos(x) = pi/2 - asin(x)
        return pi.shiftLeftCR(-1).subtract(crAsin(x))
    }
}

// MARK: - Subclasses

/// A CR wrapping an integer constant.
internal class IntCR: CR {
    let value: BigInt

    init(_ value: BigInt) {
        self.value = value
    }

    override func approximate(precision: Int) -> BigInt {
        // Return value * 2^(-precision)
        return value.shiftRight(precision)
    }
}

/// A CR wrapping a BoundedRational.
internal class RationalCR: CR {
    let rational: BoundedRational

    init(_ rational: BoundedRational) {
        self.rational = rational
    }

    override func approximate(precision: Int) -> BigInt {
        // Return (num/den) * 2^(-precision)
        if precision >= 0 {
            // (num/den) / 2^precision
            return rational.num.divide(rational.den.shiftLeft(precision))
        } else {
            // (num/den) * 2^|precision|
            let shifted = rational.num.multiply(BigInt.powerOfTwo(-precision))
            return shifted.divide(rational.den)
        }
    }
}

/// Addition: a + b
internal class AddCR: CR {
    let left: CR
    let right: CR

    init(_ left: CR, _ right: CR) {
        self.left = left
        self.right = right
    }

    override func approximate(precision: Int) -> BigInt {
        // Evaluate both at one extra bit of precision, then shift and add
        let aApprox = left.evaluate(precision: precision - 2)
        let bApprox = right.evaluate(precision: precision - 2)
        let sum = aApprox.add(bApprox)
        // Scale back: divide by 4 (shift right 2), adding 1 for rounding
        return sum.add(BigInt.two).shiftRight(2)
    }
}

/// Negation: -a
internal class NegCR: CR {
    let operand: CR

    init(_ operand: CR) {
        self.operand = operand
    }

    override func approximate(precision: Int) -> BigInt {
        return operand.evaluate(precision: precision).negate()
    }
}

/// Multiplication: a * b
internal class MultCR: CR {
    let left: CR
    let right: CR

    init(_ left: CR, _ right: CR) {
        self.left = left
        self.right = right
    }

    override func approximate(precision: Int) -> BigInt {
        let leftMsd = left.msd(precision: precision - 10)
        let rightMsd = right.msd(precision: precision - 10)
        if leftMsd == Int.min || rightMsd == Int.min {
            return BigInt.zero
        }
        // Request extra precision from each operand based on the other's magnitude
        let leftPrec = precision - rightMsd - 4
        let rightPrec = precision - leftMsd - 4
        let aApprox = left.evaluate(precision: leftPrec)
        let bApprox = right.evaluate(precision: rightPrec)
        let product = aApprox.multiply(bApprox)
        // product ≈ left*right * 2^(-leftPrec-rightPrec), want * 2^(-precision)
        let shift = precision - leftPrec - rightPrec
        return product.shiftRight(shift)
    }
}

/// Inverse: 1/a
internal class InvCR: CR {
    let operand: CR

    init(_ operand: CR) {
        self.operand = operand
    }

    override func approximate(precision: Int) -> BigInt {
        let opMsd = operand.msd(precision: precision)
        if opMsd == Int.min {
            // Attempting to invert zero — return a large value
            return BigInt.fromInt(Int.max / 2)
        }
        // We need operand at precision that gives us enough bits for accuracy.
        // Error analysis: need opPrec < precision + 2*opMsd for error < 1.
        // Use margin of 2 for safety.
        let opPrec = precision - 2 * opMsd - 2
        let opApprox = operand.evaluate(precision: opPrec)
        if opApprox.isZero {
            return BigInt.fromInt(Int.max / 2)
        }
        // 1/operand ≈ 2^(-opPrec) / opApprox, scaled to 2^(-precision)
        // result = 2^(-opPrec - precision) / opApprox
        let shift = -opPrec - precision
        if shift < 0 {
            return BigInt.zero
        }
        let numerator = BigInt.powerOfTwo(shift)
        return numerator.divide(opApprox)
    }
}

/// Shift: a * 2^n
internal class ShiftCR: CR {
    let operand: CR
    let shiftAmount: Int

    init(_ operand: CR, _ shiftAmount: Int) {
        self.operand = operand
        self.shiftAmount = shiftAmount
    }

    override func approximate(precision: Int) -> BigInt {
        return operand.evaluate(precision: precision - shiftAmount)
    }
}

/// Square root: √a (Newton's method)
internal class SqrtCR: CR {
    let operand: CR

    init(_ operand: CR) {
        self.operand = operand
    }

    override func approximate(precision: Int) -> BigInt {
        let opMsd = operand.msd(precision: precision - 10)
        if opMsd == Int.min {
            return BigInt.zero
        }

        // Compute sqrt using Newton's method with increasing precision
        let targetPrec = precision - 2

        // Get initial estimate from double
        let roughPrec = -60
        let roughApprox = operand.evaluate(precision: roughPrec)
        let roughDouble = roughApprox.toDouble() * pow(2.0, Double(roughPrec))
        if roughDouble <= 0 { return BigInt.zero }
        var estimate = sqrt(roughDouble)
        if estimate == 0.0 { estimate = 1e-100 }

        // Convert estimate to BigInt at target precision
        // estimate ≈ sqrt(operand), we want result * 2^(-targetPrec) ≈ estimate
        var x = BigInt.fromString(String(format: "%.0f", estimate * pow(2.0, Double(-targetPrec))))
        if x.isZero { x = BigInt.one }

        // Newton iterations: x = (x + operand/x) / 2
        // Operand at target precision: opVal = operand * 2^(-2*targetPrec)
        let opVal = operand.evaluate(precision: 2 * targetPrec)

        var iterations = 0
        let maxIterations = 100
        while iterations < maxIterations {
            // new_x = (x + opVal / x) / 2
            let xDiv = opVal.divide(x)
            let sum = x.add(xDiv)
            let newX = sum.shiftRight(1)
            // Check convergence
            let diff = newX.subtract(x).abs()
            if diff.compareTo(BigInt.one) <= 0 {
                break
            }
            x = newX
            iterations += 1
        }

        // x is at targetPrec, adjust to precision
        return x.shiftRight(precision - targetPrec)
    }
}

/// Pi via Gauss-Legendre algorithm (fast convergence).
/// Falls back to Machin's formula for simplicity.
internal class GLPiCR: CR {
    override func approximate(precision: Int) -> BigInt {
        // Machin's formula: pi/4 = 4*atan(1/5) - atan(1/239)
        let one = CR.fromInt(1)
        let five = CR.fromInt(5)
        let two39 = CR.fromInt(239)
        let four = CR.fromInt(4)

        let atan1_5 = CR.crAtan(one.multiply(five.inverse()))
        let atan1_239 = CR.crAtan(one.multiply(two39.inverse()))

        let piCR = four.multiply(four.multiply(atan1_5).subtract(atan1_239))
        return piCR.evaluate(precision: precision)
    }
}

/// Prescaled exp: e^x for |x| ≤ 1, via Taylor series.
/// e^x = 1 + x + x²/2! + x³/3! + ...
internal class PrescaledExpCR: CR {
    let operand: CR

    init(_ operand: CR) {
        self.operand = operand
    }

    override func approximate(precision: Int) -> BigInt {
        // Number of Taylor terms needed: we need |x^n/n!| < 2^precision
        // For |x| <= 1, this is roughly n! > 2^(-precision), so n ≈ -precision / 2
        let iterPrec = precision - 4
        let neededTerms = (-iterPrec / 2) + 10
        let terms = neededTerms < 10 ? 10 : neededTerms

        // Evaluate at higher precision for intermediate computation
        let workPrec = iterPrec - 10
        let xApprox = operand.evaluate(precision: workPrec)

        // Taylor series in fixed point: all values scaled by 2^(-workPrec)
        var sum = BigInt.powerOfTwo(-workPrec) // 1.0 scaled
        var term = sum // x^0/0! = 1
        var n = 1
        while n <= terms {
            // term = term * x / n
            term = term.multiply(xApprox).divide(BigInt.powerOfTwo(-workPrec)).divide(BigInt.fromInt(n))
            sum = sum.add(term)
            if term.abs().isZero { break }
            n += 1
        }

        // Scale from workPrec to precision: sum is at workPrec, want precision
        return sum.shiftRight(precision - workPrec)
    }
}

/// atanh-based ln: ln(x) ≈ 2 * atanh(ratio) where ratio = (x-1)/(x+1)
/// Uses: atanh(r) = r + r³/3 + r⁵/5 + ...
internal class PrescaledAtanhLnCR: CR {
    let ratio: CR // should be in (-1, 1)

    init(_ ratio: CR) {
        self.ratio = ratio
    }

    override func approximate(precision: Int) -> BigInt {
        let workPrec = precision - 10
        let rApprox = ratio.evaluate(precision: workPrec)
        let rSquared = rApprox.multiply(rApprox).shiftRight(-workPrec)
        let scaleFactor = BigInt.powerOfTwo(-workPrec)

        // atanh(r) = sum of r^(2k+1)/(2k+1)
        var sum = rApprox // first term: r
        var powerR = rApprox // r^(2k+1), starts at r
        var k = 1
        let maxTerms = (-workPrec) + 20
        while k <= maxTerms {
            // powerR *= r^2
            powerR = powerR.multiply(rSquared).divide(scaleFactor)
            let term = powerR.divide(BigInt.fromInt(2 * k + 1))
            if term.abs().isZero { break }
            sum = sum.add(term)
            k += 1
        }

        // Multiply by 2 for ln
        sum = sum.shiftLeft(1)

        // Scale from workPrec to precision
        return sum.shiftRight(precision - workPrec)
    }
}

/// Sin/Cos via Taylor series with argument reduction.
/// sin(x) = x - x³/3! + x⁵/5! - ...
/// cos(x) = 1 - x²/2! + x⁴/4! - ...
internal class SinCosCR: CR {
    let operand: CR
    let isCos: Bool

    init(_ operand: CR, isCos: Bool) {
        self.operand = operand
        self.isCos = isCos
    }

    override func approximate(precision: Int) -> BigInt {
        // Argument reduction: reduce x modulo 2*pi, then use half-angle formulas
        // sin(2a) = 2*sin(a)*cos(a), cos(2a) = 2*cos²(a) - 1

        let workPrec = precision - 10

        // Get pi at working precision
        let piCR = CR.pi
        let twoPiCR = piCR.shiftLeftCR(1)

        // Reduce x to [0, 2*pi)
        // x_reduced = x - floor(x / (2*pi)) * 2*pi
        let xDouble = operand.toDouble()
        let twoPi = 2.0 * Double.pi
        var reduced = xDouble
        if abs(reduced) > twoPi {
            reduced = reduced - floor(reduced / twoPi) * twoPi
        }

        // Further reduce using half-angle: compute at x/2^k where k makes |x/2^k| < 0.5
        var k = 0
        var reducedAbs = abs(reduced)
        while reducedAbs > 0.5 {
            reducedAbs = reducedAbs / 2.0
            k += 1
        }

        // Compute sin and cos of the reduced angle via CR
        let reducedCR: CR
        if k > 0 {
            let divisor = BigInt.powerOfTwo(k)
            // x / 2^k, but with proper CR argument reduction
            let floorVal = floor(xDouble / twoPi)
            let remainderCR = operand.subtract(twoPiCR.multiply(CR.fromInt(Int(floorVal))))
            reducedCR = remainderCR.shiftLeftCR(-k)
        } else {
            let floorVal = floor(xDouble / twoPi)
            if floorVal == 0.0 {
                reducedCR = operand
            } else {
                reducedCR = operand.subtract(twoPiCR.multiply(CR.fromInt(Int(floorVal))))
            }
        }

        // Taylor series for sin/cos of small angle
        let xApprox = reducedCR.evaluate(precision: workPrec)
        let scaleFactor = BigInt.powerOfTwo(-workPrec)
        let xSquared = xApprox.multiply(xApprox).divide(scaleFactor)

        var sinSum: BigInt
        var cosSum: BigInt

        // cos = 1 - x²/2! + x⁴/4! - ...
        cosSum = scaleFactor // 1.0
        var cosTerm = scaleFactor
        var cosN = 1
        while cosN <= 50 {
            // cosTerm *= -x² / ((2n-1)(2n))
            cosTerm = cosTerm.multiply(xSquared).divide(scaleFactor)
            cosTerm = cosTerm.negate().divide(BigInt.fromInt((2 * cosN - 1) * (2 * cosN)))
            cosSum = cosSum.add(cosTerm)
            if cosTerm.abs().isZero { break }
            cosN += 1
        }

        // sin = x - x³/3! + x⁵/5! - ...
        sinSum = xApprox
        var sinTerm = xApprox
        var sinN = 1
        while sinN <= 50 {
            sinTerm = sinTerm.multiply(xSquared).divide(scaleFactor)
            sinTerm = sinTerm.negate().divide(BigInt.fromInt((2 * sinN) * (2 * sinN + 1)))
            sinSum = sinSum.add(sinTerm)
            if sinTerm.abs().isZero { break }
            sinN += 1
        }

        // Reconstruct using double-angle formulas k times
        var sinVal = sinSum
        var cosVal = cosSum
        var step = 0
        while step < k {
            // sin(2a) = 2*sin(a)*cos(a)
            let newSin = sinVal.multiply(cosVal).shiftLeft(1).divide(scaleFactor)
            // cos(2a) = 2*cos²(a) - 1
            let newCos = cosVal.multiply(cosVal).shiftLeft(1).divide(scaleFactor).subtract(scaleFactor)
            sinVal = newSin
            cosVal = newCos
            step += 1
        }

        let result = isCos ? cosVal : sinVal
        // Scale from workPrec to precision
        return result.shiftRight(precision - workPrec)
    }
}

/// Prescaled atan: atan(x) for |x| < 1 via Taylor series.
/// atan(x) = x - x³/3 + x⁵/5 - ...
internal class PrescaledAtanCR: CR {
    let operand: CR

    init(_ operand: CR) {
        self.operand = operand
    }

    override func approximate(precision: Int) -> BigInt {
        let workPrec = precision - 10
        let xApprox = operand.evaluate(precision: workPrec)
        let scaleFactor = BigInt.powerOfTwo(-workPrec)
        let xSquared = xApprox.multiply(xApprox).divide(scaleFactor)

        var sum = xApprox // first term: x
        var powerX = xApprox
        var k = 1
        let maxTerms = (-workPrec) + 20
        while k <= maxTerms {
            // powerX *= -x²
            powerX = powerX.multiply(xSquared).negate().divide(scaleFactor)
            let term = powerX.divide(BigInt.fromInt(2 * k + 1))
            if term.abs().isZero { break }
            sum = sum.add(term)
            k += 1
        }

        // Scale from workPrec to precision
        return sum.shiftRight(precision - workPrec)
    }
}
