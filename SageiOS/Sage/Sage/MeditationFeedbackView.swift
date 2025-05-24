import UIKit

protocol MeditationFeedbackViewDelegate: AnyObject {
    func meditationFeedbackViewDidSubmit(rating: Int, feedback: String?)
}

class MeditationFeedbackView: UIView {

    weak var delegate: MeditationFeedbackViewDelegate?
    private var currentRating: Int = 0

    private let backgroundOverlay: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let contentView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.appBackground // Or a specific popup background color
        view.layer.cornerRadius = 16
        view.layer.masksToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Meditation Complete!"
        label.font = .zenHeading2
        label.textColor = UIColor.chatBubbleText // Ensure this contrasts with contentView background
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let starsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    private let feedbackTextView: UITextView = {
        let textView = UITextView()
        textView.font = .zenBody
        textView.textColor = UIColor.chatBubbleText
        textView.backgroundColor = UIColor.pandaCircleBackground // Or a slightly different shade
        textView.layer.cornerRadius = 8
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.isScrollEnabled = true
        return textView
    }()
    
    private let placeholderLabel: UILabel = {
        let label = UILabel()
        label.text = "Share your thoughts (optional)..."
        label.font = .zenBody
        label.textColor = UIColor.statusLabelAndIcon
        label.sizeToFit()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let doneButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Done", for: .normal)
        button.backgroundColor = UIColor.primaryButtonBackground
        button.setTitleColor(UIColor.primaryButtonText, for: .normal)
        button.titleLabel?.font = .zenButton
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(doneButtonTapped), for: .touchUpInside)
        return button
    }()

    private var starButtons: [UIButton] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        setupStars()
        setupKeyboardDismissal()
        feedbackTextView.delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        addSubview(backgroundOverlay)
        addSubview(contentView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(starsStackView)
        contentView.addSubview(feedbackTextView)
        feedbackTextView.addSubview(placeholderLabel) // Add placeholder to text view
        contentView.addSubview(doneButton)

        NSLayoutConstraint.activate([
            backgroundOverlay.leadingAnchor.constraint(equalTo: leadingAnchor),
            backgroundOverlay.trailingAnchor.constraint(equalTo: trailingAnchor),
            backgroundOverlay.topAnchor.constraint(equalTo: topAnchor),
            backgroundOverlay.bottomAnchor.constraint(equalTo: bottomAnchor),

            contentView.centerXAnchor.constraint(equalTo: centerXAnchor),
            contentView.centerYAnchor.constraint(equalTo: centerYAnchor),
            contentView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.85),
            
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            starsStackView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            starsStackView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            starsStackView.heightAnchor.constraint(equalToConstant: 40),
            starsStackView.widthAnchor.constraint(lessThanOrEqualTo: contentView.widthAnchor, constant: -40),

            feedbackTextView.topAnchor.constraint(equalTo: starsStackView.bottomAnchor, constant: 20),
            feedbackTextView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            feedbackTextView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            feedbackTextView.heightAnchor.constraint(equalToConstant: 100), // Min height for ~3 lines
            
            placeholderLabel.leadingAnchor.constraint(equalTo: feedbackTextView.leadingAnchor, constant: 12), // Aligned with text view content
            placeholderLabel.topAnchor.constraint(equalTo: feedbackTextView.topAnchor, constant: 8),

            doneButton.topAnchor.constraint(equalTo: feedbackTextView.bottomAnchor, constant: 20),
            doneButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            doneButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            doneButton.heightAnchor.constraint(equalToConstant: 50),
            doneButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
    }

    private func setupStars() {
        for i in 0..<5 {
            let button = UIButton(type: .system)
            button.setImage(UIImage(systemName: "star"), for: .normal)
            button.tintColor = .gray // Initial color
            button.tag = i + 1 // 1 to 5
            button.addTarget(self, action: #selector(starTapped(_:)), for: .touchUpInside)
            starButtons.append(button)
            starsStackView.addArrangedSubview(button)
        }
    }

    @objc private func starTapped(_ sender: UIButton) {
        currentRating = sender.tag
        updateStarAppearance()
    }

    private func updateStarAppearance() {
        for (index, button) in starButtons.enumerated() {
            if index < currentRating {
                button.setImage(UIImage(systemName: "star.fill"), for: .normal)
                button.tintColor = .systemYellow // Gold color
            } else {
                button.setImage(UIImage(systemName: "star"), for: .normal)
                button.tintColor = .gray
            }
        }
    }
    
    private func setupKeyboardDismissal() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        // Add to backgroundOverlay so taps outside contentView dismiss keyboard
        backgroundOverlay.addGestureRecognizer(tapGesture) 
        
        // Allow taps on contentView itself (but not its interactive subviews) to dismiss keyboard
        let contentViewTapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        contentViewTapGesture.cancelsTouchesInView = false // Let subviews like buttons still get taps
        contentView.addGestureRecognizer(contentViewTapGesture)
    }

    @objc private func dismissKeyboard() {
        feedbackTextView.resignFirstResponder()
    }

    @objc private func doneButtonTapped() {
        let feedbackText = feedbackTextView.text == placeholderLabel.text ? "" : feedbackTextView.text
        delegate?.meditationFeedbackViewDidSubmit(rating: currentRating, feedback: feedbackText)
    }
}

extension MeditationFeedbackView: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        placeholderLabel.isHidden = !textView.text.isEmpty
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.text == placeholderLabel.text {
             //This case should not happen if placeholder logic is correct
        }
        placeholderLabel.isHidden = true
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            placeholderLabel.isHidden = false
        }
    }
} 