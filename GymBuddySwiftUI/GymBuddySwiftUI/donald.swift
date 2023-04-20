//
//  donald.swift
//  GymBuddySwiftUI
//
//  Created by Freddie Kohn on 18/04/2023.
//

import SwiftUI

import SwiftUI
import PhotosUI

struct DonaldView: View {
    @State private var showImagePicker = false
    @State private var showFileUploader = false
    @State private var videoURL: URL? = nil
    
    var body: some View {
        VStack {
            Button("Upload Account") {
                uploadAccount()
            }
            .padding()
            
            Button("Select Video") {
                showImagePicker.toggle()
            }
            .padding()
            .sheet(isPresented: $showImagePicker) {
                VideoPicker(isShown: $showImagePicker, videoURL: $videoURL)
                    .ignoresSafeArea()
            }
            
            Button("Upload Workout") {
                //DonaldView.uploadWorkout()
            }
            .padding()
            
        }
    }
    
    static func uploadVideo(_ videoURL: URL) {
        //turning the video url into video file
        guard let videoData = try? Data(contentsOf: videoURL) else {
            print("Failed to read video file")
            return
        }
        
        
        
        let urlString = "http://\(ip):8000/api/exercise/"
        let url = URL(string: urlString)!
        let boundary = UUID().uuidString
        
        
        
        
        //getting the url string from the local file felix use file maneger so u might have to delete this
//        guard let csvURL = Bundle.main.url(forResource: "test_squat", withExtension: "csv") else {
//            print("CSV file not found")
//            return
//        }
        let csvURL = globalCsvURL!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"account\"\r\n\r\n".data(using: .utf8)!)
        body.append("1\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"exercise_type\"\r\n\r\n".data(using: .utf8)!)
        body.append("squat\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"datetime\"\r\n\r\n".data(using: .utf8)!)
        body.append("2023-03-10 13:48:41\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"video_file\"; filename=\"video.mov\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: video/quicktime\r\n\r\n".data(using: .utf8)!)
        //  let videoData = try Data(contentsOf: videoFileURL)
        body.append(videoData)
        
        body.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"csv_file\"; filename=\"data.csv\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: text/csv\r\n\r\n".data(using: .utf8)!)
        do {
            //turning csv url into csv file
            let csvData = try Data(contentsOf: csvURL)
            body.append(csvData)
            body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        } catch let error {
            print("Error reading CSV data: \(error.localizedDescription)")
        }
        
        body.append("Content-Disposition: form-data; name=\"quality\"\r\n\r\n".data(using: .utf8)!)
        body.append("unchecked\r\n".data(using: .utf8)!)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        
        let session = URLSession.shared
        let task = session.uploadTask(with: request, from: body) { data, response, error in
            
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("Invalid response")
                return
            }
            if httpResponse.statusCode == 200 {
                print("Video uploaded successfully")
            } else {
                print("Error uploading video: \(httpResponse.statusCode)")
            }
            
        }
        task.resume()
    }
    
    func uploadAccount() {
        let data = ["first_name": "felix","last_name": "berns","username": "fb","password": "fb1234","email": "fb123@gmail.com"] as [String : Any]
        guard let jsonData = try? JSONSerialization.data(withJSONObject: data, options: [])else{
            print("Failed to convert to jsonfile")
            return
        }
        let url = URL(string: "http://\(ip):8000/api/accounts/")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let session = URLSession.shared
        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                return
            }
            
            if let response = response as? HTTPURLResponse {
                print("Status code: \(response.statusCode)")
                if response.statusCode == 500{
                    print("server side error, accounts most likely exist")
                }
            }
            
        }
        
        task.resume()
    }
    
    static func uploadWorkout(workout: [String: Any]) {
        let data = workout
        //convert into json file
        guard let jsonData = try? JSONSerialization.data(withJSONObject: data, options: [])else{
            print("Failed to convert to jsonfile")
            return
        }
        let url = URL(string: "http://\(ip):8000/api/workouts/")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let session = URLSession.shared
        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                return
            }
            
            if let response = response as? HTTPURLResponse {
                print("Status code: \(response.statusCode)")
                if response.statusCode == 500{
                    print("server side error, accounts most likely exist")
                }
            }
            
        }
        
        task.resume()
    }
}

struct VideoPicker: UIViewControllerRepresentable {
    @Binding var isShown: Bool
    @Binding var videoURL: URL?
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.mediaTypes = ["public.movie"]
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: VideoPicker
        
        init(parent: VideoPicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let url = info[.mediaURL] as? URL {
                parent.videoURL = url
            }
            parent.isShown = false
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.isShown = false
        }
    }
}

struct DonaldView_Previews: PreviewProvider {
    static var previews: some View {
        DonaldView()
    }
}
