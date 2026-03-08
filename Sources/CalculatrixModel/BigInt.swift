import Foundation

// MARK: - BigInt: Arbitrary-Precision Integer

/// An arbitrary-precision signed integer, stored as base-10^9 digits.
///
/// Uses `[Int]` in little-endian order (least significant digit first).
/// Each element is in `[0, 999_999_999]`. Compatible with Skip transpilation.
public final class BigInt: Hashable, CustomStringConvertible, Sendable {
    /// Base-10^9 digits, little-endian. Empty means zero.
    internal let digits: [Int]
    /// Whether this value is negative. Zero is never negative.
    internal let isNeg: Bool

    // Base 10^4 ensures intermediate products (< BASE^2 ≈ 10^8) fit in 32-bit Int,
    // which is critical for Kotlin/JVM compatibility via Skip transpilation.
    internal static let BASE: Int = 10_000
    internal static let BASE_DIGITS: Int = 4

    // MARK: - Constants

    public static let zero = BigInt([], false)
    public static let one = BigInt([1], false)
    public static let minusOne = BigInt([1], true)
    public static let two = BigInt([2], false)
    public static let ten = BigInt([10], false)

    // MARK: - Initializer

    public init(_ digits: [Int], _ isNeg: Bool) {
        // Normalize: remove trailing zero digits, zero is not negative
        var d = digits
        while !d.isEmpty && d[d.count - 1] == 0 {
            d.removeLast()
        }
        self.digits = d
        self.isNeg = d.isEmpty ? false : isNeg
    }

    // MARK: - Factory Methods

    public static func fromInt(_ value: Int) -> BigInt {
        if value == 0 {
            return zero
        }
        var mag: Int
        let neg = value < 0
        if value == Int.min {
            // Handle Int.min overflow when negating
            return fromString(String(value))
        }
        mag = neg ? -value : value
        var d: [Int] = []
        while mag > 0 {
            d.append(mag % BASE)
            mag = mag / BASE
        }
        return BigInt(d, neg)
    }

    public static func fromString(_ string: String) -> BigInt {
        guard !string.isEmpty else {
            return zero
        }

        var s = string
        var neg = false
        if s.hasPrefix("-") {
            neg = true
            s = String(s.dropFirst())
        } else if s.hasPrefix("+") {
            s = String(s.dropFirst())
        }

        guard !s.isEmpty else {
            return zero
        }

        // Remove leading zeros
        while s.count > 1 && s.hasPrefix("0") {
            s = String(s.dropFirst())
        }

        if s == "0" {
            return zero
        }

        // Parse right-to-left in chunks of 9
        var d: [Int] = []
        var end = s.count
        while end > 0 {
            let start = end - BASE_DIGITS > 0 ? end - BASE_DIGITS : 0
            let startIdx = s.index(s.startIndex, offsetBy: start)
            let endIdx = s.index(s.startIndex, offsetBy: end)
            let chunk = String(s[startIdx..<endIdx])
            d.append(Int(chunk) ?? 0)
            end = start
        }
        return BigInt(d, neg)
    }

    // MARK: - Basic Properties

    public var isZero: Bool { digits.isEmpty }

    public var signum: Int {
        if digits.isEmpty { return 0 }
        return isNeg ? -1 : 1
    }

    /// Approximate number of bits needed to represent the magnitude.
    public var bitLength: Int {
        if digits.isEmpty { return 0 }
        // Each base-10^9 digit is ~29.9 bits. Top digit contributes fewer.
        let topDigit = digits[digits.count - 1]
        var topBits = 0
        var v = topDigit
        while v > 0 {
            topBits += 1
            v = v / 2
        }
        // Lower digits each contribute ~14 bits (log2(10^4) ≈ 13.3)
        return (digits.count - 1) * 14 + topBits
    }

    // MARK: - Comparison

    /// Compare magnitudes. Returns -1, 0, or 1.
    internal static func compareMagnitude(_ a: [Int], _ b: [Int]) -> Int {
        if a.count != b.count {
            return a.count < b.count ? -1 : 1
        }
        var i = a.count - 1
        while i >= 0 {
            if a[i] != b[i] {
                return a[i] < b[i] ? -1 : 1
            }
            i -= 1
        }
        return 0
    }

