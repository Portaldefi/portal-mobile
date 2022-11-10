//
//  LabelsManagerView.swift
// Portal
//
//  Created by farid on 10/3/22.
//

import SwiftUI
import PortalUI
import Combine

struct LabelsManagerView: View {
    @StateObject var viewModel: LabelsManagerViewModel
    let onSaveAcion: ([TxLable]) -> ()
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Text(viewModel.title)
                    .font(.Main.fixed(.monoBold, size: 16))
                    .foregroundColor(Palette.grayScaleF4)
                
                HStack {
                    PButton(config: .onlyIcon(Asset.plusIcon), style: .free, size: .medium, applyGradient: true, enabled: true) {
                        viewModel.showAddLabelInterface.toggle()
                    }
                    .frame(width: 30)
                    
                    Spacer()
                    
                    PButton(config: .onlyLabel("Save"), style: .free, size: .small, applyGradient: true, enabled: viewModel.saveButtonEnabled) {
                        onSaveAcion(viewModel.selectedLabels)
                    }
                    .frame(width: 39)
                }
                .padding(.vertical, 20)
            }
            .frame(height: 62)
            
            List(viewModel.labels) { item in
                Button {
                    viewModel.update(item: item)
                } label: {
                    SelectableTxLabelView(item: item, isSelected: viewModel.isSelected(item: item))
                }
                .swipeActions(edge: .trailing) {
                    Button {
                        viewModel.remove(item: item)
                    } label: {
                        Text("Delete")
                            .font(.Main.fixed(.bold, size: 14))
                    }
                    .tint(Color(red: 1, green: 0.349, blue: 0.349))
                    
                    Button {
                        viewModel.edit(item: item)
                    } label: {
                        Text("Edit")
                            .font(.Main.fixed(.bold, size: 14))
                    }
                    .tint(Color(red: 0.969, green: 0.6, blue: 0.149))
                }
            }
            .listRowSeparator(.hidden)
            .listStyle(.plain)
            .background(Palette.grayScale20)
            .cornerRadius(8)
            .padding(.bottom)
        }
        .padding(.horizontal, 16)
        .background(Palette.grayScale2A)
        .frame(height: 350)
        .textFieldAlert(isPresented: $viewModel.showAddLabelInterface) { () -> TextFieldAlert in
            TextFieldAlert(
                title: "Create new label",
                message: "Set a name for your new label:",
                actionButtonTitle: "Create",
                onAcionButton: { text in
                    viewModel.createLabel()
                },
                text: $viewModel.newLabelTitle
            )
        }
        .textFieldAlert(isPresented: $viewModel.showEditLabelInterface) { () -> TextFieldAlert in
            TextFieldAlert(
                title: "Edit Label",
                message: "Update the name for '\(viewModel.newLabelTitle!)'",
                actionButtonTitle: "Update",
                onAcionButton: { text in
                    guard let newTitle = text, !newTitle.isEmpty else { return }
                    viewModel.updateItem(title: newTitle)
                },
                text: $viewModel.newLabelTitle
            )
        }
    }
}

struct LabelsManagerView_Previews: PreviewProvider {
    static var previews: some View {
        LabelsManagerView(
            viewModel:
                LabelsManagerViewModel(
                    selectedLabels: [
                        TxLable(label: "Buisness"),
                        TxLable(label: "Friend"),
                        TxLable(label: "Do Not Spend")
                    ]
                ), onSaveAcion: { _ in }
        )
        .previewLayout(.sizeThatFits)
    }
}
