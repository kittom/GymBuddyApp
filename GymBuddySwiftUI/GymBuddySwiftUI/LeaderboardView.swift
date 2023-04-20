//
//  LeaderboardView.swift
//  GymBuddySwiftUI
//
//  Created by Freddie Kohn on 08/04/2023.
//

import SwiftUI

struct LeaderboardView: View {
    @State private var selectedLeague = 0
    let leagues = ["Beginner", "Intermediate", "Advanced", "Elite"]
    @State private var users: [AccountSearch] = []
    @StateObject private var leaderboardAPI = LeaderboardAPI()

    var body: some View {
        NavigationView {
            VStack {
                Text("Gym Leaderboard")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(Color("GymGreen"))

                Picker("League", selection: $selectedLeague) {
                    ForEach(0..<4) { index in
                        Text(leagues[index]).tag(index)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        ForEach(users) { user in
                                                    LeaderboardRow(user: user, rank: users.firstIndex(where: { $0.id == user.id })! + 1)
                                                }
                    }
                    .padding(.horizontal)
                }

                Spacer()
            }
            .onAppear(perform: {
                leaderboardAPI.fetchLeaderboard { fetchedUsers in
                    users = fetchedUsers
                }
            })
            .navigationBarTitleDisplayMode(.inline)
            .background(Color("BackgroundGray").edgesIgnoringSafeArea(.all))
        }
    }
}

struct LeaderboardRow: View {
    let user: AccountSearch
    let rank: Int

    var body: some View {
        HStack {
            Text("\(rank)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Color("GymGreen"))

            VStack(alignment: .leading) {
                            Text("\(user.first_name) \(user.last_name)")
                                .font(.headline)
                                .fontWeight(.semibold)

                            HStack {
                                Text("XP: \(user.xp)")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)

                                Spacer()

                                // Assuming you have a function to calculate user levels based on XP
                                Text("Level \(1 + Int(floor(Double(user.xp)/100)))")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                        }
            .padding(.leading)

            Spacer()

            ZStack {
                Circle()
                    .fill(Color("GymGreen"))
                    .frame(width: 50, height: 50)

                Text("\(rank)")
                    .foregroundColor(.white)
                    .fontWeight(.bold)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 2)
    }
}

class LeaderboardAPI: ObservableObject {
    func fetchLeaderboard(completion: @escaping ([AccountSearch]) -> ()) {
        guard let url = URL(string: "http://\(ip):8000/api/leaderboard") else { return }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data {
                let decoder = JSONDecoder()

                if let leaderboard = try? decoder.decode([AccountSearch].self, from: data) {
                    DispatchQueue.main.async {
                        completion(leaderboard)
                    }
                }
            }
        }.resume()
    }
}

struct LeaderboardView_Previews: PreviewProvider {
    static var previews: some View {
        LeaderboardView()
    }
}
