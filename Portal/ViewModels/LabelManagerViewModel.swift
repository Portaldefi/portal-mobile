//
//  LabelManagerViewModel.swift
// Portal
//
//  Created by farid on 10/3/22.
//

import Combine
import Foundation

class LabelsManagerViewModel: ObservableObject {
    let title = "Select labels"
    @Published var labels: [TxLabel]
    @Published var selectedLabels: [TxLabel]
    private let selectionStateHash: Int
    private let initialStateHash: Int
    
    @Published var saveButtonEnabled = false
    
    @Published var showAddLabelInterface = false
    @Published var showEditLabelInterface = false

    @Published var newLabelTitle: String?
    @Published var editItem: TxLabel?
    
    let storage: UserDefaults
    let storageKey = "TxLabelsStorage"
    
    init(selectedLabels: [TxLabel]) {
        self.storage = UserDefaults.standard
        
        let allLabels = storage.object(forKey: storageKey) as? [String] ?? []
        self.labels = allLabels.map{ TxLabel(label: $0) }
        self.selectedLabels = selectedLabels
        
        self.initialStateHash = allLabels.hashValue
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
    
    func update(item: TxLabel) {
        DispatchQueue.main.async {
            if let index = self.selectedLabels.firstIndex(where: { $0.label == item.label }) {
                self.selectedLabels.remove(at: index)
            } else {
                self.selectedLabels.append(item)
            }
        }
    }
    
    func remove(item: TxLabel) {
        if let index = labels.firstIndex(where: { $0.label == item.label }) {
            labels.remove(at: index)
        }
        if let index = selectedLabels.firstIndex(where: { $0.label == item.label }) {
            selectedLabels.remove(at: index)
        }
        storage.set(labels.map{ $0.label }, forKey: storageKey)
    }
    
    func isSelected(item: TxLabel) -> Bool {
        selectedLabels.contains(where: { $0.label == item.label })
    }
    
    func createLabel() {
        guard let newLabelTitle = newLabelTitle else {
            return
        }

        let label = TxLabel(label: newLabelTitle)
        labels.append(label)
        
        self.newLabelTitle = nil
        storage.set(labels.map{ $0.label }, forKey: storageKey)
    }
    
    func edit(item: TxLabel) {
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
        storage.set(labels.map{ $0.label }, forKey: storageKey)
    }
}
