//
//  ViewController.swift
//  Sage
//
//  Created by hassan Khan on 4/30/25.
//

import UIKit

class LoginViewController: UIViewController {
    private let authManager = FirebaseAuthManager()
    
    private let faceView: RedPandaView = {
        let view = RedPandaView(frame: .zero, type: .happy)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "ZenPal"
        label.font = .zenAppTitle
        label.textColor = UIColor.appTitleBlue
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let usernameTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Username"
        textField.backgroundColor = UIColor.pandaCircleBackground
        textField.textColor = UIColor.loginFormText
        textField.attributedPlaceholder = NSAttributedString(
            string: "Username",
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.loginFormPlaceholder]
        )
        textField.layer.cornerRadius = 8
        textField.autocapitalizationType = .none
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 15, height: textField.frame.height))
        textField.leftViewMode = .always
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private let passwordTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Password"
        textField.backgroundColor = UIColor.pandaCircleBackground
        textField.textColor = UIColor.loginFormText
        textField.attributedPlaceholder = NSAttributedString(
            string: "Password",
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.loginFormPlaceholder]
        )
        textField.layer.cornerRadius = 8
        textField.isSecureTextEntry = true
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 15, height: textField.frame.height))
        textField.leftViewMode = .always
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private let errorLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.systemRed
        label.font = .zenCaption
        label.textAlignment = .center
        label.numberOfLines = 0
        label.isHidden = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let loginButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Log In", for: .normal)
        button.backgroundColor = UIColor.primaryButtonBackground
        button.setTitleColor(UIColor.primaryButtonText, for: .normal)
        button.titleLabel?.font = .zenButton
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let forgotPasswordButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Forgot Password?", for: .normal)
        button.setTitleColor(UIColor.loginFormText, for: .normal)
        button.titleLabel?.font = .zenCaption
        button.translatesAutoresizingMaskIntoConstraints = false
        button.alpha = 0
        return button
    }()

    private let signupButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Sign Up", for: .normal)
        button.backgroundColor = UIColor.pandaCircleBackground
        button.setTitleColor(UIColor.loginFormText, for: .normal)
        button.titleLabel?.font = .zenButton
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.appBackground
        faceView.updateInitializingLabelState(isInitializing: true)
        setupUI()

        // Add tap gesture recognizer to dismiss keyboard
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)

        // Add swipe gesture recognizer to dismiss keyboard
        let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        swipeGesture.direction = .down
        view.addGestureRecognizer(swipeGesture)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    private func setupUI() {
        // Add subviews
        view.addSubview(faceView)
        view.addSubview(titleLabel)
        view.addSubview(usernameTextField)
        view.addSubview(passwordTextField)
        view.addSubview(loginButton)
        view.addSubview(signupButton)
        view.addSubview(errorLabel)
        view.addSubview(forgotPasswordButton)
        
        // Set up constraints
        NSLayoutConstraint.activate([
            faceView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 60),
            faceView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            faceView.widthAnchor.constraint(equalToConstant: 120),
            faceView.heightAnchor.constraint(equalToConstant: 120),
            
            // Title constraints
            titleLabel.topAnchor.constraint(equalTo: faceView.bottomAnchor, constant: 30),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            // Username text field constraints
            usernameTextField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 40),
            usernameTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            usernameTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            usernameTextField.heightAnchor.constraint(equalToConstant: 50),
            
            // Password text field constraints
            passwordTextField.topAnchor.constraint(equalTo: usernameTextField.bottomAnchor, constant: 16),
            passwordTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            passwordTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            passwordTextField.heightAnchor.constraint(equalToConstant: 50),
            
            // Login button constraints
            loginButton.topAnchor.constraint(equalTo: passwordTextField.bottomAnchor, constant: 30),
            loginButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            loginButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            loginButton.heightAnchor.constraint(equalToConstant: 50),
            
            // Signup button constraints
            signupButton.topAnchor.constraint(equalTo: loginButton.bottomAnchor, constant: 16),
            signupButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            signupButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            signupButton.heightAnchor.constraint(equalToConstant: 50),
            
            // Error label constraints - now below the signup button
            errorLabel.topAnchor.constraint(equalTo: signupButton.bottomAnchor, constant: 16),
            errorLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            errorLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            
            // Forgot password button constraints
            forgotPasswordButton.topAnchor.constraint(equalTo: errorLabel.bottomAnchor, constant: 8),
            forgotPasswordButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30)
        ])
        
        // Add button actions
        forgotPasswordButton.addTarget(self, action: #selector(forgotPasswordTapped), for: .touchUpInside)
        loginButton.addTarget(self, action: #selector(loginButtonTapped), for: .touchUpInside)
        signupButton.addTarget(self, action: #selector(signupButtonTapped), for: .touchUpInside)
    }
    
    @objc private func signupButtonTapped() {
        let signUpVC = SignUpViewController()
        signUpVC.delegate = self // Set the delegate
        signUpVC.modalPresentationStyle = .automatic // Changed from .fullScreen to enable swipe down dismissal
        present(signUpVC, animated: true, completion: nil)
    }
    
    @objc private func loginButtonTapped() {
        // Hide any previous error
        hideError()
        
        guard let username = usernameTextField.text, !username.isEmpty,
              let password = passwordTextField.text, !password.isEmpty else {
            // Show error message for empty fields
            showError(message: "Please enter both email and password")
            return
        }
        
        authManager.signIn(email: username, password: password) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self?.hideError()
                    self?.transitionToHomeViewController()
                case .failure(let error):
                    // Show error message to the user
                    self?.showError(message: "Login error: \(error.localizedDescription)")
                    print("Login error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // Show error message in the UI
    private func showError(message: String) {
        errorLabel.text = message
        errorLabel.isHidden = false
    }
    
    // Hide the error message
    private func hideError() {
        errorLabel.isHidden = true
    }
    
    private func transitionToHomeViewController() {
        let homeViewController = HomeViewController()
        homeViewController.modalPresentationStyle = .fullScreen
        homeViewController.authManager = authManager
        present(homeViewController, animated: true)
    }
    
    @objc private func forgotPasswordTapped() {
        // Handle forgot password tap
        print("Forgot password tapped")
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
}

extension LoginViewController: SignUpViewControllerDelegate {
    func didSignUpSuccessfully(from signUpViewController: SignUpViewController) {
        // First, dismiss the SignUpViewController
        signUpViewController.dismiss(animated: true) { [weak self] in
            // Then, transition to HomeViewController
            self?.transitionToHomeViewController()
        }
    }
}
