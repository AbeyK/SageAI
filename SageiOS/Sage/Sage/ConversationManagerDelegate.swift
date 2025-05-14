public protocol ConversationManagerDelegate: AnyObject {
    func conversationManagerAddingMessage(_ transcript: String)
    
    func conversationManagerStatus(status: ConversationStatus)
  
    func conversationManagerDidAddMessage(_ message: ChatMessage)
} 
