//
//  OpenAIDataModels.swift
//  WeatherAgent
//
//  Created by Mariusz Smoliński on 16.05.25.
//

import Foundation

struct ChatMessage: Codable {
    let role: String  // "system", "user", or "assistant"
    let content: String
}

struct ChatRequest: Codable {
    let model: String
    let messages: [ChatMessage]
    let max_completion_tokens: Int
}

struct ChatResponse: Codable {
    let id: String
    let object: String
    let created: Int
    let choices: [Choice]
    
    struct Choice: Codable {
        let index: Int
        let message: ChatMessage
        let finish_reason: String?
    }
}
