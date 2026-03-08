import Foundation

// MARK: - BoundedRational: Exact Rational with Overflow Protection

/// An exact rational number `num/den` stored in lowest terms.
///
/// Arithmetic operations return `nil` when the result exceeds the bit bound,
/// signaling that the caller should fall back to constructive real computation.
public final class BoundedRational: Hashable, CustomStringConvertible, Sendable {
    /// The numerator.
    public let num: BigInt
    /// The denominator (always positive, always coprime with numerator).
    public let den: BigInt

    /// Maximum bit length before we consider the rational "overflowed".
    private static let MAX_BITS: Int = 10_000

    // MARK: - Constants

    public static let zero = BoundedRational(BigInt.zero, BigInt.one)
    public static let one = BoundedRational(BigInt.one, BigInt.one)
    public static let minusOne = BoundedRational(BigInt.minusOne, BigInt.one)
    public static let half = BoundedRational(BigInt.one, BigInt.two)
    public static let two = BoundedRational(BigInt.two, BigInt.one)
    public static let ten = BoundedRational(BigInt.ten, BigInt.one)

    // MARK: - Initializer

    /// Create a rational in lowest terms. Denominator must not be zero.
    public init(_ num: BigInt, _ den: BigInt) {
        if den.isZero {
            fatalError("BoundedRational: zero denominator")
        }
        if num.isZero {
            self.num = BigInt.zero
            self.den = BigInt.one
            return
        }
        let g = BigInt.gcd(num.abs(), den.abs())
        var n = g.compareTo(BigInt.one) == 0 ? num : num.divide(g)
        var d = g.compareTo(BigInt.one) == 0 ? den : den.divide(g)
        // Ensure denominator is positive
        if d.isNeg {
            n = n.negate()
            d = d.negate()
        }
        self.num = n
        self.den = d
    }

    // MARK: - Factory Methods

    public static func fromInt(_ value: Int) -> BoundedRational {
        return BoundedRational(BigInt.fromInt(value), BigInt.one)
    }

    /// Parse a decimal string like "123.456" into an exact rational.
    public static func fromDecimalString(_ s: String) -> BoundedRational? {
        if s.isEmpty { return nil }

        var str = s
        var neg = false
        if str.hasPrefix("-") {
            neg = true
            str = String(str.dropFirst())
        }

        let dotIndex = str.firstIndex(of: ".")
        if let dot = dotIndex {
            let intPart = String(str[str.startIndex..<dot])
            let fracPart = String(str[str.index(after: dot)...])
            let wholePart = intPart.isEmpty ? "0" : intPart

            // numerator = wholePart * 10^fracLen + fracPart
            // denominator = 10^fracLen
            let fracLen = fracPart.count
            if fracLen == 0 {
                let n = BigInt.fromString(neg ? "-" + wholePart : wholePart)
                return BoundedRational(n, BigInt.one)
            }

            var denominator = BigInt.one
            var i = 0
            while i < fracLen {
                denominator = denominator.multiplyByInt(10)
                i += 1
            }

            let wholeNum = BigInt.fromString(wholePart).multiply(denominator)
            let fracNum = BigInt.fromString(fracPart.isEmpty ? "0" : fracPart)
            var numerator = wholeNum.add(fracNum)
            if neg {
                numerator = numerator.negate()
            }
            return BoundedRational(numerator, denominator)
        } else {
            let n = BigInt.fromString(neg ? "-" + str : str)
            return BoundedRational(n, BigInt.one)
        }
    }

    // MARK: - Overflow Check

    /// Returns nil if this rational exceeds the bit bound.
    private func bounded() -> BoundedRational? {
        if num.bitLength > BoundedRational.MAX_BITS || den.bitLength > BoundedRational.MAX_BITS {
            return nil
        }
        return self
    }

    // MARK: - Basic Properties

    public var isZero: Bool { num.isZero }

    public var signum: Int { num.signum }

    public var isNegative: Bool { num.isNeg }

    /// Whether this rational is an integer (denominator is 1).
    public var isInteger: Bool {
        return den.compareTo(BigInt.one) == 0
    }

    // MARK: - Bounded Arithmetic

    /// Add two rationals, returning nil on overflow.
    public static func add(_ a: BoundedRational, _ b: BoundedRational) -> BoundedRational? {
        if a.isZero { return b }
        if b.isZero { return a }
        // a.num/a.den + b.num/b.den = (a.num*b.den + b.num*a.den) / (a.den*b.den)
        let newNum = a.num.multiply(b.den).add(b.num.multiply(a.den))
        let newDen = a.den.multiply(b.den)
        return BoundedRational(newNum, newDen).bounded()
    }

    /// Subtract two rationals.
    public static func subtract(_ a: BoundedRational, _ b: BoundedRational) -> BoundedRational? {
        return add(a, BoundedRational(b.num.negate(), b.den))
    }

