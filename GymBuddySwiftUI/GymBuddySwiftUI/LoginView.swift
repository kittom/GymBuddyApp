//
//  logintest.swift
//  GymBuddySwiftUI
//
//  Created by Freddie Kohn on 13/04/2023.
//

import SwiftUI
import Combine

struct LoginPage: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @AppStorage("isLoggedIn") private var isLoggedIn: Bool = false
    @AppStorage("accountId") private var accountId: Int?
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Gym Buddy")
                    .font(.largeTitle)
                    .fontWeight(.semibold)
                    .padding(.bottom, 20)
                
                TextField("Email", text: $email)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(5.0)
                    .padding(.bottom, 20)
                
                SecureField("Password", text: $password)
                    .autocorrectionDisabled(true)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(5.0)
                    .padding(.bottom, 20)
                
                if showError {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding(.bottom, 10)
                }
                
                Button(action: {
                    // Add API call for login functionality
                    self.login()
                }) {
                    Text("Log In")
                        .frame(minWidth: 0, maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(5.0)
                }
                .padding(.bottom, 10)
                
                NavigationLink(destination: SignUpPage()) {
                    Text("Sign Up")
                        .foregroundColor(.blue)
                }
            }
            .padding()
        }
    }
    
    func login() {
        // Add API call for login functionality
        // Validate inputs and set showError and errorMessage accordingly
        guard !email.isEmpty, !password.isEmpty else {
                showError = true
                errorMessage = "Please enter your email and password."
                return
            }
            
            guard let url = URL(string: "http://\(ip):8000/api/accounts/") else { return }

            // Create a URLRequest and set the appropriate headers
            var request = URLRequest(url: url)
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("application/json", forHTTPHeaderField: "Accept")

            // Create a URLSession data task to make the API request
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                DispatchQueue.main.async {
                    self.showError = true
                    self.errorMessage = "Error fetching accounts. Please try again."
                }
                return
            }
            
            // Decode the fetched account data
            let decoder = JSONDecoder()
            do {
                let accounts = try decoder.decode([Account].self, from: data)
                
                // Check if the provided email and password match an existing account
                if let matchingAccount = accounts.first(where: { $0.email == email && $0.password == password }) {
                    DispatchQueue.main.async {
                        self.showError = false
                        self.errorMessage = ""
                        print("logged in")
                        
                        // Navigate to the app's main page or perform any login-related actions
                        self.isLoggedIn = true
                        self.accountId = matchingAccount.id
                        mainAccount = matchingAccount
                    }
                } else {
                    DispatchQueue.main.async {
                        self.showError = true
                        self.errorMessage = "Invalid email or password."
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.showError = true
                    self.errorMessage = "Error decoding accounts data. Please try again."
                }
            }
        }.resume()
    }
}

struct SignUpPage: View {
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var email: String = ""
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @State private var isLogged: Bool = false
    
    var body: some View {
        VStack {
            Text("Sign Up")
                .font(.largeTitle)
                .fontWeight(.semibold)
                .padding(.bottom, 20)
            
            // Add input fields for first name, last name, email, username, password, and confirm password
            TextField("First Name", text: $firstName)
                .autocorrectionDisabled(true)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(5.0)
                .padding(.bottom, 20)
            
            TextField("Last Name", text: $lastName)
                .autocorrectionDisabled(true)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(5.0)
                .padding(.bottom, 20)
            
            TextField("Email", text: $email)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(5.0)
                .padding(.bottom, 20)
            
            TextField("Username", text: $username)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(5.0)
                .padding(.bottom, 20)
            
            SecureField("Password", text: $password)
                .autocorrectionDisabled(true)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(5.0)
                .padding(.bottom, 20)
            
            SecureField("Confirm Password", text: $confirmPassword)
                .autocorrectionDisabled(true)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(5.0)
                .padding(.bottom, 20)
            
            if showError {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding(.bottom, 10)
            }
            
            Button(action: {
                // Add API call for sign up functionality
                self.signUp()
            }) {
                Text("Sign Up")
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(5.0)
            }
            .padding(.bottom, 10)
            
            NavigationLink(destination: LoginPage()) {
                Text("Already have an account? Log In")
                    .foregroundColor(.blue)
            }
        }
        .padding()
    }
    
