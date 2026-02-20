import Foundation
import Observation
import OSLog

/// A logger for the CalculatrixModel module.
let logger: Logger = Logger(subsystem: "calculatrix.model", category: "CalculatrixModel")

/// The arithmetic operations supported by the calculator.
public enum CalcOperation: String, Hashable {
    case add = "+"
    case subtract = "−"
    case multiply = "×"
    case divide = "÷"
    case power = "xʸ"
    case yRoot = "ʸ√x"
    case ee = "EE"
}

/// The Observable calculator model used by the application.
@Observable public class CalculatorModel {
    /// The text currently shown on the calculator display.
    public var displayText: String = "0"

    /// Whether the clear button should show "AC" (all clear) or "C" (clear entry).
    public var isAllClear: Bool = true

    /// The currently active (highlighted) operation button, if any.
    public var activeOperation: CalcOperation? = nil

    /// Whether the 2nd function mode is active.
    public var isSecondFunction: Bool = false

    /// Whether trigonometric functions use radians (true) or degrees (false).
    public var useRadians: Bool = false

    /// The current memory value.
    public var memory: Double = 0.0

    /// The depth of open parentheses.
    public var parenthesesDepth: Int = 0

    private var accumulator: Double = 0.0
    private var pendingOperation: CalcOperation? = nil
    private var isEnteringNumber: Bool = false
    private var lastOperand: Double = 0.0
    private var lastOperation: CalcOperation? = nil
    private var justEvaluated: Bool = false

    private var savedAccumulators: [Double] = []
    private var savedOperations: [CalcOperation?] = []

    public init() {
    }

    /// The numeric value represented by the current display text.
    public var displayValue: Double {
        return Double(displayText) ?? 0.0
    }

    // MARK: - Digit Input

    /// Handle a digit button press (0-9).
    public func inputDigit(_ digit: Int) {
        if displayText == "Error" { inputClear() }

        if isEnteringNumber {
            if displayText == "0" {
                displayText = "\(digit)"
            } else if displayText == "-0" {
                displayText = "-\(digit)"
            } else {
                let stripped = displayText
                    .replacingOccurrences(of: ".", with: "")
                    .replacingOccurrences(of: "-", with: "")
                if stripped.count < 9 {
                    displayText = displayText + "\(digit)"
                }
            }
        } else {
            displayText = "\(digit)"
            isEnteringNumber = true
        }
        isAllClear = false
        justEvaluated = false
    }

    // MARK: - Decimal Input

    /// Handle the decimal point button press.
    public func inputDecimal() {
        if displayText == "Error" { inputClear() }

        if !isEnteringNumber {
            displayText = "0."
            isEnteringNumber = true
        } else if !displayText.contains(".") {
            displayText = displayText + "."
        }
        isAllClear = false
        justEvaluated = false
    }

    // MARK: - Operation Input

    /// Handle an arithmetic operation button press.
    public func inputOperation(_ operation: CalcOperation) {
        if displayText == "Error" { inputClear() }

        if (isEnteringNumber || justEvaluated) && pendingOperation != nil {
            performCalculation()
        } else {
            accumulator = displayValue
        }
        pendingOperation = operation
        activeOperation = operation
        isEnteringNumber = false
        justEvaluated = false
    }

    // MARK: - Equals

    /// Handle the equals button press.
    public func inputEquals() {
        if displayText == "Error" { inputClear(); return }

        if pendingOperation != nil {
            lastOperation = pendingOperation
            lastOperand = displayValue
            performCalculation()
            pendingOperation = nil
        } else if let op = lastOperation {
            accumulator = displayValue
            performOperation(op, operand: lastOperand)
        }
        activeOperation = nil
        isEnteringNumber = false
        justEvaluated = true
    }

    // MARK: - Clear

    /// Handle the clear / all-clear button press.
    public func inputClear() {
        if isAllClear {
            accumulator = 0.0
            pendingOperation = nil
            lastOperation = nil
            lastOperand = 0.0
            activeOperation = nil
            savedAccumulators = []
            savedOperations = []
            parenthesesDepth = 0
        }
        displayText = "0"
        isEnteringNumber = false
        isAllClear = true
        justEvaluated = false
    }

