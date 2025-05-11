public protocol ConversationManagerDelegate: AnyObject {
    func conversationManagerAddingMessage(_ transcript: String)
    func conversationManagerListening(isListening: Bool)
}
