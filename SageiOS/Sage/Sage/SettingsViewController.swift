//
//  SettingsViewController.swift
//  Sage
//
//  Created by hassan Khan on 4/30/25.
//

import UIKit

protocol ChatViewControllerDelegate: AnyObject {
    func didTapSignOut()
}

class SettingsViewController: UIViewController {
    public weak var delegate: ChatViewControllerDelegate?

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Settings"
        label.font = .boldSystemFont(ofSize: 24)
        label.textColor = .white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let voicePicker: UISegmentedControl = {
        let control = UISegmentedControl(items: ["Voice 1", "Voice 2", "Voice 3"])
        control.selectedSegmentIndex = 0
        control.translatesAutoresizingMaskIntoConstraints = false
        return control
    }()
    
    private let signOutButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Sign Out", for: .normal)
        button.setTitleColor(.red, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let gradientLayer: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.colors = [
            UIColor(red: 0.6, green: 0.4, blue: 0.9, alpha: 1.0).cgColor,
            UIColor(red: 0.2, green: 0.2, blue: 0.4, alpha: 1.0).cgColor
        ]
        layer.locations = [0.0, 1.0]
        return layer
    }()

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set up gradient background
        view.layer.insertSublayer(gradientLayer, at: 0)

        
        view.addSubview(titleLabel)
        view.addSubview(voicePicker)
        view.addSubview(signOutButton)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            voicePicker.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 40),
            voicePicker.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            voicePicker.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            signOutButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -40),
            signOutButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
        
        signOutButton.addTarget(self, action: #selector(signOutTapped), for: .touchUpInside)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientLayer.frame = view.bounds
    }
    
    @objc private func signOutTapped() {
        // Handle sign out
        dismiss(animated: true)
        
        if let delegate = delegate {
            delegate.didTapSignOut()
        }
    }
}
