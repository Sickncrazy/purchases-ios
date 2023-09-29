//
//  AppContentView.swift
//  SimpleApp
//
//  Created by Nacho Soto on 7/13/23.
//

import RevenueCat
import RevenueCatUI
import SwiftUI

struct AppContentView: View {

    @ObservedObject
    private var configuration = Configuration.shared

    @State
    private var customerInfo: CustomerInfo?

    @State
    private var showingDefaultPaywall: Bool = false

    @State
    private var customerInfoTask: Task<(), Never>? = nil


    var body: some View {
        TabView {
            if Purchases.isConfigured {
                NavigationView {
                    ZStack {
                        self.background
                        self.content
                    }
                    .navigationTitle("Paywall Tester")
                }
                .tabItem {
                    Label("App", systemImage: "iphone")
                }
                .navigationViewStyle(StackNavigationViewStyle())
            }

            #if DEBUG
            SamplePaywallsList()
                .tabItem {
                    Label("Examples", systemImage: "pawprint")
                }
            #endif

            if Purchases.isConfigured {
                OfferingsList()
                    .tabItem {
                        Label("All paywalls", systemImage: "network")
                    }
            }
        }
    }

    private var background: some View {
        Rectangle()
            .foregroundStyle(.orange)
            .opacity(0.05)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .edgesIgnoringSafeArea(.all)
    }

    @ViewBuilder
    private var content: some View {
        VStack(spacing: 20) {
            if let info = self.customerInfo {
                Text(verbatim: "You're signed in: \(info.originalAppUserId)")
                    .font(.callout)

                if self.customerInfo?.activeSubscriptions.count ?? 0 > 0 {
                    Text("Thanks for purchasing!")
                }

                Spacer()

                if let date = info.latestExpirationDate {
                    Text(verbatim: "Your subscription expires: \(date.formatted())")
                        .font(.caption)
                }

                Spacer()
            }
            Spacer()

            Text("Currently configured for \(self.descriptionForCurrentMode())")
                .font(.footnote)

            ConfigurationButton(title: "Configure for demos", mode: .demos, configuration: configuration) {
                self.reconfigure(for: .demos)
            }

            ConfigurationButton(title: "Configure for testing", mode: .testing, configuration: configuration) {
                self.reconfigure(for: .testing)
            }

            ProminentButton(title: "Present default paywall") {
                showingDefaultPaywall.toggle()
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 80)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("Simple App")
        .task {
            self.observeCustomerInfoStream()
        }
        #if DEBUG
        .overlay {
            if #available(iOS 16.0, macOS 13.0, *) {
                DebugView()
                    .frame(maxHeight: .infinity, alignment: .bottom)
            }
        }
        #endif
        .sheet(isPresented: self.$showingDefaultPaywall) {
            NavigationView {
                PaywallView()
                #if targetEnvironment(macCatalyst)
                    .toolbar {
                        ToolbarItem(placement: .destructiveAction) {
                            Button {
                                self.showingDefaultPaywall = false
                            } label: {
                                Image(systemName: "xmark")
                            }
                        }
                    }
                #endif
            }
        }
    }

    private func reconfigure(for mode: Configuration.Mode) {
        configuration.reconfigure(for: mode)
        self.observeCustomerInfoStream()
    }

    private func observeCustomerInfoStream() {
        self.customerInfoTask?.cancel()
        self.customerInfoTask = Task {
            if Purchases.isConfigured {
                for await info in Purchases.shared.customerInfoStream {
                    self.customerInfo = info
                    self.showingDefaultPaywall = self.showingDefaultPaywall && info.activeSubscriptions.count == 0
                }
            }
        }
    }

    private func descriptionForCurrentMode() -> String {

        switch self.configuration.currentMode {
        case .custom:
            return "the API set locally in Configuration.swift"
        case .testing:
            return "the Paywalls Tester app in RevenueCat Dashboard"
        case .demos:
            return "Demos"
        }

    }

}
private struct ProminentButton: View {
    var title: String
    var action: () -> Void
    var background: Color = .accentColor

    var body: some View {
        Button(action: action) {
            Text(title)
                .bold()
                .padding()
                .frame(maxWidth: .infinity)
                .background(background)
                .foregroundColor(.white)
                .cornerRadius(10)
        }
    }
}

private struct ConfigurationButton: View {
    var title: String
    var mode: Configuration.Mode
    @ObservedObject var configuration: Configuration
    var action: () -> Void

    var body: some View {
        ProminentButton(
            title: title,
            action: action,
            background: configuration.currentMode == mode ? Color.gray : Color.accentColor
        )
        .disabled(configuration.currentMode == mode)
    }
}

extension CustomerInfo {

    var hasPro: Bool {
        return self.entitlements.active.contains { $1.identifier == Configuration.shared.entitlement }
    }

}

#if DEBUG

@testable import RevenueCatUI

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
struct AppContentView_Previews: PreviewProvider {

    static var previews: some View {
        NavigationStack {
            AppContentView()
        }
    }

}

#endif
