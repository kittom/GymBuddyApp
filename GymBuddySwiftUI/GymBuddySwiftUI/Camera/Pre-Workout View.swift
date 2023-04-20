//
//  Pre-Workout View.swift
//  GymBuddySwiftUI
//
//  Created by Freddie Kohn on 19/04/2023.
//

import SwiftUI

struct PreWorkout: View {
    @State private var workoutTitle: String = ""
    @State private var workoutDescription: String = ""
    //@State private var reps: [Exercise] = []
    @State private var isRecordingViewPresented: Bool = false
    @State private var creatingWorkout: Bool = false
    @AppStorage("isLoggedIn") private var isLoggedIn: Bool = false
    @AppStorage("accountId") private var accountId: Int?
    @State private var exerciseTypeRows: [ExerciseTypeRow] = []
    @State private var startTime = ""
    @State private var endTime = ""

    var body: some View {
        NavigationView {
            if !creatingWorkout {
                Button (action: {
                    creatingWorkout = true
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                    startTime = dateFormatter.string(from: Date())
                    print(startTime)
                }) {
                    Text("Start a workout")
                        .padding(.all, 10)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                }
            } else {
                VStack {
                    HStack {
                        TextField("Workout Title \(Image(systemName: "pencil"))", text: $workoutTitle)
                            .frame(width: 200)
                            .font(.system(size: 25))
                            .fontWeight(.bold)
                        Spacer()
                        Button(action: {
                            //done
                            let dateFormatter = DateFormatter()
                            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                            endTime = dateFormatter.string(from: Date())
                            print(endTime)
                            DonaldView.uploadWorkout(workout: ["account" : accountId!,
                                                               "startTime" : startTime,
                                                               "endTime" : endTime,
                                                               "title": workoutTitle == "" ? "Workout" : workoutTitle,
                                                               "description": "description goes here...",
                                                               "xp" : 20])
                            creatingWorkout = false
                        }) {
                            Text("Finish")
                                .foregroundColor(Color(.white))
                                .padding(.all, 8)
                                .background(Color(.systemBlue))
                                .cornerRadius(10)
                        }
                        Button(action: {
                            let exerciseTypeRow = ExerciseTypeRow(exerciseName: "", timestamp: Date(), exerciseReps: [])
                            exerciseTypeRows.append(exerciseTypeRow)
                        }) {
                            Image(systemName: "plus")
                                .scaledToFill()
                                .scaleEffect(1.4)
                                .padding(.all, 10)
                                .background(Color(.systemGray5))
                                .cornerRadius(10)
                        }
                    }
                    .padding(.all, 15)
                    .background(Color("icons"))
                    
                    HStack {
                        GrowingTextEditor()
                    }
                    ScrollView {
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(exerciseTypeRows.indices, id: \.self) { index in
                                ExerciseTypeRowView(exerciseTypeRowIndex: index, exerciseTypeRows: $exerciseTypeRows)
                            }
                        }
                    }
                    .padding()
                    

                    Button(action: {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                            isRecordingViewPresented = true
                        }
                    }) {
                        Text("Record")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    .padding(.all, 15)
                    
                    .sheet(isPresented: $isRecordingViewPresented) {
                        ViewControllerWrapper()
                    }
                }
            }
//            .navigationBarTitle("New Workout", displayMode: .inline)
//            .navigationBarItems(trailing: Button(action: {
//                createWorkout()
//            }) {
//                Text("Create Workout")
//            })
        }
    }
    
    func getLatestSquatFiles() -> (videoURL: URL?, csvURL: URL?) {
        let fileManager = FileManager.default
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Error: Could not find the app's documents directory")
            return (nil, nil)
        }
        
        do {
            let files = try fileManager.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil, options: [])
            let sortedFiles = files.sorted(by: { $0.lastPathComponent > $1.lastPathComponent })
            
            let videoFile = sortedFiles.first(where: { $0.pathExtension == "mov" || $0.pathExtension == "mp4" })
            let csvFile = sortedFiles.first(where: { $0.pathExtension == "csv" })
            
            return (videoFile, csvFile)
        } catch {
            print("Error: Could not get the contents of the documents directory: \(error)")
            return (nil, nil)
        }
    }
}

struct ExerciseTypeRowView: View {
    let exerciseTypeRowIndex: Int
    @Binding var exerciseTypeRows: [ExerciseTypeRow]
    @State private var reps: Int = 0
    @State private var quality: String = "unchecked"
    var timeFormatter: DateFormatter {
            let formatter = DateFormatter()
            formatter.dateFormat = "hh:mm:ss a"
            return formatter
        }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                TextField("Exercise Type", text: $exerciseTypeRows[exerciseTypeRowIndex].exerciseName)
                    .padding()
                    .background(Color(.systemGray5))
                    .cornerRadius(10)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(.systemGray2)))