    /// Multiply two rationals.
    public static func multiply(_ a: BoundedRational, _ b: BoundedRational) -> BoundedRational? {
        if a.isZero || b.isZero { return zero }
        let newNum = a.num.multiply(b.num)
        let newDen = a.den.multiply(b.den)
        return BoundedRational(newNum, newDen).bounded()
    }

    /// Divide two rationals.
    public static func divide(_ a: BoundedRational, _ b: BoundedRational) -> BoundedRational? {
        if b.isZero { return nil }
        if a.isZero { return zero }
        let newNum = a.num.multiply(b.den)
        let newDen = a.den.multiply(b.num)
        return BoundedRational(newNum, newDen).bounded()
    }

    public func negate() -> BoundedRational {
        return BoundedRational(num.negate(), den)
    }

    public func reciprocal() -> BoundedRational? {
        if isZero { return nil }
        return BoundedRational(den, num).bounded()
    }

    public func abs() -> BoundedRational {
        if !isNegative { return self }
        return BoundedRational(num.abs(), den)
    }

    // MARK: - Comparison

    public func compareTo(_ other: BoundedRational) -> Int {
        // a/b vs c/d => compare a*d vs c*b
        let lhs = num.multiply(other.den)
        let rhs = other.num.multiply(den)
        return lhs.compareTo(rhs)
    }

    // MARK: - Special Operations

    /// Integer power. Returns nil on overflow.
    public static func intPow(_ base: BoundedRational, _ exp: Int) -> BoundedRational? {
        if exp == 0 { return one }
        if exp == 1 { return base }
        if exp < 0 {
            guard let recip = base.reciprocal() else { return nil }
            return intPow(recip, -exp)
        }
        let newNum = base.num.power(exp)
        let newDen = base.den.power(exp)
        return BoundedRational(newNum, newDen).bounded()
    }

    /// Square root, only if the result is rational (i.e., both num and den are perfect squares).
    public static func sqrt(_ a: BoundedRational) -> BoundedRational? {
        if a.isZero { return zero }
        if a.isNegative { return nil }

        guard let numRoot = intSqrt(a.num) else { return nil }
        guard let denRoot = intSqrt(a.den) else { return nil }
        return BoundedRational(numRoot, denRoot).bounded()
    }

    /// Integer square root. Returns nil if not a perfect square.
    private static func intSqrt(_ n: BigInt) -> BigInt? {
        if n.isZero { return BigInt.zero }
        if n.isNeg { return nil }

        // Newton's method for integer square root
        var x = n
        var y = x.add(BigInt.one).divide(BigInt.two)

        while y.compareTo(x) < 0 {
            x = y
            // y = (x + n/x) / 2
            y = x.add(n.divide(x)).divide(BigInt.two)
        }

        // Verify it's a perfect square
        if x.multiply(x).compareTo(n) == 0 {
            return x
        }
        return nil
    }

    // MARK: - Conversion

    public func toDouble() -> Double {
        return num.toDouble() / den.toDouble()
    }

    public func toInt() -> Int? {
        if !isInteger { return nil }
        return num.toInt()
    }

    /// Convert to a BigInt, truncating toward zero.
    public func toBigInt() -> BigInt {
        return num.divide(den)
    }

    // MARK: - String

    public var description: String {
        if den.compareTo(BigInt.one) == 0 {
            return num.description
        }
        return "\(num.description)/\(den.description)"
    }

    // MARK: - Hashable

    public static func == (lhs: BoundedRational, rhs: BoundedRational) -> Bool {
        return lhs.num == rhs.num && lhs.den == rhs.den
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(num)
        hasher.combine(den)
    }

    // MARK: - Decimal Digit Extraction

    /// Returns the exact decimal string representation to `maxDigits` digits after the decimal point.
    /// Truncates (does not round) to avoid display artifacts.
    public func toDecimalString(maxDigits: Int) -> String {
        if isZero { return "0" }

        let negative = isNegative
        let absNum = num.abs()

        let intPart = absNum.divide(den)
        var remainder = absNum.remainder(den)

        if remainder.isZero {
            let s = intPart.description
            return negative ? "-" + s : s
        }

        var fracDigits = ""
        var i = 0
        while i < maxDigits && !remainder.isZero {
            remainder = remainder.multiplyByInt(10)
            let digit = remainder.divide(den)
            remainder = remainder.remainder(den)
            fracDigits = fracDigits + digit.description
            i += 1
        }

        // Remove trailing zeros
        while fracDigits.hasSuffix("0") {
            fracDigits = String(fracDigits.dropLast())
        }

        let intStr = intPart.description
        if fracDigits.isEmpty {
            return negative ? "-" + intStr : intStr
        }
        let result = intStr + "." + fracDigits
        return negative ? "-" + result : result
    }
}
