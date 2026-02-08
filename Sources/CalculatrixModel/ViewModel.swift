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
}

/// The Observable calculator model used by the application.
@Observable public class CalculatorModel {
    /// The text currently shown on the calculator display.
    public var displayText: String = "0"

    /// Whether the clear button should show "AC" (all clear) or "C" (clear entry).
    public var isAllClear: Bool = true

    /// The currently active (highlighted) operation button, if any.
    public var activeOperation: CalcOperation? = nil

    private var accumulator: Double = 0.0
    private var pendingOperation: CalcOperation? = nil
    private var isEnteringNumber: Bool = false
    private var lastOperand: Double = 0.0
    private var lastOperation: CalcOperation? = nil
    private var justEvaluated: Bool = false

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

    /// Handle an arithmetic operation button press (+, −, ×, ÷).
    public func inputOperation(_ operation: CalcOperation) {
        if displayText == "Error" { inputClear() }

        if isEnteringNumber && pendingOperation != nil && !justEvaluated {
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
        }
        accumulator = result
        displayText = CalculatorModel.formatNumber(result)
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
