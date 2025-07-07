//
//  ContentView.swift
//  WeatherAgent
//
//  Created by Mariusz Smoliński on 16.05.25.
//

import SwiftUI

struct ContentView: View {
    @State var prompt = ""
    @State var textToBeDisplayed = ""
    @State var isLoading = false
    
    @State var currentLocation = ""
    
    @State var chatHistory: [ChatMessage] = []
    
    var body: some View {
        VStack {
            TextField("Ask a question", text: $prompt, axis: .vertical)
                .padding()
                .textFieldStyle(.roundedBorder)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(8)
            
            Button{
                isLoading = true
                chatHistory.append(ChatMessage(role: "user", content: prompt, tool_calls: nil, tool_call_id: nil))
                Task{
                    do{
                        let maxIterations = 5
                        
                        for i in 0..<maxIterations{
//                            print("Current iteration: \(i)")
                            
                            let response = try await callChatOpenAIAPIWithTools(messages: chatHistory)
                            
                            print("RESPONSE STARTS HERE: ")
                            print(response)
                            print("END OF RESPONSE")
                            
                            chatHistory.append(ChatMessage(role: "assistant", content: response.choices.first?.message.content ?? "", tool_calls: response.choices.first?.message.tool_calls, tool_call_id: nil))
                            
                            if let choice = response.choices.first{
                                if choice.finish_reason == "stop"{
                                    await MainActor.run {
                                        textToBeDisplayed = choice.message.content ?? "Error, response not generated"
                                        isLoading = false
//                                        print("About to be stopped out")
                                    }
//                                    print("Stopping out")
                                    return
                                }else if choice.finish_reason == "tool_calls"{
//                                    print("make a function call")
                                    
                                    let toolCalls = choice.message.tool_calls ?? []
                                    
//                                    print("TOOL CALLS")
//                                    print(toolCalls)
                                    
                                    var resultToBeDisplayed = ""
                                    
                                    for toolCall in toolCalls{
                                        let functionName = toolCall.function.name
                                        let functionToCall = availableFunctions[functionName]
                                        let functionArgumentsToPass = toolCall.function.arguments
                                        
                                        //                                        print("ARGUMENTS")
                                        //                                        print(functionArgumentsToPass)
                                        
                                        let argumentsToCallFunctionWith: [String: String] = try JSONDecoder().decode([String:String].self, from: Data(functionArgumentsToPass!.utf8))
                                        
                                        //                                        print("ARGUMENTS DECODED JSON")
                                        //                                        print(argumentsToCallFunctionWith)
                                        
                                        let functionToCallResult = try await functionToCall?(argumentsToCallFunctionWith["location"] ?? "Berlin")
                                        
                                        //                                        print(functionToCallResult)
                                        
                                        resultToBeDisplayed += functionToCallResult ?? "No result found"
                                        
                                        chatHistory.append(ChatMessage(role: "tool", content: resultToBeDisplayed, tool_calls: nil, tool_call_id: toolCall.id))
                                    }
                                    
                                    await MainActor.run {
                                        textToBeDisplayed = resultToBeDisplayed
                                        isLoading = false
                                    }
                                }
                            }else{
                                textToBeDisplayed = "Error, response not generated"
                            }
                        }
                    }
                    catch{
                        await MainActor.run {
                            textToBeDisplayed = error.localizedDescription
                            isLoading = false
                        }
                    }
                    
                }
                
            } label: {
                Text(isLoading ? "Loading..." : "Generate Response")
                    .foregroundColor(Color(red: 84/255, green: 22/255, blue: 144/255))
                    .bold()
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(red: 255/255, green: 205/255, blue: 56/255))
                    .cornerRadius(8)
            }
            .padding()
            
            Text("Response:")
                .padding()
            
            if textToBeDisplayed != ""{
                ScrollView {
                    Text(textToBeDisplayed)
                        .padding()
                    Text(currentLocation)
                        .padding()
                }
                .frame(maxWidth: .infinity)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(8)
                .padding()
            }
        }
        .padding()
    }
}

#Preview {
        ContentView()
}
