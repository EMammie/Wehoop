//
//  BurgerMenuView.swift
//  Wehoop
//
//  Created by E on 1/2/26.
//

import SwiftUI

/// Burger menu overlay that can be toggled on/off
struct BurgerMenuView: View {
    @Binding var isPresented: Bool
    @Environment(\.theme) private var theme
    @State private var showSettings = false
    @State private var showFeatureFlags = false
    
    var body: some View {
        ZStack {
            // Background overlay
            if isPresented {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation {
                            isPresented = false
                        }
                    }
            }
            
            // Menu panel
            HStack {
                Spacer()
                
                VStack(alignment: .trailing, spacing: 0) {
                    // Menu header
                    HStack {
                        Spacer()
                        Button {
                            withAnimation {
                                isPresented = false
                            }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(theme.colorScheme.foreground)
                        }
                        .padding()
                    }
                    
                    // Menu items
                    VStack(alignment: .trailing, spacing: 0) {
                        #if DEBUG
                        Button {
                            showSettings = true
                        } label: {
                            HStack {
                                Text("Settings")
                                    .font(theme.typography.body)
                                    .foregroundColor(theme.colorScheme.foreground)
                                Image(systemName: "gearshape")
                                    .foregroundColor(theme.colorScheme.accent)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                        .background(theme.colorScheme.background)
                        
                        Divider()
                        
                        Button {
                            showFeatureFlags = true
                        } label: {
                            HStack {
                                Text("Feature Flags")
                                    .font(theme.typography.body)
                                    .foregroundColor(theme.colorScheme.foreground)
                                Image(systemName: "flag.fill")
                                    .foregroundColor(theme.colorScheme.accent)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                        .background(theme.colorScheme.background)
                        #endif
                    }
                    .background(theme.colorScheme.background)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
                    .frame(width: 200)
                }
                .padding(.trailing, 16)
                .padding(.top, 60)
            }
            .opacity(isPresented ? 1 : 0)
            .offset(x: isPresented ? 0 : 300)
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isPresented)
        .sheet(isPresented: $showSettings) {
            NavigationView {
                SettingsView()
            }
        }
        .sheet(isPresented: $showFeatureFlags) {
            NavigationView {
                FeatureFlagsDebugView()
            }
        }
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.2)
            .ignoresSafeArea()
        
        BurgerMenuView(isPresented: .constant(true))
    }
    .environment(\.theme, Theme.wehoop)
}
