//
//  ChatViewController.swift
//  Sage
//
//  Created by hassan Khan on 4/30/25.
//

import UIKit
import AVKit
import FirebaseAuth

class ChatViewController: UIViewController, ConversationManagerDelegate {
    var authManager: FirebaseAuthManager?
    var conversationManager: ConversationManager!

    private let pandaView: RedPandaView = {
        let view = RedPandaView(frame: .zero, type: .happy)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
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

    private let settingsButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "gearshape.fill"), for: .normal)
        button.tintColor = UIColor.statusLabelAndIcon
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let chatTableView: UITableView = {
        let tableView = UITableView()
        tableView.separatorStyle = .none
        tableView.backgroundColor = UIColor.chatTableViewBackground
        tableView.layer.cornerRadius = 16
        tableView.clipsToBounds = true
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(ChatMessageCell.self, forCellReuseIdentifier: ChatMessageCell.identifier)
        return tableView
    }()
    
    private let muteButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "mic.fill"), for: .normal)
        button.tintColor = UIColor.primaryButtonText
        button.backgroundColor = UIColor.primaryButtonBackground
        button.layer.cornerRadius = 25
        button.translatesAutoresizingMaskIntoConstraints = false
        button.alpha = 0
        return button
    }()
    
    private let meditationButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Start My Meditation", for: .normal)
        button.setTitleColor(UIColor.primaryButtonText, for: .normal)
        button.backgroundColor = UIColor.primaryButtonBackground
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        button.layer.cornerRadius = 12
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let timerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.chatTableViewBackground
        view.layer.cornerRadius = 16
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        return view
    }()
    
    private let timerLabel: UILabel = {
        let label = UILabel()
        label.text = "5:00"
        label.textColor = UIColor.primaryButtonText
        label.font = .systemFont(ofSize: 48, weight: .bold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let timerCircle: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.fillColor = UIColor.clear.cgColor
        layer.strokeColor = UIColor.primaryButtonBackground.cgColor
        layer.lineWidth = 8
        layer.lineCap = .round
        return layer
    }()
    
    private var messages: [(content: String, isSentByUser: Bool)] = []
    private var isMuted: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("[LOG] ChatViewController loaded")
        setupUI()
        setupTableView()
        
        // Initialize ConversationManager as a property
        conversationManager = ConversationManager(delegate: self)
        print("[LOG] ConversationManager initialized")
        if Auth.auth().currentUser != nil {
            print("[LOG] User is authenticated, starting conversation")
            conversationManager.startConversation()
        } else {
            print("[LOG] No authenticated user, not starting conversation")
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientLayer.frame = view.bounds
        muteButton.layer.cornerRadius = muteButton.bounds.width / 2
        
        // Update timer circle if it's visible
        if !timerView.isHidden {
            setupTimerCircle()
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            // Update colors for layers and other UI elements that don't update automatically
            updateColorsForCurrentTraitCollection()
        }
    }

    private func updateColorsForCurrentTraitCollection() {
        // Update CAGradientLayer
        gradientLayer.colors = [
            UIColor.appBackground.cgColor,
            UIColor.primaryButtonBackground.cgColor
        ]

        // Update CAShapeLayer
        timerCircle.strokeColor = UIColor.primaryButtonBackground.cgColor
        // timerCircle.fillColor is already UIColor.clear.cgColor, so no need to update if it doesn't change

        // Update view's background directly (though it should update if set with dynamic UIColor)
        view.backgroundColor = UIColor.appBackground

        // Update standard components (many of these should update automatically if set with dynamic UIColors from the palette initially,
        // but explicitly re-setting them can ensure consistency, especially for more complex views or state-dependent colors).
        settingsButton.tintColor = UIColor.statusLabelAndIcon
        chatTableView.backgroundColor = UIColor.chatTableViewBackground
        
        // Mute button color depends on state, ensure it's re-evaluated
        muteButton.tintColor = UIColor.primaryButtonText
        muteButton.backgroundColor = isMuted ? .red : UIColor.primaryButtonBackground
        
        meditationButton.setTitleColor(UIColor.primaryButtonText, for: .normal)
        meditationButton.backgroundColor = UIColor.primaryButtonBackground
        
        timerView.backgroundColor = UIColor.chatTableViewBackground
        timerLabel.textColor = UIColor.primaryButtonText

        // PandaView might have its own traitCollectionDidChange or need specific update methods
        // If RedPandaView has its own complex drawing or sublayers, it should also implement traitCollectionDidChange.
        // For now, if it relies on standard UIKit properties set with dynamic colors, it might update automatically.
        // We can call a generic update method if it exists, or just let it be for now.
        // pandaView.updateAppearanceForTraitCollection() // Example if such a method exists

        // Reload table view to update cell colors
        chatTableView.reloadData()

        // Ensure layout and display are updated
        view.setNeedsLayout() // In case any color changes affect layout
        view.setNeedsDisplay() // Forces redraw of the view and its subviews if they have custom draw() methods
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor.appBackground
        // Add subviews
        view.addSubview(pandaView)
        view.addSubview(pandaView)
        view.addSubview(chatTableView)
        view.addSubview(muteButton)
        view.addSubview(settingsButton)
        view.addSubview(meditationButton)
        view.addSubview(timerView)
        timerView.addSubview(timerLabel)
        timerView.layer.addSublayer(timerCircle)
    
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
            pandaView.bottomAnchor.constraint(equalTo: chatTableView.topAnchor, constant: -60)
        ])
        
        // Set up constraints
        NSLayoutConstraint.activate([
            // Settings button
            settingsButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            settingsButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            settingsButton.widthAnchor.constraint(equalToConstant: 40),
            settingsButton.heightAnchor.constraint(equalToConstant: 40),

            // Chat table
            chatTableView.heightAnchor.constraint(equalToConstant: 240),
            chatTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            chatTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            chatTableView.bottomAnchor.constraint(equalTo: meditationButton.topAnchor, constant: -30),
            
            // Meditation button
            meditationButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            meditationButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            meditationButton.bottomAnchor.constraint(equalTo: muteButton.topAnchor, constant: 0),
            meditationButton.heightAnchor.constraint(equalToConstant: 50),
            
            // Timer view
            timerView.heightAnchor.constraint(equalToConstant: 200),
            timerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            timerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            timerView.bottomAnchor.constraint(equalTo: meditationButton.topAnchor, constant: -20),
            
            // Timer label
            timerLabel.centerXAnchor.constraint(equalTo: timerView.centerXAnchor),
            timerLabel.centerYAnchor.constraint(equalTo: timerView.centerYAnchor),
            
            // Mute button
            muteButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            muteButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            muteButton.widthAnchor.constraint(equalToConstant: 50),
            muteButton.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        // Add button actions
        settingsButton.addTarget(self, action: #selector(settingsButtonTapped), for: .touchUpInside)
        muteButton.addTarget(self, action: #selector(muteButtonTapped), for: .touchUpInside)
        meditationButton.addTarget(self, action: #selector(meditationButtonTapped), for: .touchUpInside)

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
        muteButton.backgroundColor = isMuted ? .red : UIColor.primaryButtonBackground
        print("[LOG] Mute button tapped. isMuted: \(isMuted)")
    }

    @objc private func settingsButtonTapped() {
        let settingsVC = SettingsViewController()
        settingsVC.modalPresentationStyle = .formSheet
        settingsVC.delegate = self
        present(settingsVC, animated: true)
        print("[LOG] Settings button tapped. SettingsViewController presented.")
    }

    @objc private func meditationButtonTapped() {
        print("[LOG] Meditation button tapped")
        
        // Stop any ongoing audio and speech recognition
        conversationManager.stopAllAudioAndRecording()
        
        // Change phase to meditating
        conversationManager.currentPhase = .meditating
        
        // Animate out the meditation button and chat table view
        UIView.animate(withDuration: 0.3, animations: {
            self.meditationButton.alpha = 0
            self.chatTableView.alpha = 0
        }) { _ in
            self.meditationButton.isHidden = true
            self.chatTableView.isHidden = true
            
            // Show and animate in the timer view
            self.timerView.isHidden = false
            self.timerView.alpha = 0
            UIView.animate(withDuration: 0.3) {
                self.timerView.alpha = 1
            }
            
            // Set up timer update callback
            self.conversationManager.onTimerUpdate = { [weak self] minutes, seconds in
                self?.updateTimerLabel(minutes: minutes, seconds: seconds)
                self?.updateTimerCircle()
            }
            
            // Start the timer
            self.conversationManager.startMeditationTimer()
        }
        
        conversationManager.sendToBackend()
    }
    
    private func updateTimerLabel(minutes: Int, seconds: Int) {
        timerLabel.text = String(format: "%d:%02d", minutes, seconds)
    }
    
    private func setupTimerCircle() {
        let center = CGPoint(x: timerView.bounds.midX, y: timerView.bounds.midY)
        let radius = min(timerView.bounds.width, timerView.bounds.height) * 0.4
        let circlePath = UIBezierPath(arcCenter: center,
                                    radius: radius,
                                    startAngle: -CGFloat.pi / 2,
                                    endAngle: 2 * CGFloat.pi - CGFloat.pi / 2,
                                    clockwise: true)
        timerCircle.path = circlePath.cgPath
        timerCircle.strokeEnd = 1.0
    }
    
    private func updateTimerCircle() {
        let progress = CGFloat(conversationManager.remainingSeconds) / 300.0
        timerCircle.strokeEnd = progress
    }
    
    private func endMeditation() {
        // Animate out the timer view
        UIView.animate(withDuration: 0.3, animations: {
            self.timerView.alpha = 0
        }) { _ in
            self.timerView.isHidden = true
            
            // Show and animate in the chat table view
            self.chatTableView.isHidden = false
            self.chatTableView.alpha = 0
            UIView.animate(withDuration: 0.3) {
                self.chatTableView.alpha = 1
            }
            
            // Show and animate in the meditation button
            self.meditationButton.isHidden = false
            self.meditationButton.alpha = 0
            UIView.animate(withDuration: 0.3) {
                self.meditationButton.alpha = 1
            }
        }
        
        // Change phase back to initial discussion
        conversationManager.currentPhase = .initialDiscussion
        conversationManager.sendToBackend()
    }
    
    func addMessage(_ message: String, isSentByUser: Bool) {
        messages.append((content: message, isSentByUser: isSentByUser))
        let indexPath = IndexPath(row: messages.count - 1, section: 0)
        chatTableView.insertRows(at: [indexPath], with: .automatic)
        chatTableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
        print("[LOG] Message added to table. Content: \(message), isSentByUser: \(isSentByUser)")
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
        print("[LOG] New message from ConversationManager: \(message.content), sentByUser: \(isSentByUser)")
        DispatchQueue.main.async {
            self.addMessage(message.content, isSentByUser: isSentByUser)
        }
    }

    func conversationManagerStatus(status: ConversationStatus) {
        print("[LOG] Conversation status changed: \(status)")
        // Ensure all labels are reset before setting the new one
        pandaView.updateListeningState(isListening: false)
        pandaView.updateThinkingLabelState(isThinking: false)
        pandaView.updateSpeakingLabelState(isSpeaking: false)       // Reset speaking label
        pandaView.updateInitializingLabelState(isInitializing: false) // Reset initializing label

        switch status {
        case .isListening:
            pandaView.updateListeningState(isListening: true)
            pandaView.updatePandaView(for: .meditating)
        case .isTalking:
            pandaView.updateSpeakingLabelState(isSpeaking: true) // Use speaking label
            pandaView.updatePandaView(for: .talking)
        case .isThinking:
            pandaView.updateThinkingLabelState(isThinking: true)
            pandaView.updatePandaView(for: .meditating)
        case .isInitializing: // Handle new initializing state
            pandaView.updateInitializingLabelState(isInitializing: true)
            pandaView.updatePandaView(for: .happy) // Or .meditating, depending on desired initial animation
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
        print("[LOG] User tapped sign out")
        conversationManager.stopConversationAndMeditation()
        conversationManager.isSignedOut = true

        dismiss(animated: true) {
            print("[LOG] ChatViewController dismissed. Auth sign out should occur now if not already handled by a coordinator.")
        }
    }
}
