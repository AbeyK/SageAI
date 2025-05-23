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
    public weak var delegate: HomeViewControllerDelegate?

    private let pandaImageView: UIImageView = {
        let image = UIImage(named: "PandaHappy") ?? UIImage(contentsOfFile: Bundle.main.path(forResource: "PandaHappy", ofType: "png", inDirectory: "Resources") ?? "")
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.clipsToBounds = true
        return imageView
    }()
    
    private let pandaBackgroundCircleView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.pandaCircleBackground
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "ZenPal"
        label.font = .boldSystemFont(ofSize: 28)
        label.textColor = UIColor.statusLabelAndIcon
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let blurbLabel: UILabel = {
        let label = UILabel()
        label.text = "Ember is your personal red panda meditation guru! Just share your story and she'll craft a custom meditation that's perfect for you. Ember will adapt, evolve and grow with you with each meditation."
        label.font = .systemFont(ofSize: 20)
        label.textColor = UIColor.statusLabelAndIcon
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
        button.setTitleColor(UIColor.pandaAccentOrange, for: .normal)
        button.backgroundColor = .clear
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let feedbackButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Share Your Feedback", for: .normal)
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
        
        view.addSubview(pandaBackgroundCircleView)
        view.addSubview(titleLabel)
        view.addSubview(pandaImageView)
        view.addSubview(blurbLabel)
        view.addSubview(signOutButton)
        view.addSubview(feedbackButton)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 50),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            pandaImageView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 50),
            pandaImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            pandaImageView.widthAnchor.constraint(equalToConstant: 220),
            pandaImageView.heightAnchor.constraint(equalToConstant: 220),

            pandaBackgroundCircleView.centerXAnchor.constraint(equalTo: pandaImageView.centerXAnchor),
            pandaBackgroundCircleView.centerYAnchor.constraint(equalTo: pandaImageView.centerYAnchor),
            pandaBackgroundCircleView.widthAnchor.constraint(equalTo: pandaImageView.heightAnchor, multiplier: 1.15),
            pandaBackgroundCircleView.heightAnchor.constraint(equalTo: pandaImageView.heightAnchor, multiplier: 1.15),

            blurbLabel.topAnchor.constraint(equalTo: pandaImageView.bottomAnchor, constant: 30),
            blurbLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            blurbLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            blurbLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            blurbLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 60),
            
            feedbackButton.topAnchor.constraint(equalTo: blurbLabel.bottomAnchor, constant: 30),
            feedbackButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            feedbackButton.widthAnchor.constraint(equalToConstant: 220),
            feedbackButton.heightAnchor.constraint(equalToConstant: 50),
            feedbackButton.bottomAnchor.constraint(equalTo: signOutButton.topAnchor, constant: -30),
            
            signOutButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            signOutButton.widthAnchor.constraint(equalToConstant: 180),
            signOutButton.heightAnchor.constraint(equalToConstant: 44),
            signOutButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
        
        signOutButton.addTarget(self, action: #selector(signOutTapped), for: .touchUpInside)
        feedbackButton.addTarget(self, action: #selector(feedbackButtonTapped), for: .touchUpInside)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientLayer.frame = view.bounds
        pandaBackgroundCircleView.layer.cornerRadius = pandaBackgroundCircleView.frame.height / 2
    }
    
    @objc private func signOutTapped() {
        dismiss(animated: true) { [weak self] in
            self?.delegate?.didTapSignOut()
        }
    }

    @objc private func feedbackButtonTapped() {
        print("[LOG] Feedback button tapped!")
        if let url = URL(string: "https://docs.google.com/forms/d/e/1FAIpQLSfTqT-F24c0JRmCwJpi4a4zEQbhlJhmZxnLtmQAjTbUBfHd7w/viewform") {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
}
