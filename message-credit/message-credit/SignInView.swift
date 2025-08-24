//
//  SignInView.swift
//  message-credit
//
//  Created by Claude on 8/24/25.
//

import SwiftUI
import CoreData

struct SignInView: View {
    @State private var name = ""
    @State private var email = ""
    @State private var isSignedIn = false
    @Environment(\.managedObjectContext) private var viewContext
    
    var body: some View {
        ZStack {
            GradientBackground()
            
            VStack(spacing: 30) {
                Spacer()
                
                // App Logo/Title
                VStack(spacing: 16) {
                    Image(systemName: "shield.checkered")
                        .font(.system(size: 80))
                        .foregroundColor(.white)
                    
                    Text("Privacy Credit Analyzer")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text("Secure on-device credit analysis")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
                
                Spacer()
                
                // Sign In Form
                VStack(spacing: 20) {
                    TextField("Full Name", text: $name)
                        .textFieldStyle(ModernTextFieldStyle())
                        .colorScheme(.dark)
                    
                    TextField("Email Address", text: $email)
                        .textFieldStyle(ModernTextFieldStyle())
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .colorScheme(.dark)
                    
                    Button(action: signIn) {
                        Text("Get Started")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [Color.blue, Color.purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                    }
                    .disabled(name.isEmpty || email.isEmpty)
                    .opacity(name.isEmpty || email.isEmpty ? 0.6 : 1.0)
                }
                .padding(.horizontal, 30)
                
                Spacer()
                
                Text("Your data stays private and secure on your device")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                Spacer()
            }
        }
        .fullScreenCover(isPresented: $isSignedIn) {
            ContentView()
        }
    }
    
    private func signIn() {
        // Create new user in Core Data
        let newUser = User(context: viewContext)
        newUser.id = UUID()
        newUser.name = name
        newUser.email = email
        newUser.createdAt = Date()
        
        do {
            try viewContext.save()
            isSignedIn = true
        } catch {
            print("Failed to save user: \(error)")
        }
    }
}

struct ModernTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color.white.opacity(0.15))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.4), lineWidth: 1)
            )
            .foregroundColor(.white)
            .accentColor(.white)
    }
}

#Preview {
    SignInView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}