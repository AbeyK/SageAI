import SwiftUI

struct ContentView: View {
    @StateObject var authManager = FirebaseAuthManager()

    var body: some View {
        NavigationView {
            if authManager.user != nil {
                // User is logged in - show ChatViewController
                ChatViewControllerRepresentable(authManager: authManager)
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
    let authManager: FirebaseAuthManager
    
    func makeUIViewController(context: Context) -> ChatViewController {
        let chatVC = ChatViewController()
        chatVC.authManager = authManager
        return chatVC
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