//                Text(exerciseTypeRows[exerciseTypeRowIndex].exerciseName)
//                    .font(.title)
                Spacer()
                let timeString = timeFormatter.string(from: exerciseTypeRows[exerciseTypeRowIndex].timestamp)
                Text(timeString)
                    .font(.headline)
            }
            .padding(.bottom, 10)
            ForEach(exerciseTypeRows[exerciseTypeRowIndex].exerciseReps) { exerciseRep in
                HStack {
                    Text("Rep \(exerciseRep.reps)")
                    Spacer()
                    Spacer()
                    Text(exerciseRep.quality)
                        .padding(.all, 5)
                        .background(Color(exerciseRep.quality == "good" ? .green : .red).opacity(0.5))
                        .cornerRadius(10)
                    Spacer()
                    Text("\(formatDate(exerciseRep.timestamp))")
                        .font(.subheadline)
                }
                .padding(.all, 5)
                .background(Color(.systemGray5))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(.systemGray3)))
            }
            Button(action: {
                reps = reps + 1
                quality = Int.random(in: 1...5) <= 4 ? "good" : "bad"
                let exerciseRep = ExerciseRep(reps: reps, timestamp: Date(), quality: quality)
                exerciseTypeRows[exerciseTypeRowIndex].exerciseReps.append(exerciseRep)
            }) {
                Image(systemName: "plus")
                    .padding()
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
    
    func formatDate(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
//        dateFormatter.dateStyle = .medium
//        dateFormatter.timeStyle = .short
        dateFormatter.dateFormat = "hh:mm:ss a"
        return dateFormatter.string(from: date)
    }
}

struct ExerciseTypeRow: Identifiable {
    var id = UUID()
    var exerciseName: String
    var timestamp: Date
    var exerciseReps: [ExerciseRep]
}

struct ExerciseRep: Identifiable {
    var id = UUID()
    var reps: Int
    var timestamp: Date
    var quality: String
}

struct WorkoutCreation: Codable, Identifiable {
    let id: Int
    let title: String
    let startTime: String
    let reps: [Rep]
}

struct RepRow: View {
    let rep: Rep

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(rep.exerciseType)
                Text(rep.datetime)
            }

            Spacer()

            RoundedRectangle(cornerRadius: 5)
                .fill(backgroundColor(for: rep.quality))
                .frame(width: 50, height: 50)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
    }

    func backgroundColor(for quality: RepQuality) -> Color {
        switch quality {
        case .unchecked:
            return Color.gray
        case .good:
            return Color.green
        case .bad:
            return Color.red
        }
    }
}

struct Rep: Codable, Identifiable {
    let id: Int
    let exerciseType: String
    let datetime: String
    let quality: RepQuality
}

enum RepQuality: Codable {
    case unchecked
    case good
    case bad
}

struct Pre_Workout_View_Previews: PreviewProvider {
    static var previews: some View {
        PreWorkout()
    }
}

struct GrowingTextEditor: View {
    @State private var text: String = ""
    @State private var isEditing: Bool = false
    @State private var editorHeight: CGFloat = 40
    
    private let maxLength: Int = 140
    private let minHeight: CGFloat = 40
    private let maxHeight: CGFloat = 100
    
    var body: some View {
        VStack {
            ZStack(alignment: .leading) {
                if text.isEmpty && !isEditing {
                    Text("Start typing...")
                        .foregroundColor(Color(.placeholderText))
                        .padding(.leading, 10)
                }
                TextEditor(text: $text)
                    .onChange(of: text) { value in
                        if text.count > maxLength {
                            text = String(text.prefix(maxLength))
                        }
                        updateHeight()
                    }
                    .onTapGesture {
                        isEditing = true
                    }
                    .frame(minHeight: editorHeight, maxHeight: maxHeight)
                    .padding(.leading, 5)
                    .background(Color(.systemBackground))
                    //.overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(.black)))
            }
            .frame(minHeight: minHeight, maxHeight: maxHeight)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .padding()
            .shadow(radius: 4, x: -2, y: 2)
            .onAppear(perform: updateHeight)
        }.overlay(!isEditing ? Text("Enter Description") : Text(""))
    }
    
    private func updateHeight() {
        let newSize = CGSize(width: UIScreen.main.bounds.width - 32, height: CGFloat.infinity)
        let currentHeight = text.height(containerWidth: newSize.width)
        editorHeight = max(minHeight, min(currentHeight, maxHeight))
    }
}

extension String {
    func height(containerWidth: CGFloat) -> CGFloat {
        let font = UIFont.systemFont(ofSize: 17)
        let constraintBox = CGSize(width: containerWidth, height: .greatestFiniteMagnitude)
        let boundingBox = self.boundingRect(with: constraintBox, options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: [.font: font], context: nil)
        
        return boundingBox.height
    }
}
