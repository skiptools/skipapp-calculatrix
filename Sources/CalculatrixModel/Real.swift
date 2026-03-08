import Foundation

// MARK: - Real Number Type

/// A property tag for a Real number, enabling decidable comparison
/// for common calculator expressions via the Lindemann-Weierstrass theorem.
public enum RealProperty: Hashable {
    /// Exact rational number.
    case rational
    /// Rational multiple of π.
    case pi
    /// Rational multiple of e.
    case e
    /// Square root of a rational.
    case sqrt
    /// General transcendental — comparison may be undecidable.
    case transcendental
}

/// A real number that combines exact rational arithmetic with
/// lazily-evaluated constructive reals and property tags for decidable comparison.
///
/// Following the Boehm paper "Towards an API for the Real Numbers" (PLDI 2020).
public final class Real: Hashable, CustomStringConvertible, @unchecked Sendable {
    /// The exact rational value, if available and not overflowed.
    public let rational: BoundedRational?
    /// The constructive real for lazy arbitrary-precision evaluation.
    public let cr: CR
    /// Property tag for decidable comparison.
    public let property: RealProperty
    /// Whether this represents an error (division by zero, domain error, etc.).
    public let isError: Bool

    // MARK: - Constants

    public static let zero = Real(BoundedRational.zero, CR.fromInt(0), .rational)
    public static let one = Real(BoundedRational.one, CR.fromInt(1), .rational)
    public static let minusOne = Real(BoundedRational.minusOne, CR.fromInt(-1), .rational)
    public static let two = Real(BoundedRational.two, CR.fromInt(2), .rational)
    public static let ten = Real(BoundedRational.ten, CR.fromInt(10), .rational)
    public static let piVal = Real(BoundedRational.one, CR.pi, .pi)
    public static let eVal = Real(BoundedRational.one, CR.e, .e)
    public static let error = Real.makeError()

    // MARK: - Initializers

    internal init(_ rational: BoundedRational?, _ cr: CR, _ property: RealProperty) {
        self.rational = rational
        self.cr = cr
        self.property = property
        self.isError = false
    }

    private init(errorFlag: Bool) {
        self.rational = nil
        self.cr = CR.fromInt(0)
        self.property = .rational
        self.isError = true
    }

    private static func makeError() -> Real {
        return Real(errorFlag: true)
    }

    // MARK: - Factory Methods

    public static func fromInt(_ value: Int) -> Real {
        return Real(BoundedRational.fromInt(value), CR.fromInt(value), .rational)
    }

    public static func fromBoundedRational(_ r: BoundedRational) -> Real {
        return Real(r, CR.fromBoundedRational(r), .rational)
    }

    /// Parse a user-entered string like "123.456" into an exact Real.
    public static func fromDisplayString(_ s: String) -> Real {
        if s.isEmpty || s == "Error" { return zero }
        // Handle scientific notation
        let lower = s.lowercased()
        if lower.contains("e") {
            // Fall back to Double parsing for scientific notation
            if let d = Double(s) {
                if d.isNaN || d.isInfinite { return error }
                return fromDouble(d)
            }
            return zero
        }
        if let r = BoundedRational.fromDecimalString(s) {
            return Real(r, CR.fromBoundedRational(r), .rational)
        }
        // Fallback to Double
        if let d = Double(s) {
            return fromDouble(d)
        }
        return zero
    }

    /// Create from a Double (approximate — the rational will represent
    /// the exact Double value as a binary fraction).
    public static func fromDouble(_ d: Double) -> Real {
        if d.isNaN || d.isInfinite { return error }
        if d == 0.0 { return zero }
        // Convert to exact rational: d = m * 2^e where m is integer mantissa
        let s = String(format: "%.17g", d)
        if let r = BoundedRational.fromDecimalString(s) {
            return Real(r, CR.fromBoundedRational(r), .rational)
        }
        return Real(nil, CR.fromBigInt(BigInt.fromString(s)), .transcendental)
    }

    // MARK: - Basic Properties