    public func compareTo(_ other: BigInt) -> Int {
        if isNeg != other.isNeg {
            if isZero && other.isZero { return 0 }
            return isNeg ? -1 : 1
        }
        let cmp = BigInt.compareMagnitude(digits, other.digits)
        return isNeg ? -cmp : cmp
    }

    // MARK: - Abs / Negate

    public func abs() -> BigInt {
        if !isNeg { return self }
        return BigInt(digits, false)
    }

    public func negate() -> BigInt {
        if isZero { return self }
        return BigInt(digits, !isNeg)
    }

    // MARK: - Addition

    /// Add magnitudes.
    internal static func addMagnitudes(_ a: [Int], _ b: [Int]) -> [Int] {
        let maxLen = a.count > b.count ? a.count : b.count
        var result: [Int] = []
        var carry = 0
        var i = 0
        while i < maxLen || carry != 0 {
            let aVal = i < a.count ? a[i] : 0
            let bVal = i < b.count ? b[i] : 0
            let sum = aVal + bVal + carry
            result.append(sum % BASE)
            carry = sum / BASE
            i += 1
        }
        return result
    }

    /// Subtract magnitudes (a >= b assumed).
    internal static func subtractMagnitudes(_ a: [Int], _ b: [Int]) -> [Int] {
        var result: [Int] = []
        var borrow = 0
        var i = 0
        while i < a.count {
            let aVal = a[i]
            let bVal = (i < b.count ? b[i] : 0) + borrow
            if aVal >= bVal {
                result.append(aVal - bVal)
                borrow = 0
            } else {
                result.append(aVal + BASE - bVal)
                borrow = 1
            }
            i += 1
        }
        return result
    }

    public func add(_ other: BigInt) -> BigInt {
        if isZero { return other }
        if other.isZero { return self }

        if isNeg == other.isNeg {
            return BigInt(BigInt.addMagnitudes(digits, other.digits), isNeg)
        }
        let cmp = BigInt.compareMagnitude(digits, other.digits)
        if cmp == 0 { return BigInt.zero }
        if cmp > 0 {
            return BigInt(BigInt.subtractMagnitudes(digits, other.digits), isNeg)
        } else {
            return BigInt(BigInt.subtractMagnitudes(other.digits, digits), other.isNeg)
        }
    }

    public func subtract(_ other: BigInt) -> BigInt {
        return add(other.negate())
    }

    // MARK: - Multiply

    public func multiply(_ other: BigInt) -> BigInt {
        if isZero || other.isZero { return BigInt.zero }

        let resultNeg = isNeg != other.isNeg
        let a = digits
        let b = other.digits
        var result = [Int](repeating: 0, count: a.count + b.count)

        var i = 0
        while i < a.count {
            var carry: Int = 0
            var j = 0
            while j < b.count {
                // a[i] * b[j] is at most (10^9-1)^2 ≈ 10^18, fits in Int64
                // Adding carry (< 10^9) and result[i+j] (< 10^9) still fits
                let product: Int = a[i] * b[j] + result[i + j] + carry
                result[i + j] = product % BigInt.BASE
                carry = product / BigInt.BASE
                j += 1
            }
            if carry != 0 {
                result[i + b.count] = result[i + b.count] + carry
            }
            i += 1
        }
        return BigInt(result, resultNeg)
    }

    /// Multiply by a small integer.
    public func multiplyByInt(_ n: Int) -> BigInt {
        if isZero || n == 0 { return BigInt.zero }
        let neg = (n < 0) != isNeg
        let mag = n < 0 ? -n : n
        if mag == 1 { return BigInt(digits, neg) }

        var result: [Int] = []
        var carry = 0
        var i = 0
        while i < digits.count {
            let product = digits[i] * mag + carry
            result.append(product % BigInt.BASE)
            carry = product / BigInt.BASE
            i += 1
        }
        while carry > 0 {
            result.append(carry % BigInt.BASE)
            carry = carry / BigInt.BASE
        }
        return BigInt(result, neg)
    }

    // MARK: - Division

