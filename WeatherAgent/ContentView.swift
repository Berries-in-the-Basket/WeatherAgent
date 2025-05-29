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
            TextField("Type a message", text: $prompt)
            
            Button{
                isLoading = true
                chatHistory.append(ChatMessage(role: "user", content: prompt, tool_calls: nil, tool_call_id: nil))
                Task{
                    do{
                        let maxIterations = 5
                        
                        for i in 0..<maxIterations{
                            print("Current iteration: \(i)")

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
                                        print("About to be stopped out")
                                    }
                                    print("Stopping out")
                                    return
                                }else if choice.finish_reason == "tool_calls"{
                                    print("make a function call")
                                    
                                    let toolCalls = choice.message.tool_calls ?? []
                                    var resultToBeDisplayed = ""
                                    
                                    for toolCall in toolCalls{
                                        let functionName = toolCall.function.name
                                        let functionToCall = availableFunctions[functionName]
                                        let functionToCallResult = try await functionToCall?()
                                        print(functionToCallResult)
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
                    .foregroundColor(.white)
                    .bold()
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(8)
            }
            
            Text("Response:")
            
            if textToBeDisplayed != ""{
                ScrollView {
                    Text(textToBeDisplayed)
                    Text(currentLocation)
                }
            }
        }
        .padding()
    }
}

#Preview {
    //    ContentView()
}
