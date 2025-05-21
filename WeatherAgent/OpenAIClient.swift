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
        ChatMessage(role: "system", content: systemPrompt, tool_calls: nil),
        ChatMessage(role: "user", content: prompt, tool_calls: nil)
    ]
    
    let chatRequest = ChatRequest(model: "gpt-4o", messages: messages, max_completion_tokens: 150, tools: nil, tool_choice: "none")
    
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
        ChatMessage(role: "system", content: systemPrompt, tool_calls: nil),
    ]
    promptWithChatMemory.append(contentsOf: messages)
    
    let chatRequest = ChatRequest(model: "gpt-4o", messages: promptWithChatMemory, max_completion_tokens: 150, tools: nil, tool_choice: "none")
    
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

func callChatOpenAIAPIWithTools(prompt: String) async throws -> ChatResponse{
    let url = "https://api.openai.com/v1/chat/completions"
    
    let headers: HTTPHeaders = [
        "Content-Type": "application/json",
        "Authorization": "Bearer \(APIKeys.openAIAPIKey)"
    ]
    
    let messages = [
        ChatMessage(role: "system", content: systemPrompt, tool_calls: nil),
        ChatMessage(role: "user", content: prompt, tool_calls: nil)
    ]
    
    let tools = [
        Tool(type: "function",
             function: ToolFunction(name: "getCurrentWeather", parameters: nil)
            ),
        Tool(type: "function",
             function: ToolFunction(name: "getCurrentLocation", parameters: nil)
            )
    ]
    
    let chatRequest = ChatRequest(model: "gpt-4o", messages: messages, max_completion_tokens: 150, tools: tools, tool_choice: "auto")
    
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

//MARK: TODO - break it into smaller functions!
//func getActionBasedOnResponse(response: ChatResponse) throws -> [String]{
//    var baseResponse = ""
//    var actionFound: [String] = []
//    
//    if let choice = response.choices.first{
//        baseResponse = choice.message.content
//    }
//    
//    let responseLines = baseResponse.split(separator: "\n")
//    
//    let regex = "^Action: (\\w+): (.*)$"
//    
//    if let regexPattern = try? NSRegularExpression(pattern: regex) {
//        for line in responseLines{
//            let nsRange = NSRange(line.startIndex..., in: line)
//            if let match = regexPattern.firstMatch(in: String(line), range: nsRange) {
//                let matchResult = (0..<match.numberOfRanges).map { index in
//                    let range = match.range(at: index)
//                    if range.location != NSNotFound {
//                        return String(line[Range(range, in: line)!])
//                    } else {
//                        return ""
//                    }
//                }
//                actionFound.append(contentsOf: matchResult)
//            }
//        }
//        
//        print("Action found: \(actionFound)")
//    }
//    return actionFound
//}

//func runAction(actions: [String]) async throws -> String{
//    if actions.count > 0 {
//        let action = actions[1]
//        let actionArgument = actions[2]
//        
//        guard let functionToBeCalled = try await availableFunctions[action] else{
//            print("No function to be called")
//            return "No function to be called"
//        }
//        
//        print("Calling function: \(String(describing: functionToBeCalled))")
//        
//        let observation = try await functionToBeCalled(actionArgument)
//        return observation
//    }else{
//        return ""
//    }
//    
//}

func getCurrentWeather() async throws -> String{
    print("Current weather")
    return "Cold, -5 Celsius"
}

func getCurrentLocation() async throws -> String{
    print("Current Location")
    print("Berlin")
    return "Berlin"
}

let availableFunctions = [
    getCurrentWeather, getCurrentLocation
]

var systemPrompt = """
You are a helpful AI agent. Give highly specific answers based on the information you're provided. Prefer to gather information with the tools provided to you rather than giving basic, generic answers.
"""
