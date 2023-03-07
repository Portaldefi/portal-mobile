//
//  WrappedHStack.swift
// Portal
//
//  Created by farid on 10/3/22.
//

import SwiftUI

public struct WrappedHStack<Data, V>: View where Data: RandomAccessCollection, V: View {
    // MARK: - Properties
    public typealias ViewGenerator = (Data.Element) -> V
    
    private var models: Data
    private var horizontalSpacing: CGFloat
    private var verticalSpacing: CGFloat
    private var variant: WrappedHStackVariant
    private var viewGenerator: ViewGenerator
    
    @State private var totalHeight: CGFloat
    
    public init(_ models: Data, horizontalSpacing: CGFloat = 4, verticalSpacing: CGFloat = 4,
                variant: WrappedHStackVariant = .lists, @ViewBuilder viewGenerator: @escaping ViewGenerator) {
        self.models = models
        self.horizontalSpacing = horizontalSpacing
        self.verticalSpacing = verticalSpacing
        self.variant = variant
        _totalHeight = variant == .lists ? State<CGFloat>(initialValue: CGFloat.zero) : State<CGFloat>(initialValue: CGFloat.infinity)
        self.viewGenerator = viewGenerator
    }
    
    // MARK: - Views
    public var body: some View {
        VStack {
            GeometryReader { geometry in
                generateContent(in: geometry)
            }
        }
        .modifier(FrameViewModifier(variant: self.variant, totalHeight: $totalHeight))
    }
    
    private func generateContent(in geometry: GeometryProxy) -> some View {
        var width = CGFloat.zero
        var height = CGFloat.zero
        
        return ZStack(alignment: .topLeading) {
            ForEach(0..<models.count, id: \.self) { index in
                let idx = models.index(models.startIndex, offsetBy: index)
                viewGenerator(models[idx])
                    .padding(.horizontal, horizontalSpacing)
                    .padding(.vertical, verticalSpacing)
                    .alignmentGuide(.leading, computeValue: { dimension in
                        if abs(width - dimension.width) > geometry.size.width {
                            width = 0
                            height -= dimension.height
                        }
                        let result = width
                        
                        if index == (models.count - 1) {
                            width = 0 // last item
                        } else {
                            width -= dimension.width
                        }
                        return result
                    })
                    .alignmentGuide(.top, computeValue: {_ in
                        let result = height
                        if index == (models.count - 1) {
                            height = 0 // last item
                        }
                        return result
                    })
            }
        }
        .background(viewHeightReader($totalHeight))
    }
}

public func viewHeightReader(_ binding: Binding<CGFloat>) -> some View {
    return GeometryReader { geometry -> Color in
        let rect = geometry.frame(in: .local)
        DispatchQueue.main.async {
            binding.wrappedValue = rect.size.height
        }
        return .clear
    }
}

public enum WrappedHStackVariant {
    case lists // ScrollView/List/LazyVStack
    case stacks // VStack/ZStack
}

internal struct FrameViewModifier: ViewModifier {
    var variant: WrappedHStackVariant
    @Binding var totalHeight: CGFloat
    
    func body(content: Content) -> some View {
        if variant == .lists {
            content
                .frame(height: totalHeight)
        } else {
            content
                .frame(maxHeight: totalHeight)
        }
    }
}