    /// Whether this value is exactly zero.
    public var isZero: Bool {
        if isError { return false }
        if let r = rational {
            return r.isZero
        }
        // For non-rational values with known properties, we can sometimes decide
        switch property {
        case .pi, .e:
            return false // π and e are never zero
        default:
            // Fall back to numerical evaluation
            let approx = cr.evaluate(precision: -100)
            return approx.isZero
        }
    }

    /// Whether this value is negative.
    public var isNegative: Bool {
        if isError { return false }
        if let r = rational {
            return r.isNegative
        }
        let approx = cr.evaluate(precision: -100)
        return approx.isNeg
    }

    /// Whether this value is exactly rational.
    public var isRational: Bool { property == .rational && rational != nil }

    // MARK: - Arithmetic

    public func add(_ other: Real) -> Real {
        if isError || other.isError { return Real.error }
        // Try rational fast path
        if let a = rational, let b = other.rational, property == .rational && other.property == .rational {
            if let result = BoundedRational.add(a, b) {
                return Real(result, cr.add(other.cr), .rational)
            }
        }
        // Same property (e.g., both are π multiples)
        if property == other.property && property != .transcendental {
            if let a = rational, let b = other.rational {
                if let result = BoundedRational.add(a, b) {
                    return Real(result.isZero ? BoundedRational.zero : nil, cr.add(other.cr), result.isZero ? .rational : property)
                }
            }
        }
        return Real(nil, cr.add(other.cr), .transcendental)
    }

    public func subtract(_ other: Real) -> Real {
        return add(other.negate())
    }

    public func negate() -> Real {
        if isError { return Real.error }
        let newRational = rational?.negate()
        return Real(newRational, cr.negate(), property)
    }

    public func multiply(_ other: Real) -> Real {
        if isError || other.isError { return Real.error }
        if isZero || other.isZero { return Real.zero }

        // Try rational fast path
        if let a = rational, let b = other.rational {
            if property == .rational && other.property == .rational {
                if let result = BoundedRational.multiply(a, b) {
                    return Real(result, cr.multiply(other.cr), .rational)
                }
            }
            // rational * pi = pi, etc.
            if property == .rational {
                if let result = BoundedRational.multiply(a, b) {
                    return Real(result, cr.multiply(other.cr), other.property)
                }
            }
            if other.property == .rational {
                if let result = BoundedRational.multiply(a, b) {
                    return Real(result, cr.multiply(other.cr), property)
                }
            }
        }
        return Real(nil, cr.multiply(other.cr), .transcendental)
    }

    public func divide(_ other: Real) -> Real {
        if isError || other.isError { return Real.error }
        if other.isZero { return Real.error }
        if isZero { return Real.zero }

        let newCR = cr.multiply(other.cr.inverse())
        // Try rational fast path
        if let a = rational, let b = other.rational {
            if property == .rational && other.property == .rational {
                if let result = BoundedRational.divide(a, b) {
                    return Real(result, newCR, .rational)
                }
            }
            // non-rational property / rational preserves property (e.g. pi/2)
            if other.property == .rational {
                if let result = BoundedRational.divide(a, b) {
                    return Real(result, newCR, property)
                }
            }
        }
        return Real(nil, newCR, .transcendental)
    }

    public func reciprocal() -> Real {
        return Real.one.divide(self)
    }

    public func absValue() -> Real {
        if isError { return Real.error }
        if isNegative { return negate() }
        return self
    }

    // MARK: - Power / Root

    public static func sqrt(_ x: Real) -> Real {
        if x.isError { return error }
        if x.isZero { return zero }
        if x.isNegative { return error }

        // Try rational sqrt
        if let r = x.rational, x.property == .rational {
            if let result = BoundedRational.sqrt(r) {
                return Real(result, x.cr.crSqrt(), .rational)
            }
            // Not a perfect square — mark as sqrt property
            return Real(nil, x.cr.crSqrt(), .sqrt)
        }
        return Real(nil, x.cr.crSqrt(), .transcendental)
    }

