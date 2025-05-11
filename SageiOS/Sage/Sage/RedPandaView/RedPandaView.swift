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
<<<<<<< HEAD
    private let pandaView: UIImageView = {
        let pandaView = UIImageView()
        pandaView.contentMode = .scaleAspectFit
        pandaView.translatesAutoresizingMaskIntoConstraints = false
        return pandaView
    }()
    
    private let backgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = SageColors.primaryButtonColor.withAlphaComponent(0.3)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let listeningLabel: UILabel = {
        let label = UILabel()
        label.text = "Listening ..."
        label.textColor = UIColor.lightGray
        label.textAlignment = .center
        label.alpha = 0.0 // Initially hidden
        label.font = UIFont.systemFont(ofSize: 26, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
=======
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
>>>>>>> 3186bc5 (panda taliking, panda listening)
    }()
    
    private var currentType: PandaType

    init(frame: CGRect, type: PandaType) {
        self.currentType = type
        super.init(frame: frame)
<<<<<<< HEAD
        setupView()
        updatePandaView(for: type)
=======
        setupImageView()
        updateImageView(for: type)
>>>>>>> 3186bc5 (panda taliking, panda listening)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
<<<<<<< HEAD
    private func setupView() {
        addSubview(backgroundView)
        addSubview(pandaView)
        addSubview(listeningLabel)
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
            listeningLabel.widthAnchor.constraint(equalTo: pandaView.widthAnchor)
        ])
    }
    
    public func updatePandaView(for type: PandaType) {
        UIView.transition(with: pandaView, duration: 0.3, options: .transitionCrossDissolve, animations: {
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
    
    public func updateListeningState(isListening: Bool) {
        UIView.transition(with: listeningLabel, duration: 0.3, options: .transitionCrossDissolve, animations: {
            self.listeningLabel.alpha = isListening ? 1.0 : 0.0
        }, completion: nil)
=======
    private func setupImageView() {
        addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }
    
    public func updateImageView(for type: PandaType) {
        switch type {
        case .meditating:
            imageView.image = UIImage(named: "PandaMeditating")
        case .sleeping:
            imageView.image = UIImage(named: "PandaSleeping")
        case .talking:
            imageView.image = UIImage(named: "PandaTalking")
        case .happy:
            imageView.image = UIImage(named: "PandaHappy")
        }
>>>>>>> 3186bc5 (panda taliking, panda listening)
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
<<<<<<< HEAD
        backgroundView.layer.cornerRadius = backgroundView.frame.height / 2
=======
>>>>>>> 3186bc5 (panda taliking, panda listening)
    }
} 
