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
    
    @State var messages: [ChatMessage] = []
    
    @State var observation = ""
    
    var body: some View {
        VStack {
            TextField("Type a message", text: $prompt)
            
            Button{
                isLoading = true
                messages.append(ChatMessage(role: "user", content: prompt))
                Task{
                    do{
                        let maxIterations = 5
                        for i in 0..<maxIterations{
                            print("Current iteration: \(i)")
                            let response = try await callChatOpenAIAPIWithChatMemory(messages: messages)
                            let actionsDetected = try getActionBasedOnResponse(response: response)
                            if actionsDetected != []{
                                
                                print(response)
                                if let choice = response.choices.first{
                                    messages.append(ChatMessage(role: "assistant", content: choice.message.content))
                                }
                                print(messages)
                                
                                Task{
                                    do{
                                        observation = try await runAction(actions: actionsDetected)
                                        print("Observation: \(observation)")
                                        messages.append(ChatMessage(role: "assistant", content: "Observation: \(observation)"))
                                        print(messages)
                                        await MainActor.run {
                                            textToBeDisplayed = observation
                                            isLoading = false
                                        }
                                    }catch{
                                        textToBeDisplayed = error.localizedDescription
                                    }
                                    
                                }
                                
                                if let choice = response.choices.first{
                                    await MainActor.run {
                                        textToBeDisplayed = choice.message.content
                                        isLoading = false
                                    }
                                }else{
                                    textToBeDisplayed = "Error, response not generated"
                                }
                            }else{
                                print("No actions returned")
                                if let choice = response.choices.first{
                                    await MainActor.run {
                                        textToBeDisplayed = choice.message.content
                                        isLoading = false
                                    }
                                }else{
                                    textToBeDisplayed = "Error, response not generated"
                                }
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