    public static func pow(_ base: Real, _ exp: Real) -> Real {
        if base.isError || exp.isError { return error }
        if exp.isZero { return one }
        if base.isZero { return zero }

        // Integer exponent
        if let expR = exp.rational, exp.property == .rational, expR.isInteger {
            if let e = expR.toInt() {
                if let baseR = base.rational, base.property == .rational {
                    if let result = BoundedRational.intPow(baseR, e) {
                        return fromBoundedRational(result)
                    }
                }
                // Fall through to CR
                if e >= 0 {
                    var result = CR.fromInt(1)
                    var b = base.cr
                    var remaining = e
                    while remaining > 0 {
                        if remaining % 2 == 1 {
                            result = result.multiply(b)
                        }
                        b = b.multiply(b)
                        remaining = remaining / 2
                    }
                    return Real(nil, result, .transcendental)
                } else {
                    // Negative integer exponent: base^(-|e|) = 1/(base^|e|)
                    let posResult = pow(base, fromInt(-e))
                    return posResult.reciprocal()
                }
            }
        }

        // General case: base^exp = e^(exp * ln(base))
        let lnBase = ln(base)
        return exp_(exp.multiply(lnBase))
    }

    // MARK: - Exponential / Logarithm

    public static func exp_(_ x: Real) -> Real {
        if x.isError { return error }
        if x.isZero { return one }
        return Real(nil, CR.crExp(x.cr), .transcendental)
    }

    public static func ln(_ x: Real) -> Real {
        if x.isError { return error }
        if x.isZero || x.isNegative { return error }
        // ln(1) = 0
        if let r = x.rational, x.property == .rational {
            if r.compareTo(BoundedRational.one) == 0 {
                return zero
            }
        }
        return Real(nil, CR.crLn(x.cr), .transcendental)
    }

    public static func log10(_ x: Real) -> Real {
        // log10(x) = ln(x) / ln(10)
        let lnX = ln(x)
        let ln10 = ln(fromInt(10))
        return lnX.divide(ln10)
    }

    public static func log2(_ x: Real) -> Real {
        let lnX = ln(x)
        let ln2 = ln(fromInt(2))
        return lnX.divide(ln2)
    }

    // MARK: - Trigonometric

    public static func sin(_ x: Real) -> Real {
        if x.isError { return error }
        if x.isZero { return zero }

        // Check if x is a rational multiple of pi
        if x.property == .pi, let r = x.rational {
            // sin(n*pi) = 0 for integer n
            if r.isInteger {
                return zero
            }
            // sin(pi/2) = 1, sin(3pi/2) = -1, etc.
            // Check if r = k/2 for odd k
            let twoR = BoundedRational.multiply(r, BoundedRational.two)
            if let tr = twoR, tr.isInteger {
                if let k = tr.toInt() {
                    let kMod4 = ((k % 4) + 4) % 4
                    if kMod4 == 1 { return one }
                    if kMod4 == 3 { return minusOne }
                }
            }
        }

        return Real(nil, CR.crSin(x.cr), .transcendental)
    }

    public static func cos(_ x: Real) -> Real {
        if x.isError { return error }
        if x.isZero { return one }

        // Check if x is a rational multiple of pi
        if x.property == .pi, let r = x.rational {
            // cos(n*pi) = (-1)^n for integer n
            if r.isInteger {
                if let n = r.toInt() {
                    return n % 2 == 0 ? one : minusOne
                }
            }
            // cos(pi/2) = 0, cos(3pi/2) = 0
            let twoR = BoundedRational.multiply(r, BoundedRational.two)
            if let tr = twoR, tr.isInteger {
                if let k = tr.toInt() {
                    let kMod4 = ((k % 4) + 4) % 4
                    if kMod4 == 1 || kMod4 == 3 { return zero }
                }
            }
        }

        return Real(nil, CR.crCos(x.cr), .transcendental)
    }

    public static func tan(_ x: Real) -> Real {
        if x.isError { return error }
        let cosX = cos(x)
        if cosX.isZero { return error }
        return sin(x).divide(cosX)
    }

