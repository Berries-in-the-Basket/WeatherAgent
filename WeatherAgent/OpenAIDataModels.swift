//
//  OpenAIDataModels.swift
//  WeatherAgent
//
//  Created by Mariusz Smoliński on 16.05.25.
//

import Foundation

struct ChatMessage: Codable {
    let role: String  // "system", "user", "assistant", or "tool"
    let content: String?
    let tool_calls: [ToolCall]? //has to be an array
    let tool_call_id: String?
    
    struct ToolCall: Codable {
        let id: String
        let type: String
        let function: FunctionCalled
        
        struct FunctionCalled: Codable {
            let name: String
            let arguments: String?
        }
    }
}

struct ChatRequest: Codable {
    let model: String
    let messages: [ChatMessage]
    let max_completion_tokens: Int
    let tools: [Tool]?
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

struct Tool: Codable {
    let type: String
    let function: ToolFunction
}

struct ToolFunction: Codable {
    let name: String
    let parameters: FunctionParameters?
}

struct FunctionParameters: Codable {
    let type: String
    let properties: [Property]
    
    struct Property: Codable {
        let type: String
        let description: String
    }
}
