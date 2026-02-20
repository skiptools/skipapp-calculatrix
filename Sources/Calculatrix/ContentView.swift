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
                CalculatorButton(
                    label: "±",
                    size: buttonSize,
                    backgroundColor: Color(red: 0.65, green: 0.65, blue: 0.65),
                    foregroundColor: .black
                ) {
                    calculator.inputNegate()
                }
                CalculatorButton(
                    label: "%",
                    size: buttonSize,
                    backgroundColor: Color(red: 0.65, green: 0.65, blue: 0.65),
                    foregroundColor: .black
                ) {
                    calculator.inputPercent()
                }
                CalcOperationButton(
                    operation: .divide,
                    label: "÷",
                    size: buttonSize,
                    activeOperation: calculator.activeOperation
                ) {
                    calculator.inputOperation(.divide)
                }
            }

            // Row 2: 7, 8, 9, ×
            HStack(spacing: spacing) {
                DigitButton(digit: 7, size: buttonSize) { calculator.inputDigit(7) }
                DigitButton(digit: 8, size: buttonSize) { calculator.inputDigit(8) }
                DigitButton(digit: 9, size: buttonSize) { calculator.inputDigit(9) }
                CalcOperationButton(
                    operation: .multiply,
                    label: "×",
                    size: buttonSize,
                    activeOperation: calculator.activeOperation
                ) {
                    calculator.inputOperation(.multiply)
                }
            }

            // Row 3: 4, 5, 6, −
            HStack(spacing: spacing) {
                DigitButton(digit: 4, size: buttonSize) { calculator.inputDigit(4) }
                DigitButton(digit: 5, size: buttonSize) { calculator.inputDigit(5) }
                DigitButton(digit: 6, size: buttonSize) { calculator.inputDigit(6) }
                CalcOperationButton(
                    operation: .subtract,
                    label: "−",
                    size: buttonSize,
                    activeOperation: calculator.activeOperation
                ) {
                    calculator.inputOperation(.subtract)
                }
            }

            // Row 4: 1, 2, 3, +
            HStack(spacing: spacing) {
                DigitButton(digit: 1, size: buttonSize) { calculator.inputDigit(1) }
                DigitButton(digit: 2, size: buttonSize) { calculator.inputDigit(2) }
                DigitButton(digit: 3, size: buttonSize) { calculator.inputDigit(3) }
                CalcOperationButton(
                    operation: .add,
                    label: "+",
                    size: buttonSize,
                    activeOperation: calculator.activeOperation
                ) {
                    calculator.inputOperation(.add)
                }
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
                CalculatorButton(
                    label: ".",
                    size: buttonSize,
                    backgroundColor: Color(red: 0.2, green: 0.2, blue: 0.2),
                    foregroundColor: .white
                ) {
                    calculator.inputDecimal()
                }
                CalculatorButton(
                    label: "=",
                    size: buttonSize,
                    backgroundColor: .orange,
                    foregroundColor: .white
                ) {
                    calculator.inputEquals()
                }
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
                }
                Spacer()
                Text(calculator.displayText)
                    .font(.system(size: displayHeight * 0.8))
                    .fontWeight(.light)
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.3)
                    .lineLimit(1)
            }
            .frame(height: displayHeight)
            .padding(.horizontal, spacing)
            .padding(.top, topPadding)

            // Row 1: ( ) mc m+ m- mr | AC ± % ÷
            HStack(spacing: spacing) {
                SciButton(label: "(", w: buttonWidth, h: buttonHeight, fontSize: fontSize, bg: sciColor) {
                    calculator.inputOpenParenthesis()
                }
                SciButton(label: ")", w: buttonWidth, h: buttonHeight, fontSize: fontSize, bg: sciColor) {
                    calculator.inputCloseParenthesis()
                }
                SciButton(label: "mc", w: buttonWidth, h: buttonHeight, fontSize: fontSize, bg: sciColor) {
                    calculator.memoryClear()
                }
                SciButton(label: "m+", w: buttonWidth, h: buttonHeight, fontSize: fontSize, bg: sciColor) {
                    calculator.memoryAdd()
                }
                SciButton(label: "m-", w: buttonWidth, h: buttonHeight, fontSize: fontSize, bg: sciColor) {
                    calculator.memorySubtract()
                }
                SciButton(label: "mr", w: buttonWidth, h: buttonHeight, fontSize: fontSize, bg: sciColor) {
                    calculator.memoryRecall()
                }
                SciButton(label: calculator.isAllClear ? "AC" : "C", w: buttonWidth, h: buttonHeight, fontSize: fontSize, bg: funcColor, fg: .black) {
                    calculator.inputClear()
                }
                SciButton(label: "±", w: buttonWidth, h: buttonHeight, fontSize: fontSize, bg: funcColor, fg: .black) {
                    calculator.inputNegate()
                }
                SciButton(label: "%", w: buttonWidth, h: buttonHeight, fontSize: fontSize, bg: funcColor, fg: .black) {
                    calculator.inputPercent()
                }
                SciOpButton(operation: .divide, label: "÷", w: buttonWidth, h: buttonHeight, fontSize: fontSize, activeOp: calculator.activeOperation) {
                    calculator.inputOperation(.divide)
                }
            }

            // Row 2: 2nd x² x³ xʸ eˣ 10ˣ/2ˣ | 7 8 9 ×
            HStack(spacing: spacing) {
                SciButton(label: "2nd", w: buttonWidth, h: buttonHeight, fontSize: fontSize, bg: is2nd ? Color(red: 0.45, green: 0.45, blue: 0.45) : sciColor) {
                    calculator.toggleSecondFunction()
                }
                SciButton(label: "x²", w: buttonWidth, h: buttonHeight, fontSize: fontSize, bg: sciColor) {
                    calculator.inputScientificUnary("x²")
                }
                SciButton(label: "x³", w: buttonWidth, h: buttonHeight, fontSize: fontSize, bg: sciColor) {
                    calculator.inputScientificUnary("x³")
                }
                SciOpButton(operation: .power, label: "xʸ", w: buttonWidth, h: buttonHeight, fontSize: fontSize, activeOp: calculator.activeOperation) {
                    calculator.inputOperation(.power)
                }
                SciButton(label: "eˣ", w: buttonWidth, h: buttonHeight, fontSize: fontSize, bg: sciColor) {
                    calculator.inputScientificUnary("eˣ")
                }
                SciButton(label: is2nd ? "2ˣ" : "10ˣ", w: buttonWidth, h: buttonHeight, fontSize: fontSize, bg: sciColor) {
                    calculator.inputScientificUnary(is2nd ? "2ˣ" : "10ˣ")
                }
                SciButton(label: "7", w: buttonWidth, h: buttonHeight, fontSize: fontSize, bg: sciColor) {
                    calculator.inputDigit(7)
                }
                SciButton(label: "8", w: buttonWidth, h: buttonHeight, fontSize: fontSize, bg: sciColor) {
                    calculator.inputDigit(8)
                }
                SciButton(label: "9", w: buttonWidth, h: buttonHeight, fontSize: fontSize, bg: sciColor) {
                    calculator.inputDigit(9)
                }
                SciOpButton(operation: .multiply, label: "×", w: buttonWidth, h: buttonHeight, fontSize: fontSize, activeOp: calculator.activeOperation) {
                    calculator.inputOperation(.multiply)
                }
            }

            // Row 3: 1/x √x ³√x ʸ√x ln log₁₀/log₂ | 4 5 6 −
            HStack(spacing: spacing) {
                SciButton(label: "1/x", w: buttonWidth, h: buttonHeight, fontSize: fontSize, bg: sciColor) {
                    calculator.inputScientificUnary("1/x")
                }
                SciButton(label: "√x", w: buttonWidth, h: buttonHeight, fontSize: fontSize, bg: sciColor) {
                    calculator.inputScientificUnary("√x")
                }
                SciButton(label: "³√x", w: buttonWidth, h: buttonHeight, fontSize: fontSize, bg: sciColor) {
                    calculator.inputScientificUnary("³√x")
                }
                SciOpButton(operation: .yRoot, label: "ʸ√x", w: buttonWidth, h: buttonHeight, fontSize: fontSize, activeOp: calculator.activeOperation) {
                    calculator.inputOperation(.yRoot)
                }
                SciButton(label: "ln", w: buttonWidth, h: buttonHeight, fontSize: fontSize, bg: sciColor) {
                    calculator.inputScientificUnary("ln")
                }
                SciButton(label: is2nd ? "log₂" : "log₁₀", w: buttonWidth, h: buttonHeight, fontSize: fontSize, bg: sciColor) {
                    calculator.inputScientificUnary(is2nd ? "log₂" : "log₁₀")
                }
                SciButton(label: "4", w: buttonWidth, h: buttonHeight, fontSize: fontSize, bg: sciColor) {
                    calculator.inputDigit(4)
                }
                SciButton(label: "5", w: buttonWidth, h: buttonHeight, fontSize: fontSize, bg: sciColor) {
                    calculator.inputDigit(5)
                }
                SciButton(label: "6", w: buttonWidth, h: buttonHeight, fontSize: fontSize, bg: sciColor) {
                    calculator.inputDigit(6)
                }
                SciOpButton(operation: .subtract, label: "−", w: buttonWidth, h: buttonHeight, fontSize: fontSize, activeOp: calculator.activeOperation) {
                    calculator.inputOperation(.subtract)
                }
            }

            // Row 4: x! sin/sin⁻¹ cos/cos⁻¹ tan/tan⁻¹ e EE | 1 2 3 +
            HStack(spacing: spacing) {
                SciButton(label: "x!", w: buttonWidth, h: buttonHeight, fontSize: fontSize, bg: sciColor) {
                    calculator.inputScientificUnary("x!")
                }
                SciButton(label: is2nd ? "sin⁻¹" : "sin", w: buttonWidth, h: buttonHeight, fontSize: fontSize, bg: sciColor) {
                    calculator.inputScientificUnary(is2nd ? "sin⁻¹" : "sin")
                }
                SciButton(label: is2nd ? "cos⁻¹" : "cos", w: buttonWidth, h: buttonHeight, fontSize: fontSize, bg: sciColor) {
                    calculator.inputScientificUnary(is2nd ? "cos⁻¹" : "cos")
                }
                SciButton(label: is2nd ? "tan⁻¹" : "tan", w: buttonWidth, h: buttonHeight, fontSize: fontSize, bg: sciColor) {
                    calculator.inputScientificUnary(is2nd ? "tan⁻¹" : "tan")
                }
                SciButton(label: "e", w: buttonWidth, h: buttonHeight, fontSize: fontSize, bg: sciColor) {
                    calculator.inputConstant("e")
                }
                SciOpButton(operation: .ee, label: "EE", w: buttonWidth, h: buttonHeight, fontSize: fontSize, activeOp: calculator.activeOperation) {
                    calculator.inputOperation(.ee)
                }
                SciButton(label: "1", w: buttonWidth, h: buttonHeight, fontSize: fontSize, bg: sciColor) {
                    calculator.inputDigit(1)
                }
                SciButton(label: "2", w: buttonWidth, h: buttonHeight, fontSize: fontSize, bg: sciColor) {
                    calculator.inputDigit(2)
                }
                SciButton(label: "3", w: buttonWidth, h: buttonHeight, fontSize: fontSize, bg: sciColor) {
                    calculator.inputDigit(3)
                }
                SciOpButton(operation: .add, label: "+", w: buttonWidth, h: buttonHeight, fontSize: fontSize, activeOp: calculator.activeOperation) {
                    calculator.inputOperation(.add)
                }
            }

            // Row 5: Rad sinh/sinh⁻¹ cosh/cosh⁻¹ tanh/tanh⁻¹ π Rand | 0(wide) . =
            HStack(spacing: spacing) {
                SciButton(label: calculator.useRadians ? "Deg" : "Rad", w: buttonWidth, h: buttonHeight, fontSize: fontSize, bg: sciColor) {
                    calculator.toggleRadDeg()
                }
                SciButton(label: is2nd ? "sinh⁻¹" : "sinh", w: buttonWidth, h: buttonHeight, fontSize: fontSize, bg: sciColor) {
                    calculator.inputScientificUnary(is2nd ? "sinh⁻¹" : "sinh")
                }
                SciButton(label: is2nd ? "cosh⁻¹" : "cosh", w: buttonWidth, h: buttonHeight, fontSize: fontSize, bg: sciColor) {
                    calculator.inputScientificUnary(is2nd ? "cosh⁻¹" : "cosh")
                }
                SciButton(label: is2nd ? "tanh⁻¹" : "tanh", w: buttonWidth, h: buttonHeight, fontSize: fontSize, bg: sciColor) {
                    calculator.inputScientificUnary(is2nd ? "tanh⁻¹" : "tanh")
                }
                SciButton(label: "π", w: buttonWidth, h: buttonHeight, fontSize: fontSize, bg: sciColor) {
                    calculator.inputConstant("π")
                }
                SciButton(label: "Rand", w: buttonWidth, h: buttonHeight, fontSize: fontSize, bg: sciColor) {
                    calculator.inputConstant("Rand")
                }
                SciButton(label: "0", w: buttonWidth * 2 + spacing, h: buttonHeight, fontSize: fontSize, bg: sciColor) {
                    calculator.inputDigit(0)
                }
                SciButton(label: ".", w: buttonWidth, h: buttonHeight, fontSize: fontSize, bg: sciColor) {
                    calculator.inputDecimal()
                }
                SciButton(label: "=", w: buttonWidth, h: buttonHeight, fontSize: fontSize, bg: .orange) {
                    calculator.inputEquals()
                }
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
