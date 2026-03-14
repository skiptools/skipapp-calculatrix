import Foundation
import Observation
import OSLog

/// A logger for the CalculatrixModel module.
let logger: Logger = Logger(subsystem: "calculatrix.model", category: "CalculatrixModel")

/// The calculator mode (basic, scientific, or convert).
public enum CalculatorMode: Hashable {
    case basic
    case scientific
    case convert
}

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
    public var memory: Real = Real.zero

    /// The depth of open parentheses.
    public var parenthesesDepth: Int = 0

    // MARK: - Mode & Conversion State

    /// The current calculator mode.
    public var calculatorMode: CalculatorMode = .basic

    /// Whether the mode menu overlay is visible.
    public var isMenuVisible: Bool = false

    /// The selected conversion category.
    public var conversionCategory: ConversionCategory = .length

    /// The source unit for conversion.
    public var sourceUnit: ConversionUnit = defaultSourceUnit(for: .length)

    /// The target unit for conversion.
    public var targetUnit: ConversionUnit = defaultTargetUnit(for: .length)

    /// Whether we are editing the source (true) or target (false) value.
    public var isEditingSource: Bool = true

    /// The source value text in conversion mode.
    public var sourceText: String = "0"

    /// The target value text in conversion mode.
    public var targetText: String = "0"

    /// Whether the unit picker sheet is visible.
    public var isUnitPickerVisible: Bool = false

    /// Whether we are picking the source (true) or target (false) unit.
    public var isPickingSourceUnit: Bool = true

    /// Whether the user is entering a new number in conversion mode.
    private var conversionEnteringNumber: Bool = false

    /// The pending arithmetic operation in conversion mode.
    private var conversionPendingOperation: CalcOperation? = nil

    /// The accumulator for arithmetic in conversion mode.
    private var conversionAccumulator: Double = 0.0

    private var accumulator: Real = Real.zero
    private var pendingOperation: CalcOperation? = nil
    private var isEnteringNumber: Bool = false
    private var lastOperand: Real = Real.zero
    private var lastOperation: CalcOperation? = nil
    private var justEvaluated: Bool = false
    /// Stores the exact Real from the last computation or constant entry,
    /// avoiding precision loss from display text round-tripping.
    private var lastResult: Real? = nil

    private var savedAccumulators: [Real] = []
    private var savedOperations: [CalcOperation?] = []

    public init() {
    }

    /// The numeric value represented by the current display.
    /// Uses the stored exact Real when available (e.g., after constants or calculations),
    /// otherwise parses the display text.
    public var displayValue: Real {
        if let lr = lastResult { return lr }
        return Real.fromDisplayString(displayText)
    }

    /// The numeric value represented by the current display text as a Double (for conversion mode).
    public var displayValueDouble: Double {
        return Double(displayText) ?? 0.0
    }

    // MARK: - Digit Input

    /// Handle a digit button press (0-9).
    public func inputDigit(_ digit: Int) {
        if calculatorMode == .convert {
            inputConversionDigit(digit)
            return
        }
        if displayText == "Error" { inputClear() }

        lastResult = nil
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
        if calculatorMode == .convert {
            inputConversionDecimal()
            return
        }
        if displayText == "Error" { inputClear() }

        lastResult = nil
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
        if calculatorMode == .convert {
            inputConversionOperation(operation)
            return
        }
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
        if calculatorMode == .convert {
            inputConversionEquals()
            return
        }
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
        if calculatorMode == .convert {
            inputConversionClear()
            return
        }
        if isAllClear {
            accumulator = Real.zero
            pendingOperation = nil
            lastOperation = nil
            lastOperand = Real.zero
            activeOperation = nil
            savedAccumulators = []
            savedOperations = []
            parenthesesDepth = 0
        }
        displayText = "0"
        lastResult = nil
        isEnteringNumber = false
        isAllClear = true
        justEvaluated = false
    }

    // MARK: - Negate

    /// Handle the +/- (negate) button press.
    public func inputNegate() {
        if calculatorMode == .convert {
            inputConversionNegate()
            return
        }
        if displayText == "Error" { return }

        if !isEnteringNumber {
            if displayText == "0" {
                displayText = "-0"
                isEnteringNumber = true
                isAllClear = false
            } else {
                let value = displayValue.negate()
                displayText = CalculatorModel.formatReal(value)
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
        if calculatorMode == .convert {
            inputConversionPercent()
            return
        }
        if displayText == "Error" { return }

        let current = displayValue
        let hundred = Real.fromInt(100)
        let value: Real
        if pendingOperation == .add || pendingOperation == .subtract {
            value = accumulator.multiply(current).divide(hundred)
        } else {
            value = current.divide(hundred)
        }
        displayText = CalculatorModel.formatReal(value)
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
        memory = Real.zero
    }

    /// Add the display value to memory.
    public func memoryAdd() {
        memory = memory.add(displayValue)
    }

    /// Subtract the display value from memory.
    public func memorySubtract() {
        memory = memory.subtract(displayValue)
    }

    /// Recall the memory value to the display.
    public func memoryRecall() {
        displayText = CalculatorModel.formatReal(memory)
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
        accumulator = Real.zero
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

        displayText = CalculatorModel.formatReal(subResult)
        isEnteringNumber = false
        justEvaluated = true
        isAllClear = false
    }

    // MARK: - Scientific Unary Functions

    /// Apply a scientific unary function to the current display value.
    public func inputScientificUnary(_ function: String) {
        if displayText == "Error" { return }

        let x = displayValue
        let pi180 = Real.piVal.divide(Real.fromInt(180))
        let r180pi = Real.fromInt(180).divide(Real.piVal)
        let result: Real

        // Values with .pi property are inherently radian-based (e.g. π, 2π, π/2),
        // so they bypass degree-to-radian conversion even in degrees mode.
        let isRadianValue = x.property == .pi
        switch function {
        case "sin":
            let angle = (useRadians || isRadianValue) ? x : x.multiply(pi180)
            result = Real.sin(angle)
        case "cos":
            let angle = (useRadians || isRadianValue) ? x : x.multiply(pi180)
            result = Real.cos(angle)
        case "tan":
            let angle = (useRadians || isRadianValue) ? x : x.multiply(pi180)
            result = Real.tan(angle)
        case "sin⁻¹":
            let raw = Real.asin(x)
            result = useRadians ? raw : raw.multiply(r180pi)
        case "cos⁻¹":
            let raw = Real.acos(x)
            result = useRadians ? raw : raw.multiply(r180pi)
        case "tan⁻¹":
            let raw = Real.atan(x)
            result = useRadians ? raw : raw.multiply(r180pi)
        case "sinh":
            result = Real.sinh(x)
        case "cosh":
            result = Real.cosh(x)
        case "tanh":
            result = Real.tanh(x)
        case "sinh⁻¹":
            result = Real.asinh(x)
        case "cosh⁻¹":
            result = Real.acosh(x)
        case "tanh⁻¹":
            result = Real.atanh(x)
        case "x²":
            result = x.multiply(x)
        case "x³":
            result = x.multiply(x).multiply(x)
        case "√x":
            result = Real.sqrt(x)
        case "³√x":
            if !x.isNegative {
                result = Real.pow(x, Real.fromBoundedRational(BoundedRational(BigInt.one, BigInt.fromInt(3))))
            } else {
                result = Real.pow(x.absValue(), Real.fromBoundedRational(BoundedRational(BigInt.one, BigInt.fromInt(3)))).negate()
            }
        case "1/x":
            if x.isZero {
                displayText = "Error"
                isEnteringNumber = false
                isAllClear = true
                return
            }
            result = x.reciprocal()
        case "x!":
            result = Real.factorial(x)
        case "eˣ":
            result = Real.exp_(x)
        case "10ˣ":
            result = Real.pow(Real.ten, x)
        case "2ˣ":
            result = Real.pow(Real.two, x)
        case "ln":
            result = Real.ln(x)
        case "log₁₀":
            result = Real.log10(x)
        case "log₂":
            result = Real.log2(x)
        default:
            return
        }

        if result.isError {
            displayText = "Error"
            lastResult = nil
        } else {
            displayText = CalculatorModel.formatReal(result)
            lastResult = result
        }
        isEnteringNumber = false
        justEvaluated = true
        isAllClear = false
    }

    // MARK: - Scientific Constants

    /// Insert a mathematical constant into the display.
    public func inputConstant(_ name: String) {
        switch name {
        case "π":
            displayText = CalculatorModel.formatReal(Real.piVal)
            accumulator = Real.piVal
            lastResult = Real.piVal
            isEnteringNumber = false
            justEvaluated = true
            isAllClear = false
            return
        case "e":
            displayText = CalculatorModel.formatReal(Real.eVal)
            accumulator = Real.eVal
            lastResult = Real.eVal
            isEnteringNumber = false
            justEvaluated = true
            isAllClear = false
            return
        case "Rand":
            displayText = CalculatorModel.formatReal(Real.random())
        default:
            return
        }
        isEnteringNumber = false
        justEvaluated = true
        isAllClear = false
    }

    // MARK: - Mode Switching

    /// Switch the calculator mode.
    public func setMode(_ mode: CalculatorMode) {
        calculatorMode = mode
        isMenuVisible = false
        if mode == .convert {
            sourceText = (displayText == "Error") ? "0" : displayText
            conversionEnteringNumber = true
            conversionPendingOperation = nil
            conversionAccumulator = 0.0
            activeOperation = nil
            updateConversion()
        }
    }

    // MARK: - Conversion Methods

    /// Select a conversion category, resetting to default units.
    public func selectCategory(_ category: ConversionCategory) {
        conversionCategory = category
        sourceUnit = defaultSourceUnit(for: category)
        targetUnit = defaultTargetUnit(for: category)
        updateConversion()
    }

    /// Select the source unit for conversion.
    public func selectSourceUnit(_ unit: ConversionUnit) {
        sourceUnit = unit
        isUnitPickerVisible = false
        updateConversion()
    }

    /// Select the target unit for conversion.
    public func selectTargetUnit(_ unit: ConversionUnit) {
        targetUnit = unit
        isUnitPickerVisible = false
        updateConversion()
    }

    /// Swap the source and target units and values.
    public func swapUnits() {
        let tempUnit = sourceUnit
        sourceUnit = targetUnit
        targetUnit = tempUnit
        let tempText = sourceText
        sourceText = targetText
        targetText = tempText
        isEditingSource = !isEditingSource
    }

    /// Recalculate the conversion based on current values and units.
    public func updateConversion() {
        if isEditingSource {
            let value = Double(sourceText) ?? 0.0
            let result = convertValue(value, from: sourceUnit, to: targetUnit)
            targetText = CalculatorModel.formatDouble(result)
        } else {
            let value = Double(targetText) ?? 0.0
            let result = convertValue(value, from: targetUnit, to: sourceUnit)
            sourceText = CalculatorModel.formatDouble(result)
        }
    }

    /// Handle digit input in conversion mode.
    private func inputConversionDigit(_ digit: Int) {
        if !conversionEnteringNumber {
            // Starting a new number after an operation
            if isEditingSource {
                sourceText = "\(digit)"
            } else {
                targetText = "\(digit)"
            }
            conversionEnteringNumber = true
        } else if isEditingSource {
            if sourceText == "0" {
                sourceText = "\(digit)"
            } else {
                let stripped = sourceText.replacingOccurrences(of: ".", with: "").replacingOccurrences(of: "-", with: "")
                if stripped.count < 9 {
                    sourceText = sourceText + "\(digit)"
                }
            }
        } else {
            if targetText == "0" {
                targetText = "\(digit)"
            } else {
                let stripped = targetText.replacingOccurrences(of: ".", with: "").replacingOccurrences(of: "-", with: "")
                if stripped.count < 9 {
                    targetText = targetText + "\(digit)"
                }
            }
        }
        isAllClear = false
        updateConversion()
    }

    /// Handle decimal input in conversion mode.
    private func inputConversionDecimal() {
        if !conversionEnteringNumber {
            if isEditingSource {
                sourceText = "0."
            } else {
                targetText = "0."
            }
            conversionEnteringNumber = true
        } else if isEditingSource {
            if !sourceText.contains(".") {
                sourceText = sourceText + "."
            }
        } else {
            if !targetText.contains(".") {
                targetText = targetText + "."
            }
        }
        isAllClear = false
    }

    /// Handle clear in conversion mode.
    private func inputConversionClear() {
        if isAllClear {
            conversionAccumulator = 0.0
            conversionPendingOperation = nil
            activeOperation = nil
        }
        sourceText = "0"
        targetText = "0"
        conversionEnteringNumber = false
        isAllClear = true
    }

    /// Handle negate in conversion mode.
    private func inputConversionNegate() {
        if isEditingSource {
            if sourceText.hasPrefix("-") {
                sourceText = String(sourceText.dropFirst())
            } else if sourceText != "0" {
                sourceText = "-" + sourceText
            }
        } else {
            if targetText.hasPrefix("-") {
                targetText = String(targetText.dropFirst())
            } else if targetText != "0" {
                targetText = "-" + targetText
            }
        }
        updateConversion()
    }

    /// The current numeric value of the active conversion field.
    private var conversionCurrentValue: Double {
        return Double(isEditingSource ? sourceText : targetText) ?? 0.0
    }

    /// Set the active conversion field's text and update conversion.
    private func setConversionText(_ value: Double) {
        let text = CalculatorModel.formatDouble(value)
        if isEditingSource {
            sourceText = text
        } else {
            targetText = text
        }
        updateConversion()
    }

    /// Handle an arithmetic operation in conversion mode.
    private func inputConversionOperation(_ operation: CalcOperation) {
        if conversionEnteringNumber && conversionPendingOperation != nil {
            performConversionCalculation()
        } else {
            conversionAccumulator = conversionCurrentValue
        }
        conversionPendingOperation = operation
        activeOperation = operation
        conversionEnteringNumber = false
    }

    /// Handle equals in conversion mode.
    private func inputConversionEquals() {
        if conversionPendingOperation != nil {
            performConversionCalculation()
            conversionPendingOperation = nil
        }
        activeOperation = nil
        conversionEnteringNumber = false
    }

    /// Handle percent in conversion mode.
    private func inputConversionPercent() {
        let current = conversionCurrentValue
        let value: Double
        if conversionPendingOperation == .add || conversionPendingOperation == .subtract {
            value = conversionAccumulator * current / 100.0
        } else {
            value = current / 100.0
        }
        setConversionText(value)
        conversionEnteringNumber = false
    }

    /// Perform the pending arithmetic calculation in conversion mode.
    private func performConversionCalculation() {
        guard let operation = conversionPendingOperation else { return }
        let operand = conversionCurrentValue
        let result: Double
        switch operation {
        case .add:
            result = conversionAccumulator + operand
        case .subtract:
            result = conversionAccumulator - operand
        case .multiply:
            result = conversionAccumulator * operand
        case .divide:
            if operand == 0.0 {
                if isEditingSource {
                    sourceText = "Error"
                    targetText = "Error"
                } else {
                    targetText = "Error"
                    sourceText = "Error"
                }
                return
            }
            result = conversionAccumulator / operand
        case .power:
            result = pow(conversionAccumulator, operand)
        case .yRoot:
            result = pow(conversionAccumulator, 1.0 / operand)
        case .ee:
            result = conversionAccumulator * pow(10.0, operand)
        }
        conversionAccumulator = result
        setConversionText(result)
    }

    // MARK: - Internal Calculation

    private func performCalculation() {
        guard let operation = pendingOperation else { return }
        let operand = displayValue
        performOperation(operation, operand: operand)
    }

    private func performOperation(_ operation: CalcOperation, operand: Real) {
        let result: Real
        switch operation {
        case .add:
            result = accumulator.add(operand)
        case .subtract:
            result = accumulator.subtract(operand)
        case .multiply:
            result = accumulator.multiply(operand)
        case .divide:
            if operand.isZero {
                displayText = "Error"
                isEnteringNumber = false
                pendingOperation = nil
                activeOperation = nil
                isAllClear = true
                return
            }
            result = accumulator.divide(operand)
        case .power:
            result = Real.pow(accumulator, operand)
        case .yRoot:
            if operand.isZero {
                displayText = "Error"
                isEnteringNumber = false
                pendingOperation = nil
                activeOperation = nil
                isAllClear = true
                return
            }
            result = Real.pow(accumulator, operand.reciprocal())
        case .ee:
            result = accumulator.multiply(Real.pow(Real.ten, operand))
        }
        if result.isError {
            displayText = "Error"
            isEnteringNumber = false
            pendingOperation = nil
            activeOperation = nil
            isAllClear = true
            return
        }
        accumulator = result
        lastResult = result
        displayText = CalculatorModel.formatReal(result)
    }

    // MARK: - Number Formatting

    /// Format a Real number for display.
    public static func formatReal(_ number: Real) -> String {
        return number.toDisplayString()
    }

    /// Format a Double for display (used by conversion mode).
    public static func formatDouble(_ number: Double) -> String {
        if number.isNaN || number.isInfinite {
            return "Error"
        }
        if number == 0.0 {
            return "0"
        }
        let absNumber = number < 0 ? -number : number
        // Whole numbers within display range — avoid Int64 overflow
        if absNumber < 1e15 && absNumber == floor(absNumber) {
            return "\(Int64(number))"
        }
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

    /// Backwards-compatible alias for formatDouble.
    public static func formatNumber(_ number: Double) -> String {
        return formatDouble(number)
    }
}
