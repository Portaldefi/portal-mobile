//
//  LabelManagerViewModel.swift
//  BDKDemoApp
//
//  Created by farid on 10/3/22.
//

import Combine

class LabelsManagerViewModel: ObservableObject {
    let title = "Select labels"
    @Published var labels: [TxLable]
    @Published var selectedLabels: [TxLable]
    private let selectionStateHash: Int
    private let initialStateHash: Int
    
    @Published var saveButtonEnabled = false
    
    @Published var showAddLabelInterface = false
    @Published var showEditLabelInterface = false

    @Published var newLabelTitle: String?
    @Published var editItem: TxLable?

    
    init(selectedLabels: [TxLable]) {
        let tags = [
            TxLable(label: "Taxes"),
            TxLable(label: "Buisness"),
            TxLable(label: "Friend"),
            TxLable(label: "Do Not Spend"),
            TxLable(label: "Savings"),
            TxLable(label: "Food")
        ]
        self.labels = tags
        self.selectedLabels = selectedLabels
        
        self.initialStateHash = tags.hashValue
        self.selectionStateHash = selectedLabels.hashValue
        
        Publishers
            .Merge(initialStatePublisher, selectionStatePublisher)
            .assign(to: &$saveButtonEnabled)
    }
    
    private var initialStatePublisher: AnyPublisher<Bool, Never> {
        $labels.flatMap {
            Just($0.hashValue != self.initialStateHash)
        }
        .eraseToAnyPublisher()
    }
    
    private var selectionStatePublisher: AnyPublisher<Bool, Never> {
        $selectedLabels.flatMap {
            Just($0.hashValue != self.selectionStateHash)
        }
        .eraseToAnyPublisher()
    }
    
    func update(item: TxLable) {
        if let index = selectedLabels.firstIndex(where: { $0.label == item.label }) {
            selectedLabels.remove(at: index)
        } else {
            selectedLabels.append(item)
        }
    }
    
    func remove(item: TxLable) {
        if let index = labels.firstIndex(where: { $0.label == item.label }) {
            labels.remove(at: index)
        }
        if let index = selectedLabels.firstIndex(where: { $0.label == item.label }) {
            selectedLabels.remove(at: index)
        }
    }
    
    func isSelected(item: TxLable) -> Bool {
        selectedLabels.contains(where: { $0.label == item.label })
    }
    
    func createLabel() {
        guard let newLabelTitle = newLabelTitle else {
            return
        }

        let label = TxLable(label: newLabelTitle)
        labels.append(label)
        
        self.newLabelTitle = nil
    }
    
    func edit(item: TxLable) {
        editItem = item
        newLabelTitle = item.label
        showEditLabelInterface.toggle()
    }
    
    func updateItem(title: String) {
        guard let editItem = editItem else {
            return
        }

        if let index = labels.firstIndex(where: { $0.label == editItem.label}) {
            labels[index].label = title
        }
        
        if let index = selectedLabels.firstIndex(where: { $0.label == editItem.label}) {
            selectedLabels[index].label = title
        }
        
        self.editItem = nil
        self.newLabelTitle = nil
    }
}
