//
//  ProfileView.swift
//  GymBuddySwiftUI
//
//  Created by Freddie Kohn on 08/04/2023.
//

import SwiftUI
import Foundation

struct UserProfileView: View {
    @AppStorage("accountId") private var accountId: Int?
    @AppStorage("isLoggedIn") private var isLoggedIn: Bool = false
    @State private var account: Account?

    var body: some View {
        NavigationView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        Image(systemName: "person.fill")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                            .shadow(radius: 10)
                            .scaleEffect(1.1)
                            .padding(.leading)
                            //.animation(Animation.easeInOut(duration: 0.5).delay(0.5))
                        
                        VStack(alignment: .leading) {
                            Text(account?.username ?? "")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(Color("accent"))

                            Text("\(account?.first_name ?? "") \(account?.last_name ?? "")")
                                .font(.headline)
                                .foregroundColor(Color("text"))
                            
                            HStack {
                                Text("Level: \(1 + Int(floor(Double(account?.xp ?? 0)/100)))")
                                    .font(.headline)
                                    .foregroundColor(Color("text"))
                                
                                ZStack(alignment: .leading) {
                                    Capsule()
                                        .frame(width: 125, height: 10)
                                        .foregroundColor(.gray)
                                    Capsule()
                                        .frame(width: CGFloat((account?.xp ?? 0)%100) * 1.25, height: 10)
                                        .foregroundColor(.green)
                                        //.animation(.linear(duration: 0.1))
                                }
                                
                                Image(systemName: "flame")
                                
                                Text("\(account?.streak ?? 0)")
                                    .foregroundColor(Color("text"))
                                    .offset(x: -5)
                            }
                        }
                        .padding(.leading)
                        
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top)
                    .padding(.bottom)
                    .background(RoundedRectangle(cornerRadius: 25)
                        .fill(LinearGradient(gradient: Gradient(
                            colors: [Color("tabs"), Color("background").opacity(0.25)]),
                                             startPoint: UnitPoint(x: 0, y: 0.5),
                                             endPoint: UnitPoint(x: 1, y: 0.5))
                        ))
                    .overlay(RoundedRectangle(cornerRadius: 25).stroke(Color("text")))
                    //.clipShape(RoundedRectangle(cornerRadius:15))

                    Text("Recent Workouts")
                        .font(.title)
                        .fontWeight(.bold)
                        .padding(.top)
                        .foregroundColor(Color("accent"))
                    
                    RecentWorkouts()
                    
            }
//            .navigationBarItems(trailing:
//                                    Button("Refetch account info") {
//                fetchAccountInfo()
//                //print(accountId!)
//                print(account ?? "none")
//            }.foregroundColor(Color("accent")).padding(3).background(Color("icons")).clipShape(RoundedRectangle(cornerRadius:15)).padding()
//            )
            .padding()
            .background(Color("background"))
            .onAppear {
                fetchAccountInfo()
            }
        }
    }
    
    func fetchAccountInfo() {
        guard let url = URL(string: "http://\(ip):8000/api/account/\(accountId!)") else { return }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                // Handle error
                return
            }
            
            let decoder = JSONDecoder()
            do {
                let fetchedAccount = try decoder.decode(Account.self, from: data)
                DispatchQueue.main.async {
                    account = fetchedAccount
                }
            } catch {
                // Handle error
                print("Could not fetch account")
            }
        }.resume()
    }
}

struct RecentWorkouts: View {
    @AppStorage("isLoggedIn") private var isLoggedIn: Bool = false
    @AppStorage("accountId") private var accountId: Int?
    @State private var workouts: [Workout] = []

    var body: some View {
        ScrollView {
            VStack {
                ForEach(workouts) { workout in
                    // Output workout info here
                    WorkoutRows(workout: workout)
                }
            }
        }
        .onAppear() {
            fetchWorkouts()
        }
    }

    func fetchWorkouts() {
        guard let url = URL(string: "http://\(ip):8000/api/workouts/\(accountId ?? 1)/") else { return }

        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                // Handle error
                print("first error")
                return
            }

            let decoder = JSONDecoder()
            do {
                let fetchedWorkouts = try decoder.decode([Workout].self, from: data)
                DispatchQueue.main.async {
                    workouts = fetchedWorkouts
                }
            } catch {
                // Handle error
                print("Couldn't decode workouts \n\(error)")
            }
        }.resume()
    }
}


struct WorkoutRows: View {
    let workout: Workout

    var body: some View {
        NavigationLink(destination: ExerciseView(workout: workout)) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("\(workout.title)")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(Color("accent"))
                        
                        Spacer()
                        
                        Text("\(String(workout.startTime.prefix(16).suffix(5)))")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(Color("text"))
                    }
                    
                    Text("\(workout.description)")
                        .font(.subheadline)
                        .foregroundColor(Color("text"))
                    
                    if let startTime = ISO8601DateFormatter().date(from: workout.startTime),
                       let endTime = ISO8601DateFormatter().date(from: workout.endTime) {
                        let duration = endTime.timeIntervalSince(startTime) / 60
                        Text("\(duration, specifier: "%.0f") minutes")
                            .font(.subheadline)
                            .foregroundColor(Color("text"))
                    }
                }
                Spacer()
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 10)
                .fill(LinearGradient(gradient: Gradient(
                    colors: [Color("tabs"), Color("buttons").opacity(0.5)]),
                                     startPoint: UnitPoint(x: 0, y: 0.5),
                                     endPoint: UnitPoint(x: 0.7, y: 0.5))
                     ))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color("text")))
            .cornerRadius(10)
            .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 2)
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        UserProfileView()
    }
}
