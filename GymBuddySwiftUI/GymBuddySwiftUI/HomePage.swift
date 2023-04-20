//
//  HomePage.swift
//  GymBuddySwiftUI
//
//  Created by Freddie Kohn on 08/04/2023.
//

import SwiftUI

struct homePage: View {
    @Binding var selection: Int
    @AppStorage("isLoggedIn") private var isLoggedIn: Bool = false
    
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .center) {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .center, spacing: 25) {
                        Button(action: {
                            selection = 2
                        }) {
                            RoundedRectangle(cornerRadius: 25)
                                .fill(LinearGradient(gradient: Gradient(
                                    colors: [Color("tabs"), Color("background").opacity(0.75)]),
                                                     startPoint: UnitPoint(x: 0, y: 0.5),
                                                     endPoint: UnitPoint(x: 0.4, y: 0.5))
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .shadow(color: .black, radius: 2, x: -3, y: 5)
                                .frame(maxWidth: .infinity, minHeight: 100)
                                .overlay(
                                    Text("Get Started")
                                        .font(.system(size: 40, weight: .bold))
                                        .padding()
                                        .foregroundColor(Color("accent"))
                                )
                        }
                        
                        Friends()
                        
                        LeaderboardOverview()
                        
//                        RoundedRectangle(cornerRadius: 10)
//                            .fill(Color("buttons"))
//                            .shadow(color: .black, radius: 2, x: -3, y: 5)
//                            .frame(maxWidth: .infinity, maxHeight: .infinity * 0.2)
//                            .overlay(Text("Tab 4")
//                                .foregroundColor(Color("accent"))
//                            )
                    }
                    .padding(.vertical, 90)
                    .padding(.horizontal, 10)
                }
                .background(Color("background"))
                .clipShape(RoundedRectangle(cornerRadius: 30))
                .overlay(
                    RoundedRectangle(cornerRadius: 30)
                        .stroke(Color("background"), lineWidth: 2)
                        .shadow(color: .black, radius: 2, x: 0, y: 5)
                        .clipShape(
                            RoundedRectangle(cornerRadius: 15)
                        )
                )
            }
            .background(Color("inputs"))
            .overlay(
//                Button(action: {
//                    appStorageManager.logout()
//                }) {
                    GeometryReader { proxy in
                        Text("Home")
                            .font(.title)
                            .foregroundColor(Color("accent"))
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(LinearGradient(gradient: Gradient(
                                        colors: [Color("tabs"), Color("background").opacity(0.5)]),
                                                         startPoint: UnitPoint(x: 0, y: 0.5),
                                                         endPoint: UnitPoint(x: 1, y: 0.5))
                                         )
                                    .frame(width: 100, height: 40)
                                    .shadow(radius: 2, x: -3, y: 3)
                            )
                            .position(x: proxy.safeAreaInsets.leading + 70, y: proxy.safeAreaInsets.top - 10)
                    }
//                }
            )
        }//.fullScreenCover(isPresented: appStorageManager.isLoggedIn) {
            //LoginPage()
        //}
    }
}

struct Friends: View {
    @State private var users: [AccountSearch] = []
    @State private var workouts: [Workout] = []
    @StateObject private var friendsAPI = FriendsAPI()
    var body: some View {
        VStack(alignment: .center, spacing: 15) {
            Text("Friends")
                .font(.system(size: 30, weight: .bold))
                .foregroundColor(Color("accent"))
                .padding(.horizontal, -20)
                .padding(.top)
            Text("See what everyone's been getting up to...")
                .font(.system(size: 18))
                .foregroundColor(Color("accent"))
                .padding(.horizontal, -10)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(users) { user in
                        if let workout = workouts.first(where: { $0.account == user.id }) {
                            friendCard(username: user.username, time: 2.4, workout: workout) // You should calculate the time based on the workout data
                        }
                    }
//                    friendCard(username: "Cbum", time: 2.4)
//                    friendCard(username: "Arnold",pfp: "person.fill", time: 3.1)
//                    friendCard(username: "Zyzz",pfp: "person.fill", time: 6.8)
//                    friendCard(username: "Freddie",pfp: "person.fill", time: 9.3)
                }
            }
            .onAppear(perform: {
                        friendsAPI.fetchFriends { fetchedUsers, fetchedWorkouts in
                            users = fetchedUsers
                            workouts = fetchedWorkouts
                        }
                    })
            .background(Color("background").opacity(0.8))
            .cornerRadius(10)
            .padding(.bottom, 15)
            .padding(.horizontal, 15)
            
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity * 0.4)
        .background(RoundedRectangle(cornerRadius: 25)
            .fill(LinearGradient(gradient: Gradient(
                colors: [Color("tabs"), Color("background").opacity(0.75)]),
                                 startPoint: UnitPoint(x: 0, y: 0.5),
                                 endPoint: UnitPoint(x: 0.4, y: 0.5))
            )
            .shadow(color: .black, radius: 2, x: -3, y: 5))
    }
}

