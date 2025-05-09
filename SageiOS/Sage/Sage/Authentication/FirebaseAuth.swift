import Firebase
import FirebaseAuth
import FirebaseCore
import FirebaseAppCheck

class FirebaseAuthManager: ObservableObject {
    @Published var user: User?
    @Published var authError: Error?

    private var authStateHandler: AuthStateDidChangeListenerHandle?

    init() {
        // Initialize Firebase if not already configured
        if FirebaseApp.app() == nil {
            // Configure App Check
            let providerFactory = AppCheckDebugProviderFactory()
            AppCheck.setAppCheckProviderFactory(providerFactory)
            
            // Configure Firebase
            FirebaseApp.configure()
        }
        addAuthStateListener()
    }

    deinit {
        removeAuthStateListener()
    }

    func addAuthStateListener() {
        authStateHandler = Auth.auth().addStateDidChangeListener { [weak self] (auth, user) in
            self?.user = user
            if user == nil {
                // User is signed out
                // You might want to clear any user-specific data here
            } else {
                // User is signed in
                // You can fetch user-specific data here if needed
            }
            self?.authError = nil // Clear previous errors on state change
        }
    }

    func removeAuthStateListener() {
        if let handle = authStateHandler {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }

    func signIn(email: String, password: String) {
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] (authResult, error) in
            if let error = error {
                self?.authError = error
                return
            }
            // User is signed in
            self?.authError = nil
        }
    }

    func signUp(email: String, password: String) {
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] (authResult, error) in
            if let error = error {
                self?.authError = error
                return
            }
            // User is signed up and signed in
            self?.authError = nil
        }
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
            self.authError = nil
        } catch let signOutError as NSError {
            self.authError = signOutError
        }
    }
} 