    public static func asin(_ x: Real) -> Real {
        if x.isError { return error }
        if x.isZero { return zero }
        // asin(1) = π/2, asin(-1) = -π/2
        if let r = x.rational, x.property == .rational {
            if r.compareTo(BoundedRational.one) == 0 {
                return Real(BoundedRational.half, CR.pi.shiftLeftCR(-1), .pi)
            }
            if r.compareTo(BoundedRational.minusOne) == 0 {
                return Real(BoundedRational.half.negate(), CR.pi.shiftLeftCR(-1).negate(), .pi)
            }
        }
        return Real(nil, CR.crAsin(x.cr), .transcendental)
    }

    public static func acos(_ x: Real) -> Real {
        if x.isError { return error }
        // acos(1) = 0, acos(-1) = π
        if let r = x.rational, x.property == .rational {
            if r.compareTo(BoundedRational.one) == 0 {
                return zero
            }
            if r.compareTo(BoundedRational.minusOne) == 0 {
                return piVal
            }
        }
        return Real(nil, CR.crAcos(x.cr), .transcendental)
    }

    public static func atan(_ x: Real) -> Real {
        if x.isError { return error }
        if x.isZero { return zero }
        return Real(nil, CR.crAtan(x.cr), .transcendental)
    }

    // MARK: - Hyperbolic

    public static func sinh(_ x: Real) -> Real {
        if x.isError { return error }
        if x.isZero { return zero }
        // sinh(x) = (e^x - e^(-x)) / 2
        let ex = exp_(x)
        let emx = exp_(x.negate())
        return ex.subtract(emx).divide(two)
    }

    public static func cosh(_ x: Real) -> Real {
        if x.isError { return error }
        if x.isZero { return one }
        let ex = exp_(x)
        let emx = exp_(x.negate())
        return ex.add(emx).divide(two)
    }

    public static func tanh(_ x: Real) -> Real {
        if x.isError { return error }
        return sinh(x).divide(cosh(x))
    }

    public static func asinh(_ x: Real) -> Real {
        if x.isError { return error }
        // asinh(x) = ln(x + sqrt(x² + 1))
        let x2plus1 = x.multiply(x).add(one)
        return ln(x.add(sqrt(x2plus1)))
    }

    public static func acosh(_ x: Real) -> Real {
        if x.isError { return error }
        // acosh(x) = ln(x + sqrt(x² - 1))
        let x2minus1 = x.multiply(x).subtract(one)
        return ln(x.add(sqrt(x2minus1)))
    }

    public static func atanh(_ x: Real) -> Real {
        if x.isError { return error }
        // atanh(x) = ln((1+x)/(1-x)) / 2
        let num = one.add(x)
        let den = one.subtract(x)
        if den.isZero { return error }
        return ln(num.divide(den)).divide(two)
    }

    // MARK: - Factorial

    public static func factorial(_ n: Real) -> Real {
        if n.isError { return error }
        guard let r = n.rational, n.property == .rational, r.isInteger else {
            return error // Factorial only for non-negative integers
        }
        guard let intN = r.toInt(), intN >= 0 else { return error }
        if intN > 10000 { return error } // Prevent extremely large computation

        var result = BigInt.one
        var i = 2
        while i <= intN {
            result = result.multiplyByInt(i)
            i += 1
        }
        let br = BoundedRational(result, BigInt.one)
        return Real(br, CR.fromBigInt(result), .rational)
    }

    // MARK: - Percent

    public func percent(base: Real?) -> Real {
        if isError { return Real.error }
        if let b = base {
            // In context of addition/subtraction: base * self / 100
            return b.multiply(self).divide(Real.fromInt(100))
        }
        return divide(Real.fromInt(100))
    }

    // MARK: - Random

    public static func random() -> Real {
        return fromDouble(Double.random(in: 0.0...1.0))
    }

    // MARK: - Display

    public func toDouble() -> Double {
        if isError { return Double.nan }
        if let r = rational {
            return r.toDouble()
        }
        return cr.toDouble()
    }