struct friendCard: View {
    let username: String
    var pfp: String? = "person.fill"
    let time: Float
    var workout: Workout = Workout(id: 100, account: 3, startTime: "", endTime: "", title: "", description: "", xp: 0)

    var body: some View {
        
        NavigationLink(destination: DetailView(username: username, workout: workout)) {
            VStack(spacing: 8) {
                // Title
                Text(username)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color("accent"))
                
                // Image
                Image(systemName: pfp!)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .foregroundColor(Color("accent"))
                
                // Timestamp label
                Text(String(time) + " hrs ago")
                    .font(.subheadline)
                    .foregroundColor(Color("text"))
            }
            .padding()
            .background(RadialGradient(gradient: Gradient(
                colors: [Color("background"), Color("buttons")]),
                                       center: .center,
                                       startRadius: 40,
                                       endRadius: 80))
            .overlay(RoundedRectangle(cornerRadius:10).stroke(Color("text").opacity(0.4)))
            .cornerRadius(10)
            .shadow(color: Color("background"), radius: 2, x: 0, y: 2)
        }
    }
}

class FriendsAPI: ObservableObject {
    
    @AppStorage("accountId") private var accountId: Int?
    
    func fetchFriends(completion: @escaping ([AccountSearch], [Workout]) -> ()) {
        let accountURL = URL(string: "http://\(ip):8000/api/account/\(accountId!)")
        //var workoutsURL = URL(string: "http://\(ip):8000/api/workouts/")
        
        let group = DispatchGroup()
        var users: [AccountSearch] = []
        var workouts: [Workout] = []
        
        group.enter()
        URLSession.shared.dataTask(with: accountURL!) { data, response, error in
            if let data = data {
                let decoder = JSONDecoder()
                do {
                    let fetchedAccount = try decoder.decode(Account.self, from: data)
                    users = fetchedAccount.friends.map { $0.account }
                    print(users)
                        // Fetch workouts for each friend
                    for user in users {
                        group.enter()
                        let friendWorkoutsURL = URL(string: "http://\(ip):8000/api/workouts/\(user.id)")
                        
                        URLSession.shared.dataTask(with: friendWorkoutsURL!) { data, response, error in
                            if let data = data {
                                let decoder = JSONDecoder()
                                if let fetchedWorkouts = try? decoder.decode([Workout].self, from: data) {
                                    workouts += fetchedWorkouts
                                    print(workouts)
                                }
                            }
                            group.leave()
                        }.resume()
                    }
                } catch let error {
                    print("Error decoding Account:", error)
                }
            }
            group.leave()
        }.resume()
        
        group.notify(queue: .main) {
            completion(users, workouts)
        }
    }
}



struct DetailView: View {
    let username: String
    var workout: Workout
    @State var isShowingWorkout: Bool = false
    @State private var exerciseTypeRows: [ExerciseTypeRow] = []