    func signUp() {
        // Add API call for sign up functionality
        // Validate inputs and set showError and errorMessage accordingly
        guard !firstName.isEmpty, !lastName.isEmpty, !email.isEmpty, !username.isEmpty, !password.isEmpty, !confirmPassword.isEmpty else {
            showError = true
            errorMessage = "Please fill in all fields."
            return
        }

        guard password == confirmPassword else {
            showError = true
            errorMessage = "Passwords do not match."
            return
        }

        // Prepare the data for the request
        let account = AccountSearch(id: -1, first_name: firstName, last_name: lastName, username: username, password: password, email: email, xp: 0)
        guard let url = URL(string: "http://\(ip):8000/api/accounts/") else { return }

        // Create a URLRequest and set the appropriate headers and HTTP method
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")

        // Encode the account object into JSON
        let encoder = JSONEncoder()
        do {
            let jsonData = try encoder.encode(account)
            request.httpBody = jsonData
        } catch {
            print("Error encoding account data: \(error)")
            return
        }

            // Create a URLSession data task to make the API request
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 201 else {
                DispatchQueue.main.async {
                    self.showError = true
                    self.errorMessage = "Error creating account. Please try again."
                }
                return
            }
            
            DispatchQueue.main.async {
                self.showError = false
                self.errorMessage = ""
                print("account created")
                
                // Navigate back to the login screen or show a success message
                //MainView()
                
            }
        }.resume()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        LoginPage()
    }
}





