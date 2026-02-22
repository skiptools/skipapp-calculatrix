import SwiftUI
import CalculatrixModel

/// The main calculator view with display and button grid.
struct ContentView: View {
    @State var calculator = CalculatorModel()

    var body: some View {
        GeometryReader { geometry in
            let isScientific = geometry.size.width > geometry.size.height

            if isScientific {
                scientificLayout(geometry: geometry)
            } else {
                standardLayout(geometry: geometry)
            }
        }
        .background(Color.black)
    }

    // MARK: - Standard Layout (Portrait)

    func standardLayout(geometry: GeometryProxy) -> some View {
        let spacing: CGFloat = 12
        let buttonSize = (geometry.size.width - spacing * 5) / 4

        return VStack(spacing: spacing) {
            Spacer()

            // Display
            HStack {
                Spacer()
                Text(calculator.displayText)
                    .font(.system(size: 64))
                    .fontWeight(.light)
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.3)
                    .lineLimit(1)
                    .accessibilityIdentifier("display")
                    .accessibilityLabel(calculator.displayText)
            }
            .padding(.horizontal, spacing)
            .padding(.bottom, 8)

            // Row 1: AC/C, ±, %, ÷
            HStack(spacing: spacing) {
                CalculatorButton(
                    label: calculator.isAllClear ? "AC" : "C",
                    size: buttonSize,
                    backgroundColor: Color(red: 0.65, green: 0.65, blue: 0.65),
                    foregroundColor: .black
                ) {
                    calculator.inputClear()
                }
                .accessibilityIdentifier("clear")
                .accessibilityLabel(calculator.isAllClear ? "All Clear" : "Clear")

                CalculatorButton(
                    label: "±",
                    size: buttonSize,
                    backgroundColor: Color(red: 0.65, green: 0.65, blue: 0.65),
                    foregroundColor: .black
                ) {
                    calculator.inputNegate()
                }
                .accessibilityIdentifier("negate")
                .accessibilityLabel("Negate")

                CalculatorButton(
                    label: "%",
                    size: buttonSize,
                    backgroundColor: Color(red: 0.65, green: 0.65, blue: 0.65),
                    foregroundColor: .black
                ) {
                    calculator.inputPercent()
                }
                .accessibilityIdentifier("percent")
                .accessibilityLabel("Percent")

                CalcOperationButton(
                    operation: .divide,
                    label: "÷",
                    size: buttonSize,
                    activeOperation: calculator.activeOperation
                ) {
                    calculator.inputOperation(.divide)
                }
                .accessibilityIdentifier("divide")
                .accessibilityLabel("Divide")
            }

            // Row 2: 7, 8, 9, ×
            HStack(spacing: spacing) {
                DigitButton(digit: 7, size: buttonSize) { calculator.inputDigit(7) }
                    .accessibilityIdentifier("digit-7")
                    .accessibilityLabel("Seven")
                DigitButton(digit: 8, size: buttonSize) { calculator.inputDigit(8) }
                    .accessibilityIdentifier("digit-8")
                    .accessibilityLabel("Eight")
                DigitButton(digit: 9, size: buttonSize) { calculator.inputDigit(9) }
                    .accessibilityIdentifier("digit-9")
                    .accessibilityLabel("Nine")
                CalcOperationButton(
                    operation: .multiply,
                    label: "×",
                    size: buttonSize,
                    activeOperation: calculator.activeOperation
                ) {
                    calculator.inputOperation(.multiply)
                }
                .accessibilityIdentifier("multiply")
                .accessibilityLabel("Multiply")
            }

            // Row 3: 4, 5, 6, −
            HStack(spacing: spacing) {
                DigitButton(digit: 4, size: buttonSize) { calculator.inputDigit(4) }
                    .accessibilityIdentifier("digit-4")
                    .accessibilityLabel("Four")
                DigitButton(digit: 5, size: buttonSize) { calculator.inputDigit(5) }
                    .accessibilityIdentifier("digit-5")
                    .accessibilityLabel("Five")
                DigitButton(digit: 6, size: buttonSize) { calculator.inputDigit(6) }
                    .accessibilityIdentifier("digit-6")
                    .accessibilityLabel("Six")
                CalcOperationButton(
                    operation: .subtract,
                    label: "−",
                    size: buttonSize,
                    activeOperation: calculator.activeOperation
                ) {
                    calculator.inputOperation(.subtract)
                }
                .accessibilityIdentifier("subtract")
                .accessibilityLabel("Subtract")
            }

            // Row 4: 1, 2, 3, +
            HStack(spacing: spacing) {
                DigitButton(digit: 1, size: buttonSize) { calculator.inputDigit(1) }
                    .accessibilityIdentifier("digit-1")
                    .accessibilityLabel("One")
                DigitButton(digit: 2, size: buttonSize) { calculator.inputDigit(2) }
                    .accessibilityIdentifier("digit-2")
                    .accessibilityLabel("Two")
                DigitButton(digit: 3, size: buttonSize) { calculator.inputDigit(3) }
                    .accessibilityIdentifier("digit-3")
                    .accessibilityLabel("Three")
                CalcOperationButton(
                    operation: .add,
                    label: "+",
                    size: buttonSize,
                    activeOperation: calculator.activeOperation
                ) {
                    calculator.inputOperation(.add)
                }
                .accessibilityIdentifier("add")
                .accessibilityLabel("Add")
            }

            // Row 5: 0 (wide), ., =
            HStack(spacing: spacing) {
                CalculatorButton(
                    label: "0",
                    size: buttonSize,
                    isWide: true,
                    spacing: spacing,
                    backgroundColor: Color(red: 0.2, green: 0.2, blue: 0.2),
                    foregroundColor: .white
                ) {
                    calculator.inputDigit(0)
                }
                .accessibilityIdentifier("digit-0")
                .accessibilityLabel("Zero")

                CalculatorButton(
                    label: ".",
                    size: buttonSize,
                    backgroundColor: Color(red: 0.2, green: 0.2, blue: 0.2),
                    foregroundColor: .white
                ) {
                    calculator.inputDecimal()
                }
                .accessibilityIdentifier("decimal")
                .accessibilityLabel("Decimal")

                CalculatorButton(
                    label: "=",
                    size: buttonSize,
                    backgroundColor: .orange,
                    foregroundColor: .white
                ) {
                    calculator.inputEquals()
                }
                .accessibilityIdentifier("equals")
                .accessibilityLabel("Equals")
            }
        }
        .padding(spacing)
    }

    // MARK: - Scientific Layout (Landscape)

    func scientificLayout(geometry: GeometryProxy) -> some View {
        let spacing: CGFloat = 8
        let columns = 10
        let buttonWidth = (geometry.size.width - spacing * CGFloat(columns + 1)) / CGFloat(columns)
        let rows = 5
        let displayHeight: CGFloat = 50
        let topPadding: CGFloat = 8
        let buttonHeight = (geometry.size.height - spacing * CGFloat(rows + 1) - displayHeight - topPadding) / CGFloat(rows)
        let sciColor = Color(red: 0.2, green: 0.2, blue: 0.2)
        let funcColor = Color(red: 0.65, green: 0.65, blue: 0.65)
        let fontSize: CGFloat = min(buttonHeight * 0.35, 18)
        let is2nd = calculator.isSecondFunction

        return VStack(spacing: spacing) {
            // Display
            HStack {
                if calculator.useRadians {
                    Text("Rad")
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.6))
                        .accessibilityIdentifier("rad-indicator")
                        .accessibilityLabel("Radians mode")
                }
                Spacer()
                Text(calculator.displayText)
                    .font(.system(size: displayHeight * 0.8))
                    .fontWeight(.light)
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.3)
                    .lineLimit(1)
                    .accessibilityIdentifier("display")
                    .accessibilityLabel(calculator.displayText)
            }
            .frame(height: displayHeight)
            .padding(.horizontal, spacing)
            .padding(.top, topPadding)

            // Row 1: ( ) mc m+ m- mr | AC ± % ÷
            HStack(spacing: spacing) {
                SciButton(label: "(", w: buttonWidth, h: buttonHeight, fontSize: fontSize, bg: sciColor) {
                    calculator.inputOpenParenthesis()
                }
                .accessibilityIdentifier("open-parenthesis")
                .accessibilityLabel("Open Parenthesis")

                SciButton(label: ")", w: buttonWidth, h: buttonHeight, fontSize: fontSize, bg: sciColor) {
                    calculator.inputCloseParenthesis()
                }
                .accessibilityIdentifier("close-parenthesis")
                .accessibilityLabel("Close Parenthesis")

                SciButton(label: "mc", w: buttonWidth, h: buttonHeight, fontSize: fontSize, bg: sciColor) {
                    calculator.memoryClear()
                }
                .accessibilityIdentifier("memory-clear")
                .accessibilityLabel("Memory Clear")

                SciButton(label: "m+", w: buttonWidth, h: buttonHeight, fontSize: fontSize, bg: sciColor) {
                    calculator.memoryAdd()
                }
                .accessibilityIdentifier("memory-add")
                .accessibilityLabel("Memory Add")

                SciButton(label: "m-", w: buttonWidth, h: buttonHeight, fontSize: fontSize, bg: sciColor) {
                    calculator.memorySubtract()
                }
                .accessibilityIdentifier("memory-subtract")
                .accessibilityLabel("Memory Subtract")

                SciButton(label: "mr", w: buttonWidth, h: buttonHeight, fontSize: fontSize, bg: sciColor) {
                    calculator.memoryRecall()
                }
                .accessibilityIdentifier("memory-recall")
                .accessibilityLabel("Memory Recall")

                SciButton(label: calculator.isAllClear ? "AC" : "C", w: buttonWidth, h: buttonHeight, fontSize: fontSize, bg: funcColor, fg: .black) {
                    calculator.inputClear()
                }
                .accessibilityIdentifier("clear")
                .accessibilityLabel(calculator.isAllClear ? "All Clear" : "Clear")

                SciButton(label: "±", w: buttonWidth, h: buttonHeight, fontSize: fontSize, bg: funcColor, fg: .black) {
                    calculator.inputNegate()
                }
                .accessibilityIdentifier("negate")
                .accessibilityLabel("Negate")

                SciButton(label: "%", w: buttonWidth, h: buttonHeight, fontSize: fontSize, bg: funcColor, fg: .black) {
                    calculator.inputPercent()
                }
                .accessibilityIdentifier("percent")
                .accessibilityLabel("Percent")

                SciOpButton(operation: .divide, label: "÷", w: buttonWidth, h: buttonHeight, fontSize: fontSize, activeOp: calculator.activeOperation) {
                    calculator.inputOperation(.divide)
                }
                .accessibilityIdentifier("divide")
                .accessibilityLabel("Divide")
            }

            // Row 2: 2nd x² x³ xʸ eˣ 10ˣ/2ˣ | 7 8 9 ×
            HStack(spacing: spacing) {
                SciButton(label: "2nd", w: buttonWidth, h: buttonHeight, fontSize: fontSize, bg: is2nd ? Color(red: 0.45, green: 0.45, blue: 0.45) : sciColor) {
                    calculator.toggleSecondFunction()
                }
                .accessibilityIdentifier("second-function")
                .accessibilityLabel("Second Function")

                SciButton(label: "x²", w: buttonWidth, h: buttonHeight, fontSize: fontSize, bg: sciColor) {
                    calculator.inputScientificUnary("x²")
                }
                .accessibilityIdentifier("x-squared")
                .accessibilityLabel("X Squared")

                SciButton(label: "x³", w: buttonWidth, h: buttonHeight, fontSize: fontSize, bg: sciColor) {
                    calculator.inputScientificUnary("x³")
                }
                .accessibilityIdentifier("x-cubed")
                .accessibilityLabel("X Cubed")

                SciOpButton(operation: .power, label: "xʸ", w: buttonWidth, h: buttonHeight, fontSize: fontSize, activeOp: calculator.activeOperation) {
                    calculator.inputOperation(.power)
                }
                .accessibilityIdentifier("power")
                .accessibilityLabel("Power")

                SciButton(label: "eˣ", w: buttonWidth, h: buttonHeight, fontSize: fontSize, bg: sciColor) {
                    calculator.inputScientificUnary("eˣ")
                }
                .accessibilityIdentifier("e-to-x")
                .accessibilityLabel("E to the Power of X")

                SciButton(label: is2nd ? "2ˣ" : "10ˣ", w: buttonWidth, h: buttonHeight, fontSize: fontSize, bg: sciColor) {
                    calculator.inputScientificUnary(is2nd ? "2ˣ" : "10ˣ")
                }
                .accessibilityIdentifier(is2nd ? "two-to-x" : "ten-to-x")
                .accessibilityLabel(is2nd ? "Two to the Power of X" : "Ten to the Power of X")

                SciButton(label: "7", w: buttonWidth, h: buttonHeight, fontSize: fontSize, bg: sciColor) {
                    calculator.inputDigit(7)
                }
                .accessibilityIdentifier("digit-7")
                .accessibilityLabel("Seven")

                SciButton(label: "8", w: buttonWidth, h: buttonHeight, fontSize: fontSize, bg: sciColor) {
                    calculator.inputDigit(8)
                }
                .accessibilityIdentifier("digit-8")
                .accessibilityLabel("Eight")

                SciButton(label: "9", w: buttonWidth, h: buttonHeight, fontSize: fontSize, bg: sciColor) {
                    calculator.inputDigit(9)
                }
                .accessibilityIdentifier("digit-9")
                .accessibilityLabel("Nine")

                SciOpButton(operation: .multiply, label: "×", w: buttonWidth, h: buttonHeight, fontSize: fontSize, activeOp: calculator.activeOperation) {
                    calculator.inputOperation(.multiply)
                }
                .accessibilityIdentifier("multiply")
                .accessibilityLabel("Multiply")
            }

            // Row 3: 1/x √x ³√x ʸ√x ln log₁₀/log₂ | 4 5 6 −
            HStack(spacing: spacing) {
                SciButton(label: "1/x", w: buttonWidth, h: buttonHeight, fontSize: fontSize, bg: sciColor) {
                    calculator.inputScientificUnary("1/x")
                }
                .accessibilityIdentifier("reciprocal")
                .accessibilityLabel("Reciprocal")

                SciButton(label: "√x", w: buttonWidth, h: buttonHeight, fontSize: fontSize, bg: sciColor) {
                    calculator.inputScientificUnary("√x")
                }
                .accessibilityIdentifier("square-root")
                .accessibilityLabel("Square Root")

                SciButton(label: "³√x", w: buttonWidth, h: buttonHeight, fontSize: fontSize, bg: sciColor) {
                    calculator.inputScientificUnary("³√x")
                }
                .accessibilityIdentifier("cube-root")
                .accessibilityLabel("Cube Root")

                SciOpButton(operation: .yRoot, label: "ʸ√x", w: buttonWidth, h: buttonHeight, fontSize: fontSize, activeOp: calculator.activeOperation) {
                    calculator.inputOperation(.yRoot)
                }
                .accessibilityIdentifier("y-root")
                .accessibilityLabel("Y Root of X")

                SciButton(label: "ln", w: buttonWidth, h: buttonHeight, fontSize: fontSize, bg: sciColor) {
                    calculator.inputScientificUnary("ln")
                }
                .accessibilityIdentifier("natural-log")
                .accessibilityLabel("Natural Logarithm")

                SciButton(label: is2nd ? "log₂" : "log₁₀", w: buttonWidth, h: buttonHeight, fontSize: fontSize, bg: sciColor) {
                    calculator.inputScientificUnary(is2nd ? "log₂" : "log₁₀")
                }
                .accessibilityIdentifier(is2nd ? "log-base-2" : "log-base-10")
                .accessibilityLabel(is2nd ? "Log Base Two" : "Log Base Ten")

                SciButton(label: "4", w: buttonWidth, h: buttonHeight, fontSize: fontSize, bg: sciColor) {
                    calculator.inputDigit(4)
                }
                .accessibilityIdentifier("digit-4")
                .accessibilityLabel("Four")

                SciButton(label: "5", w: buttonWidth, h: buttonHeight, fontSize: fontSize, bg: sciColor) {
                    calculator.inputDigit(5)
                }
                .accessibilityIdentifier("digit-5")
                .accessibilityLabel("Five")

                SciButton(label: "6", w: buttonWidth, h: buttonHeight, fontSize: fontSize, bg: sciColor) {
                    calculator.inputDigit(6)
                }
                .accessibilityIdentifier("digit-6")
                .accessibilityLabel("Six")

                SciOpButton(operation: .subtract, label: "−", w: buttonWidth, h: buttonHeight, fontSize: fontSize, activeOp: calculator.activeOperation) {
                    calculator.inputOperation(.subtract)
                }
                .accessibilityIdentifier("subtract")
                .accessibilityLabel("Subtract")
            }

            // Row 4: x! sin/sin⁻¹ cos/cos⁻¹ tan/tan⁻¹ e EE | 1 2 3 +
            HStack(spacing: spacing) {
                SciButton(label: "x!", w: buttonWidth, h: buttonHeight, fontSize: fontSize, bg: sciColor) {
                    calculator.inputScientificUnary("x!")
                }
                .accessibilityIdentifier("factorial")
                .accessibilityLabel("Factorial")

                SciButton(label: is2nd ? "sin⁻¹" : "sin", w: buttonWidth, h: buttonHeight, fontSize: fontSize, bg: sciColor) {
                    calculator.inputScientificUnary(is2nd ? "sin⁻¹" : "sin")
                }
                .accessibilityIdentifier(is2nd ? "arc-sine" : "sine")
                .accessibilityLabel(is2nd ? "Arc Sine" : "Sine")

                SciButton(label: is2nd ? "cos⁻¹" : "cos", w: buttonWidth, h: buttonHeight, fontSize: fontSize, bg: sciColor) {
                    calculator.inputScientificUnary(is2nd ? "cos⁻¹" : "cos")
                }
                .accessibilityIdentifier(is2nd ? "arc-cosine" : "cosine")
                .accessibilityLabel(is2nd ? "Arc Cosine" : "Cosine")

                SciButton(label: is2nd ? "tan⁻¹" : "tan", w: buttonWidth, h: buttonHeight, fontSize: fontSize, bg: sciColor) {
                    calculator.inputScientificUnary(is2nd ? "tan⁻¹" : "tan")
                }
                .accessibilityIdentifier(is2nd ? "arc-tangent" : "tangent")
                .accessibilityLabel(is2nd ? "Arc Tangent" : "Tangent")

                SciButton(label: "e", w: buttonWidth, h: buttonHeight, fontSize: fontSize, bg: sciColor) {
                    calculator.inputConstant("e")
                }
                .accessibilityIdentifier("euler-number")
                .accessibilityLabel("Euler's Number")

                SciOpButton(operation: .ee, label: "EE", w: buttonWidth, h: buttonHeight, fontSize: fontSize, activeOp: calculator.activeOperation) {
                    calculator.inputOperation(.ee)
                }
                .accessibilityIdentifier("scientific-notation")
                .accessibilityLabel("Scientific Notation")

                SciButton(label: "1", w: buttonWidth, h: buttonHeight, fontSize: fontSize, bg: sciColor) {
                    calculator.inputDigit(1)
                }
                .accessibilityIdentifier("digit-1")
                .accessibilityLabel("One")

                SciButton(label: "2", w: buttonWidth, h: buttonHeight, fontSize: fontSize, bg: sciColor) {
                    calculator.inputDigit(2)
                }
                .accessibilityIdentifier("digit-2")
                .accessibilityLabel("Two")

                SciButton(label: "3", w: buttonWidth, h: buttonHeight, fontSize: fontSize, bg: sciColor) {
                    calculator.inputDigit(3)
                }
                .accessibilityIdentifier("digit-3")
                .accessibilityLabel("Three")

                SciOpButton(operation: .add, label: "+", w: buttonWidth, h: buttonHeight, fontSize: fontSize, activeOp: calculator.activeOperation) {
                    calculator.inputOperation(.add)
                }
                .accessibilityIdentifier("add")
                .accessibilityLabel("Add")
            }

            // Row 5: Rad sinh/sinh⁻¹ cosh/cosh⁻¹ tanh/tanh⁻¹ π Rand | 0(wide) . =
            HStack(spacing: spacing) {
                SciButton(label: calculator.useRadians ? "Deg" : "Rad", w: buttonWidth, h: buttonHeight, fontSize: fontSize, bg: sciColor) {
                    calculator.toggleRadDeg()
                }
                .accessibilityIdentifier("rad-deg-toggle")
                .accessibilityLabel(calculator.useRadians ? "Switch to Degrees" : "Switch to Radians")

                SciButton(label: is2nd ? "sinh⁻¹" : "sinh", w: buttonWidth, h: buttonHeight, fontSize: fontSize, bg: sciColor) {
                    calculator.inputScientificUnary(is2nd ? "sinh⁻¹" : "sinh")
                }
                .accessibilityIdentifier(is2nd ? "arc-hyperbolic-sine" : "hyperbolic-sine")
                .accessibilityLabel(is2nd ? "Inverse Hyperbolic Sine" : "Hyperbolic Sine")

                SciButton(label: is2nd ? "cosh⁻¹" : "cosh", w: buttonWidth, h: buttonHeight, fontSize: fontSize, bg: sciColor) {
                    calculator.inputScientificUnary(is2nd ? "cosh⁻¹" : "cosh")
                }
                .accessibilityIdentifier(is2nd ? "arc-hyperbolic-cosine" : "hyperbolic-cosine")
                .accessibilityLabel(is2nd ? "Inverse Hyperbolic Cosine" : "Hyperbolic Cosine")

                SciButton(label: is2nd ? "tanh⁻¹" : "tanh", w: buttonWidth, h: buttonHeight, fontSize: fontSize, bg: sciColor) {
                    calculator.inputScientificUnary(is2nd ? "tanh⁻¹" : "tanh")
                }
                .accessibilityIdentifier(is2nd ? "arc-hyperbolic-tangent" : "hyperbolic-tangent")
                .accessibilityLabel(is2nd ? "Inverse Hyperbolic Tangent" : "Hyperbolic Tangent")

                SciButton(label: "π", w: buttonWidth, h: buttonHeight, fontSize: fontSize, bg: sciColor) {
                    calculator.inputConstant("π")
                }
                .accessibilityIdentifier("pi")
                .accessibilityLabel("Pi")

                SciButton(label: "Rand", w: buttonWidth, h: buttonHeight, fontSize: fontSize, bg: sciColor) {
                    calculator.inputConstant("Rand")
                }
                .accessibilityIdentifier("random")
                .accessibilityLabel("Random Number")

                SciButton(label: "0", w: buttonWidth * 2 + spacing, h: buttonHeight, fontSize: fontSize, bg: sciColor) {
                    calculator.inputDigit(0)
                }
                .accessibilityIdentifier("digit-0")
                .accessibilityLabel("Zero")

                SciButton(label: ".", w: buttonWidth, h: buttonHeight, fontSize: fontSize, bg: sciColor) {
                    calculator.inputDecimal()
                }
                .accessibilityIdentifier("decimal")
                .accessibilityLabel("Decimal")

                SciButton(label: "=", w: buttonWidth, h: buttonHeight, fontSize: fontSize, bg: .orange) {
                    calculator.inputEquals()
                }
                .accessibilityIdentifier("equals")
                .accessibilityLabel("Equals")
            }
        }
        .padding(spacing)
    }
}

