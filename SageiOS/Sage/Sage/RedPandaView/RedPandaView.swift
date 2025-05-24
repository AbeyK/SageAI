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
        
        // Create attributed string with custom green indicator
        let attributedText = NSMutableAttributedString()
        
        // Add larger, brighter green bullet point
        let bulletAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.brightListeningIndicator,
            .font: UIFont.systemFont(ofSize: 20, weight: .bold) // Larger bullet
        ]
        attributedText.append(NSAttributedString(string: "● ", attributes: bulletAttributes))
        
        // Add regular text
        let textAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.statusLabelAndIcon,
            .font: UIFont.zenAccent
        ]
        attributedText.append(NSAttributedString(string: "Listening...", attributes: textAttributes))
        
        label.attributedText = attributedText
        label.textAlignment = .center
        label.alpha = 0.0 // Initially hidden
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
        label.font = .zenAccent
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
        
    private let speakingLabel: UILabel = {
        let label = UILabel()
        label.text = "Speaking..."
        label.textColor = UIColor.statusLabelAndIcon
        label.textAlignment = .center
        label.alpha = 0.0 // Initially hidden
        label.font = .zenAccent
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let initializingLabel: UILabel = {
        let label = UILabel()
        label.text = "Waking Up..."
        label.textColor = UIColor.statusLabelAndIcon
        label.textAlignment = .center
        label.alpha = 0.0 // Initially hidden
        label.font = .zenAccent
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
            
            // Update listening label attributed text colors
            updateListeningLabelColors()
            
            thinkingLabel.textColor = UIColor.statusLabelAndIcon
            speakingLabel.textColor = UIColor.statusLabelAndIcon
            initializingLabel.textColor = UIColor.statusLabelAndIcon
        }
    }
    
    private func updateListeningLabelColors() {
        let attributedText = NSMutableAttributedString()
        
        // Add larger, brighter green bullet point
        let bulletAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.brightListeningIndicator,
            .font: UIFont.systemFont(ofSize: 20, weight: .bold) // Larger bullet
        ]
        attributedText.append(NSAttributedString(string: "● ", attributes: bulletAttributes))
        
        // Add regular text
        let textAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.statusLabelAndIcon,
            .font: UIFont.zenAccent
        ]
        attributedText.append(NSAttributedString(string: "Listening...", attributes: textAttributes))
        
        listeningLabel.attributedText = attributedText
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

// MARK: - SwiftUI Preview
#if DEBUG
import SwiftUI

struct RedPandaView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            Group {
                RedPandaViewRepresentable(type: .happy)
                    .frame(width: 120, height: 120)
                    .previewDisplayName("Happy Panda")
                
                RedPandaViewRepresentable(type: .meditating)
                    .frame(width: 120, height: 120)
                    .previewDisplayName("Meditating Panda")
                
                RedPandaViewRepresentable(type: .talking)
                    .frame(width: 120, height: 120)
                    .previewDisplayName("Talking Panda")
                
                RedPandaViewRepresentable(type: .sleeping)
                    .frame(width: 120, height: 120)
                    .previewDisplayName("Sleeping Panda")
            }
        }
        .padding()
        .previewLayout(.sizeThatFits)
        .preferredColorScheme(.light)
        
        VStack(spacing: 20) {
            Group {
                RedPandaViewRepresentable(type: .happy)
                    .frame(width: 120, height: 120)
                
                RedPandaViewRepresentable(type: .meditating)
                    .frame(width: 120, height: 120)
                
                RedPandaViewRepresentable(type: .talking)
                    .frame(width: 120, height: 120)
                
                RedPandaViewRepresentable(type: .sleeping)
                    .frame(width: 120, height: 120)
            }
        }
        .padding()
        .previewLayout(.sizeThatFits)
        .preferredColorScheme(.dark)
        .previewDisplayName("All Pandas - Dark Mode")
    }
}

struct RedPandaViewRepresentable: UIViewRepresentable {
    let type: PandaType
    
    func makeUIView(context: Context) -> RedPandaView {
        let pandaView = RedPandaView(frame: .zero, type: type)
        // Simulate listening state for preview
        if type == .meditating {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                pandaView.updateListeningState(isListening: true)
            }
        }
        return pandaView
    }
    
    func updateUIView(_ uiView: RedPandaView, context: Context) {
        // Update the view if needed
    }
}
#endif
