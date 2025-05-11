public protocol ConversationManagerDelegate: AnyObject {
    func conversationManagerAddingMessage(_ transcript: String)
    func conversationManagerDidAddMessage(_ message: ChatMessage)
} 