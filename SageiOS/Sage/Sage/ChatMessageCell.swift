//
//  AppDelegate.swift
//  Sage
//
//  Created by hassan Khan on 5//25.
//

import UIKit

class ChatMessageCell: UITableViewCell {
    
    static let identifier = "ChatMessageCell"
    
    private let bubbleView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.aiChatBubbleBackground
        view.layer.cornerRadius = 16
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let messageLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.chatBubbleText
        label.font = .zenBody
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private var sentLeadingConstraint: NSLayoutConstraint!
    private var sentTrailingConstraint: NSLayoutConstraint!
    private var receivedLeadingConstraint: NSLayoutConstraint!
    private var receievedTrailingConstraint: NSLayoutConstraint!
    
    // Configure the cell with message
    func configure(with text: String, sent: Bool) {
        messageLabel.text = text
        
        // Use different text colors for user vs AI messages
        messageLabel.textColor = sent 
            ? UIColor.userChatBubbleText    // User messages: dusky blue
            : UIColor.chatBubbleText        // AI messages: neutral gray
        
        bubbleView.backgroundColor = sent
        ? UIColor.userChatBubbleBackground    // User's messages: bright green
        : UIColor.aiChatBubbleBackground      // Sage's messages: sage green
        
        messageLabel.textAlignment = .left
        
        sentLeadingConstraint.isActive = sent
        sentTrailingConstraint.isActive = sent
        receivedLeadingConstraint.isActive = !sent
        receievedTrailingConstraint.isActive = !sent
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none
        
        contentView.addSubview(bubbleView)
        bubbleView.addSubview(messageLabel)
        
        receivedLeadingConstraint = bubbleView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20)
        receievedTrailingConstraint = bubbleView.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -60)
        
        sentLeadingConstraint = bubbleView.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: 60)
        sentTrailingConstraint = bubbleView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20)
        
        
        NSLayoutConstraint.activate([
            bubbleView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            bubbleView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
            sentLeadingConstraint,
            sentTrailingConstraint,
            receivedLeadingConstraint,
            receievedTrailingConstraint,
//            bubbleView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 60),
//            bubbleView.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -20),
            
            messageLabel.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 10),
            messageLabel.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -10),
            messageLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 12),
            messageLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -12),
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
