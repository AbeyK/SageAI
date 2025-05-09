import SwiftUI

struct ContentView: View {
    @StateObject var authManager = FirebaseAuthManager()

    var body: some View {
        NavigationView {
            if authManager.user != nil {
                // User is logged in - show ChatViewController
                ChatViewControllerRepresentable()
                    .navigationBarItems(trailing: Button(action: {
                        authManager.signOut()
                    }) {
                        Text("Sign Out")
                            .foregroundColor(.red)
                    })
            } else {
                // User is not logged in
                LoginView(authManager: authManager)
                    .navigationTitle("Sign In / Sign Up")
            }
        }
    }
}

// UIKit wrapper for ChatViewController
struct ChatViewControllerRepresentable: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> ChatViewController {
        return ChatViewController()
    }
    
    func updateUIViewController(_ uiViewController: ChatViewController, context: Context) {
        // Update the view controller if needed
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
} 