    // MARK: - Negate

    /// Handle the +/- (negate) button press.
    public func inputNegate() {
        if displayText == "Error" { return }

        if !isEnteringNumber {
            if displayText == "0" {
                displayText = "-0"
                isEnteringNumber = true
                isAllClear = false
            } else {
                let value = -displayValue
                displayText = CalculatorModel.formatNumber(value)
            }
            return
        }
        // Toggle sign while entering a number
        if displayText == "0" {
            displayText = "-0"
        } else if displayText == "-0" {
            displayText = "0"
        } else if displayText.hasPrefix("-") {
            displayText = String(displayText.dropFirst())
        } else {
            displayText = "-" + displayText
        }
    }

    // MARK: - Percent

    /// Handle the percent button press.
    public func inputPercent() {
        if displayText == "Error" { return }

        let current = displayValue
        let value: Double
        if pendingOperation == .add || pendingOperation == .subtract {
            value = accumulator * current / 100.0
        } else {
            value = current / 100.0
        }
        displayText = CalculatorModel.formatNumber(value)
        isEnteringNumber = false
        justEvaluated = true
    }

    // MARK: - 2nd Function Toggle

    /// Toggle the 2nd function mode.
    public func toggleSecondFunction() {
        isSecondFunction = !isSecondFunction
    }

    // MARK: - Rad/Deg Toggle

    /// Toggle between radians and degrees for trigonometric functions.
    public func toggleRadDeg() {
        useRadians = !useRadians
    }

    // MARK: - Memory Operations

    /// Clear the memory.
    public func memoryClear() {
        memory = 0.0
    }

    /// Add the display value to memory.
    public func memoryAdd() {
        memory += displayValue
    }

    /// Subtract the display value from memory.
    public func memorySubtract() {
        memory -= displayValue
    }

    /// Recall the memory value to the display.
    public func memoryRecall() {
        displayText = CalculatorModel.formatNumber(memory)
        isEnteringNumber = false
        justEvaluated = true
    }

    // MARK: - Parentheses

    /// Handle the open parenthesis button press.
    public func inputOpenParenthesis() {
        if displayText == "Error" { inputClear() }
        savedAccumulators.append(accumulator)
        savedOperations.append(pendingOperation)
        parenthesesDepth += 1
        accumulator = 0.0
        pendingOperation = nil
        activeOperation = nil
        isEnteringNumber = false
        justEvaluated = false
    }

    /// Handle the close parenthesis button press.
    public func inputCloseParenthesis() {
        if parenthesesDepth <= 0 { return }
        if displayText == "Error" { return }

        // Evaluate pending operation within the sub-expression
        if pendingOperation != nil {
            performCalculation()
            pendingOperation = nil
        }

        let subResult = displayValue

        // Restore outer context
        parenthesesDepth -= 1
        accumulator = savedAccumulators.removeLast()
        pendingOperation = savedOperations.removeLast()
        activeOperation = pendingOperation

        displayText = CalculatorModel.formatNumber(subResult)
        isEnteringNumber = false
        justEvaluated = true
        isAllClear = false
    }

    // MARK: - Scientific Unary Functions

