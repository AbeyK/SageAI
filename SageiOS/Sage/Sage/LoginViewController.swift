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
        label.text = "Sage"
        label.font = .systemFont(ofSize: 28, weight: .semibold)
        label.textColor = UIColor.statusLabelAndIcon
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let usernameTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Username"
        textField.backgroundColor = UIColor.pandaCircleBackground
        textField.textColor = UIColor.chatBubbleText
        textField.attributedPlaceholder = NSAttributedString(
            string: "Username",
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.statusLabelAndIcon]
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
    
    private let loginButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Log In", for: .normal)
        button.backgroundColor = UIColor.primaryButtonBackground
        button.setTitleColor(UIColor.primaryButtonText, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let forgotPasswordButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Forgot Password?", for: .normal)
        button.setTitleColor(UIColor.statusLabelAndIcon, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let signupLabel: UILabel = {
        let label = UILabel()
        label.text = "Don't have an account? Sign Up"
        label.font = .systemFont(ofSize: 14)
        label.textColor = UIColor.statusLabelAndIcon
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.appBackground
        faceView.updateInitializingLabelState(isInitializing: true)
        setupUI()
        setupSignUpLabelTap()
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
        view.addSubview(forgotPasswordButton)
        view.addSubview(signupLabel)
        
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
            
            // Forgot password button constraints
            forgotPasswordButton.topAnchor.constraint(equalTo: loginButton.bottomAnchor, constant: 16),
            forgotPasswordButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            
            // Sign up label constraints
            signupLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            signupLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
        
        // Add button actions
        forgotPasswordButton.addTarget(self, action: #selector(forgotPasswordTapped), for: .touchUpInside)
        loginButton.addTarget(self, action: #selector(loginButtonTapped), for: .touchUpInside)
    }
    
    private func setupSignUpLabelTap() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(signupLabelTapped))
        signupLabel.isUserInteractionEnabled = true // Ensure interaction is enabled
        signupLabel.addGestureRecognizer(tapGesture)
    }

    @objc private func signupLabelTapped() {
        let signUpVC = SignUpViewController()
        signUpVC.delegate = self // Set the delegate
        signUpVC.modalPresentationStyle = .automatic // Changed from .fullScreen to enable swipe down dismissal
        present(signUpVC, animated: true, completion: nil)
    }
    
    @objc private func loginButtonTapped() {
        guard let username = usernameTextField.text, !username.isEmpty,
              let password = passwordTextField.text, !password.isEmpty else {
            // Show error message
            return
        }
        
        authManager.signIn(email: username, password: password) { [weak self] result in
            switch result {
            case .success:
                self?.transitionToChatViewController()
            case .failure(let error):
                // Handle error (e.g., show alert)
                print("Login error: \(error.localizedDescription)")
            }
        }
    }
    
    private func transitionToChatViewController() {
        let chatViewController = ChatViewController()
        chatViewController.modalPresentationStyle = .fullScreen
        chatViewController.authManager = authManager
        present(chatViewController, animated: true)
    }
    
    @objc private func forgotPasswordTapped() {
        // Handle forgot password tap
        print("Forgot password tapped")
    }
}

extension LoginViewController: SignUpViewControllerDelegate {
    func didSignUpSuccessfully(from signUpViewController: SignUpViewController) {
        // First, dismiss the SignUpViewController
        signUpViewController.dismiss(animated: true) { [weak self] in
            // Then, transition to ChatViewController
            self?.transitionToChatViewController()
        }
    }
}
