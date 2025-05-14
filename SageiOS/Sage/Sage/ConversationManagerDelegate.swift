public protocol ConversationManagerDelegate: AnyObject {
    func conversationManagerStatus(status: ConversationStatus)
  
    func conversationManagerDidAddMessage(_ message: ChatMessage, isSentByUser: Bool)
} 
