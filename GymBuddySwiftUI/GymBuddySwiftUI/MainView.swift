//
//  SwiftUIViewTester.swift
//  GymBuddySwiftUI
//
//  Created by Freddie Kohn on 13/03/2023.
//

import SwiftUI
import AVFoundation
import Foundation
import Combine


struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}

struct MainView: View {
    init() {
        // Customize the appearance of the tab bar
        UITabBar.appearance().barTintColor = UIColor.blue
        UITabBar.appearance().unselectedItemTintColor = UIColor.black
        UITabBar.appearance().backgroundColor = UIColor.darkGray
        UITabBar.appearance().shadowImage = UIImage()
        UITabBar.appearance().backgroundImage = UIImage()
    }
    
    
    @State private var selection = 0
    
    
    var body: some View {
        
        TabView(selection: $selection) {
            homePage(selection: $selection)
                .tabItem {
                    Image(systemName: "house")
                    Text("Home")
                }
                .tag(0)
            
            // Second tab
            FriendsView()
                .tabItem {
                    Image(systemName: "person.3")
                    Text("Social")
                }
                .tag(1)
            
            // Third tab
            PreWorkout()//ViewControllerWrapper()
                .tabItem {
                    Image(systemName: "camera")
                    Text("FormAR")
                }
                .tag(2)
            
            // Fourth tab
            LeaderboardView()
                .tabItem {
                    Image(systemName: "chart.bar")
                    Text("Leaderboard")
                }
                .tag(3)
            
            // Fifth tab
            UserProfileView()
                .tabItem {
                    Image(systemName: "person")
                    Text("Profile ")
                }
                .tag(4)
        }
    }
}



struct ViewControllerWrapper: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> ViewController {
        let ViewController = ViewController()
        return ViewController
    }
    
    func updateUIViewController(_ uiViewController: ViewController, context: Context) {
        // Update the view controller here if needed
    }
    
    typealias UIViewControllerType = ViewController
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject {
        let parent: ViewControllerWrapper
        
        init(_ parent: ViewControllerWrapper) {
            self.parent = parent
        }
    }
}

public struct apiUser: Identifiable, Hashable {
    public let id = UUID()
    let first_name: String
    let last_name: String
    let username: String
    let password: String
    let email: String
    let xp: Int
}

struct apiExercise: Identifiable, Hashable {
    let id = UUID()
    let exercise_type: String
    let datetime: String
    var quality: String = "unchecked"
}

struct apiWorkout: Identifiable, Hashable {
    let id = UUID()
    let account: Int
    let startTime: String
    let endTime: String
}

//public var mainAccount: Account = Account(id: 0, first_name: "", last_name: "", username: "", password: "", email: "", xp: 0, streak: 0)
