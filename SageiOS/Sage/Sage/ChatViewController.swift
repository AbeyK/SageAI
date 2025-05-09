//
//  ChatViewController.swift
//  Sage
//
//  Created by hassan Khan on 4/30/25.
//

import UIKit
import AVKit

class ChatViewController: UIViewController, ConversationManagerDelegate {
    var authManager: FirebaseAuthManager?
    
    private let backgroundModeView: BackgroundModeView = {
        guard let url = Bundle.main.url(forResource: "Forest", withExtension: "mp4") else {
            fatalError("testing -> Video file not found in bundle.")
        }
        let view = BackgroundModeView(frame: .zero, videoURL: url)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let faceView: WaterFaceView = {
        let view = WaterFaceView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let settingsButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "gearshape.fill"), for: .normal)
        button.tintColor = .white
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let chatTableView: UITableView = {
        let tableView = UITableView()
        tableView.separatorStyle = .none
        tableView.backgroundColor = UIColor(white: 0.5, alpha: 0.3) // semi-transparent grey
        tableView.layer.cornerRadius = 16
        tableView.clipsToBounds = true
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(ChatMessageCell.self, forCellReuseIdentifier: ChatMessageCell.identifier)
        return tableView
    }()
    
    private let muteButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "mic.fill"), for: .normal)
        button.tintColor = .white
        button.backgroundColor = UIColor.gray
        button.layer.cornerRadius = 25
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
    
    private var messages: [String] = []
    private var isMuted: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTableView()
        
        let conversationManager = ConversationManager(apiKey: "sk-proj-REDACTED", delegate: self)
        conversationManager.startConversation()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientLayer.frame = view.bounds
        muteButton.layer.cornerRadius = muteButton.bounds.width / 2
    }
    
    private func setupUI() {
        // Set up gradient background
//        view.layer.insertSublayer(gradientLayer, at: 0)
        view.backgroundColor = .clear
        // Add subviews
        view.insertSubview(backgroundModeView, at: 0)
        view.addSubview(faceView)
        view.addSubview(chatTableView)
        view.addSubview(muteButton)
        view.addSubview(settingsButton)
        
        // Set up constraints
        NSLayoutConstraint.activate([
            // Background mode view
            backgroundModeView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundModeView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            backgroundModeView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundModeView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            // Settings button
            settingsButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            settingsButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            settingsButton.widthAnchor.constraint(equalToConstant: 30),
            settingsButton.heightAnchor.constraint(equalToConstant: 30),

            // Face view (larger)
            faceView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 30),
            faceView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            faceView.widthAnchor.constraint(equalToConstant: 180),
            faceView.heightAnchor.constraint(equalToConstant: 180),

            // Chat table (shorter)
            chatTableView.topAnchor.constraint(equalTo: faceView.bottomAnchor, constant: 20),
            chatTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            chatTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            chatTableView.bottomAnchor.constraint(equalTo: muteButton.topAnchor, constant: -60),

            // Mute button (larger)
            muteButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            muteButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            muteButton.widthAnchor.constraint(equalToConstant: 70),
            muteButton.heightAnchor.constraint(equalToConstant: 70)
        ])
        
        // Add button action
        settingsButton.addTarget(self, action: #selector(settingsButtonTapped), for: .touchUpInside)
        muteButton.addTarget(self, action: #selector(muteButtonTapped), for: .touchUpInside)

        // Start occasional rotation
        // startRotatingSettingsButton()
    }
    
    private func setupTableView() {
        chatTableView.delegate = self
        chatTableView.dataSource = self
        chatTableView.register(ChatMessageCell.self, forCellReuseIdentifier: "ChatMessageCell")
    }
    
    @objc private func muteButtonTapped() {
        isMuted.toggle()
        muteButton.backgroundColor = isMuted ? .red : .gray
    }

    private func stopBackgroundVideo() {
        backgroundModeView.stopVideo()
    }

    @objc private func settingsButtonTapped() {
        let settingsVC = SettingsViewController()
        settingsVC.modalPresentationStyle = .formSheet
        settingsVC.delegate = self
        present(settingsVC, animated: true)
    }

    
    func addMessage(_ message: String) {
        messages.append(message)
        let indexPath = IndexPath(row: messages.count - 1, section: 0)
        chatTableView.insertRows(at: [indexPath], with: .automatic)
        chatTableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
    }

    private func startRotatingSettingsButton() {
        Timer.scheduledTimer(withTimeInterval: 8.0, repeats: true) { _ in
            UIView.animate(withDuration: 1.0) {
                self.settingsButton.transform = self.settingsButton.transform.rotated(by: CGFloat.pi)
            }
        }
    }

    func conversationManagerAddingMessage(_ transcript: String) {
        DispatchQueue.main.async {
            self.addMessage(transcript)
        }
    }
}

// MARK: - UITableViewDelegate & UITableViewDataSource
extension ChatViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChatMessageCell", for: indexPath) as! ChatMessageCell
        cell.configure(with: messages[indexPath.row], sent: indexPath.row % 2 == 0)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}

extension ChatViewController: ChatViewControllerDelegate {
    func didTapSignOut() {
        stopBackgroundVideo()
        dismiss(animated: true) {
            self.authManager?.signOut()
        }
    }
}
