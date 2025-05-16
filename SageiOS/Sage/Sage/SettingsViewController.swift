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

    private let pandaImageView: UIImageView = {
        let image = UIImage(named: "PandaHappy") ?? UIImage(contentsOfFile: Bundle.main.path(forResource: "PandaHappy", ofType: "png", inDirectory: "Resources") ?? "")
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.clipsToBounds = true
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Settings"
        label.font = .boldSystemFont(ofSize: 32)
        label.textColor = UIColor.primaryButtonBackground
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let blurbLabel: UILabel = {
        let label = UILabel()
        label.text = "Sage is your mindful AI companion, here to guide you through meditation, reflection, and growth."
        label.font = .systemFont(ofSize: 20, weight: .semibold)
        label.textColor = UIColor.primaryButtonBackground
        label.textAlignment = .center
        label.numberOfLines = 0
        label.backgroundColor = UIColor.appBackground.withAlphaComponent(0.7)
        label.layer.cornerRadius = 12
        label.layer.masksToBounds = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let signOutButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Sign Out", for: .normal)
        button.setTitleColor(UIColor.primaryButtonText, for: .normal)
        button.backgroundColor = UIColor.primaryButtonBackground
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let gradientLayer: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.colors = [
            UIColor.appBackground.cgColor,
            UIColor.primaryButtonBackground.cgColor
        ]
        layer.locations = [0.0, 1.0]
        return layer
    }()

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.appBackground
        
        view.addSubview(titleLabel)
        view.addSubview(pandaImageView)
        view.addSubview(blurbLabel)
        view.addSubview(signOutButton)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            pandaImageView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 18),
            pandaImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            pandaImageView.widthAnchor.constraint(equalToConstant: 220),
            pandaImageView.heightAnchor.constraint(equalToConstant: 220),

            blurbLabel.topAnchor.constraint(equalTo: pandaImageView.bottomAnchor, constant: 18),
            blurbLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
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
