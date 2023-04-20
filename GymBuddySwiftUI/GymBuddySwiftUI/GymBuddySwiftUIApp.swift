//
//  GymBuddySwiftUIApp.swift
//  GymBuddySwiftUI
//
//  Created by Freddie Kohn on 12/03/2023.
//

import SwiftUI

@main
struct GymBuddySwiftUIApp: App {
    let persistenceController = PersistenceController.shared
    @AppStorage("isLoggedIn") private var isLoggedIn: Bool = false

    var body: some Scene {
        WindowGroup {
            if isLoggedIn {
                MainView()
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
            } else {
                LoginPage()
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
            }
        }
    }
}


public let ip = "192.168.0.126"
//public var accounts: [Account] = []
public var globalVideoURL = URL(string: "")
public var globalCsvURL = URL(string: "")

public var mainAccount: Account = Account(id: 0, first_name: "", last_name: "", username: "", password: "", email: "", xp: 0, friends: [], pending_requests: [], streak: 0)


//public var exercises: [Exercise] = []
//public var workouts: [Workout] = []

//struct Functions {
//
//    @AppStorage("accountId") var accountId: Int?
//
//
//}

struct Exercise: Codable, Identifiable {
    let id: Int
    let exercise_type: String
    let datetime: String
    let account: Int
    let quality: String
    let video_file: String
    let csv_file: String
}

func uploadExerciseData(accountId: Int, exerciseType: String, datetime: String, videoURL: URL, csvURL: URL, completion: @escaping (Result<Exercise, Error>) -> Void) {
    let uploadURL = URL(string: "http://\(ip):8000/api/exercise/")!
    
    var request = URLRequest(url: uploadURL)
    request.httpMethod = "POST"
    
    let boundary = "Boundary-\(UUID().uuidString)"
    request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
    
    let videoData = try? Data(contentsOf: videoURL)
    let csvData = try? Data(contentsOf: csvURL)
    
    guard let videoFileData = videoData, let csvFileData = csvData else {
        print("Error: Unable to read file data")
        return
    }
    
    var body = Data()
    
    let params = [
        "account": String(accountId),
        "exercise_type": exerciseType,
        "datetime": datetime
    ]
    
    for (key, value) in params {
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(value)\r\n".data(using: .utf8)!)
    }
    
    let videoFilename = videoURL.lastPathComponent
    let csvFilename = csvURL.lastPathComponent
    
    body.append("--\(boundary)\r\n".data(using: .utf8)!)
    body.append("Content-Disposition: form-data; name=\"video_file\"; filename=\"\(videoFilename)\"\r\n".data(using: .utf8)!)
    body.append("Content-Type: video/quicktime\r\n\r\n".data(using: .utf8)!)
    body.append(videoFileData)

    body.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
    body.append("Content-Disposition: form-data; name=\"csv_file\"; filename=\"\(csvFilename)\"\r\n".data(using: .utf8)!)
    body.append("Content-Type: text/csv\r\n\r\n".data(using: .utf8)!)
    body.append(csvFileData)
    
    body.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
    body.append("Content-Disposition: form-data; name=\"quality\"\r\n\r\n".data(using: .utf8)!)
    body.append("unchecked\r\n".data(using: .utf8)!)
    body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
    
    request.httpBody = body
    print(body)
    
    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            DispatchQueue.main.async {
                completion(.failure(error))
            }
            return
        }
        
        if let data = data {
            do {
                let decodedData = try JSONDecoder().decode(Exercise.self, from: data)
                DispatchQueue.main.async {
                    completion(.success(decodedData))
                }
            } catch let decodingError {
                DispatchQueue.main.async {
                    completion(.failure(decodingError))
                }
            }
        }
    }
    task.resume()
}

public struct Account: Codable, Identifiable {

    public let id: Int

    let first_name: String

    let last_name: String

    let username: String

    let password: String

    let email: String
    
    let xp: Int
    
    let friends: [FriendAccount] //[Friend]
    
    let pending_requests: [AccountSearch]
    
    let streak: Int

}

struct FriendAccount: Codable {
    let account: AccountSearch
}

struct AccountSearch: Codable, Identifiable {

    let id: Int

    let first_name: String

    let last_name: String

    let username: String

    let password: String

    let email: String
    
    let xp: Int

}

struct Friend: Codable, Identifiable {
    let id: Int
    let account: AccountSearch
}

struct Workout: Codable, Identifiable {
    let id: Int
    let account: Int
    let startTime: String
    let endTime: String
    let title: String
    let description: String
    let xp: Int

    enum CodingKeys: String, CodingKey {
        case id
        case account
        case startTime = "startTime"
        case endTime = "endTime"
        case title
        case description
        case xp
    }
}
