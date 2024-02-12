//
//  ConfirmationCounterView.swift
// Portal
//
//  Created by farid on 9/29/22.
//

import SwiftUI
import PortalUI

struct ConfirmationsCounterViewStyle: ProgressViewStyle {
    let lineWidth: CGFloat
    func makeBody(configuration: Configuration) -> some View {
        Circle()
            .trim(from: 0.1, to: CGFloat(configuration.fractionCompleted ?? 0))
            .stroke(
                style: StrokeStyle(
                    lineWidth: lineWidth,
                    lineCap: .square,
                    lineJoin: .miter,
                    miterLimit: 0,
                    dash: [4.2],
                    dashPhase: 1)
            )
    }
}

struct ConfirmationCounterView: View {
    enum Layout {
        case vertical, horizontal
    }
    
    let confirmations: Int32
    let maxConfirmations: Int
    let layout: Layout
    
    private var progressColor: Color {
        switch confirmations {
        case 1, 2:
            return Palette.grayScaleAA
        default:
            return Color(red: 1, green: 0.742, blue: 0.079, opacity: 1)
        }
    }
    
    private var title: String {
        switch layout {
        case .vertical:
            return "\(confirmations)/\(maxConfirmations) confirmations"
        case .horizontal:
            switch confirmations {
            case 0:
                return "Confirming..."
            case 1:
                return "\(Int(confirmations)) confirmation"
            case 2, 3, 4, 5, 6:
                return "\(Int(confirmations)) confirmations"
            default:
                return "6+ confirmations"
            }
        }
    }
    
    init(confirmations: Int32, maxConfirmations: Int? = 6, layout: Layout? = .horizontal) {
        self.confirmations = confirmations
        self.maxConfirmations = maxConfirmations ?? 6
        self.layout = layout ?? .vertical
    }
    
    var body: some View {
        switch layout {
        case .vertical:
            VStack(spacing: 4) {
                ZStack {
                    ProgressView(
                        String(),
                        value: CGFloat(maxConfirmations),
                        total: CGFloat(maxConfirmations)
                    )
                        .progressViewStyle(ConfirmationsCounterViewStyle(lineWidth: 1))
                        .foregroundColor(progressColor)

                    ProgressView(
                        String(),
                        value: confirmations > maxConfirmations ? CGFloat(maxConfirmations) : CGFloat(confirmations),
                        total: CGFloat(maxConfirmations)
                    )
                        .progressViewStyle(ConfirmationsCounterViewStyle(lineWidth: 2))
                        .foregroundColor(progressColor)
                }
                .rotationEffect(.degrees(-110))
                .frame(width: 16, height: 16)
                .padding(3.3)
                
                Text(title)
                    .font(.Main.fixed(.monoRegular, size: 12))
                    .foregroundColor(progressColor)
            }
            .frame(height: 40)
        case .horizontal:
            HStack(spacing: 4) {
                ZStack {
                    ProgressView(
                        String(),
                        value: CGFloat(maxConfirmations),
                        total: CGFloat(maxConfirmations)
                    )
                        .progressViewStyle(ConfirmationsCounterViewStyle(lineWidth: 1))
                        .foregroundColor(progressColor)

                    ProgressView(
                        String(),
                        value: confirmations > maxConfirmations ? CGFloat(maxConfirmations) : CGFloat(confirmations),
                        total: CGFloat(maxConfirmations)
                    )
                        .progressViewStyle(ConfirmationsCounterViewStyle(lineWidth: 2))
                        .foregroundColor(progressColor)
                }
                .rotationEffect(.degrees(-110))
                .frame(width: 16, height: 16)
                .padding(3.3)
                
                Text(title)
                    .font(.Main.fixed(.monoRegular, size: 16))
                    .foregroundColor(progressColor)
            }
            .frame(height: 22)
        }
    }
}

struct TxConfirmationsCounterView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ConfirmationCounterView(confirmations: 0)
                .padding()
                .previewLayout(.sizeThatFits)
            
            ConfirmationCounterView(confirmations: 1)
                .padding()
                .previewLayout(.sizeThatFits)
            
            ConfirmationCounterView(confirmations: 2)
                .padding()
                .previewLayout(.sizeThatFits)
            
            ConfirmationCounterView(confirmations: 3)
                .padding()
                .previewLayout(.sizeThatFits)
            
            ConfirmationCounterView(confirmations: 4)
                .padding()
                .previewLayout(.sizeThatFits)
            
            ConfirmationCounterView(confirmations: 5)
                .padding()
                .previewLayout(.sizeThatFits)
            
            ConfirmationCounterView(confirmations: 6)
                .padding()
                .previewLayout(.sizeThatFits)
            
            ConfirmationCounterView(confirmations: 7)
                .padding()
                .previewLayout(.sizeThatFits)
        }
    }
}