    /// Apply a scientific unary function to the current display value.
    public func inputScientificUnary(_ function: String) {
        if displayText == "Error" { return }

        let x = displayValue
        let result: Double

        switch function {
        case "sin":
            result = sin(useRadians ? x : x * Double.pi / 180.0)
        case "cos":
            result = cos(useRadians ? x : x * Double.pi / 180.0)
        case "tan":
            result = tan(useRadians ? x : x * Double.pi / 180.0)
        case "sin⁻¹":
            let raw = asin(x)
            result = useRadians ? raw : raw * 180.0 / Double.pi
        case "cos⁻¹":
            let raw = acos(x)
            result = useRadians ? raw : raw * 180.0 / Double.pi
        case "tan⁻¹":
            let raw = atan(x)
            result = useRadians ? raw : raw * 180.0 / Double.pi
        case "sinh":
            result = sinh(x)
        case "cosh":
            result = cosh(x)
        case "tanh":
            result = tanh(x)
        case "sinh⁻¹":
            result = asinh(x)
        case "cosh⁻¹":
            result = acosh(x)
        case "tanh⁻¹":
            result = atanh(x)
        case "x²":
            result = x * x
        case "x³":
            result = x * x * x
        case "√x":
            result = sqrt(x)
        case "³√x":
            if x >= 0 {
                result = pow(x, 1.0 / 3.0)
            } else {
                result = -pow(-x, 1.0 / 3.0)
            }
        case "1/x":
            if x == 0.0 {
                displayText = "Error"
                isEnteringNumber = false
                isAllClear = true
                return
            }
            result = 1.0 / x
        case "x!":
            result = CalculatorModel.computeFactorial(x)
        case "eˣ":
            result = exp(x)
        case "10ˣ":
            result = pow(10.0, x)
        case "2ˣ":
            result = pow(2.0, x)
        case "ln":
            result = log(x)
        case "log₁₀":
            result = log10(x)
        case "log₂":
            result = log(x) / log(2.0)
        default:
            return
        }

        displayText = CalculatorModel.formatNumber(result)
        isEnteringNumber = false
        justEvaluated = true
        isAllClear = false
    }

    // MARK: - Scientific Constants

    /// Insert a mathematical constant into the display.
    public func inputConstant(_ name: String) {
        switch name {
        case "π":
            displayText = CalculatorModel.formatNumber(Double.pi)
        case "e":
            displayText = CalculatorModel.formatNumber(exp(1.0))
        case "Rand":
            displayText = CalculatorModel.formatNumber(Double.random(in: 0.0...1.0))
        default:
            return
        }
        isEnteringNumber = false
        justEvaluated = true
        isAllClear = false
    }

    // MARK: - Internal Calculation

    private func performCalculation() {
        guard let operation = pendingOperation else { return }
        let operand = displayValue
        performOperation(operation, operand: operand)
    }

    private func performOperation(_ operation: CalcOperation, operand: Double) {
        let result: Double
        switch operation {
        case .add:
            result = accumulator + operand
        case .subtract:
            result = accumulator - operand
        case .multiply:
            result = accumulator * operand
        case .divide:
            if operand == 0.0 {
                displayText = "Error"
                isEnteringNumber = false
                pendingOperation = nil
                activeOperation = nil
                isAllClear = true
                return
            }
            result = accumulator / operand
        case .power:
            result = pow(accumulator, operand)
        case .yRoot:
            if operand == 0.0 {
                displayText = "Error"
                isEnteringNumber = false
                pendingOperation = nil
                activeOperation = nil
                isAllClear = true
                return
            }
            result = pow(accumulator, 1.0 / operand)
        case .ee:
            result = accumulator * pow(10.0, operand)
        }
        accumulator = result
        displayText = CalculatorModel.formatNumber(result)
    }

    // MARK: - Factorial Helper

    private static func computeFactorial(_ n: Double) -> Double {
        if n < 0.0 { return Double.nan }
        if n == 0.0 || n == 1.0 { return 1.0 }
        if n != n.rounded(.down) { return Double.nan }
        if n > 170.0 { return Double.infinity }
        var result = 1.0
        let count = Int(n)
        var i = 2
        while i <= count {
            result *= Double(i)
            i += 1
        }
        return result
    }

    // MARK: - Number Formatting

    /// Format a number for display, removing unnecessary trailing zeros
    /// and using integer format for whole numbers.
    public static func formatNumber(_ number: Double) -> String {
        if number.isNaN || number.isInfinite {
            return "Error"
        }
        if number == 0.0 {
            return "0"
        }
        // Whole numbers within display range
        let isWholeNumber = number == Double(Int64(number))
        let inRange = number > -1e15 && number < 1e15
        if isWholeNumber && inRange {
            return "\(Int64(number))"
        }
        // Format with up to 9 significant digits, then strip trailing zeros
        // (Kotlin's String.format pads with zeros unlike Swift, so we strip)
        var str = String(format: "%.9g", number)
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
}
