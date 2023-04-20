//
//  ExerciseView.swift
//  GymBuddySwiftUI
//
//  Created by Freddie Kohn on 16/04/2023.
//

import SwiftUI

struct ExerciseView: View {
    @State private var exercises: [Exercise] = []
    @State private var exerciseTypeRows: [ExerciseTypeRow] = []
    
    let workout: Workout

    var body: some View {
        ZStack {
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
        }.background(Color("background"))
            .navigationTitle("\(workout.title)")
            .toolbarBackground(Color("background"))
            //.navigationBarHidden(true)
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