    /// Divide by a single-digit divisor. Returns (quotient, remainder).
    internal static func divideByInt(_ a: [Int], _ d: Int) -> (quotient: [Int], remainder: Int) {
        if a.isEmpty { return ([], 0) }
        var q = [Int](repeating: 0, count: a.count)
        var rem = 0
        var i = a.count - 1
        while i >= 0 {
            let cur = rem * BASE + a[i]
            q[i] = cur / d
            rem = cur % d
            i -= 1
        }
        return (q, rem)
    }

    /// Full division: returns (quotient, remainder).
    public static func divmod(_ dividend: BigInt, _ divisor: BigInt) -> (quotient: BigInt, remainder: BigInt) {
        if divisor.isZero {
            fatalError("BigInt division by zero")
        }
        if dividend.isZero {
            return (zero, zero)
        }

        let cmp = compareMagnitude(dividend.digits, divisor.digits)
        if cmp < 0 {
            return (zero, dividend)
        }
        if cmp == 0 {
            let sign = dividend.isNeg != divisor.isNeg
            return (BigInt([1], sign), zero)
        }

        // Single-digit divisor fast path
        if divisor.digits.count == 1 {
            let (qDigits, rem) = divideByInt(dividend.digits, divisor.digits[0])
            let qSign = dividend.isNeg != divisor.isNeg
            let rSign = dividend.isNeg && rem != 0
            return (BigInt(qDigits, qSign),
                    BigInt(rem == 0 ? [] : [rem], rSign))
        }

        // Multi-digit long division
        return longDivision(dividend.digits, divisor.digits,
                            dividendNeg: dividend.isNeg, divisorNeg: divisor.isNeg)
    }

    /// Long division for multi-digit divisors.
    private static func longDivision(_ u: [Int], _ v: [Int],
                                     dividendNeg: Bool, divisorNeg: Bool) -> (quotient: BigInt, remainder: BigInt) {
        let n = v.count
        let m = u.count - n

        // Normalize: multiply both by a factor so v's top digit >= BASE/2
        let factor = BASE / (v[n - 1] + 1)
        let un = multiplyArrayByInt(u, factor)
        let vn = multiplyArrayByInt(v, factor)

        let vnTop = vn[vn.count - 1]

        // Copy un into a working array with extra room
        var work = un
        while work.count <= m + n {
            work.append(0)
        }

        var q = [Int](repeating: 0, count: m + 1)

        var j = m
        while j >= 0 {
            // Estimate quotient digit q[j]
            let twoDigit = work[j + n] * BASE + work[j + n - 1]
            var qhat = twoDigit / vnTop
            var rhat = twoDigit % vnTop

            // Refine
            if n >= 2 {
                while qhat >= BASE || qhat * vn[n - 2] > rhat * BASE + work[j + n - 2] {
                    qhat = qhat - 1
                    rhat = rhat + vnTop
                    if rhat >= BASE { break }
                }
            }

            // Multiply vn by qhat and subtract from work[j..j+n]
            var borrow = 0
            var k = 0
            while k < n {
                let product = qhat * vn[k] + borrow
                let sub = work[j + k] - (product % BASE)
                if sub < 0 {
                    work[j + k] = sub + BASE
                    borrow = product / BASE + 1
                } else {
                    work[j + k] = sub
                    borrow = product / BASE
                }
                k += 1
            }
            work[j + n] = work[j + n] - borrow

            q[j] = qhat

            if work[j + n] < 0 {
                // Subtracted too much, add back
                q[j] = q[j] - 1
                var carry = 0
                var k2 = 0
                while k2 < n {
                    let sum = work[j + k2] + vn[k2] + carry
                    work[j + k2] = sum % BASE
                    carry = sum / BASE
                    k2 += 1
                }
                work[j + n] = work[j + n] + carry
            }
            j = j - 1
        }

        // Unnormalize remainder: divide work[0..n-1] by factor
        var remDigits = [Int](repeating: 0, count: n)
        var idx = 0
        while idx < n {
            remDigits[idx] = work[idx]
            idx += 1
        }
        let (remResult, _) = divideByInt(remDigits, factor)

        let qSign = dividendNeg != divisorNeg
        return (BigInt(q, qSign),
                BigInt(remResult, dividendNeg))
    }