    /// Format for calculator display with the given maximum number of significant digits.
    public func toDisplayString(maxDigits: Int = 9) -> String {
        if isError { return "Error" }

        // Fast path for exact rationals
        if let r = rational, property == .rational {
            return formatRational(r, maxDigits: maxDigits)
        }

        // Use CR evaluation
        return cr.toStringTruncated(digits: maxDigits)
    }

    /// Format an exact rational for display.
    private func formatRational(_ r: BoundedRational, maxDigits: Int) -> String {
        if r.isZero { return "0" }

        // Check if it's an integer
        if r.isInteger {
            let intStr = r.num.description
            let isNeg = r.num.isNeg
            let absStr = isNeg ? String(intStr.dropFirst()) : intStr
            // Show full integer up to 15 digits (matching old behavior)
            if absStr.count <= 15 {
                return intStr
            }
            // Too many digits — use scientific notation
            let d = r.toDouble()
            return formatDoubleForDisplay(d, maxDigits: maxDigits)
        }

        // Non-integer rational — compute decimal representation
        let decStr = r.toDecimalString(maxDigits: maxDigits + 2)

        // Check if it fits in display
        let displayStr = truncateToSignificantDigits(decStr, maxDigits: maxDigits)
        return displayStr
    }

    /// Truncate a decimal string to at most maxDigits significant digits.
    private func truncateToSignificantDigits(_ s: String, maxDigits: Int) -> String {
        if s.isEmpty || s == "0" { return "0" }

        let isNeg = s.hasPrefix("-")
        let abs = isNeg ? String(s.dropFirst()) : s

        // Count significant digits
        var sigDigits = 0
        var result = ""
        var foundNonZero = false
        var afterDecimal = false
        var truncateIdx: String.Index? = nil

        for (i, c) in abs.enumerated() {
            if c == "." {
                afterDecimal = true
                result += String(c)
                continue
            }
            if c != "0" { foundNonZero = true }
            if foundNonZero {
                sigDigits += 1
                if sigDigits > maxDigits {
                    truncateIdx = abs.index(abs.startIndex, offsetBy: i)
                    break
                }
            }
            result += String(c)
        }

        // Remove trailing zeros after decimal
        if result.contains(".") {
            while result.hasSuffix("0") {
                result = String(result.dropLast())
            }
            if result.hasSuffix(".") {
                result = String(result.dropLast())
            }
        }

        // If number is too large/small for fixed notation, use scientific
        let d = Double(abs) ?? 0.0
        if d != 0.0 && (d >= 1e15 || d < 1e-6) {
            let origD = isNeg ? -d : d
            return formatDoubleForDisplay(origD, maxDigits: maxDigits)
        }

        return isNeg && result != "0" ? "-" + result : result
    }

    /// Format a Double for display (used as fallback for very large/small numbers).
    internal static func formatDoubleForDisplay(_ d: Double, maxDigits: Int) -> String {
        if d.isNaN || d.isInfinite { return "Error" }
        if d == 0.0 { return "0" }
        var str = String(format: "%.\(maxDigits)g", d)
        if str.contains(".") && !str.contains("e") && !str.contains("E") {
            while str.hasSuffix("0") {
                str = String(str.dropLast())
            }
            if str.hasSuffix(".") {
                str = String(str.dropLast())
            }
        }
        return str
    }

    private func formatDoubleForDisplay(_ d: Double, maxDigits: Int) -> String {
        return Real.formatDoubleForDisplay(d, maxDigits: maxDigits)
    }

    // MARK: - Description

    public var description: String {
        return toDisplayString()
    }

    // MARK: - Hashable

    public static func == (lhs: Real, rhs: Real) -> Bool {
        if lhs.isError && rhs.isError { return true }
        if lhs.isError || rhs.isError { return false }
        if let a = lhs.rational, let b = rhs.rational,
           lhs.property == rhs.property && lhs.property == .rational {
            return a.compareTo(b) == 0
        }
        // For non-rational, compare numerically
        let diff = lhs.subtract(rhs)
        return diff.isZero
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(isError)
        hasher.combine(property)
        if let r = rational {
            hasher.combine(r)
        }
    }
}
