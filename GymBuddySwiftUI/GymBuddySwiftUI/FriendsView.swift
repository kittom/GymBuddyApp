//
//  FriendsView.swift
//  GymBuddySwiftUI
//
//  Created by Freddie Kohn on 20/04/2023.
//

import SwiftUI

import SwiftUI
import Combine

struct FriendsView: View {
    @AppStorage("accountId") private var accountId: Int?
    
    @State private var searchText = ""
    @State private var searchResults: [AccountSearch] = []
    @State private var pendingRequests: [Account] = []
    @AppStorage("isLoggedIn") private var isLoggedIn: Bool = false
    
    var body: some View {
        NavigationView {
            VStack {
                TextField("Search", text: $searchText)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                    .padding(.horizontal, 16)
                    .onChange(of: searchText) { newValue in
                        performSearch(query: newValue)
                    }
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                List {
                    Section(header: Text("Pending Requests")) {
                        ForEach(pendingRequests) { request in
                            HStack {
                                Text(request.username)
                            }
                        }
                    }
                    
                    Section(header: Text("Search Results")) {
                        ForEach(searchResults) { result in
                            HStack {
                                Text(result.username)
                                Spacer()
                                Button(action: {
                                    sendFriendRequest(account1ID: accountId!, account2ID: result.id)
                                }) {
                                    Image(systemName: "person.badge.plus")
                                }
                            }
                        }
                    }
                }
                .listStyle(GroupedListStyle())
            }
            .navigationBarTitle("Add Friends")
        }
    }
    
    private func performSearch(query: String) {
        let searchUrl = "http://\(ip):8000/api/search/?q=\(query)"
        
        guard let url = URL(string: searchUrl) else {
            print("Invalid URL")
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data {
                do {
                    let decodedResponse = try JSONDecoder().decode([AccountSearch].self, from: data)
                    DispatchQueue.main.async {
                        self.searchResults = decodedResponse
                    }
                } catch {
                    print("Error decoding response: \(error)")
                }
            } else {
                print("Error fetching data: \(error?.localizedDescription ?? "Unknown error")")
            }
        }.resume()
    }

    
    private func sendFriendRequest(account1ID: Int, account2ID: Int) {
        print("\(account1ID) \(account2ID)")
        let requestUrl = "http://\(ip):8000/api/friend/request/?account1=\(account1ID)&account2=\(account2ID)"
        
        guard let url = URL(string: requestUrl) else {
            print("Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST" // Adjust this according to your API requirements
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("Error sending friend request: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            DispatchQueue.main.async {
                // Update the pendingRequests list, if necessary
                // You may also want to show an alert or a message to inform the user that the friend request has been sent successfully
                
            }
        }.resume()
    }
}

struct FriendSearchView_Previews: PreviewProvider {
    static var previews: some View {
        FriendsView()
    }
}
