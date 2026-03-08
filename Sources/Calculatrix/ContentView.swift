import SwiftUI
import CalculatrixModel

/// The main calculator view with display and button grid.
struct ContentView: View {
    @State var calculator = CalculatorModel()

    var body: some View {
        ZStack {
            GeometryReader { geometry in
                switch calculator.calculatorMode {
                case .basic:
                    standardLayout(geometry: geometry)
                case .scientific:
                    scientificLayout(geometry: geometry)
                case .convert:
                    conversionLayout(geometry: geometry)
                }
            }

            if calculator.isMenuVisible {
                Color.black.opacity(0.5)
                    .onTapGesture { calculator.isMenuVisible = false }
                ModeMenuView(calculator: calculator)
            }
        }
        .background(Color.black)
        .sheet(isPresented: Binding(get: { calculator.isUnitPickerVisible }, set: { calculator.isUnitPickerVisible = $0 })) {
            UnitPickerView(calculator: calculator)
        }
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

            // Row 5: Menu, 0, ., =
            HStack(spacing: spacing) {
                CalculatorButton(
                    label: "\u{2630}",
                    size: buttonSize,
                    backgroundColor: Color(red: 0.2, green: 0.2, blue: 0.2),
                    foregroundColor: .orange
                ) {
                    calculator.isMenuVisible = true
                }
                .accessibilityIdentifier("menu")
                .accessibilityLabel("Menu")

                CalculatorButton(
                    label: "0",
                    size: buttonSize,
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

    // MARK: - Scientific Layout (Vertical)

    func scientificLayout(geometry: GeometryProxy) -> some View {
        let spacing: CGFloat = 8
        let sciColumns = 6
        let basicColumns = 4
        let totalRows = 10 // 5 scientific + 5 basic
        let displayHeight: CGFloat = 50
        let topPadding: CGFloat = 8
        let buttonHeight = (geometry.size.height - spacing * CGFloat(totalRows + 1) - displayHeight - topPadding) / CGFloat(totalRows)
        let sciButtonWidth = (geometry.size.width - spacing * CGFloat(sciColumns + 1)) / CGFloat(sciColumns)
        let basicButtonWidth = (geometry.size.width - spacing * CGFloat(basicColumns + 1)) / CGFloat(basicColumns)
        let sciColor = Color(red: 0.2, green: 0.2, blue: 0.2)
        let funcColor = Color(red: 0.65, green: 0.65, blue: 0.65)
        let sciFontSize: CGFloat = min(buttonHeight * 0.4, 16)
        let basicFontSize: CGFloat = min(buttonHeight * 0.5, 24)
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

            // Scientific Row 1: ( ) mc m+ m- mr
            HStack(spacing: spacing) {
                SciButton(label: "(", w: sciButtonWidth, h: buttonHeight, fontSize: sciFontSize, bg: sciColor) {
                    calculator.inputOpenParenthesis()
                }
                .accessibilityIdentifier("open-parenthesis")
                .accessibilityLabel("Open Parenthesis")

                SciButton(label: ")", w: sciButtonWidth, h: buttonHeight, fontSize: sciFontSize, bg: sciColor) {
                    calculator.inputCloseParenthesis()
                }
                .accessibilityIdentifier("close-parenthesis")
                .accessibilityLabel("Close Parenthesis")

                SciButton(label: "mc", w: sciButtonWidth, h: buttonHeight, fontSize: sciFontSize, bg: sciColor) {
                    calculator.memoryClear()
                }
                .accessibilityIdentifier("memory-clear")
                .accessibilityLabel("Memory Clear")

                SciButton(label: "m+", w: sciButtonWidth, h: buttonHeight, fontSize: sciFontSize, bg: sciColor) {
                    calculator.memoryAdd()
                }
                .accessibilityIdentifier("memory-add")
                .accessibilityLabel("Memory Add")

                SciButton(label: "m-", w: sciButtonWidth, h: buttonHeight, fontSize: sciFontSize, bg: sciColor) {
                    calculator.memorySubtract()
                }
                .accessibilityIdentifier("memory-subtract")
                .accessibilityLabel("Memory Subtract")

                SciButton(label: "mr", w: sciButtonWidth, h: buttonHeight, fontSize: sciFontSize, bg: sciColor) {
                    calculator.memoryRecall()
                }
                .accessibilityIdentifier("memory-recall")
                .accessibilityLabel("Memory Recall")
            }

            // Scientific Row 2: 2nd x² x³ xʸ eˣ 10ˣ/2ˣ
            HStack(spacing: spacing) {
                SciButton(label: "2nd", w: sciButtonWidth, h: buttonHeight, fontSize: sciFontSize, bg: is2nd ? Color(red: 0.45, green: 0.45, blue: 0.45) : sciColor) {
                    calculator.toggleSecondFunction()
                }
                .accessibilityIdentifier("second-function")
                .accessibilityLabel("Second Function")

                SciButton(label: "x²", w: sciButtonWidth, h: buttonHeight, fontSize: sciFontSize, bg: sciColor) {
                    calculator.inputScientificUnary("x²")
                }
                .accessibilityIdentifier("x-squared")
                .accessibilityLabel("X Squared")

                SciButton(label: "x³", w: sciButtonWidth, h: buttonHeight, fontSize: sciFontSize, bg: sciColor) {
                    calculator.inputScientificUnary("x³")
                }
                .accessibilityIdentifier("x-cubed")
                .accessibilityLabel("X Cubed")

                SciOpButton(operation: .power, label: "xʸ", w: sciButtonWidth, h: buttonHeight, fontSize: sciFontSize, activeOp: calculator.activeOperation) {
                    calculator.inputOperation(.power)
                }
                .accessibilityIdentifier("power")
                .accessibilityLabel("Power")

                SciButton(label: "eˣ", w: sciButtonWidth, h: buttonHeight, fontSize: sciFontSize, bg: sciColor) {
                    calculator.inputScientificUnary("eˣ")
                }
                .accessibilityIdentifier("e-to-x")
                .accessibilityLabel("E to the Power of X")

                SciButton(label: is2nd ? "2ˣ" : "10ˣ", w: sciButtonWidth, h: buttonHeight, fontSize: sciFontSize, bg: sciColor) {
                    calculator.inputScientificUnary(is2nd ? "2ˣ" : "10ˣ")
                }
                .accessibilityIdentifier(is2nd ? "two-to-x" : "ten-to-x")
                .accessibilityLabel(is2nd ? "Two to the Power of X" : "Ten to the Power of X")
            }

            // Scientific Row 3: 1/x √x ³√x ʸ√x ln log₁₀/log₂
            HStack(spacing: spacing) {
                SciButton(label: "1/x", w: sciButtonWidth, h: buttonHeight, fontSize: sciFontSize, bg: sciColor) {
                    calculator.inputScientificUnary("1/x")
                }
                .accessibilityIdentifier("reciprocal")
                .accessibilityLabel("Reciprocal")

                SciButton(label: "√x", w: sciButtonWidth, h: buttonHeight, fontSize: sciFontSize, bg: sciColor) {
                    calculator.inputScientificUnary("√x")
                }
                .accessibilityIdentifier("square-root")
                .accessibilityLabel("Square Root")

                SciButton(label: "³√x", w: sciButtonWidth, h: buttonHeight, fontSize: sciFontSize, bg: sciColor) {
                    calculator.inputScientificUnary("³√x")
                }
                .accessibilityIdentifier("cube-root")
                .accessibilityLabel("Cube Root")

                SciOpButton(operation: .yRoot, label: "ʸ√x", w: sciButtonWidth, h: buttonHeight, fontSize: sciFontSize, activeOp: calculator.activeOperation) {
                    calculator.inputOperation(.yRoot)
                }
                .accessibilityIdentifier("y-root")
                .accessibilityLabel("Y Root of X")

                SciButton(label: "ln", w: sciButtonWidth, h: buttonHeight, fontSize: sciFontSize, bg: sciColor) {
                    calculator.inputScientificUnary("ln")
                }
                .accessibilityIdentifier("natural-log")
                .accessibilityLabel("Natural Logarithm")

                SciButton(label: is2nd ? "log₂" : "log₁₀", w: sciButtonWidth, h: buttonHeight, fontSize: sciFontSize, bg: sciColor) {
                    calculator.inputScientificUnary(is2nd ? "log₂" : "log₁₀")
                }
                .accessibilityIdentifier(is2nd ? "log-base-2" : "log-base-10")
                .accessibilityLabel(is2nd ? "Log Base Two" : "Log Base Ten")
            }

            // Scientific Row 4: x! sin cos tan e EE
            HStack(spacing: spacing) {
                SciButton(label: "x!", w: sciButtonWidth, h: buttonHeight, fontSize: sciFontSize, bg: sciColor) {
                    calculator.inputScientificUnary("x!")
                }
                .accessibilityIdentifier("factorial")
                .accessibilityLabel("Factorial")

                SciButton(label: is2nd ? "sin⁻¹" : "sin", w: sciButtonWidth, h: buttonHeight, fontSize: sciFontSize, bg: sciColor) {
                    calculator.inputScientificUnary(is2nd ? "sin⁻¹" : "sin")
                }
                .accessibilityIdentifier(is2nd ? "arc-sine" : "sine")
                .accessibilityLabel(is2nd ? "Arc Sine" : "Sine")

                SciButton(label: is2nd ? "cos⁻¹" : "cos", w: sciButtonWidth, h: buttonHeight, fontSize: sciFontSize, bg: sciColor) {
                    calculator.inputScientificUnary(is2nd ? "cos⁻¹" : "cos")
                }
                .accessibilityIdentifier(is2nd ? "arc-cosine" : "cosine")
                .accessibilityLabel(is2nd ? "Arc Cosine" : "Cosine")

                SciButton(label: is2nd ? "tan⁻¹" : "tan", w: sciButtonWidth, h: buttonHeight, fontSize: sciFontSize, bg: sciColor) {
                    calculator.inputScientificUnary(is2nd ? "tan⁻¹" : "tan")
                }
                .accessibilityIdentifier(is2nd ? "arc-tangent" : "tangent")
                .accessibilityLabel(is2nd ? "Arc Tangent" : "Tangent")

                SciButton(label: "e", w: sciButtonWidth, h: buttonHeight, fontSize: sciFontSize, bg: sciColor) {
                    calculator.inputConstant("e")
                }
                .accessibilityIdentifier("euler-number")
                .accessibilityLabel("Euler's Number")

                SciOpButton(operation: .ee, label: "EE", w: sciButtonWidth, h: buttonHeight, fontSize: sciFontSize, activeOp: calculator.activeOperation) {
                    calculator.inputOperation(.ee)
                }
                .accessibilityIdentifier("scientific-notation")
                .accessibilityLabel("Scientific Notation")
            }

            // Scientific Row 5: Rad sinh cosh tanh π Rand
            HStack(spacing: spacing) {
                SciButton(label: calculator.useRadians ? "Deg" : "Rad", w: sciButtonWidth, h: buttonHeight, fontSize: sciFontSize, bg: sciColor) {
                    calculator.toggleRadDeg()
                }
                .accessibilityIdentifier("rad-deg-toggle")
                .accessibilityLabel(calculator.useRadians ? "Switch to Degrees" : "Switch to Radians")

                SciButton(label: is2nd ? "sinh⁻¹" : "sinh", w: sciButtonWidth, h: buttonHeight, fontSize: sciFontSize, bg: sciColor) {
                    calculator.inputScientificUnary(is2nd ? "sinh⁻¹" : "sinh")
                }
                .accessibilityIdentifier(is2nd ? "arc-hyperbolic-sine" : "hyperbolic-sine")
                .accessibilityLabel(is2nd ? "Inverse Hyperbolic Sine" : "Hyperbolic Sine")

                SciButton(label: is2nd ? "cosh⁻¹" : "cosh", w: sciButtonWidth, h: buttonHeight, fontSize: sciFontSize, bg: sciColor) {
                    calculator.inputScientificUnary(is2nd ? "cosh⁻¹" : "cosh")
                }
                .accessibilityIdentifier(is2nd ? "arc-hyperbolic-cosine" : "hyperbolic-cosine")
                .accessibilityLabel(is2nd ? "Inverse Hyperbolic Cosine" : "Hyperbolic Cosine")

                SciButton(label: is2nd ? "tanh⁻¹" : "tanh", w: sciButtonWidth, h: buttonHeight, fontSize: sciFontSize, bg: sciColor) {
                    calculator.inputScientificUnary(is2nd ? "tanh⁻¹" : "tanh")
                }
                .accessibilityIdentifier(is2nd ? "arc-hyperbolic-tangent" : "hyperbolic-tangent")
                .accessibilityLabel(is2nd ? "Inverse Hyperbolic Tangent" : "Hyperbolic Tangent")

                SciButton(label: "π", w: sciButtonWidth, h: buttonHeight, fontSize: sciFontSize, bg: sciColor) {
                    calculator.inputConstant("π")
                }
                .accessibilityIdentifier("pi")
                .accessibilityLabel("Pi")

                SciButton(label: "Rand", w: sciButtonWidth, h: buttonHeight, fontSize: sciFontSize, bg: sciColor) {
                    calculator.inputConstant("Rand")
                }
                .accessibilityIdentifier("random")
                .accessibilityLabel("Random Number")
            }

            // Basic Row 1: AC ± % ÷
            HStack(spacing: spacing) {
                SciButton(label: calculator.isAllClear ? "AC" : "C", w: basicButtonWidth, h: buttonHeight, fontSize: basicFontSize, bg: funcColor, fg: .black) {
                    calculator.inputClear()
                }
                .accessibilityIdentifier("clear")
                .accessibilityLabel(calculator.isAllClear ? "All Clear" : "Clear")

                SciButton(label: "±", w: basicButtonWidth, h: buttonHeight, fontSize: basicFontSize, bg: funcColor, fg: .black) {
                    calculator.inputNegate()
                }
                .accessibilityIdentifier("negate")
                .accessibilityLabel("Negate")

                SciButton(label: "%", w: basicButtonWidth, h: buttonHeight, fontSize: basicFontSize, bg: funcColor, fg: .black) {
                    calculator.inputPercent()
                }
                .accessibilityIdentifier("percent")
                .accessibilityLabel("Percent")

                SciOpButton(operation: .divide, label: "÷", w: basicButtonWidth, h: buttonHeight, fontSize: basicFontSize, activeOp: calculator.activeOperation) {
                    calculator.inputOperation(.divide)
                }
                .accessibilityIdentifier("divide")
                .accessibilityLabel("Divide")
            }

            // Basic Row 2: 7 8 9 ×
            HStack(spacing: spacing) {
                SciButton(label: "7", w: basicButtonWidth, h: buttonHeight, fontSize: basicFontSize, bg: sciColor) {
                    calculator.inputDigit(7)
                }
                .accessibilityIdentifier("digit-7")
                .accessibilityLabel("Seven")

                SciButton(label: "8", w: basicButtonWidth, h: buttonHeight, fontSize: basicFontSize, bg: sciColor) {
                    calculator.inputDigit(8)
                }
                .accessibilityIdentifier("digit-8")
                .accessibilityLabel("Eight")

                SciButton(label: "9", w: basicButtonWidth, h: buttonHeight, fontSize: basicFontSize, bg: sciColor) {
                    calculator.inputDigit(9)
                }
                .accessibilityIdentifier("digit-9")
                .accessibilityLabel("Nine")

                SciOpButton(operation: .multiply, label: "×", w: basicButtonWidth, h: buttonHeight, fontSize: basicFontSize, activeOp: calculator.activeOperation) {
                    calculator.inputOperation(.multiply)
                }
                .accessibilityIdentifier("multiply")
                .accessibilityLabel("Multiply")
            }

            // Basic Row 3: 4 5 6 −
            HStack(spacing: spacing) {
                SciButton(label: "4", w: basicButtonWidth, h: buttonHeight, fontSize: basicFontSize, bg: sciColor) {
                    calculator.inputDigit(4)
                }
                .accessibilityIdentifier("digit-4")
                .accessibilityLabel("Four")

                SciButton(label: "5", w: basicButtonWidth, h: buttonHeight, fontSize: basicFontSize, bg: sciColor) {
                    calculator.inputDigit(5)
                }
                .accessibilityIdentifier("digit-5")
                .accessibilityLabel("Five")

                SciButton(label: "6", w: basicButtonWidth, h: buttonHeight, fontSize: basicFontSize, bg: sciColor) {
                    calculator.inputDigit(6)
                }
                .accessibilityIdentifier("digit-6")
                .accessibilityLabel("Six")

                SciOpButton(operation: .subtract, label: "−", w: basicButtonWidth, h: buttonHeight, fontSize: basicFontSize, activeOp: calculator.activeOperation) {
                    calculator.inputOperation(.subtract)
                }
                .accessibilityIdentifier("subtract")
                .accessibilityLabel("Subtract")
            }

            // Basic Row 4: 1 2 3 +
            HStack(spacing: spacing) {
                SciButton(label: "1", w: basicButtonWidth, h: buttonHeight, fontSize: basicFontSize, bg: sciColor) {
                    calculator.inputDigit(1)
                }
                .accessibilityIdentifier("digit-1")
                .accessibilityLabel("One")

                SciButton(label: "2", w: basicButtonWidth, h: buttonHeight, fontSize: basicFontSize, bg: sciColor) {
                    calculator.inputDigit(2)
                }
                .accessibilityIdentifier("digit-2")
                .accessibilityLabel("Two")

                SciButton(label: "3", w: basicButtonWidth, h: buttonHeight, fontSize: basicFontSize, bg: sciColor) {
                    calculator.inputDigit(3)
                }
                .accessibilityIdentifier("digit-3")
                .accessibilityLabel("Three")

                SciOpButton(operation: .add, label: "+", w: basicButtonWidth, h: buttonHeight, fontSize: basicFontSize, activeOp: calculator.activeOperation) {
                    calculator.inputOperation(.add)
                }
                .accessibilityIdentifier("add")
                .accessibilityLabel("Add")
            }

            // Basic Row 5: Menu 0 . =
            HStack(spacing: spacing) {
                SciButton(label: "\u{2630}", w: basicButtonWidth, h: buttonHeight, fontSize: basicFontSize, bg: sciColor, fg: .orange) {
                    calculator.isMenuVisible = true
                }
                .accessibilityIdentifier("menu")
                .accessibilityLabel("Menu")

                SciButton(label: "0", w: basicButtonWidth, h: buttonHeight, fontSize: basicFontSize, bg: sciColor) {
                    calculator.inputDigit(0)
                }
                .accessibilityIdentifier("digit-0")
                .accessibilityLabel("Zero")

                SciButton(label: ".", w: basicButtonWidth, h: buttonHeight, fontSize: basicFontSize, bg: sciColor) {
                    calculator.inputDecimal()
                }
                .accessibilityIdentifier("decimal")
                .accessibilityLabel("Decimal")

                SciButton(label: "=", w: basicButtonWidth, h: buttonHeight, fontSize: basicFontSize, bg: .orange) {
                    calculator.inputEquals()
                }
                .accessibilityIdentifier("equals")
                .accessibilityLabel("Equals")
            }
        }
        .padding(spacing)
    }

    // MARK: - Conversion Layout

    func conversionLayout(geometry: GeometryProxy) -> some View {
        let spacing: CGFloat = 12
        let buttonSize = (geometry.size.width - spacing * 5) / 4

        return VStack(spacing: spacing) {
            Spacer()

            // Source value display
            HStack {
                Spacer()
                Text(calculator.sourceText)
                    .font(.system(size: 48))
                    .fontWeight(.light)
                    .foregroundStyle(calculator.isEditingSource ? .white : .gray)
                    .minimumScaleFactor(0.3)
                    .lineLimit(1)
                    .onTapGesture { calculator.isEditingSource = true }
            }
            .padding(.horizontal, spacing)

            // Source unit button
            Button {
                calculator.isPickingSourceUnit = true
                calculator.isUnitPickerVisible = true
            } label: {
                HStack {
                    Spacer()
                    Text(unitName(for: calculator.sourceUnit))
                        .font(.system(size: 16))
                        .foregroundStyle(.orange)
                    Text("(\(unitAbbreviation(for: calculator.sourceUnit)))")
                        .font(.system(size: 14))
                        .foregroundStyle(.orange.opacity(0.7))
                }
            }
            .buttonStyle(.plain)
            .padding(.horizontal, spacing)

            // Swap button
            HStack {
                Spacer()
                Button {
                    calculator.swapUnits()
                } label: {
                    Text("\u{21C5}")
                        .font(.system(size: 24))
                        .foregroundStyle(.orange)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, spacing)

            // Target value display
            HStack {
                Spacer()
                Text(calculator.targetText)
                    .font(.system(size: 48))
                    .fontWeight(.light)
                    .foregroundStyle(calculator.isEditingSource ? .gray : .white)
                    .minimumScaleFactor(0.3)
                    .lineLimit(1)
                    .onTapGesture { calculator.isEditingSource = false }
            }
            .padding(.horizontal, spacing)

            // Target unit button
            Button {
                calculator.isPickingSourceUnit = false
                calculator.isUnitPickerVisible = true
            } label: {
                HStack {
                    Spacer()
                    Text(unitName(for: calculator.targetUnit))
                        .font(.system(size: 16))
                        .foregroundStyle(.orange)
                    Text("(\(unitAbbreviation(for: calculator.targetUnit)))")
                        .font(.system(size: 14))
                        .foregroundStyle(.orange.opacity(0.7))
                }
            }
            .buttonStyle(.plain)
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

            // Row 5: Menu, 0, ., =
            HStack(spacing: spacing) {
                CalculatorButton(
                    label: "\u{2630}",
                    size: buttonSize,
                    backgroundColor: Color(red: 0.2, green: 0.2, blue: 0.2),
                    foregroundColor: .orange
                ) {
                    calculator.isMenuVisible = true
                }

                CalculatorButton(
                    label: "0",
                    size: buttonSize,
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
}

// MARK: - Mode Menu Overlay

struct ModeMenuView: View {
    var calculator: CalculatorModel

    var body: some View {
        VStack(spacing: 2) {
            Text("Mode")
                .font(.headline)
                .foregroundStyle(.white)
                .padding(.bottom, 12)

            ModeOptionButton(
                label: "Basic",
                isSelected: calculator.calculatorMode == .basic
            ) {
                calculator.setMode(.basic)
            }

            ModeOptionButton(
                label: "Scientific",
                isSelected: calculator.calculatorMode == .scientific
            ) {
                calculator.setMode(.scientific)
            }

            ModeOptionButton(
                label: "Convert",
                isSelected: calculator.calculatorMode == .convert
            ) {
                calculator.setMode(.convert)
            }
        }
        .padding(24)
        .background(Color(red: 0.15, green: 0.15, blue: 0.15))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(40)
    }
}

struct ModeOptionButton: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(label)
                    .foregroundStyle(.white)
                    .font(.system(size: 18))
                Spacer()
                if isSelected {
                    Text("\u{2713}")
                        .foregroundStyle(.orange)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(isSelected ? Color(red: 0.25, green: 0.25, blue: 0.25) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Unit Picker

struct UnitPickerView: View {
    var calculator: CalculatorModel

    var body: some View {
        VStack(spacing: 0) {
            // Title bar
            HStack {
                Text("Select Unit")
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
                Button("Done") {
                    calculator.isUnitPickerVisible = false
                }
                .foregroundStyle(.orange)
                .buttonStyle(.plain)
            }
            .padding()

            // Horizontal category scroller
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(ConversionCategory.allCases, id: \.self) { category in
                        Button {
                            calculator.selectCategory(category)
                        } label: {
                            Text(categoryName(for: category))
                                .font(.system(size: 14))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    calculator.conversionCategory == category
                                        ? Color.orange
                                        : Color(red: 0.2, green: 0.2, blue: 0.2)
                                )
                                .foregroundStyle(
                                    calculator.conversionCategory == category
                                        ? .black : .white
                                )
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 8)

            // Unit list
            let units = conversionUnits(for: calculator.conversionCategory)
            ScrollView {
                VStack(spacing: 1) {
                    ForEach(0..<units.count, id: \.self) { index in
                        let unit = units[index]
                        Button {
                            if calculator.isPickingSourceUnit {
                                calculator.selectSourceUnit(unit)
                            } else {
                                calculator.selectTargetUnit(unit)
                            }
                        } label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(unitName(for: unit))
                                        .foregroundStyle(.white)
                                    Text(unitAbbreviation(for: unit))
                                        .font(.caption)
                                        .foregroundStyle(.gray)
                                }
                                Spacer()
                                if isUnitSelected(unit) {
                                    Text("\u{2713}")
                                        .foregroundStyle(.orange)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color(red: 0.1, green: 0.1, blue: 0.1))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .background(Color.black)
    }

    func isUnitSelected(_ unit: ConversionUnit) -> Bool {
        if calculator.isPickingSourceUnit {
            return unit == calculator.sourceUnit
        } else {
            return unit == calculator.targetUnit
        }
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

// MARK: - Category & Unit Display Strings

/// Returns the localized display name for a conversion category.
func categoryName(for category: ConversionCategory) -> LocalizedStringKey {
    switch category {
    case .angles: return "Angles"
    case .area: return "Area"
    case .data: return "Data"
    case .energy: return "Energy"
    case .force: return "Force"
    case .fuel: return "Fuel"
    case .length: return "Length"
    case .power: return "Power"
    case .pressure: return "Pressure"
    case .speed: return "Speed"
    case .temperature: return "Temperature"
    case .time: return "Time"
    case .volume: return "Volume"
    case .weight: return "Weight"
    }
}

/// Returns the localized display name for a conversion unit.
func unitName(for unit: ConversionUnit) -> LocalizedStringKey {
    switch unit {
    case .angle(let u):
        switch u {
        case .degrees: return "Degrees"
        case .radians: return "Radians"
        case .gradians: return "Gradians"
        case .arcminutes: return "Arcminutes"
        case .arcseconds: return "Arcseconds"
        case .revolutions: return "Revolutions"
        case .milliradians: return "Milliradians"
        }
    case .area(let u):
        switch u {
        case .squareMillimeters: return "Square Millimeters"
        case .squareCentimeters: return "Square Centimeters"
        case .squareMeters: return "Square Meters"
        case .squareKilometers: return "Square Kilometers"
        case .hectares: return "Hectares"
        case .ares: return "Ares"
        case .squareInches: return "Square Inches"
        case .squareFeet: return "Square Feet"
        case .squareYards: return "Square Yards"
        case .squareMiles: return "Square Miles"
        case .acres: return "Acres"
        }
    case .data(let u):
        switch u {
        case .bits: return "Bits"
        case .bytes: return "Bytes"
        case .kilobits: return "Kilobits"
        case .kibibits: return "Kibibits"
        case .kilobytes: return "Kilobytes"
        case .kibibytes: return "Kibibytes"
        case .megabits: return "Megabits"
        case .mebibits: return "Mebibits"
        case .megabytes: return "Megabytes"
        case .mebibytes: return "Mebibytes"
        case .gigabits: return "Gigabits"
        case .gibibits: return "Gibibits"
        case .gigabytes: return "Gigabytes"
        case .gibibytes: return "Gibibytes"
        case .terabits: return "Terabits"
        case .tebibits: return "Tebibits"
        case .terabytes: return "Terabytes"
        case .tebibytes: return "Tebibytes"
        case .petabytes: return "Petabytes"
        case .pebibytes: return "Pebibytes"
        }
    case .energy(let u):
        switch u {
        case .joules: return "Joules"
        case .kilojoules: return "Kilojoules"
        case .megajoules: return "Megajoules"
        case .calories: return "Calories"
        case .kilocalories: return "Kilocalories"
        case .wattHours: return "Watt-hours"
        case .kilowattHours: return "Kilowatt-hours"
        case .electronvolts: return "Electronvolts"
        case .britishThermalUnits: return "British Thermal Units"
        case .footPounds: return "Foot-pounds"
        case .therms: return "Therms"
        case .ergs: return "Ergs"
        }
    case .force(let u):
        switch u {
        case .newtons: return "Newtons"
        case .kilonewtons: return "Kilonewtons"
        case .meganewtons: return "Meganewtons"
        case .millinewtons: return "Millinewtons"
        case .micronewtons: return "Micronewtons"
        case .dynes: return "Dynes"
        case .poundsForce: return "Pounds-force"
        case .ouncesForce: return "Ounces-force"
        case .kilogramForce: return "Kilogram-force"
        case .poundals: return "Poundals"
        case .kips: return "Kips"
        }
    case .fuel(let u):
        switch u {
        case .litersPer100km: return "Liters per 100km"
        case .milesPerGallonUS: return "Miles per Gallon (US)"
        case .milesPerGallonUK: return "Miles per Gallon (UK)"
        case .kilometersPerLiter: return "Kilometers per Liter"
        }
    case .length(let u):
        switch u {
        case .nanometers: return "Nanometers"
        case .micrometers: return "Micrometers"
        case .millimeters: return "Millimeters"
        case .centimeters: return "Centimeters"
        case .decimeters: return "Decimeters"
        case .meters: return "Meters"
        case .kilometers: return "Kilometers"
        case .inches: return "Inches"
        case .feet: return "Feet"
        case .yards: return "Yards"
        case .miles: return "Miles"
        case .nauticalMiles: return "Nautical Miles"
        case .fathoms: return "Fathoms"
        case .furlongs: return "Furlongs"
        case .mils: return "Mils"
        case .lightYears: return "Light-years"
        case .astronomicalUnits: return "Astronomical Units"
        case .parsecs: return "Parsecs"
        }
    case .power(let u):
        switch u {
        case .milliwatts: return "Milliwatts"
        case .watts: return "Watts"
        case .kilowatts: return "Kilowatts"
        case .megawatts: return "Megawatts"
        case .gigawatts: return "Gigawatts"
        case .horsepower: return "Horsepower"
        case .metricHorsepower: return "Metric Horsepower"
        case .footPoundsPerSecond: return "Foot-pounds per Second"
        case .btuPerHour: return "BTU per Hour"
        case .tonsOfRefrigeration: return "Tons of Refrigeration"
        }
    case .pressure(let u):
        switch u {
        case .pascals: return "Pascals"
        case .hectopascals: return "Hectopascals"
        case .kilopascals: return "Kilopascals"
        case .megapascals: return "Megapascals"
        case .bars: return "Bars"
        case .millibars: return "Millibars"
        case .atmospheres: return "Atmospheres"
        case .torr: return "Torr"
        case .millimetersOfMercury: return "Millimeters of Mercury"
        case .poundsPerSquareInch: return "Pounds per Square Inch"
        case .inchesOfMercury: return "Inches of Mercury"
        case .inchesOfWater: return "Inches of Water"
        }
    case .speed(let u):
        switch u {
        case .metersPerSecond: return "Meters per Second"
        case .kilometersPerHour: return "Kilometers per Hour"
        case .milesPerHour: return "Miles per Hour"
        case .feetPerSecond: return "Feet per Second"
        case .knots: return "Knots"
        case .mach: return "Mach"
        case .speedOfLight: return "Speed of Light"
        }
    case .temperature(let u):
        switch u {
        case .celsius: return "Celsius"
        case .fahrenheit: return "Fahrenheit"
        case .kelvin: return "Kelvin"
        case .rankine: return "Rankine"
        }
    case .time(let u):
        switch u {
        case .nanoseconds: return "Nanoseconds"
        case .microseconds: return "Microseconds"
        case .milliseconds: return "Milliseconds"
        case .seconds: return "Seconds"
        case .minutes: return "Minutes"
        case .hours: return "Hours"
        case .days: return "Days"
        case .weeks: return "Weeks"
        case .fortnights: return "Fortnights"
        case .months: return "Months (30-day)"
        case .years: return "Years (365-day)"
        case .decades: return "Decades"
        case .centuries: return "Centuries"
        }
    case .volume(let u):
        switch u {
        case .milliliters: return "Milliliters"
        case .centiliters: return "Centiliters"
        case .deciliters: return "Deciliters"
        case .liters: return "Liters"
        case .kiloliters: return "Kiloliters"
        case .cubicCentimeters: return "Cubic Centimeters"
        case .cubicMeters: return "Cubic Meters"
        case .cubicInches: return "Cubic Inches"
        case .cubicFeet: return "Cubic Feet"
        case .cubicYards: return "Cubic Yards"
        case .usTeaspoons: return "US Teaspoons"
        case .usTablespoons: return "US Tablespoons"
        case .usFluidOunces: return "US Fluid Ounces"
        case .usCups: return "US Cups"
        case .usPints: return "US Pints"
        case .usQuarts: return "US Quarts"
        case .usGallons: return "US Gallons"
        case .imperialTeaspoons: return "Imperial Teaspoons"
        case .imperialTablespoons: return "Imperial Tablespoons"
        case .imperialFluidOunces: return "Imperial Fluid Ounces"
        case .imperialPints: return "Imperial Pints"
        case .imperialQuarts: return "Imperial Quarts"
        case .imperialGallons: return "Imperial Gallons"
        }
    case .weight(let u):
        switch u {
        case .micrograms: return "Micrograms"
        case .milligrams: return "Milligrams"
        case .grams: return "Grams"
        case .kilograms: return "Kilograms"
        case .metricTons: return "Metric Tons"
        case .ounces: return "Ounces"
        case .pounds: return "Pounds"
        case .stones: return "Stones"
        case .shortTons: return "Short Tons"
        case .longTons: return "Long Tons"
        case .carats: return "Carats"
        case .troyOunces: return "Troy Ounces"
        case .grains: return "Grains"
        case .slugs: return "Slugs"
        }
    }
}

/// Returns the abbreviation string for a conversion unit.
func unitAbbreviation(for unit: ConversionUnit) -> String {
    switch unit {
    case .angle(let u):
        switch u {
        case .degrees: return "\u{00B0}"
        case .radians: return "rad"
        case .gradians: return "grad"
        case .arcminutes: return "\u{2032}"
        case .arcseconds: return "\u{2033}"
        case .revolutions: return "rev"
        case .milliradians: return "mrad"
        }
    case .area(let u):
        switch u {
        case .squareMillimeters: return "mm\u{00B2}"
        case .squareCentimeters: return "cm\u{00B2}"
        case .squareMeters: return "m\u{00B2}"
        case .squareKilometers: return "km\u{00B2}"
        case .hectares: return "ha"
        case .ares: return "a"
        case .squareInches: return "in\u{00B2}"
        case .squareFeet: return "ft\u{00B2}"
        case .squareYards: return "yd\u{00B2}"
        case .squareMiles: return "mi\u{00B2}"
        case .acres: return "ac"
        }
    case .data(let u):
        switch u {
        case .bits: return "b"
        case .bytes: return "B"
        case .kilobits: return "kb"
        case .kibibits: return "Kib"
        case .kilobytes: return "KB"
        case .kibibytes: return "KiB"
        case .megabits: return "Mb"
        case .mebibits: return "Mib"
        case .megabytes: return "MB"
        case .mebibytes: return "MiB"
        case .gigabits: return "Gb"
        case .gibibits: return "Gib"
        case .gigabytes: return "GB"
        case .gibibytes: return "GiB"
        case .terabits: return "Tb"
        case .tebibits: return "Tib"
        case .terabytes: return "TB"
        case .tebibytes: return "TiB"
        case .petabytes: return "PB"
        case .pebibytes: return "PiB"
        }
    case .energy(let u):
        switch u {
        case .joules: return "J"
        case .kilojoules: return "kJ"
        case .megajoules: return "MJ"
        case .calories: return "cal"
        case .kilocalories: return "kcal"
        case .wattHours: return "Wh"
        case .kilowattHours: return "kWh"
        case .electronvolts: return "eV"
        case .britishThermalUnits: return "BTU"
        case .footPounds: return "ft\u{00B7}lb"
        case .therms: return "thm"
        case .ergs: return "erg"
        }
    case .force(let u):
        switch u {
        case .newtons: return "N"
        case .kilonewtons: return "kN"
        case .meganewtons: return "MN"
        case .millinewtons: return "mN"
        case .micronewtons: return "\u{00B5}N"
        case .dynes: return "dyn"
        case .poundsForce: return "lbf"
        case .ouncesForce: return "ozf"
        case .kilogramForce: return "kgf"
        case .poundals: return "pdl"
        case .kips: return "kip"
        }
    case .fuel(let u):
        switch u {
        case .litersPer100km: return "L/100km"
        case .milesPerGallonUS: return "mpg"
        case .milesPerGallonUK: return "mpg UK"
        case .kilometersPerLiter: return "km/L"
        }
    case .length(let u):
        switch u {
        case .nanometers: return "nm"
        case .micrometers: return "\u{00B5}m"
        case .millimeters: return "mm"
        case .centimeters: return "cm"
        case .decimeters: return "dm"
        case .meters: return "m"
        case .kilometers: return "km"
        case .inches: return "in"
        case .feet: return "ft"
        case .yards: return "yd"
        case .miles: return "mi"
        case .nauticalMiles: return "nmi"
        case .fathoms: return "ftm"
        case .furlongs: return "fur"
        case .mils: return "mil"
        case .lightYears: return "ly"
        case .astronomicalUnits: return "AU"
        case .parsecs: return "pc"
        }
    case .power(let u):
        switch u {
        case .milliwatts: return "mW"
        case .watts: return "W"
        case .kilowatts: return "kW"
        case .megawatts: return "MW"
        case .gigawatts: return "GW"
        case .horsepower: return "hp"
        case .metricHorsepower: return "PS"
        case .footPoundsPerSecond: return "ft\u{00B7}lb/s"
        case .btuPerHour: return "BTU/h"
        case .tonsOfRefrigeration: return "TR"
        }
    case .pressure(let u):
        switch u {
        case .pascals: return "Pa"
        case .hectopascals: return "hPa"
        case .kilopascals: return "kPa"
        case .megapascals: return "MPa"
        case .bars: return "bar"
        case .millibars: return "mbar"
        case .atmospheres: return "atm"
        case .torr: return "Torr"
        case .millimetersOfMercury: return "mmHg"
        case .poundsPerSquareInch: return "psi"
        case .inchesOfMercury: return "inHg"
        case .inchesOfWater: return "inH\u{2082}O"
        }
    case .speed(let u):
        switch u {
        case .metersPerSecond: return "m/s"
        case .kilometersPerHour: return "km/h"
        case .milesPerHour: return "mph"
        case .feetPerSecond: return "ft/s"
        case .knots: return "kn"
        case .mach: return "Mach"
        case .speedOfLight: return "c"
        }
    case .temperature(let u):
        switch u {
        case .celsius: return "\u{00B0}C"
        case .fahrenheit: return "\u{00B0}F"
        case .kelvin: return "K"
        case .rankine: return "\u{00B0}R"
        }
    case .time(let u):
        switch u {
        case .nanoseconds: return "ns"
        case .microseconds: return "\u{00B5}s"
        case .milliseconds: return "ms"
        case .seconds: return "s"
        case .minutes: return "min"
        case .hours: return "h"
        case .days: return "d"
        case .weeks: return "wk"
        case .fortnights: return "fn"
        case .months: return "mo"
        case .years: return "yr"
        case .decades: return "dec"
        case .centuries: return "cent"
        }
    case .volume(let u):
        switch u {
        case .milliliters: return "mL"
        case .centiliters: return "cL"
        case .deciliters: return "dL"
        case .liters: return "L"
        case .kiloliters: return "kL"
        case .cubicCentimeters: return "cm\u{00B3}"
        case .cubicMeters: return "m\u{00B3}"
        case .cubicInches: return "in\u{00B3}"
        case .cubicFeet: return "ft\u{00B3}"
        case .cubicYards: return "yd\u{00B3}"
        case .usTeaspoons: return "tsp"
        case .usTablespoons: return "tbsp"
        case .usFluidOunces: return "fl oz"
        case .usCups: return "cup"
        case .usPints: return "pt"
        case .usQuarts: return "qt"
        case .usGallons: return "gal"
        case .imperialTeaspoons: return "imp tsp"
        case .imperialTablespoons: return "imp tbsp"
        case .imperialFluidOunces: return "imp fl oz"
        case .imperialPints: return "imp pt"
        case .imperialQuarts: return "imp qt"
        case .imperialGallons: return "imp gal"
        }
    case .weight(let u):
        switch u {
        case .micrograms: return "\u{00B5}g"
        case .milligrams: return "mg"
        case .grams: return "g"
        case .kilograms: return "kg"
        case .metricTons: return "t"
        case .ounces: return "oz"
        case .pounds: return "lb"
        case .stones: return "st"
        case .shortTons: return "US ton"
        case .longTons: return "UK ton"
        case .carats: return "ct"
        case .troyOunces: return "oz t"
        case .grains: return "gr"
        case .slugs: return "slug"
        }
    }
}
