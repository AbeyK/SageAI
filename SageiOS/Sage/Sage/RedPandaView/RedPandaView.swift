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
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private var currentType: PandaType

    init(frame: CGRect, type: PandaType) {
        self.currentType = type
        super.init(frame: frame)
        setupImageView()
        updateImageView(for: type)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
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
        UIView.transition(with: imageView, duration: 0.3, options: .transitionCrossDissolve, animations: {
            switch type {
            case .meditating:
                self.imageView.image = UIImage(named: "PandaMeditating")
            case .sleeping:
                self.imageView.image = UIImage(named: "PandaSleeping")
            case .talking:
                self.imageView.image = UIImage(named: "PandaTalking")
            case .happy:
                self.imageView.image = UIImage(named: "PandaHappy")
            }
        }, completion: nil)
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
    }
} 
