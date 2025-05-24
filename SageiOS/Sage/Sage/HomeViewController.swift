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
        label.textColor = UIColor.appTitleBlue
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private func createHeroCard(title: String, subtitle: String, backgroundColor: UIColor, textColor: UIColor, customContentView: UIView? = nil) -> UIButton {
        let button = UIButton(type: .custom)
        button.backgroundColor = backgroundColor
        button.layer.cornerRadius = 12 // Match coming soon cards corner radius
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowOpacity = 0.1
        button.layer.shadowRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        button.clipsToBounds = false

        let mainStackView = UIStackView()
        mainStackView.axis = .horizontal
        mainStackView.alignment = .center
        mainStackView.spacing = 16
        mainStackView.translatesAutoresizingMaskIntoConstraints = false
        mainStackView.isUserInteractionEnabled = false

        // Left side - text content
        let textStackView = UIStackView()
        textStackView.axis = .vertical
        textStackView.alignment = .leading
        textStackView.spacing = 6 // Increased spacing between title and subtitle
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .zenAccent // Comfortaa font
        titleLabel.textColor = UIColor.sectionTitleText
        titleLabel.numberOfLines = 0
        
        let subtitleLabel = UILabel()
        subtitleLabel.text = subtitle
        subtitleLabel.font = .zenCaption // Keep consistent with coming soon cards
        subtitleLabel.textColor = UIColor.sectionSubtitleText
        subtitleLabel.numberOfLines = 0
        
        textStackView.addArrangedSubview(titleLabel)
        textStackView.addArrangedSubview(subtitleLabel)
        mainStackView.addArrangedSubview(textStackView)

        // Right side - panda
        if let contentView = customContentView {
            contentView.translatesAutoresizingMaskIntoConstraints = false
            mainStackView.addArrangedSubview(contentView)
            NSLayoutConstraint.activate([
                contentView.widthAnchor.constraint(equalToConstant: 60),
                contentView.heightAnchor.constraint(equalToConstant: 60)
            ])
        }

        button.addSubview(mainStackView)
        NSLayoutConstraint.activate([
            mainStackView.leadingAnchor.constraint(equalTo: button.leadingAnchor, constant: 16),
            mainStackView.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -16),
            mainStackView.topAnchor.constraint(equalTo: button.topAnchor, constant: 16),
            mainStackView.bottomAnchor.constraint(equalTo: button.bottomAnchor, constant: -16)
        ])
        
        return button
    }
    
    private func createComingSoonCard(title: String, customContentView: UIView? = nil) -> UIButton {
        let button = UIButton(type: .custom)
        button.backgroundColor = UIColor.homeScreenCardViewBackground.withAlphaComponent(0.2) // Neutral background for coming soon
        button.layer.cornerRadius = 12
        button.translatesAutoresizingMaskIntoConstraints = false
        button.clipsToBounds = true

        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = 16 // Match hero card spacing for consistency
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.isUserInteractionEnabled = false

        // Left side - text
        let textStackView = UIStackView()
        textStackView.axis = .vertical
        textStackView.alignment = .leading
        textStackView.spacing = 6 // Increased spacing to match hero card
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .zenAccent // Comfortaa font - same as hero card
        titleLabel.textColor = UIColor.sectionTitleText // White in dark mode, blue in light mode
        titleLabel.numberOfLines = 0
        
        let comingSoonLabel = UILabel()
        comingSoonLabel.text = "Coming Soon"
        comingSoonLabel.font = .zenCaption
        comingSoonLabel.textColor = UIColor.sectionSubtitleText
        comingSoonLabel.numberOfLines = 0
        
        textStackView.addArrangedSubview(titleLabel)
        textStackView.addArrangedSubview(comingSoonLabel)
        stackView.addArrangedSubview(textStackView)

        // Right side - panda
        if let contentView = customContentView {
            contentView.translatesAutoresizingMaskIntoConstraints = false
            contentView.alpha = 0.8 // Slightly transparent but visible
            stackView.addArrangedSubview(contentView)
            NSLayoutConstraint.activate([
                contentView.widthAnchor.constraint(equalToConstant: 60),
                contentView.heightAnchor.constraint(equalToConstant: 60)
            ])
        }
        
        button.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: button.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -16),
            stackView.topAnchor.constraint(equalTo: button.topAnchor, constant: 16),
            stackView.bottomAnchor.constraint(equalTo: button.bottomAnchor, constant: -16)
        ])
        
        return button
    }

    private lazy var meditationHeroCard: UIButton = {
        let pandaContainer = UIView()
        let pandaView = RedPandaView(frame: .zero, type: .meditating)
        pandaView.translatesAutoresizingMaskIntoConstraints = false
        pandaContainer.addSubview(pandaView)
        NSLayoutConstraint.activate([
            pandaView.centerXAnchor.constraint(equalTo: pandaContainer.centerXAnchor),
            pandaView.centerYAnchor.constraint(equalTo: pandaContainer.centerYAnchor),
            pandaView.widthAnchor.constraint(equalTo: pandaContainer.widthAnchor),
            pandaView.heightAnchor.constraint(equalTo: pandaContainer.heightAnchor)
        ])

        let button = createHeroCard(
            title: "Meditations", 
            subtitle: "Crafted just for you", 
            backgroundColor: UIColor.homeScreenCardViewBackground.withAlphaComponent(0.2),
            textColor: UIColor.sectionTitleText,
            customContentView: pandaContainer
        )
        button.addTarget(self, action: #selector(meditationButtonTapped), for: .touchUpInside)
        return button
    }()

    private lazy var sleepCard: UIButton = {
        let pandaContainer = UIView()
        let pandaView = RedPandaView(frame: .zero, type: .sleeping)
        pandaView.translatesAutoresizingMaskIntoConstraints = false
        pandaContainer.addSubview(pandaView)
        NSLayoutConstraint.activate([
            pandaView.centerXAnchor.constraint(equalTo: pandaContainer.centerXAnchor),
            pandaView.centerYAnchor.constraint(equalTo: pandaContainer.centerYAnchor),
            pandaView.widthAnchor.constraint(equalTo: pandaContainer.widthAnchor),
            pandaView.heightAnchor.constraint(equalTo: pandaContainer.heightAnchor)
        ])

        let button = createComingSoonCard(title: "Sleep Meditation", customContentView: pandaContainer)
        button.addTarget(self, action: #selector(sleepButtonTapped), for: .touchUpInside)
        return button
    }()

    private lazy var journalCard: UIButton = {
        let pandaContainer = UIView()
        let pandaView = RedPandaView(frame: .zero, type: .talking)
        pandaView.translatesAutoresizingMaskIntoConstraints = false
        pandaContainer.addSubview(pandaView)
        NSLayoutConstraint.activate([
            pandaView.centerXAnchor.constraint(equalTo: pandaContainer.centerXAnchor),
            pandaView.centerYAnchor.constraint(equalTo: pandaContainer.centerYAnchor),
            pandaView.widthAnchor.constraint(equalTo: pandaContainer.widthAnchor),
            pandaView.heightAnchor.constraint(equalTo: pandaContainer.heightAnchor)
        ])

        let button = createComingSoonCard(title: "Voice Journal", customContentView: pandaContainer)
        button.addTarget(self, action: #selector(journalButtonTapped), for: .touchUpInside)
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.appBackground // Back to original beige background
        setupUI()
        
        if authManager == nil {
            authManager = FirebaseAuthManager()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if Auth.auth().currentUser == nil {
            presentLoginViewController(animated: false)
        }
    }

    private func setupUI() {
        view.addSubview(settingsButton)
        view.addSubview(titleLabel)
        view.addSubview(meditationHeroCard)
        view.addSubview(sleepCard)
        view.addSubview(journalCard)

        NSLayoutConstraint.activate([
            settingsButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            settingsButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            settingsButton.widthAnchor.constraint(equalToConstant: 40),
            settingsButton.heightAnchor.constraint(equalToConstant: 40),

            titleLabel.topAnchor.constraint(equalTo: settingsButton.bottomAnchor, constant: 20),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20),
            
            // Hero meditation card
            meditationHeroCard.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 40),
            meditationHeroCard.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            meditationHeroCard.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            meditationHeroCard.heightAnchor.constraint(equalToConstant: 120),
            
            // Coming soon cards
            sleepCard.topAnchor.constraint(equalTo: meditationHeroCard.bottomAnchor, constant: 16),
            sleepCard.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            sleepCard.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            sleepCard.heightAnchor.constraint(equalToConstant: 100),
            
            journalCard.topAnchor.constraint(equalTo: sleepCard.bottomAnchor, constant: 16),
            journalCard.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            journalCard.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            journalCard.heightAnchor.constraint(equalToConstant: 100),
            journalCard.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
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
        popupLabel.backgroundColor = UIColor.appTitleBlue.withAlphaComponent(0.9)
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

// MARK: - SwiftUI Preview
#if DEBUG
import SwiftUI

struct HomeViewController_Previews: PreviewProvider {
    static var previews: some View {
        HomeViewControllerRepresentable()
            .previewDisplayName("Home - Light Mode")
            .preferredColorScheme(.light)
        
        HomeViewControllerRepresentable()
            .previewDisplayName("Home - Dark Mode")
            .preferredColorScheme(.dark)
    }
}

struct HomeViewControllerRepresentable: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> HomeViewController {
        let homeVC = HomeViewController()
        homeVC.authManager = FirebaseAuthManager()
        return homeVC
    }
    
    func updateUIViewController(_ uiViewController: HomeViewController, context: Context) {
        // Update the view controller if needed
    }
}
#endif
