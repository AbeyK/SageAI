//
//  ChatViewController.swift
//  Sage
//
//  Created by hassan Khan on 4/30/25.
//

import UIKit
import AVKit
import FirebaseAuth
import FirebaseFirestore

class ChatViewController: UIViewController, ConversationManagerDelegate {
    var authManager: FirebaseAuthManager?
    var conversationManager: ConversationManager!

    private let pandaView: RedPandaView = {
        let view = RedPandaView(frame: .zero, type: .happy)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let interruptButton: UIButton = {
        let button = UIButton(type: .custom) // Use .custom for more control
        button.translatesAutoresizingMaskIntoConstraints = false
        button.alpha = 0 // Start fully transparent
        button.backgroundColor = .black

        // Label setup
        let label = UILabel()
        label.text = "Tap to interrupt"
        label.textColor = .white
        label.font = .zenBody
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        button.addSubview(label)

        // Center label, slightly offset downwards
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: button.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: button.centerYAnchor, constant: 20), // Adjust constant for "slightly below"
            label.leadingAnchor.constraint(greaterThanOrEqualTo: button.leadingAnchor, constant: 8),
            label.trailingAnchor.constraint(lessThanOrEqualTo: button.trailingAnchor, constant: -8)
        ])

        // Shadow properties (will be applied conditionally)
        button.layer.shadowOpacity = 0.5
        button.layer.shadowRadius = 5
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shouldRasterize = true // For performance
        button.layer.rasterizationScale = UIScreen.main.scale
        button.layer.masksToBounds = false // Important for shadow to be visible

        button.addTarget(self, action: #selector(interruptButtonTapped), for: .touchUpInside)

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
        button.titleLabel?.font = .zenButton
        button.layer.cornerRadius = 12
        button.translatesAutoresizingMaskIntoConstraints = false
        button.alpha = 0 // Initially hide the meditation button
        return button
    }()
    
    private let progressBarOutlineView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.layer.borderColor = UIColor.primaryButtonBackground.cgColor
        view.layer.borderWidth = 2
        view.layer.cornerRadius = 12
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let progressBarFillView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.primaryButtonBackground
        view.layer.cornerRadius = 10
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let progressBarLabel: UILabel = {
        let label = UILabel()
        label.text = "Creating Your Meditation..."
        label.textColor = UIColor.progressBarText // Progress bar text color with light/dark mode support
        label.font = .systemFont(ofSize: 16, weight: .bold) // Explicitly bold font
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
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
        label.font = .zenTimer
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
    
    private let backButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        button.tintColor = UIColor.statusLabelAndIcon // Or another suitable color
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private var messages: [(content: String, isSentByUser: Bool)] = []
    private var isMuted: Bool = false
    private var userMessageCount: Int = 0 // To track user messages for progress bar
    private var feedbackView: MeditationFeedbackView?
    
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
        interruptButton.layer.cornerRadius = interruptButton.bounds.width / 2 // Make it circular
        
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
        backButton.tintColor = UIColor.statusLabelAndIcon // Ensure back button color updates

        // Update standard components (many of these should update automatically if set with dynamic UIColors from the palette initially,
        // but explicitly re-setting them can ensure consistency, especially for more complex views or state-dependent colors).
        chatTableView.backgroundColor = UIColor.chatTableViewBackground
        
        // Mute button color depends on state, ensure it's re-evaluated
        muteButton.tintColor = UIColor.primaryButtonText
        muteButton.backgroundColor = isMuted ? .red : UIColor.primaryButtonBackground
        
        meditationButton.setTitleColor(UIColor.primaryButtonText, for: .normal)
        meditationButton.backgroundColor = UIColor.primaryButtonBackground
        
        // Update progress bar colors
        progressBarOutlineView.layer.borderColor = UIColor.primaryButtonBackground.cgColor
        progressBarFillView.backgroundColor = UIColor.primaryButtonBackground
        progressBarLabel.textColor = UIColor.progressBarText
        
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
        view.addSubview(backButton)
        view.addSubview(pandaView)
        view.addSubview(pandaView)
        view.addSubview(chatTableView)
        view.addSubview(muteButton)
        view.addSubview(meditationButton)
        view.addSubview(progressBarOutlineView)
        progressBarOutlineView.addSubview(progressBarFillView)
        progressBarOutlineView.addSubview(progressBarLabel)
        
        // Ensure the label is always on top of the fill view
        progressBarOutlineView.bringSubviewToFront(progressBarLabel)
        
        view.addSubview(timerView)
        timerView.addSubview(timerLabel)
        timerView.layer.addSublayer(timerCircle)
        view.addSubview(interruptButton)
    
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
            pandaView.bottomAnchor.constraint(equalTo: chatTableView.topAnchor, constant: -60),

            // Interrupt Button constraints (to match pandaView)
            interruptButton.centerXAnchor.constraint(equalTo: pandaView.centerXAnchor),
            interruptButton.centerYAnchor.constraint(equalTo: pandaView.centerYAnchor),
            interruptButton.widthAnchor.constraint(equalTo: pandaView.widthAnchor),
            interruptButton.heightAnchor.constraint(equalTo: pandaView.heightAnchor)
        ])
        
        // Set up constraints
        NSLayoutConstraint.activate([
            // Back button
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            backButton.widthAnchor.constraint(equalToConstant: 40),
            backButton.heightAnchor.constraint(equalToConstant: 40),

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

            // Progress Bar Outline View constraints (mirrors meditationButton)
            progressBarOutlineView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            progressBarOutlineView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            progressBarOutlineView.bottomAnchor.constraint(equalTo: muteButton.topAnchor, constant: 0),
            progressBarOutlineView.heightAnchor.constraint(equalToConstant: 50),

            // Progress Bar Fill View constraints
            progressBarFillView.leadingAnchor.constraint(equalTo: progressBarOutlineView.leadingAnchor, constant: 2),
            progressBarFillView.topAnchor.constraint(equalTo: progressBarOutlineView.topAnchor, constant: 2),
            progressBarFillView.bottomAnchor.constraint(equalTo: progressBarOutlineView.bottomAnchor, constant: -2),
            // Width constraint will be added dynamically

            // Progress Bar Label constraints
            progressBarLabel.centerXAnchor.constraint(equalTo: progressBarOutlineView.centerXAnchor),
            progressBarLabel.centerYAnchor.constraint(equalTo: progressBarOutlineView.centerYAnchor),
            progressBarLabel.leadingAnchor.constraint(greaterThanOrEqualTo: progressBarOutlineView.leadingAnchor, constant: 8),
            progressBarLabel.trailingAnchor.constraint(lessThanOrEqualTo: progressBarOutlineView.trailingAnchor, constant: -8),
            
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
        muteButton.addTarget(self, action: #selector(muteButtonTapped), for: .touchUpInside)
        meditationButton.addTarget(self, action: #selector(meditationButtonTapped), for: .touchUpInside)
    }
    
    private func setupTableView() {
        chatTableView.delegate = self
        chatTableView.dataSource = self
        chatTableView.register(ChatMessageCell.self, forCellReuseIdentifier: "ChatMessageCell")
    }
    
    @objc private func backButtonTapped() {
        print("[LOG] Back button tapped.")
        conversationManager.stopConversationAndMeditation() // Stop all activities
        conversationManager.stopAllAudioAndRecording()
        dismiss(animated: true, completion: nil)
    }

    @objc private func muteButtonTapped() {
        isMuted.toggle()
        muteButton.backgroundColor = isMuted ? .red : UIColor.primaryButtonBackground
        print("[LOG] Mute button tapped. isMuted: \(isMuted)")
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

        userMessageCount += 1

        // if userMessageCount <= 1 { We want to show that its a progress bar 
        //     return // we want this because its more clear to the user that this is a progress bar
        // }
        
        updateProgressBar()
        
        if !isSentByUser {
            // Check if the received message contains any of these phrases
            if message.localizedCaseInsensitiveContains("Start My Meditation") 
            || message.localizedCaseInsensitiveContains("personalized meditation")
            || message.localizedCaseInsensitiveContains("would you like to try that") {
                userMessageCount = 6 // Set to max messages to fill the bar
                updateProgressBar()
            }
        }
    }

    private func updateProgressBar() {
        let maxMessages = 6
        let progress = min(CGFloat(userMessageCount) / CGFloat(maxMessages), 1.0)
        let fullWidth = progressBarOutlineView.bounds.width - 4 // account for border/padding

        // Remove existing width constraint if any
        progressBarFillView.constraints.filter { $0.firstAttribute == .width }.forEach { $0.isActive = false }

        let widthConstraint = progressBarFillView.widthAnchor.constraint(equalToConstant: fullWidth * progress)
        widthConstraint.isActive = true

        UIView.animate(withDuration: 3) {
            self.view.layoutIfNeeded() // Animate constraint change
        } completion: { _ in
            // Ensure the label stays on top after layout updates
            self.progressBarOutlineView.bringSubviewToFront(self.progressBarLabel)
        }

        if userMessageCount >= maxMessages {
            // Fade out progress bar, fade in meditation button
            UIView.animate(withDuration: 1, delay: 0.3, options: [], animations: {
                self.progressBarOutlineView.alpha = 0
                self.progressBarLabel.alpha = 0 // Fade out the label as well
                self.meditationButton.alpha = 1
            }) { _ in
                self.progressBarOutlineView.isHidden = true
                self.progressBarLabel.isHidden = true // Hide the label as well
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

    func conversationManagerDidEndMeditation() {
        DispatchQueue.main.async {
            self.showMeditationFeedbackPopup()
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
            interruptButton.isUserInteractionEnabled = false
        case .isTalking:
            pandaView.updateSpeakingLabelState(isSpeaking: true) // Use speaking label
            pandaView.updatePandaView(for: .talking)
            interruptButton.isUserInteractionEnabled = true
            // Animate interrupt button
            DispatchQueue.main.async { // Ensure UI updates are on the main thread
                // self.animateInterruptButton() removing for now this needs to be fixed. Tap not working 
            }
        case .isThinking:
            pandaView.updateThinkingLabelState(isThinking: true)
            pandaView.updatePandaView(for: .meditating)
            interruptButton.isUserInteractionEnabled = false
        case .isInitializing: // Handle new initializing state
            pandaView.updateInitializingLabelState(isInitializing: true)
            pandaView.updatePandaView(for: .happy) // Or .meditating, depending on desired initial animation
            interruptButton.isUserInteractionEnabled = false
        }
    }

    private func animateInterruptButton() {
        // Ensure shadow is visible during animation
        interruptButton.layer.shadowOpacity = 0.4 

        UIView.animate(withDuration: 0.6, animations: {
            self.interruptButton.alpha = 0.8
        }) { _ in
            UIView.animate(withDuration: 0.6, delay: 1.0, options: [], animations: {
                self.interruptButton.alpha = 0
            }) { _ in
                // Hide shadow after animation
                self.interruptButton.layer.shadowOpacity = 0 
            }
        }
    }

    @objc private func interruptButtonTapped() {
        print("[LOG] Interrupt button tapped.")
        conversationManager.userInterrupted() // Call the new method
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIApplication.shared.isIdleTimerDisabled = true
        print("[LOG] ChatViewController appeared. Idle timer disabled.")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        UIApplication.shared.isIdleTimerDisabled = false
        print("[LOG] ChatViewController will disappear. Idle timer enabled.")
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

// MARK: - MeditationFeedbackViewDelegate
extension ChatViewController: MeditationFeedbackViewDelegate {
    func meditationFeedbackViewDidSubmit(rating: Int, feedback: String?) {
        print("[LOG] Meditation Feedback: Rating - \(rating) stars, Feedback - \(feedback ?? "None")")
        
        // Firebase logic
        guard let userID = Auth.auth().currentUser?.uid else {
            print("[ERROR] User not logged in, cannot save feedback.")
            // Dismiss view even if feedback isn't saved, or handle error as appropriate
            feedbackView?.removeFromSuperview()
            feedbackView = nil
            dismiss(animated: true, completion: nil)
            return
        }
        
        let userName = Auth.auth().currentUser?.displayName ?? "Anonymous"
        let conversationHistory = conversationManager.getConversationHistory()
        
        let db = Firestore.firestore()
        db.collection("meditation_feedback").addDocument(data: [
            "userID": userID,
            "userName": userName,
            "rating": rating,
            "feedbackText": feedback ?? "",
            "timestamp": FieldValue.serverTimestamp(),
            "conversationHistory": conversationHistory
        ]) { err in
            if let err = err {
                print("[ERROR] Error adding document: \(err)")
            } else {
                print("[LOG] Meditation feedback successfully saved to Firestore.")
            }
        }
        
        feedbackView?.removeFromSuperview()
        feedbackView = nil
        
        // Dismiss ChatViewController after feedback submission
        dismiss(animated: true, completion: nil)
    }
    
    private func showMeditationFeedbackPopup() {
        if feedbackView == nil {
            feedbackView = MeditationFeedbackView(frame: view.bounds)
            feedbackView!.delegate = self
            feedbackView!.translatesAutoresizingMaskIntoConstraints = false // Important for manual layout
            view.addSubview(feedbackView!)
            
            NSLayoutConstraint.activate([
                feedbackView!.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                feedbackView!.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                feedbackView!.topAnchor.constraint(equalTo: view.topAnchor),
                feedbackView!.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
            
            feedbackView!.alpha = 0
            UIView.animate(withDuration: 0.3) {
                self.feedbackView!.alpha = 1
            }
        } else {
            // Ensure it's visible if somehow already created but hidden
            feedbackView?.alpha = 1
            view.bringSubviewToFront(feedbackView!)
        }
    }
}

