/*
 * Based on the excellent tutorial by Aubree Quiroz here:
 * https://medium.com/better-programming/reusable-components-in-swiftui-custom-sliders-8c115914b856
 */

import SwiftUI

// First, let’s create a helper function to simplify our conversions from value to x coordinate, and vice versa
extension Double {
    func convert(fromRange: (Double, Double), toRange: (Double, Double)) -> Double {
        // Example: if self = 1, fromRange = (0,2), toRange = (10,12) -> solution = 11
        var value = self
        value -= fromRange.0
        value /= Double(fromRange.1 - fromRange.0)
        value *= toRange.1 - toRange.0
        value += toRange.0
        return value
    }
}

// Since we have a couple of different elements we’d like to distinguish, we’ll create another struct, CustomSliderComponents, to organize our modifiers by name.
public struct VerticalSliderComponents {
    let barBottom: VerticalSliderModifier
    let barTop: VerticalSliderModifier
    let knob: VerticalSliderModifier
}

// Now, let’s create a view modifier called CustomSliderModifier with which we’ll pass element attributes back to our content view.
public struct VerticalSliderModifier: ViewModifier {
    enum Name {
        case barBottom
        case barTop
        case knob
    }
    let name: Name
    let size: CGSize
    let offset: CGFloat
    
    @available(iOS 13.0.0, *)
    public func body(content: Content) -> some View {
        content
            .frame(height: size.height)
            .position(x: size.width*0.5, y: size.height*0.5)
            .offset(y: offset)
    }
}

@available(iOS 13.0, *)
public struct VerticalSlider<Component: View>: View {
    @Binding var value: Double
    var range: (Double, Double)
    var knobHeight: CGFloat?
    let viewBuilder: (VerticalSliderComponents) -> Component
    
    public init(value: Binding<Double>, range: (Double, Double), knobHeight: CGFloat? = nil,
         _ viewBuilder: @escaping (VerticalSliderComponents) -> Component
    ) {
        _value = value
        self.range = range
        self.viewBuilder = viewBuilder
        self.knobHeight = knobHeight
    }
    
    public var body: some View {
        return GeometryReader { geometry in
            self.view(geometry: geometry) // function below
        }
    }
    
    private func view(geometry: GeometryProxy) -> some View {
        // First, let’s create a DragGesture that’ll perform our onDragChange(_ drag:,_ frame: ) function.
        let frame = geometry.frame(in: .global)
        let drag = DragGesture(minimumDistance: 0).onChanged({ drag in
            self.onDragChange(drag, frame) }
        )
        
        let offsetY = self.getOffsetY(frame: frame)
        let knobSize = CGSize(width: frame.width, height: knobHeight ?? frame.width)
        let barBottomSize = CGSize(width: frame.width, height: CGFloat(offsetY + knobSize.height * 0.5))
        let barTopSize = CGSize(width: frame.width, height:  frame.height - barBottomSize.height)
        
        // Next, we build our view modifiers using the values calculated in the previous step. We then pass our modifiers as an argument to our view builder and add our drag gesture.
        let modifiers = VerticalSliderComponents(
            barBottom: VerticalSliderModifier(name: .barBottom, size: barBottomSize, offset: barTopSize.height),
            barTop: VerticalSliderModifier(name: .barTop, size: barTopSize, offset: 0),
            knob: VerticalSliderModifier(name: .knob, size: knobSize, offset: frame.height - offsetY - knobSize.height))
        
        return ZStack { viewBuilder(modifiers).gesture(drag) }
    }
    
    private func onDragChange(_ drag: DragGesture.Value,_ frame: CGRect) {
        let height = (knob: Double(knobHeight ?? frame.size.width), view: Double(frame.size.height))
        let yrange = (min: Double(0), max: Double(height.view - height.knob))
        var value = height.view - Double(drag.startLocation.y + drag.translation.height) // knob center x
        value -= 0.5*height.knob // offset from center to leading edge of knob
        value = value > yrange.max ? yrange.max : value // limit to leading edge
        value = value < yrange.min ? yrange.min : value // limit to trailing edge
        value = value.convert(fromRange: (yrange.min, yrange.max), toRange: range)
        self.value = value
    }
    
    // Add another helper function for calculating our knob’s x offset (in terms of pixels) given a slider value.
    private func getOffsetY(frame: CGRect) -> CGFloat {
        let height = (knob: knobHeight ?? frame.size.width, view: frame.size.height)
        let yrange: (Double, Double) = (0, Double(height.view - height.knob))
        let result = self.value.convert(fromRange: range, toRange: yrange)
        return CGFloat(result)
    }
}
