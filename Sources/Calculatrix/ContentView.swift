import SwiftUI
import CalculatrixModel

/// The main calculator view with display and button grid.
struct ContentView: View {
    @State var calculator = CalculatorModel()

    var body: some View {
        GeometryReader { geometry in
            let spacing: CGFloat = 12
            let buttonSize = (geometry.size.width - spacing * 5) / 4

            VStack(spacing: spacing) {
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
        .background(Color.black)
    }
}

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
