import SwiftUI

public struct ESMScaleView: View {

    let item: ESMItem
    let onSubmit: (String) -> Void

    @State private var value: Double
    @Environment(\.esmHideSubmitButton) private var hideSubmitButton

    public init(item: ESMItem, onSubmit: @escaping (String) -> Void) {
        self.item = item
        self.onSubmit = onSubmit
        let start = item.esmScaleStart ?? item.esmScaleMin ?? 0
        _value = State(initialValue: Double(start))
    }

    private var minValue: Double { Double(item.esmScaleMin ?? 0) }
    private var maxValue: Double { Double(item.esmScaleMax ?? 100) }
    private var step:     Double { Double(max(1, item.esmScaleStep ?? 1)) }

    public var body: some View {
        VStack(spacing: 16) {
            currentValueLabel
            sliderWithLabels
            if !hideSubmitButton {
                submitButton
            }
        }
    }

    private var currentValueLabel: some View {
        Text("\(Int(value))")
            .font(.system(size: 48, weight: .bold, design: .rounded))
            .monospacedDigit()
    }

    private var sliderWithLabels: some View {
        VStack(spacing: 4) {
            Slider(value: $value, in: minValue...maxValue, step: step)
                .padding(.horizontal)
                .onChange(of: value) { newValue in
                    if hideSubmitButton { onSubmit("\(Int(newValue))") }
                }
            HStack {
                Text(item.esmScaleMinLabel ?? "\(Int(minValue))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(item.esmScaleMaxLabel ?? "\(Int(maxValue))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
        }
    }

    private var submitButton: some View {
        Button(item.esmSubmit ?? "OK") {
            onSubmit("\(Int(value))")
        }
        .buttonStyle(.borderedProminent)
        .frame(maxWidth: .infinity)
        .padding(.horizontal)
    }
}