// MARK: - Standard Mode Buttons

/// A digit button (0-9) with dark gray background.
struct DigitButton: View {
    let digit: Int
    let size: CGFloat
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("\(digit)")
                .font(.system(size: 32))
                .foregroundStyle(.white)
                .frame(width: size, height: size)
                .background(Color(red: 0.2, green: 0.2, blue: 0.2))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }
}

/// An operation button (+, −, ×, ÷) that highlights when active.
struct CalcOperationButton: View {
    let operation: CalcOperation
    let label: String
    let size: CGFloat
    let activeOperation: CalcOperation?
    let action: () -> Void

    var body: some View {
        let isActive = activeOperation == operation
        Button(action: action) {
            Text(label)
                .font(.system(size: 32))
                .foregroundStyle(isActive ? .orange : .white)
                .frame(width: size, height: size)
                .background(isActive ? Color.white : Color.orange)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }
}

/// A general calculator button with configurable appearance.
struct CalculatorButton: View {
    let label: String
    let size: CGFloat
    var isWide: Bool = false
    var spacing: CGFloat = 12
    let backgroundColor: Color
    var foregroundColor: Color = .white
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 32))
                .foregroundStyle(foregroundColor)
                .frame(width: isWide ? size * 2 + spacing : size, height: size)
                .background(backgroundColor)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Scientific Mode Buttons

/// A rectangular button for the scientific calculator layout.
struct SciButton: View {
    let label: String
    var w: CGFloat
    var h: CGFloat
    var fontSize: CGFloat = 16
    var bg: Color = Color(red: 0.2, green: 0.2, blue: 0.2)
    var fg: Color = .white
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: fontSize))
                .foregroundStyle(fg)
                .frame(width: w, height: h)
                .background(bg)
                .clipShape(RoundedRectangle(cornerRadius: h / 4))
        }
        .buttonStyle(.plain)
    }
}

/// An operation button for scientific layout that highlights when active.
struct SciOpButton: View {
    let operation: CalcOperation
    let label: String
    var w: CGFloat
    var h: CGFloat
    var fontSize: CGFloat = 16
    let activeOp: CalcOperation?
    let action: () -> Void

    var body: some View {
        let isActive = activeOp == operation
        Button(action: action) {
            Text(label)
                .font(.system(size: fontSize))
                .foregroundStyle(isActive ? .orange : .white)
                .frame(width: w, height: h)
                .background(isActive ? Color.white : Color.orange)
                .clipShape(RoundedRectangle(cornerRadius: h / 4))
        }
        .buttonStyle(.plain)
    }
}
