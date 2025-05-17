//
//  RedPandaView.swift
//  Sage
//
//  Created by hassan Khan on 4/30/25.
//

import UIKit

public enum PandaType {
    case meditating
    case sleeping
    case talking
    case happy
}

public class RedPandaView: UIView {
    private let pandaView: UIImageView = {
        let pandaView = UIImageView()
        pandaView.contentMode = .scaleAspectFit
        pandaView.translatesAutoresizingMaskIntoConstraints = false
        return pandaView
    }()
    
    private let backgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.pandaCircleBackground
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let listeningLabel: UILabel = {
        let label = UILabel()
        label.text = "🟢 Listening..."
        label.textColor = UIColor.statusLabelAndIcon
        label.textAlignment = .center
        label.alpha = 0.0 // Initially hidden
        label.font = UIFont(name: "AvenirNext-Medium", size: 26) ?? UIFont.systemFont(ofSize: 26, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
        
    private let thinkingLabel: UILabel = {
        let label = UILabel()
        label.text = "Reflecting..."
        label.textColor = UIColor.statusLabelAndIcon
        label.textAlignment = .center
        label.alpha = 0.0 // Initially hidden
        label.font = UIFont(name: "AvenirNext-Medium", size: 26) ?? UIFont.systemFont(ofSize: 26, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
        
    private let speakingLabel: UILabel = {
        let label = UILabel()
        label.text = "Speaking..."
        label.textColor = UIColor.statusLabelAndIcon
        label.textAlignment = .center
        label.alpha = 0.0 // Initially hidden
        label.font = UIFont(name: "AvenirNext-Medium", size: 26) ?? UIFont.systemFont(ofSize: 26, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let initializingLabel: UILabel = {
        let label = UILabel()
        label.text = "Waking Up..."
        label.textColor = UIColor.statusLabelAndIcon
        label.textAlignment = .center
        label.alpha = 0.0 // Initially hidden
        label.font = UIFont(name: "AvenirNext-Medium", size: 26) ?? UIFont.systemFont(ofSize: 26, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private var currentType: PandaType
        
    private func isHostedByChatViewController() -> Bool {
        var responder: UIResponder? = self
        while responder != nil {
            if let viewController = responder as? UIViewController {
                return viewController is ChatViewController
            }
            responder = responder?.next
        }
        return false
    }
        
    init(frame: CGRect, type: PandaType) {
        self.currentType = type
        super.init(frame: frame)
        setupView()
        updatePandaView(for: type)
    }
        
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
        
    override public func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            // Ensure dynamic colors are reapplied
            backgroundView.backgroundColor = UIColor.pandaCircleBackground
            listeningLabel.textColor = UIColor.statusLabelAndIcon
            thinkingLabel.textColor = UIColor.statusLabelAndIcon
            speakingLabel.textColor = UIColor.statusLabelAndIcon
            initializingLabel.textColor = UIColor.statusLabelAndIcon
        }
    }
        
    private func setupView() {
        addSubview(backgroundView)
        addSubview(pandaView)
        addSubview(listeningLabel)
        addSubview(thinkingLabel)
        addSubview(speakingLabel)
        addSubview(initializingLabel)
        
        NSLayoutConstraint.activate([
            pandaView.topAnchor.constraint(equalTo: topAnchor),
            pandaView.bottomAnchor.constraint(equalTo: bottomAnchor),
            pandaView.leadingAnchor.constraint(equalTo: leadingAnchor),
            pandaView.trailingAnchor.constraint(equalTo: trailingAnchor),
            
            backgroundView.centerXAnchor.constraint(equalTo: pandaView.centerXAnchor),
            backgroundView.centerYAnchor.constraint(equalTo: pandaView.centerYAnchor),
            backgroundView.widthAnchor.constraint(equalTo: pandaView.heightAnchor, multiplier: 1.3),
            backgroundView.heightAnchor.constraint(equalTo: pandaView.heightAnchor, multiplier: 1.3),
            
            listeningLabel.bottomAnchor.constraint(equalTo: backgroundView.topAnchor, constant: -16),
            listeningLabel.centerXAnchor.constraint(equalTo: pandaView.centerXAnchor),
            listeningLabel.widthAnchor.constraint(equalTo: pandaView.widthAnchor),
            
            thinkingLabel.bottomAnchor.constraint(equalTo: backgroundView.topAnchor, constant: -16),
            thinkingLabel.centerXAnchor.constraint(equalTo: pandaView.centerXAnchor),
            thinkingLabel.widthAnchor.constraint(equalTo: pandaView.widthAnchor),
            
            speakingLabel.bottomAnchor.constraint(equalTo: backgroundView.topAnchor, constant: -16),
            speakingLabel.centerXAnchor.constraint(equalTo: pandaView.centerXAnchor),
            speakingLabel.widthAnchor.constraint(equalTo: pandaView.widthAnchor),

            initializingLabel.bottomAnchor.constraint(equalTo: backgroundView.topAnchor, constant: -16),
            initializingLabel.centerXAnchor.constraint(equalTo: pandaView.centerXAnchor),
            initializingLabel.widthAnchor.constraint(equalTo: pandaView.widthAnchor)
        ])
    }
        
    public func updatePandaView(for type: PandaType) {
        DispatchQueue.main.async {
            UIView.transition(with: self.pandaView, duration: 0.3, options: .transitionCrossDissolve, animations: {
                switch type {
                case .meditating:
                    self.pandaView.image = UIImage(named: "PandaMeditating")
                case .sleeping:
                    self.pandaView.image = UIImage(named: "PandaSleeping")
                case .talking:
                    self.pandaView.image = UIImage(named: "PandaTalking")
                case .happy:
                    self.pandaView.image = UIImage(named: "PandaHappy")
                }
            }, completion: nil)
        }
    }

    public func updateListeningState(isListening: Bool) {
        DispatchQueue.main.async {
            let shouldShowListeningLabel = isListening && self.isHostedByChatViewController()
            UIView.transition(with: self.listeningLabel, duration: 0.3, options:.transitionCrossDissolve, animations: {
                    self.listeningLabel.alpha = shouldShowListeningLabel ? 1.0 : 0.0
                }, completion: nil)
        }
    }
            
    public func updateThinkingLabelState(isThinking: Bool) {
        DispatchQueue.main.async {
            UIView.transition(with: self.thinkingLabel, duration: 0.3, options: .transitionCrossDissolve, animations: {
                self.thinkingLabel.alpha = isThinking ? 1.0 : 0.0
            }, completion: nil)
        }
    }

    public func updateSpeakingLabelState(isSpeaking: Bool) {
        DispatchQueue.main.async {
            UIView.transition(with: self.speakingLabel, duration: 0.3, options: .transitionCrossDissolve, animations: {
                self.speakingLabel.alpha = isSpeaking ? 1.0 : 0.0
            }, completion: nil)
        }
    }

    public func updateInitializingLabelState(isInitializing: Bool) {
        DispatchQueue.main.async {
            let shouldShowInitializingLabel = isInitializing && self.isHostedByChatViewController()
            UIView.transition(with: self.initializingLabel, duration: 0.3, options: .transitionCrossDissolve, animations: {
                self.initializingLabel.alpha = shouldShowInitializingLabel ? 1.0 : 0.0
            }, completion: nil)
        }
    }
            
    public override func layoutSubviews() {
        super.layoutSubviews()
        backgroundView.layer.cornerRadius = backgroundView.frame.height / 2
    }
}
