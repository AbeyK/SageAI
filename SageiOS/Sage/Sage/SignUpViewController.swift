import UIKit

protocol SignUpViewControllerDelegate: AnyObject {
    func didSignUpSuccessfully(from signUpViewController: SignUpViewController)
}

class SignUpViewController: UIViewController {
    weak var delegate: SignUpViewControllerDelegate?
    private let authManager = FirebaseAuthManager()

    private let faceView: RedPandaView = {
        let view = RedPandaView(frame: .zero, type: .happy)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Create Account"
        label.font = .systemFont(ofSize: 28, weight: .semibold)
        label.textColor = UIColor.statusLabelAndIcon
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let emailTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Email"
        textField.backgroundColor = UIColor.pandaCircleBackground
        textField.textColor = UIColor.chatBubbleText
        textField.attributedPlaceholder = NSAttributedString(
            string: "Email",
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.statusLabelAndIcon]
        )
        textField.layer.cornerRadius = 8
        textField.autocapitalizationType = .none
        textField.keyboardType = .emailAddress
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 15, height: textField.frame.height))
        textField.leftViewMode = .always
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()

    private let passwordTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Password"
        textField.backgroundColor = UIColor.pandaCircleBackground
        textField.textColor = UIColor.chatBubbleText
        textField.attributedPlaceholder = NSAttributedString(
            string: "Password",
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.statusLabelAndIcon]
        )
        textField.layer.cornerRadius = 8
        textField.isSecureTextEntry = true
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 15, height: textField.frame.height))
        textField.leftViewMode = .always
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()

    private let signUpButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Sign Up", for: .normal)
        button.backgroundColor = UIColor.primaryButtonBackground
        button.setTitleColor(UIColor.primaryButtonText, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let loginLabel: UILabel = {
        let label = UILabel()
        label.text = "Already have an account? Log In"
        label.font = .systemFont(ofSize: 14)
        label.textColor = UIColor.statusLabelAndIcon
        label.textAlignment = .center
        label.isUserInteractionEnabled = true // Enable for tap gesture
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.appBackground
        faceView.updateInitializingLabelState(isInitializing: true) // Or another appropriate state
        setupUI()
    }

    private func setupUI() {
        view.addSubview(faceView)
        view.addSubview(titleLabel)
        view.addSubview(emailTextField)
        view.addSubview(passwordTextField)
        view.addSubview(signUpButton)
        view.addSubview(loginLabel)

        NSLayoutConstraint.activate([
            faceView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 60),
            faceView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            faceView.widthAnchor.constraint(equalToConstant: 120),
            faceView.heightAnchor.constraint(equalToConstant: 120),

            titleLabel.topAnchor.constraint(equalTo: faceView.bottomAnchor, constant: 30),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            emailTextField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 40),
            emailTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            emailTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            emailTextField.heightAnchor.constraint(equalToConstant: 50),

            passwordTextField.topAnchor.constraint(equalTo: emailTextField.bottomAnchor, constant: 16),
            passwordTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            passwordTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            passwordTextField.heightAnchor.constraint(equalToConstant: 50),

            signUpButton.topAnchor.constraint(equalTo: passwordTextField.bottomAnchor, constant: 30),
            signUpButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            signUpButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            signUpButton.heightAnchor.constraint(equalToConstant: 50),

            loginLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            loginLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])

        signUpButton.addTarget(self, action: #selector(signUpButtonTapped), for: .touchUpInside)
        let loginTapGesture = UITapGestureRecognizer(target: self, action: #selector(loginLabelTapped))
        loginLabel.addGestureRecognizer(loginTapGesture)
    }

    @objc private func signUpButtonTapped() {
        guard let email = emailTextField.text, !email.isEmpty,
              let password = passwordTextField.text, !password.isEmpty else {
            showErrorAlert(message: "Please enter both email and password")
            print("Email or password is empty")
            return
        }

        // TODO: Add email validation if desired

        authManager.signUp(email: email, password: password) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                switch result {
                case .success(let user):
                    print("Sign up successful for user: \(user.uid)")
                    // Notify delegate (LoginViewController) to handle transition
                    self.delegate?.didSignUpSuccessfully(from: self)
                case .failure(let error):
                    self.showErrorAlert(message: "Sign up error: \(error.localizedDescription)")
                    print("Sign up error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // Helper method to display error alerts
    private func showErrorAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    @objc private func loginLabelTapped() {
        dismiss(animated: true, completion: nil)
    }
} 