////
////  logintest.swift
////  GymBuddySwiftUI
////
////  Created by Freddie Kohn on 13/04/2023.
////
//
//import SwiftUI
//import Combine
//
//struct LoginPage: View {
//    @State private var email: String = ""
//    @State private var password: String = ""
//    @State private var showError: Bool = false
//    @State private var errorMessage: String = ""
//    @State private var navigateToNextView = false
//    @AppStorage("accountId") private var accountId: Int?
//    @AppStorage("isLoggedIn") private var isLoggedIn: Bool = false
//
//    var body: some View {
//        NavigationView {
//            VStack {
//                Text("Gym Buddy")
//                    .font(.largeTitle)
//                    .fontWeight(.semibold)
//                    .padding(.bottom, 20)
//
//                TextField("Email", text: $email)
//                    .textInputAutocapitalization(.never)
//                    .autocorrectionDisabled(true)
//                    .padding()
//                    .background(Color(.systemGray6))
//                    .cornerRadius(5.0)
//                    .padding(.bottom, 20)
//
//                SecureField("Password", text: $password)
//                    .autocorrectionDisabled(true)
//                    .padding()
//                    .background(Color(.systemGray6))
//                    .cornerRadius(5.0)
//                    .padding(.bottom, 20)
//
//                if showError {
//                    Text(errorMessage)
//                        .foregroundColor(.red)
//                        .padding(.bottom, 10)
//                }
//
//                if login() {
//                    NavigationLink(destination: MainView().navigationBarHidden(true), isActive: $navigateToNextView) {
//                                            EmptyView()
////                        RoundedRectangle(cornerRadius: 5.0)
////                            .stroke(Color.blue, lineWidth: 2)
////                            .overlay(
////                                Text("Log In")
////                                    .frame(minWidth: 100)
////                                    .padding()
////                                    .background(Color.blue)
////                                    .foregroundColor(.white)
////                                    .cornerRadius(5.0)
////                            )
//                    }
//                    .buttonStyle(PlainButtonStyle())
//                    .padding(.bottom, 10)
//                }
//
//
//                NavigationLink(destination: SignUpPage()) {
//                    Text("Sign Up")
//                        .foregroundColor(.blue)
//                }
//            }
//            .padding()
//        }//.fullScreenCover(isPresented: $isLoggedIn) {
////            MainView()
////        }
//    }
//
//    func login() -> Bool {
//        // Add API call for login functionality
//        // Validate inputs and set showError and errorMessage accordingly
//        guard !email.isEmpty, !password.isEmpty else {
//                showError = true
//                errorMessage = "Please enter your email and password."
//                return false
//            }
//
//        guard let url = URL(string: "http://\(ip):8000/api/accounts/") else { return false}
//
//            // Create a URLRequest and set the appropriate headers
//            var request = URLRequest(url: url)
//            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
//            request.addValue("application/json", forHTTPHeaderField: "Accept")
//
//            // Create a URLSession data task to make the API request
//        URLSession.shared.dataTask(with: request) { data, response, error in
//            guard let data = data, let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
//                DispatchQueue.main.async {
//                    self.showError = true
//                    self.errorMessage = "Error fetching accounts. Please try again."
//                }
//                return
//            }
//
//            // Decode the fetched account data
//            let decoder = JSONDecoder()
//            do {
//                let accounts = try decoder.decode([AccountSearch].self, from: data)
//
//                // Check if the provided email and password match an existing account
//                if let matchingAccount = accounts.first(where: { $0.email == email && $0.password == password }) {
//                    DispatchQueue.main.async {
//                        self.showError = false
//                        self.errorMessage = ""
//                        print("logged in")
//
//                        // Navigate to the app's main page or perform any login-related actions
//                        isLoggedIn = true
//                        accountId = matchingAccount.id
//                        //mainAccount = matchingAccount
//
//                        // Trigger navigation
//                        self.navigateToNextView = true
//                    }
//                } else {
//                    DispatchQueue.main.async {
//                        self.showError = true
//                        self.errorMessage = "Invalid email or password."
//                    }
//                }
//            } catch {
//                DispatchQueue.main.async {
//                    self.showError = true
//                    self.errorMessage = "Error decoding accounts data. Please try again."
//                }
//            }
//        }.resume()
//        if self.navigateToNextView == true {
//            return true
//        } else {return false}
//    }
//}
//
//struct SignUpPage: View {
//    @State private var firstName: String = ""
//    @State private var lastName: String = ""
//    @State private var email: String = ""
//    @State private var username: String = ""
//    @State private var password: String = ""
//    @State private var confirmPassword: String = ""
//    @State private var showError: Bool = false
//    @State private var errorMessage: String = ""
//    @State private var isLogged: Bool = false
//
//    var body: some View {
//        VStack {
//            Text("Sign Up")
//                .font(.largeTitle)
//                .fontWeight(.semibold)
//                .padding(.bottom, 20)
//
//            // Add input fields for first name, last name, email, username, password, and confirm password
//            TextField("First Name", text: $firstName)
//                .autocorrectionDisabled(true)
//                .padding()
//                .background(Color(.systemGray6))
//                .cornerRadius(5.0)
//                .padding(.bottom, 20)
//
//            TextField("Last Name", text: $lastName)
//                .autocorrectionDisabled(true)
//                .padding()
//                .background(Color(.systemGray6))
//                .cornerRadius(5.0)
//                .padding(.bottom, 20)
//
//            TextField("Email", text: $email)
//                .textInputAutocapitalization(.never)
//                .autocorrectionDisabled(true)
//                .padding()
//                .background(Color(.systemGray6))
//                .cornerRadius(5.0)
//                .padding(.bottom, 20)
//
//            TextField("Username", text: $username)
//                .textInputAutocapitalization(.never)
//                .autocorrectionDisabled(true)
//                .padding()
//                .background(Color(.systemGray6))
//                .cornerRadius(5.0)
//                .padding(.bottom, 20)
//
//            SecureField("Password", text: $password)
//                .autocorrectionDisabled(true)
//                .padding()
//                .background(Color(.systemGray6))
//                .cornerRadius(5.0)
//                .padding(.bottom, 20)
//
//            SecureField("Confirm Password", text: $confirmPassword)
//                .autocorrectionDisabled(true)
//                .padding()
//                .background(Color(.systemGray6))
//                .cornerRadius(5.0)
//                .padding(.bottom, 20)
//
//            if showError {
//                Text(errorMessage)
//                    .foregroundColor(.red)
//                    .padding(.bottom, 10)
//            }
//
//            Button(action: {
//                // Add API call for sign up functionality
//                self.signUp()
//            }) {
//                Text("Sign Up")
//                    .frame(minWidth: 0, maxWidth: .infinity)
//                    .padding()
//                    .background(Color.blue)
//                    .foregroundColor(.white)
//                    .cornerRadius(5.0)
//            }
//            .padding(.bottom, 10)
//
//            NavigationLink(destination: LoginPage()) {
//                Text("Already have an account? Log In")
//                    .foregroundColor(.blue)
//            }
//        }
//        .padding()
//    }
//
//    func signUp() {
//        // Add API call for sign up functionality
//        // Validate inputs and set showError and errorMessage accordingly
//        guard !firstName.isEmpty, !lastName.isEmpty, !email.isEmpty, !username.isEmpty, !password.isEmpty, !confirmPassword.isEmpty else {
//            showError = true
//            errorMessage = "Please fill in all fields."
//            return
//        }
//
//        guard password == confirmPassword else {
//            showError = true
//            errorMessage = "Passwords do not match."
//            return
//        }
//
//        // Prepare the data for the request
//        let account = Account(id: -1, first_name: firstName, last_name: lastName, username: username, password: password, email: email, xp: 0, friends: [], pending_requests: [], streak: 0)
//        guard let url = URL(string: "http://\(ip):8000/api/accounts/") else { return }
//
//        // Create a URLRequest and set the appropriate headers and HTTP method
//        var request = URLRequest(url: url)
//        request.httpMethod = "POST"
//        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
//        request.addValue("application/json", forHTTPHeaderField: "Accept")
//
//        // Encode the account object into JSON
//        let encoder = JSONEncoder()
//        do {
//            let jsonData = try encoder.encode(account)
//            request.httpBody = jsonData
//        } catch {
//            print("Error encoding account data: \(error)")
//            return
//        }
//
//            // Create a URLSession data task to make the API request
//        URLSession.shared.dataTask(with: request) { data, response, error in
//            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 201 else {
//                DispatchQueue.main.async {
//                    self.showError = true
//                    self.errorMessage = "Error creating account. Please try again."
//                }
//                return
//            }
//
//            DispatchQueue.main.async {
//                self.showError = false
//                self.errorMessage = ""
//                print("account created")
//
//                // Navigate back to the login screen or show a success message
//                //MainView()
//
//            }
//        }.resume()
//    }
//}
//
//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        LoginPage()
//    }
//}
