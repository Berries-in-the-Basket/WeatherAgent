//
//  OpenAIClient.swift
//  WeatherAgent
//
//  Created by Mariusz Smoliński on 16.05.25.
//

import Foundation
import Alamofire

func callChatOpenAIAPI(prompt: String) async throws -> ChatResponse {
    let url = "https://api.openai.com/v1/chat/completions"
    
    let headers: HTTPHeaders = [
        "Content-Type": "application/json",
        "Authorization": "Bearer \(APIKeys.openAIAPIKey)"
    ]
    
    let messages = [
        ChatMessage(role: "system", content: systemPrompt, tool_calls: nil, tool_call_id: nil),
        ChatMessage(role: "user", content: prompt, tool_calls: nil, tool_call_id: nil)
    ]
    
    let chatRequest = ChatRequest(model: "gpt-4o", messages: messages, max_completion_tokens: 150, tools: nil)
    
    // request using Alamofire
    let dataTask = AF.request(
        url,
        method: .post,
        parameters: chatRequest,
        encoder: JSONParameterEncoder.default,
        headers: headers
    )
        .validate()
        .serializingDecodable(ChatResponse.self)
    
    let result = try await dataTask.value
    return result
}

func callChatOpenAIAPIWithChatMemory(messages: [ChatMessage]) async throws -> ChatResponse{
    let url = "https://api.openai.com/v1/chat/completions"
    
    let headers: HTTPHeaders = [
        "Content-Type": "application/json",
        "Authorization": "Bearer \(APIKeys.openAIAPIKey)"
    ]
    
    var promptWithChatMemory = [
        ChatMessage(role: "system", content: systemPrompt, tool_calls: nil, tool_call_id: nil),
    ]
    promptWithChatMemory.append(contentsOf: messages)
    
    let chatRequest = ChatRequest(model: "gpt-4o", messages: promptWithChatMemory, max_completion_tokens: 150, tools: nil)
    
    // request using Alamofire
    let dataTask = AF.request(
        url,
        method: .post,
        parameters: chatRequest,
        encoder: JSONParameterEncoder.default,
        headers: headers
    )
        .validate()
        .serializingDecodable(ChatResponse.self)
    
    let result = try await dataTask.value
    return result
}

func callChatOpenAIAPIWithTools(messages: [ChatMessage]) async throws -> ChatResponse{
    let url = "https://api.openai.com/v1/chat/completions"
    
    let headers: HTTPHeaders = [
        "Content-Type": "application/json",
        "Authorization": "Bearer \(APIKeys.openAIAPIKey)"
    ]
    
    let tools = [
        Tool(type: "function",
             function: ToolFunction(name: "getCurrentWeather", parameters: nil)
            ),
        Tool(type: "function",
             function: ToolFunction(name: "getCurrentLocation", parameters: nil)
            )
    ]
        
    var promptWithChatMemory = [ChatMessage(role: "system", content: systemPrompt, tool_calls: nil, tool_call_id: nil)]
    promptWithChatMemory.append(contentsOf: messages)
        
        print("CHAT HISTORY STARTS HERE: ")
        print(promptWithChatMemory)
        print("END OF CHAT HISTORY")
        
        let chatRequest = ChatRequest(model: "gpt-4o", messages: promptWithChatMemory, max_completion_tokens: 150, tools: tools)
        // request using Alamofire
        let dataTask = AF.request(
            url,
            method: .post,
            parameters: chatRequest,
            encoder: JSONParameterEncoder.default,
            headers: headers
        )
            .validate()
            .serializingDecodable(ChatResponse.self)
        
        let result = try await dataTask.value
        return result

}

func getCurrentWeather() async throws -> String{
    print("Current weather")
    return "Cold, -5 Celsius"
}

func getCurrentLocation() async throws -> String{
    print("Current Location: Berlin")
    return "Berlin"
}

let availableFunctions = [
    "getCurrentWeather": getCurrentWeather,
    "getCurrentLocation": getCurrentLocation
]

var systemPrompt = """
You are a helpful AI agent. Give highly specific answers based on the information you're provided. Prefer to gather information with the tools provided to you rather than giving basic, generic answers.
"""
