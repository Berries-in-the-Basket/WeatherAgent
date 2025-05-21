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
        ChatMessage(role: "system", content: systemPrompt),
        ChatMessage(role: "user", content: prompt)
    ]
    
    let chatRequest = ChatRequest(model: "gpt-4o", messages: messages, max_completion_tokens: 150)
    
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
        ChatMessage(role: "system", content: systemPrompt),
    ]
    promptWithChatMemory.append(contentsOf: messages)
    
    let chatRequest = ChatRequest(model: "gpt-4o", messages: promptWithChatMemory, max_completion_tokens: 150)
    
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
func getActionBasedOnResponse(response: ChatResponse) throws -> [String]{
    var baseResponse = ""
    var actionFound: [String] = []
    
    if let choice = response.choices.first{
        baseResponse = choice.message.content
    }
    
    let responseLines = baseResponse.split(separator: "\n")
    
    let regex = "^Action: (\\w+): (.*)$"
    
    if let regexPattern = try? NSRegularExpression(pattern: regex) {
        for line in responseLines{
            let nsRange = NSRange(line.startIndex..., in: line)
            if let match = regexPattern.firstMatch(in: String(line), range: nsRange) {
                let matchResult = (0..<match.numberOfRanges).map { index in
                    let range = match.range(at: index)
                    if range.location != NSNotFound {
                        return String(line[Range(range, in: line)!])
                    } else {
                        return ""
                    }
                }
                actionFound.append(contentsOf: matchResult)
            }
        }
        
        print("Action found: \(actionFound)")
    }
    return actionFound
}

func runAction(actions: [String]) async throws -> String{
    if actions.count > 0 {
        let action = actions[1]
        let actionArgument = actions[2]
        
        guard let functionToBeCalled = try await availableFunctions[action] else{
            print("No function to be called")
            return "No function to be called"
        }
        
        print("Calling function: \(String(describing: functionToBeCalled))")
        
        let observation = try await functionToBeCalled(actionArgument)
        return observation
    }else{
        return ""
    }
    
}

func getCurrentWeather(location: String) async throws -> String{
    print("Current weather")
    return "Cold, -5 Celsius"
}

func getCurrentLocation(_: String) async throws -> String{
    print("Current Location")
    print("Berlin")
    return "Berlin"
}

let availableFunctions: [String: (String) async throws -> String] = [
    "getCurrentWeather": getCurrentWeather,
    "getCurrentLocation": getCurrentLocation
]

var systemPrompt = """
You cycle through Thought, Action, PAUSE, Observation. At the end of the loop you output a final Answer. Your final answer should be highly specific to the observations you have from running the actions. 

1. Thought: Describe your thoughts about the question you have been asked. 
2. Action: run one of the actions available to you - then return PAUSE.
3. PAUSE
4. Observation: will be the result of running those actions.

Available actions:
- getCurrentWeather:
    E.g. getCurrenttWeather: Salt Lake City
    Returns the current weather of the location specified.
- getCurrentLocation:
    E.g. getCurrentLocation: null
    Returns user's location details. No arguments needed.

Example session:
Question: Please give me some ideas for activities to do this afternoon.
Thought: I should look up the user's location so I can give location-specific activity ideas.
Action: getCurrentLocation: null
PAUSE

You will be called again with something like this:
Observation: "New York City, NY"

Then you loop again:
Thought: To get even more specific activity ideas, I should get the current weather at the user's location.
Action: getCurrentWeather: New York City
PAUSE

You'll then be called again with something like this:
Observation: { location: "New York City, NY", forecast: ["sunny"] }

You then output:
Answer: <Suggested activities based on sunny weather that are highly specific to New York City and surrounding areas.>
"""
