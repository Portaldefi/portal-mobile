//
//  LockscreenModifier.swift
//  Portal
//
//  Created by farid on 27.06.2023.
//

import SwiftUI
import Factory

struct LockScreenModifier: ViewModifier {
    @Bindable var viewState = Container.viewState()

    func body(content: Content) -> some View {
        content.fullScreenCover(isPresented: $viewState.walletLocked) {
            PincodeView()
        }
    }
}

import PopupView
import PortalUI
import Combine

class NotifiableViewModel: ObservableObject {
    @Injected(Container.notificationService) var notificationService
    @Published var notification: PNotification?
    @Published var showNotification = false

    private var cancellables = Set<AnyCancellable>()

    init() {
        notificationService.notifications.dropFirst()
            .sink { [weak self] notifications in
                self?.notification = notifications.last
                self?.showNotification = true
            }
            .store(in: &cancellables)
    }
}

struct NotifiableViewModifier: ViewModifier {
    @StateObject var viewModel = NotifiableViewModel()

    func body(content: Content) -> some View {
        content
            .popup(isPresented: $viewModel.showNotification) {
                HStack {
                    ZStack {
                        Circle()
                            .foregroundColor(Color(red: 0.191, green: 0.858, blue: 0.418))
                        Asset.checkIcon
                            .resizable()
                            .frame(width: 20, height: 20)
                            .foregroundColor(.black)
                    }
                    .frame(width: 32, height: 32)
                    .padding(.horizontal, 12)
                    
                    if let notif = viewModel.notification {
                        Text(notif.message)
                            .font(.Main.fixed(.monoBold, size: 16))
                            .foregroundColor(.white)
                    }

                    Spacer()
                }
                .frame(width: 300, height: 56)
                .background(Color(red: 0.165, green: 0.165, blue: 0.165))
                .cornerRadius(16)
            } customize: {
                $0.autohideIn(5).type(.floater()).position(.top).animation(.spring()).closeOnTapOutside(true)
            }
    }
}
