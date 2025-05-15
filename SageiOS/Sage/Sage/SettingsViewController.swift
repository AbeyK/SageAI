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
        label.textColor = SageColors.primaryButtonColor
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let blurbLabel: UILabel = {
        let label = UILabel()
        label.text = "Sage is your mindful AI companion, here to guide you through meditation, reflection, and growth."
        label.font = .systemFont(ofSize: 16, weight: .regular)
        label.textColor = SageColors.primaryButtonColor
        label.textAlignment = .center
        label.numberOfLines = 0
        label.backgroundColor = SageColors.backgroundColor.withAlphaComponent(0.7)
        label.layer.cornerRadius = 12
        label.layer.masksToBounds = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let signOutButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Sign Out", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = SageColors.primaryButtonColor
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        button.layer.cornerRadius = 8
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
        
        view.backgroundColor = SageColors.backgroundColor
        
        view.addSubview(titleLabel)
        view.addSubview(blurbLabel)
        view.addSubview(signOutButton)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            blurbLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 18),
            blurbLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            blurbLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            blurbLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 60),
            
            signOutButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -40),
            signOutButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            signOutButton.widthAnchor.constraint(equalToConstant: 180),
            signOutButton.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        signOutButton.addTarget(self, action: #selector(signOutTapped), for: .touchUpInside)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientLayer.frame = view.bounds
    }
    
    @objc private func signOutTapped() {
        dismiss(animated: true) { [weak self] in
            self?.delegate?.didTapSignOut()
        }
    }
}
