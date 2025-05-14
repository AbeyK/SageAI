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

    private let pandaView: RedPandaView = {
        let view = RedPandaView(frame: .zero, type: .happy)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let settingsButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "gearshape.fill"), for: .normal)
        button.tintColor = SageColors.primaryButtonColor
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let chatTableView: UITableView = {
        let tableView = UITableView()
        tableView.separatorStyle = .none
        tableView.backgroundColor = SageColors.primaryButtonColor.withAlphaComponent(0.3)
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
        button.backgroundColor = SageColors.primaryButtonColor
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
    
    private var messages: [(content: String, isSentByUser: Bool)] = []
    private var isMuted: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTableView()
        
        // Initialize ConversationManager without the hardcoded API key
        let conversationManager = ConversationManager(delegate: self)
        conversationManager.startConversation()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientLayer.frame = view.bounds
        muteButton.layer.cornerRadius = muteButton.bounds.width / 2
    }
    
    private func setupUI() {
        view.backgroundColor = SageColors.backgroundColor
        view.backgroundColor = SageColors.backgroundColor
        // Add subviews
        view.addSubview(pandaView)
        view.addSubview(pandaView)
        view.addSubview(chatTableView)
        view.addSubview(muteButton)
        view.addSubview(settingsButton)
    
        // Calculate pandaView dimensions
        let screenWidth = UIScreen.main.bounds.width
        let pandaViewDimension = screenWidth * 0.5

        // Create constraints
        let faceWidthConstraint = pandaView.widthAnchor.constraint(equalToConstant: pandaViewDimension)
        let faceHeightConstraint = pandaView.heightAnchor.constraint(equalToConstant: pandaViewDimension)
        let faceMaxWidthConstraint = pandaView.widthAnchor.constraint(lessThanOrEqualToConstant: pandaViewDimension + 20)
        let faceMaxHeightConstraint = pandaView.heightAnchor.constraint(lessThanOrEqualToConstant: pandaViewDimension + 20)

        // Activate constraints
        NSLayoutConstraint.activate([
            faceWidthConstraint,
            faceHeightConstraint,
            faceMaxWidthConstraint,
            faceMaxHeightConstraint,
            pandaView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            pandaView.bottomAnchor.constraint(equalTo: chatTableView.topAnchor, constant: -80)
        ])
        
        // Set up constraints
        NSLayoutConstraint.activate([
            // Settings button
            settingsButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            settingsButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            settingsButton.widthAnchor.constraint(equalToConstant: 40),
            settingsButton.heightAnchor.constraint(equalToConstant: 40),

            // Chat table
            chatTableView.heightAnchor.constraint(equalToConstant: 200),
            chatTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            chatTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            chatTableView.bottomAnchor.constraint(equalTo: muteButton.topAnchor, constant: -60),
            
            // Mute button
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
        muteButton.backgroundColor = isMuted ? .red : SageColors.primaryButtonColor
    }

    @objc private func settingsButtonTapped() {
        let settingsVC = SettingsViewController()
        settingsVC.modalPresentationStyle = .formSheet
        settingsVC.delegate = self
        present(settingsVC, animated: true)
    }

    
    func addMessage(_ message: String, isSentByUser: Bool) {
        messages.append((content: message, isSentByUser: isSentByUser))
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
    
    // MARK: - ConversationManagerDelegate

    func conversationManagerDidAddMessage(_ message: ChatMessage, isSentByUser: Bool) {
        DispatchQueue.main.async {
            self.addMessage(message.content, isSentByUser: isSentByUser)
        }
    }

    func conversationManagerStatus(status: ConversationStatus) {
        switch status {
        case .isListening:
            pandaView.updateListeningState(isListening: true)
            pandaView.updateThinkingLabelState(isThinking: false)
            pandaView.updatePandaView(for: .meditating)
        case .isTalking:
            pandaView.updateListeningState(isListening: false)
            pandaView.updateThinkingLabelState(isThinking: false)
            pandaView.updatePandaView(for: .talking)
        case .isThinking:
            pandaView.updateListeningState(isListening: false)
            pandaView.updateThinkingLabelState(isThinking: true)
            pandaView.updatePandaView(for: .meditating)
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
        let message = messages[indexPath.row]
        cell.configure(with: message.content, sent: message.isSentByUser)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}

extension ChatViewController: ChatViewControllerDelegate {
    func didTapSignOut() {
        dismiss(animated: true) {
            self.authManager?.signOut()
        }
    }
}