    var body: some View {
        VStack() {
            VStack(alignment: .center, spacing: 5) {
                
                HStack {
                    Text(username + "'s workout")
                        .font(.title)
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(Color("accent"))
                        .padding(.horizontal)
                        .padding(.bottom)
                }
                
                HStack {
                    
                    HStack {
                        Image(systemName: "clock")
                            .foregroundColor(Color("GymGreen"))
                        
//                        Text("\(workout.duration) min")
//                            .foregroundColor(Color("background"))
                    }
                    .padding(.horizontal)
                    .frame(height: 30)
                    .background(RoundedRectangle(cornerRadius: 25)
                        .fill(Color("icons")))
                    
                    HStack {
                        Image(systemName: "flame")
                            .foregroundColor(Color(.red))
                        
//                        Text("\(workout.caloriesBurned) xp")
//                            .foregroundColor(Color("background"))
                    }
                    .padding(.horizontal)
                    .frame(height: 30)
                    .background(RoundedRectangle(cornerRadius: 25)
                        .fill(Color("icons")))
                    
                }
                
            }
            .padding(.vertical)
            .padding(.horizontal)
            .background(RoundedRectangle(cornerRadius: 25)
                .fill(LinearGradient(gradient: Gradient(
                colors: [Color("tabs"), Color("background").opacity(0.75)]),
                                 startPoint: UnitPoint(x: 0, y: 0.5),
                                 endPoint: UnitPoint(x: 0.4, y: 0.5))
            ))
            .overlay(RoundedRectangle(cornerRadius:25).stroke(Color(.white).opacity(0.5)))

            VStack {
                HStack() {
                    Text("Exercises:")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(Color("text"))
                        .padding(EdgeInsets(top: 5, leading: 10, bottom: 5, trailing: 10))
                        .background(RoundedRectangle(cornerRadius: 15).fill(Color("inputs")))
                        .padding(.horizontal)
                    Spacer()
                }
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        ForEach(0..<exerciseTypeRows.count, id: \.self) { index in
                            ExerciseTypeRowView(exerciseTypeRowIndex: index, exerciseTypeRows: $exerciseTypeRows)
                        }
                    }
                    .padding()
                }
                .background(RoundedRectangle(cornerRadius: 25)
                    .fill(LinearGradient(gradient: Gradient(
                        colors: [Color("tabs"), Color("background").opacity(0.75)]),
                                         startPoint: UnitPoint(x: 0.5, y: 0),
                                         endPoint: UnitPoint(x: 0.5, y: 0.7))))
                .clipShape(RoundedRectangle(cornerRadius: 30))
                .onAppear() {
                    fetchExercises()
                }
                    //FriendWorkoutRow(friend: Friend(name: "John Doe", workout: Workout(exerciseName: "Bench Press", sets: 4, reps: 8, weight: 185, date: "2023-04-01", duration: 60, caloriesBurned: 350, notes: "Felt strong today."))).padding(.horizontal)
                
            }
            .padding(EdgeInsets(top: 10, leading: 0, bottom: 0, trailing: 10))
            .background(RoundedRectangle(cornerRadius: 25).fill(LinearGradient(gradient: Gradient(
                colors: [Color("icons"), Color("buttons").opacity(0.75)]),
                                 startPoint: UnitPoint(x: 0, y: 0.5),
                                 endPoint: UnitPoint(x: 0.4, y: 0.5))))
            .padding()
            .navigationTitle("Workout Details")
        }
        .background(Color("background"))
        .font(.headline)
        .navigationBarTitle("")
    }
    func fetchExercises() {
        guard let url = URL(string: "http://\(ip):8000/api/exercises_by_workout/\(workout.id)") else { return }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                // Handle error
                return
            }
            
            let decoder = JSONDecoder()
            do {
                let fetchedExercises = try decoder.decode([Exercise].self, from: data)
                
                DispatchQueue.main.async {
                    let groupedExercises = Dictionary(grouping: fetchedExercises, by: { $0.exercise_type })
                    exerciseTypeRows = groupedExercises.map { (exerciseType, exercises) -> ExerciseTypeRow in
                        let reps = exercises.map { ExerciseRep(reps: $0.id, timestamp: ISO8601DateFormatter().date(from: $0.datetime)!, quality: $0.quality) }
                        return ExerciseTypeRow(exerciseName: exerciseType, timestamp: reps.first?.timestamp ?? Date(), exerciseReps: reps)
                    }
                }
            } catch {
                // Handle error
                print("Could not fetch exercises. Error: \(error)")
            }
        }.resume()
    }
}


struct LeaderboardOverview: View {
    @State private var users: [AccountSearch] = []
    @StateObject private var leaderboardAPI = LeaderboardAPI()

    var body: some View {
        VStack(alignment: .center, spacing: 15) {
            Text("Top Gym Buddies")
                .font(.system(size: 30, weight: .bold))
                .foregroundColor(Color("accent"))
                .padding(.horizontal, -20)
                .padding(.top)
            Text("Meet the high achievers...")
                .font(.system(size: 18))
                .foregroundColor(Color("accent"))
                .padding(.horizontal, -10)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(users.prefix(5)) { user in
                        leaderboardOverviewCard(user: user, rank: users.firstIndex(where: { $0.id == user.id })! + 1)
                    }
                }
            }
            .onAppear(perform: {
                leaderboardAPI.fetchLeaderboard { fetchedUsers in
                    users = fetchedUsers
                }
            })
            .background(Color("background").opacity(0.8))
            .cornerRadius(10)
            .padding(.bottom, 15)
            .padding(.horizontal, 15)

        }
        .frame(maxWidth: .infinity, maxHeight: .infinity * 0.4)
        .background(RoundedRectangle(cornerRadius: 25)
            .fill(LinearGradient(gradient: Gradient(
                colors: [Color("tabs"), Color("background").opacity(0.75)]),
                                 startPoint: UnitPoint(x: 0, y: 0.5),
                                 endPoint: UnitPoint(x: 0.4, y: 0.5))
            )
            .shadow(color: .black, radius: 2, x: -3, y: 5))
    }
}

struct leaderboardOverviewCard: View {
    let user: AccountSearch
    let rank: Int

    var body: some View {
        VStack(spacing: 8) {
            Text("\(rank)")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Color("accent"))

            Image(systemName: "person.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
                .foregroundColor(Color("accent"))

            Text("\(user.first_name) \(user.last_name)")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color("accent"))

            Text("Level \(1 + Int(floor(Double(user.xp)/100)))")
                .font(.subheadline)
                .foregroundColor(Color("text"))
        }
        .padding()
        .background(RadialGradient(gradient: Gradient(
            colors: [Color("background"), Color("buttons")]),
                                   center: .center,
                                   startRadius: 40,
                                   endRadius: 80))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color("text").opacity(0.4)))
        .cornerRadius(10)
        .shadow(color: Color("background"), radius: 2, x: 0, y: 2)
    }
}


//struct HomePage_Previews: PreviewProvider {
//
//    private var selection = 0
//
//    static var previews: some View {
//        //DetailView(username: "Chickohn", workout: Workout)
//        homePage()
//    }
//}
