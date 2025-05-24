import UIKit
import FirebaseAuth

// Assuming SettingsViewController uses a delegate like this, which ChatViewController also conforms to.
// If ChatViewControllerDelegate is defined elsewhere and accessible, this re-definition isn't strictly needed
// but it clarifies the interface HomeViewController must adhere to for SettingsViewController.
protocol HomeViewControllerDelegate: AnyObject {
    func didTapSignOut()
}

class HomeViewController: UIViewController {

    var authManager: FirebaseAuthManager? // Injected by SceneDelegate

    private let settingsButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "gearshape.fill"), for: .normal)
        button.tintColor = UIColor.statusLabelAndIcon
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(settingsButtonTapped), for: .touchUpInside)
        return button
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "ZenPal"
        label.font = .zenAppTitle
        label.textColor = UIColor.statusLabelAndIcon
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private func createActionButton(title: String, systemImageName: String? = nil, customContentView: UIView? = nil) -> UIButton {
        let button = UIButton(type: .custom)
        button.backgroundColor = UIColor.pandaCircleBackground
        button.layer.cornerRadius = 8 // Smaller radius for more square appearance
        button.translatesAutoresizingMaskIntoConstraints = false
        button.clipsToBounds = true

        let mainStackView = UIStackView()
        mainStackView.axis = .vertical
        mainStackView.alignment = .center
        mainStackView.spacing = 8 // Reduced spacing
        mainStackView.translatesAutoresizingMaskIntoConstraints = false
        mainStackView.isUserInteractionEnabled = false

        if let contentView = customContentView {
            contentView.translatesAutoresizingMaskIntoConstraints = false
            mainStackView.addArrangedSubview(contentView)
            // Larger size for panda views to be more prominent
            NSLayoutConstraint.activate([
                contentView.widthAnchor.constraint(equalToConstant: 85),
                contentView.heightAnchor.constraint(equalToConstant: 85)
            ])
        } else if let imageName = systemImageName, let image = UIImage(systemName: imageName) {
            let imageView = UIImageView(image: image)
            imageView.contentMode = .scaleAspectFit
            imageView.tintColor = UIColor.primaryButtonBackground
            imageView.translatesAutoresizingMaskIntoConstraints = false
            mainStackView.addArrangedSubview(imageView)
            NSLayoutConstraint.activate([
                imageView.widthAnchor.constraint(equalToConstant: 44),
                imageView.heightAnchor.constraint(equalToConstant: 44)
            ])
        }

        // Split title if it contains "Coming Soon"
        if title.contains("(Coming Soon)") {
            let parts = title.components(separatedBy: " (Coming Soon)")
            let mainTitle = parts.first ?? title
            
            // Main title
            let titleLabel = UILabel()
            titleLabel.text = mainTitle
            titleLabel.font = .zenHeading3
            titleLabel.textColor = UIColor.chatBubbleText
            titleLabel.textAlignment = .center
            titleLabel.numberOfLines = 0
            mainStackView.addArrangedSubview(titleLabel)
            
            // Coming Soon label - smaller and at bottom
            let comingSoonLabel = UILabel()
            comingSoonLabel.text = "Coming Soon"
            comingSoonLabel.font = .zenFootnote
            comingSoonLabel.textColor = UIColor.statusLabelAndIcon
            comingSoonLabel.textAlignment = .center
            comingSoonLabel.numberOfLines = 0
            mainStackView.addArrangedSubview(comingSoonLabel)
        } else {
            // Regular title for buttons without "Coming Soon"
            let titleLabel = UILabel()
            titleLabel.text = title
            titleLabel.font = .zenHeading3
            titleLabel.textColor = UIColor.chatBubbleText
            titleLabel.textAlignment = .center
            titleLabel.numberOfLines = 0
            mainStackView.addArrangedSubview(titleLabel)
        }
        
        button.addSubview(mainStackView)
        NSLayoutConstraint.activate([
            mainStackView.centerXAnchor.constraint(equalTo: button.centerXAnchor),
            mainStackView.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            mainStackView.leadingAnchor.constraint(equalTo: button.leadingAnchor, constant: 16),
            mainStackView.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -16)
        ])
        
        return button
    }

    private lazy var meditationButton: UIButton = {
        let pandaContainer = UIView() // Container for the panda view
        let pandaView = RedPandaView(frame: .zero, type: .meditating)
        pandaView.translatesAutoresizingMaskIntoConstraints = false
        pandaContainer.addSubview(pandaView)
        NSLayoutConstraint.activate([
            pandaView.centerXAnchor.constraint(equalTo: pandaContainer.centerXAnchor),
            pandaView.centerYAnchor.constraint(equalTo: pandaContainer.centerYAnchor),
            pandaView.widthAnchor.constraint(equalTo: pandaContainer.widthAnchor),
            pandaView.heightAnchor.constraint(equalTo: pandaContainer.heightAnchor)
        ])

        let button = createActionButton(title: "Guided Meditation", customContentView: pandaContainer)
        button.addTarget(self, action: #selector(meditationButtonTapped), for: .touchUpInside)
        return button
    }()

    private lazy var journalButton: UIButton = {
        let pandaContainer = UIView() // Container for the panda view
        let pandaView = RedPandaView(frame: .zero, type: .talking)
        pandaView.translatesAutoresizingMaskIntoConstraints = false
        pandaContainer.addSubview(pandaView)
        NSLayoutConstraint.activate([
            pandaView.centerXAnchor.constraint(equalTo: pandaContainer.centerXAnchor),
            pandaView.centerYAnchor.constraint(equalTo: pandaContainer.centerYAnchor),
            pandaView.widthAnchor.constraint(equalTo: pandaContainer.widthAnchor),
            pandaView.heightAnchor.constraint(equalTo: pandaContainer.heightAnchor)
        ])

        let button = createActionButton(title: "Voice Journal (Coming Soon)", customContentView: pandaContainer)
        button.addTarget(self, action: #selector(journalButtonTapped), for: .touchUpInside)
        return button
    }()

    private lazy var sleepButton: UIButton = {
        let pandaContainer = UIView() // Container for the panda view
        let pandaView = RedPandaView(frame: .zero, type: .sleeping)
        pandaView.translatesAutoresizingMaskIntoConstraints = false
        pandaContainer.addSubview(pandaView)
        NSLayoutConstraint.activate([
            pandaView.centerXAnchor.constraint(equalTo: pandaContainer.centerXAnchor),
            pandaView.centerYAnchor.constraint(equalTo: pandaContainer.centerYAnchor),
            pandaView.widthAnchor.constraint(equalTo: pandaContainer.widthAnchor),
            pandaView.heightAnchor.constraint(equalTo: pandaContainer.heightAnchor)
        ])

        let button = createActionButton(title: "Sleep Meditation(Coming Soon)", customContentView: pandaContainer)
        button.addTarget(self, action: #selector(sleepButtonTapped), for: .touchUpInside)
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.appBackground
        setupUI()
        
        if authManager == nil {
            authManager = FirebaseAuthManager()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if Auth.auth().currentUser == nil {
            presentLoginViewController(animated: false) // Present immediately if no user
        }
    }

    private func setupUI() {
        view.addSubview(settingsButton)
        view.addSubview(titleLabel)
        
        let buttonsStackView = UIStackView(arrangedSubviews: [meditationButton, sleepButton, journalButton])
        buttonsStackView.axis = .vertical
        buttonsStackView.spacing = 20
        buttonsStackView.distribution = .fillEqually
        buttonsStackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(buttonsStackView)

        NSLayoutConstraint.activate([
            settingsButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            settingsButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            settingsButton.widthAnchor.constraint(equalToConstant: 40),
            settingsButton.heightAnchor.constraint(equalToConstant: 40),

            titleLabel.topAnchor.constraint(equalTo: settingsButton.bottomAnchor, constant: 20),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20),
            
            buttonsStackView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 30),
            buttonsStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            buttonsStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            buttonsStackView.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),

            meditationButton.heightAnchor.constraint(equalToConstant: 160), // Taller for better proportions
            // journalButton and sleepButton will also be this height due to fillEqually
        ])
    }

    @objc private func settingsButtonTapped() {
        let settingsVC = SettingsViewController() // Ensure SettingsViewController is available
        settingsVC.modalPresentationStyle = .formSheet
        settingsVC.delegate = self // HomeViewController conforms to ChatViewControllerDelegate
        present(settingsVC, animated: true)
    }

    @objc private func meditationButtonTapped() {
        let chatVC = ChatViewController()
        chatVC.authManager = self.authManager
        chatVC.modalPresentationStyle = .fullScreen
        present(chatVC, animated: true, completion: nil)
    }

    @objc private func journalButtonTapped() {
        print("Voice Journal button tapped - Showing Coming Soon")
        showComingSoonPopup(message: "Voice Journaling Coming Soon!")
        // Example: Present a VoiceJournalViewController
        // let journalVC = VoiceJournalViewController()
    }

    @objc private func sleepButtonTapped() {
        print("Sleep meditation button tapped - Showing Coming Soon")
        showComingSoonPopup(message: "Sleep Meditations Coming Soon!")
        // Example: Present a SleepMeditationViewController
        // let sleepVC = SleepMeditationViewController()
    }
    
    private func showComingSoonPopup(message: String) {
        let popupLabel = UILabel()
        popupLabel.text = message
        popupLabel.textColor = UIColor.white
        popupLabel.backgroundColor = UIColor.black.withAlphaComponent(0.75)
        popupLabel.textAlignment = .center
        popupLabel.numberOfLines = 0 // Allow multiple lines if needed
        popupLabel.layer.cornerRadius = 12
        popupLabel.layer.masksToBounds = true // Essential for cornerRadius with background
        popupLabel.font = .zenBodyMedium
        popupLabel.translatesAutoresizingMaskIntoConstraints = false
        popupLabel.alpha = 0 // Start transparent

        // Determine the size needed for the text
        popupLabel.preferredMaxLayoutWidth = view.bounds.width * 0.7 // Max width for the label
        let textSize = popupLabel.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)

        // Define padding
        let horizontalPadding: CGFloat = 25
        let verticalPadding: CGFloat = 15

        // Add to the key window's view or HomeViewController's view
        // Using HomeViewController's view is generally safer and simpler.
        view.addSubview(popupLabel)

        NSLayoutConstraint.activate([
            popupLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            popupLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            popupLabel.widthAnchor.constraint(equalToConstant: textSize.width + 2 * horizontalPadding),
            popupLabel.heightAnchor.constraint(equalToConstant: textSize.height + 2 * verticalPadding)
        ])

        // Enhanced Animation
        popupLabel.transform = CGAffineTransform(scaleX: 0.8, y: 0.8) // Start slightly smaller
        UIView.animate(withDuration: 0.35, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.2, options: .curveEaseOut, animations: {
            popupLabel.alpha = 1
            popupLabel.transform = .identity // Animate to normal size
        }) { _ in
            UIView.animate(withDuration: 0.35, delay: 1.8, options: .curveEaseIn, animations: {
                popupLabel.alpha = 0
                popupLabel.transform = CGAffineTransform(scaleX: 0.8, y: 0.8) // Shrink out
            }) { _ in
                popupLabel.removeFromSuperview()
            }
        }
    }
    
    private func presentLoginViewController(animated: Bool = true) {
        // Ensure no other presentations are in progress if called multiple times
        if self.presentedViewController == nil || self.presentedViewController is LoginViewController {
            let loginVC = LoginViewController()
            loginVC.modalPresentationStyle = .fullScreen
            present(loginVC, animated: animated, completion: nil)
        }
    }
} 
extension HomeViewController: HomeViewControllerDelegate {
    func didTapSignOut() {
        authManager?.signOut()
        // After sign out, present the LoginViewController.
        // This will cover the case where HomeVC is root.
        presentLoginViewController()
    }
}