    /// Multiply a digit array by a small integer.
    private static func multiplyArrayByInt(_ a: [Int], _ n: Int) -> [Int] {
        if n == 1 { return a }
        var result: [Int] = []
        var carry = 0
        var i = 0
        while i < a.count {
            let product = a[i] * n + carry
            result.append(product % BASE)
            carry = product / BASE
            i += 1
        }
        if carry > 0 {
            result.append(carry)
        }
        return result
    }

    public func divide(_ other: BigInt) -> BigInt {
        return BigInt.divmod(self, other).quotient
    }

    public func remainder(_ other: BigInt) -> BigInt {
        return BigInt.divmod(self, other).remainder
    }

    // MARK: - Shift Operations

    /// Multiply by 2^n.
    public func shiftLeft(_ n: Int) -> BigInt {
        if n == 0 || isZero { return self }
        if n < 0 { return shiftRight(-n) }
        return multiply(BigInt.powerOfTwo(n))
    }

    /// Divide by 2^n (toward zero).
    public func shiftRight(_ n: Int) -> BigInt {
        if n == 0 || isZero { return self }
        if n < 0 { return shiftLeft(-n) }
        return divide(BigInt.powerOfTwo(n))
    }

    /// Compute 2^n.
    public static func powerOfTwo(_ n: Int) -> BigInt {
        if n == 0 { return one }
        if n < 0 { return zero }
        var result = one
        var base = two
        var exp = n
        while exp > 0 {
            if exp % 2 == 1 {
                result = result.multiply(base)
            }
            base = base.multiply(base)
            exp = exp / 2
        }
        return result
    }

    // MARK: - GCD

    /// Greatest common divisor.
    public static func gcd(_ a: BigInt, _ b: BigInt) -> BigInt {
        var x = a.abs()
        var y = b.abs()
        while !y.isZero {
            let temp = y
            y = divmod(x, y).remainder
            x = temp
        }
        return x
    }

    // MARK: - Power

    /// Compute self^exp for non-negative exp.
    public func power(_ exp: Int) -> BigInt {
        if exp < 0 { return BigInt.zero }
        if exp == 0 { return BigInt.one }
        if exp == 1 { return self }

        var result = BigInt.one
        var base = self
        var e = exp
        while e > 0 {
            if e % 2 == 1 {
                result = result.multiply(base)
            }
            base = base.multiply(base)
            e = e / 2
        }
        return result
    }

    // MARK: - Conversion

    public func toInt() -> Int? {
        if isZero { return 0 }
        if digits.count > 3 { return nil }
        var result = 0
        var factor = 1
        var i = 0
        while i < digits.count {
            let addend = digits[i] * factor
            if result > Int.max - addend { return nil }
            result = result + addend
            if i + 1 < digits.count {
                if factor > Int.max / BigInt.BASE { return nil }
                factor = factor * BigInt.BASE
            }
            i += 1
        }
        if isNeg { return -result }
        return result
    }

    public func toDouble() -> Double {
        if isZero { return 0.0 }
        var result = 0.0
        var i = digits.count - 1
        while i >= 0 {
            result = result * Double(BigInt.BASE) + Double(digits[i])
            i -= 1
        }
        return isNeg ? -result : result
    }

    // MARK: - String Representation

    public var description: String {
        if isZero { return "0" }
        var result = ""
        result = "\(digits[digits.count - 1])"
        var i = digits.count - 2
        while i >= 0 {
            var chunk = "\(digits[i])"
            while chunk.count < BigInt.BASE_DIGITS {
                chunk = "0" + chunk
            }
            result = result + chunk
            i -= 1
        }
        if isNeg { result = "-" + result }
        return result
    }

    // MARK: - Hashable

    public static func == (lhs: BigInt, rhs: BigInt) -> Bool {
        return lhs.isNeg == rhs.isNeg && lhs.digits == rhs.digits
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(isNeg)
        hasher.combine(digits)
    }

    // MARK: - Min/Max

    public static func max(_ a: BigInt, _ b: BigInt) -> BigInt {
        return a.compareTo(b) >= 0 ? a : b
    }

    public static func min(_ a: BigInt, _ b: BigInt) -> BigInt {
        return a.compareTo(b) <= 0 ? a : b
    }
}
