//
//  ViewController.swift
//  SquatDetectorTest4
//
//  Created by Felix Bernstein on 18/03/2023.
//

import UIKit
import AVFoundation
import Vision
import CoreML
import Foundation
import Photos
import SwiftUI

typealias SquatClassifier = TheSquatClassifier

// MARK: - ViewController
class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    @AppStorage("isLoggedIn") private var isLoggedIn: Bool = false
    @AppStorage("accountId") private var accountId: Int?
    
    // Camera preview view which shows the live feed from the device's camera
    private let cameraPreview: UIView = {
            let view = UIView() // Uses the default UIView pre made by Xcode
            view.translatesAutoresizingMaskIntoConstraints = false // Stops constraints being automatically made
            return view
        }()
    
    private var detectionOverlay: CALayer! // Layer for showing detected recognized points
    private var rootLayer: CALayer! // Bottom layer for the cameraPreview view
    private let captureSession = AVCaptureSession() // Capture session for video input and output
    private var videoDataOutput = AVCaptureVideoDataOutput() // Video data output for capturing video frames
    private var videoDataOutputQueue = DispatchQueue(label: "VideoDataOutputQueue") // Queue for processing video frames
    private var requests = [VNRequest]() // Array of vision requests
    private var didPrintSizeAndResolution = false
    private var squatCounter = 0
    private var movieFileOutput: AVCaptureMovieFileOutput!
    
    private var csvURL: URL? = URL(string: "")
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if !didPrintSizeAndResolution {
            let width = cameraPreview.frame.size.width
            let height = cameraPreview.frame.size.height
            print("CameraPreview Width: \(width), Height: \(height)")

            let screenScale = UIScreen.main.scale
            let resolutionWidth = width * screenScale
            let resolutionHeight = height * screenScale
            print("CameraPreview Resolution: \(resolutionWidth) x \(resolutionHeight)")

            didPrintSizeAndResolution = true
        }
    }
    
    // Called when the view controller is loaded
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera() // Set up camera
        setupVision() // Set up Vision framework
        setupUI() // Set up UI
        
    }

    lazy var squatClassifier: SquatClassifier = {
        do {
            let model = try TheSquatClassifier(configuration: MLModelConfiguration())
            return model
        } catch {
            fatalError("Error initializing SquatClassifier: \(error)")
        }
    }()

    func setDate() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd_HHmmssSS"
        let dateString = dateFormatter.string(from: Date())
        theCurrentDate = dateString
    }

    var theCurrentDate = ""
    
    // MARK: - UI Setup
    private func setupUI() {
        view.addSubview(cameraPreview) // Add camera preview view to the view controller's view
        cameraPreview.translatesAutoresizingMaskIntoConstraints = false
        // Add constraints for the camera preview view to match the view controller's view bounds
        // Without the constraints you get white borders like an older iPhone
        NSLayoutConstraint.activate([
            cameraPreview.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            cameraPreview.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            cameraPreview.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 1),
            cameraPreview.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.9)
        ])
    }
    
    // MARK: - Camera Setup
    private func setupCamera() {
        captureSession.sessionPreset = .hd1920x1080 // Set the capture session preset to 1080p
        // Get the back camera of the device
        // This can be changed to default camera however this can cause the phone to use the front camera sometimes
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
            fatalError("Error: No back camera found")
        }
        
        // Creates device input for the camera
        let deviceInput: AVCaptureDeviceInput
        do {
            deviceInput = try AVCaptureDeviceInput(device: device)
        } catch {
            fatalError("Error: Could not create AVCaptureDeviceInput")
        }
        
        // Configure the capture session
        captureSession.beginConfiguration()
        // Add the device input to the capture session
        if captureSession.canAddInput(deviceInput) {
            captureSession.addInput(deviceInput)
        } else {
            fatalError("Error: Could not add AVCaptureDeviceInput to captureSession")
        }
        
        // Add the video data output to the capture session
        if captureSession.canAddOutput(videoDataOutput) {
            videoDataOutput.alwaysDiscardsLateVideoFrames = true
            videoDataOutput.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
            videoDataOutput.connection(with: .video)?.isEnabled = true
            captureSession.addOutput(videoDataOutput)
        } else {
            fatalError("Error: Could not add AVCaptureVideoDataOutput to captureSession")
        }
        
        captureSession.commitConfiguration() // Commit the configuration changes to the capture session
        // Create and configure a preview layer using the capture session
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        cameraPreview.layer.addSublayer(previewLayer)

        // Initialize detectionOverlay and rootLayer
        detectionOverlay = CALayer()
        rootLayer = cameraPreview.layer
        rootLayer.addSublayer(detectionOverlay) // Add detectionOverlay to the root layer
        //rootLayer.addSublayer(recognisedDot) // Add wristDot to the root layer
        //recognisedDot.isHidden = true // Hide wristDot initially
        // Set the frame for the preview layer and detectionOverlay
        previewLayer.frame = view.bounds
        detectionOverlay.bounds = previewLayer.bounds
        detectionOverlay.position = CGPoint(x: previewLayer.bounds.midX, y: previewLayer.bounds.midY)
        
        movieFileOutput = AVCaptureMovieFileOutput()

        if captureSession.canAddOutput(movieFileOutput) {
            captureSession.addOutput(movieFileOutput)
        } else {
            fatalError("Error: Could not add AVCaptureMovieFileOutput to captureSession")
        }

        DispatchQueue.global(qos: .background).async {
            self.captureSession.startRunning() // Start the capture session
        }
    }

    func startRecordingVideo() {
        guard let connection = movieFileOutput.connection(with: .video) else { return }
        if connection.isVideoOrientationSupported {
            connection.videoOrientation = AVCaptureVideoOrientation(rawValue: 1)!
            
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
        //let fileName = "squat_\(dateFormatter.string(from: Date())).mov"
        let fileName = "temp_\(theCurrentDate)_\(squatCounter)"
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(fileName).mov")
        movieFileOutput.startRecording(to: outputURL, recordingDelegate: self)
    }

    func stopRecordingVideo() {
        movieFileOutput.stopRecording()
    }
    
    //var lastSavedVideo: String?
    
    func saveVideoToLibrary(outputFileURL: URL) {
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized else { return }

            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: outputFileURL)
            }, completionHandler: { success, error in
                if success {
                    
                    print("Video saved to library")
                } else {
                    print("Error saving video to library: \(String(describing: error))")
                }
            })
        }
        saveType = ""
    }
    
    func saveVideoToDocumentsDirectory(inputFileURL: URL) -> URL? {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
        
        guard let destinationURL = documentsURL?.appendingPathComponent("squat_\(theCurrentDate)_\(squatCounter).mov") else {
            print("Error creating destination URL")
            return nil
        }
        
        do {
            try fileManager.copyItem(at: inputFileURL, to: destinationURL)
            //print("Video file saved to Documents directory")
            return destinationURL
        } catch {
            print("Error saving video file to Documents directory: \(error)")
            return nil
        }
    }
    
    func saveVideoToDocumentsDirectoryDelete(inputFileURL: URL) -> URL? {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
        
        guard let destinationURL = documentsURL?.appendingPathComponent("delete.mov") else {
            print("Error creating destination URL")
            return nil
        }
        
        do {
            try fileManager.copyItem(at: inputFileURL, to: destinationURL)
            //print("Video file saved to Documents directory")
            return destinationURL
        } catch {
            print("Error saving video file to Documents directory: \(error)")
            return nil
        }
    }
    
    func deleteVideoFile(at fileURL: URL) {
        let fileManager = FileManager.default
        do {
            try fileManager.removeItem(at: fileURL)
            //print("Video file deleted")
        } catch {
            print("Error deleting video file: \(error)")
        }
        saveType = ""
    }

    
    // MARK: - Vision Setup
    private func setupVision() {
        // Create a body pose detection request
        let bodyTrackingRequest = VNDetectHumanBodyPoseRequest { [weak self] request, error in
            self?.processBodyTracking(request: request, error: error)
        }
        requests = [bodyTrackingRequest] // Add the request to the requests array
    }

    private var squatNumber = 0
    private var isSquatOngoing = false
    private var squatData = [[Float]]()
    private var noSquatFrameCounter = 0
    private var previousPoints = [[Float]]()
    
    var saveType = ""
    
    // Process the body tracking request result
    private func processBodyTracking(request: VNRequest, error: Error?) {
        guard let results = request.results as? [VNHumanBodyPoseObservation] else { return }
        DispatchQueue.main.async { [weak self] in
            self?.detectionOverlay.sublayers?.forEach { $0.removeFromSuperlayer() } // Remove all sublayers from the detectionOverlay
            for observation in results {
                let allJointNames: [VNHumanBodyPoseObservation.JointName] = [ //Do NOT remove joints, the MLMultiArray below is expecting 18
                    .nose, .leftEye, .rightEye, .leftEar, .rightEar,
                    .leftShoulder, .rightShoulder, .leftElbow, .rightElbow, .leftWrist, .rightWrist,
                    .leftHip, .rightHip, .leftKnee, .rightKnee, .leftAnkle, .rightAnkle,
                    .neck
                ]

                var inputArray = [Float]()
                for key in allJointNames {
                    if let point = try? observation.recognizedPoint(key) {
                        //print("Joint: \(key), Point: (\(point.location.x), \(point.location.y)")
                        self?.displayBodyPoints(point)
                        inputArray.append(Float(point.location.x))
                        inputArray.append(Float(point.location.y))
                    } else {
                        inputArray.append(0)
                        inputArray.append(0)
                    }
                }
                    
                let mlArray = try? MLMultiArray(shape: [30, 3, 18], dataType: .float32)

                for frame in 0..<30 {
                    //print("this runs 1")
                    for (index, element) in inputArray.enumerated() {
                        //print("this runs 2")
                        let zIndex = index % 2
                        let yIndex = index / 2
                        let flatIndex = frame * 18 * 3 + yIndex * 3 + zIndex
                        mlArray?[flatIndex] = NSNumber(value: element)
                        if zIndex == 0 {
                            //print("this runs 3")
                            mlArray?[flatIndex + 1] = NSNumber(value: 0)
                            mlArray?[flatIndex + 2] = NSNumber(value: 0)
                        }
                    }
                }

                if let prediction = try? self?.squatClassifier.prediction(input: TheSquatClassifierInput(poses: mlArray!)) {
                    
                    if prediction.labelProbabilities["Squats"] != nil {
                   
                        //print(self!.noSquatFrameCounter)
                        print(prediction.labelProbabilities["Squats"]!)
                        
                  
                        if prediction.labelProbabilities["Squats"]! > 0.0002 {
                            print("SQUAT DETECTED SQUAT DETECTED SQUAT DETECTED SQUAT DETECTED")
                            if !self!.isSquatOngoing {
                                self!.isSquatOngoing = true
                                self!.squatNumber += 1
                                self!.squatData = []
                                //self!.startRecordingVideo()
                            }
                            if (self!.previousPoints.count != 0) {
                                self!.squatData.append(contentsOf: self!.previousPoints)
                                self!.previousPoints.removeAll()
                            }
                            self!.squatData.append(inputArray)
                            self!.noSquatFrameCounter = 0
                                                    
                        } else {// If squat is not detected
                            if (self!.previousPoints.count >= 15) {
                                self!.previousPoints.removeAll()
                                //self?.deleteVideoFromLibrary(localIdentifier: self!.lastSavedVideo)
                                //STOP RECORDING AND DELETE VIDEO HERE
                                self!.setDate()
                                self!.saveType = "delete"
                                self!.stopRecordingVideo()
                            }
                            self!.previousPoints.append(inputArray)
                            self!.startRecordingVideo()
                            //START RECORDING HERE
                            if self!.isSquatOngoing {
                                self!.noSquatFrameCounter += 1
                                self!.squatData.append(inputArray)
                                self!.previousPoints.removeAll()
                                
                                if self!.noSquatFrameCounter >= 15 {
                                    self!.noSquatFrameCounter = 0
                                    self!.isSquatOngoing = false
                                    self!.setDate()
                                    self!.csvURL = self!.saveCSV(inputArrays: self!.squatData)
                                    self!.squatData.removeAll()
                                    self!.saveType = "save"
                                    //exerciseTypeRows[exerciseTypeRowIndex].exerciseReps.append(exerciseRep)
                                    self!.stopRecordingVideo()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    func saveCSV(inputArrays: [[Float]]) -> URL? {
        // Get the app's documents directory
        squatCounter += 1
        let fileManager = FileManager.default
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Error: Could not find the app's documents directory")
            return URL(string: "")
        }

        // Check if the documents directory exists and create it if it doesn't
        if !fileManager.fileExists(atPath: documentsURL.path) {
            do {
                try fileManager.createDirectory(at: documentsURL, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("Error: Could not create the app's documents directory: \(error)")
                return URL(string: "")
            }
        }

        let fileName = "squat_\(theCurrentDate)_\(squatCounter).csv"
        let fileURL = documentsURL.appendingPathComponent(fileName)

        // Convert the inputArrays to a CSV string
        
        let tempInputArrays = inputArrays
        let jointsNamesArray = ["NoseX", "NoseY",
                                "LeftEyeX", "LeftEyeY",
                                "RightEyeX", "RightEyeY",
                                "LeftEarX", "LeftEarY",
                                "RightEarX", "RightEarY",
                                "LeftShoulderX", "LeftShoulderY",
                                "RightShoulderX", "RightShoulderY",
                                "LeftElbowX", "LeftElbowY",
                                "RightElbowX", "RightElbowY",
                                "LeftWristX", "LeftWristY",
                                "RightWristX", "RightWristY",
                                "LeftHipX", "LeftHipY",
                                "RightHipX", "RightHipY",
                                "LeftKneeX", "LeftKneeY",
                                "RightKneeX", "RightKneeY",
                                "LeftAnkleX", "LeftAnkleY",
                                "RightAnkleX", "RightAnkleY",
                                "NeckX", "NeckY"]
        
     
        let stringInputArrays = tempInputArrays.map { $0.map {String($0) } }
        
        
      
        
        var newInputArrays = [[String]]()
        newInputArrays.append(jointsNamesArray)
       
        
        
        for theCurrentArray in stringInputArrays {
            newInputArrays.append(theCurrentArray)
        }
        
        var csvString = ""
        for inputArray in newInputArrays {
            //let row = inputArray.map { String($0) }.joined(separator: ",")
            let row = inputArray.joined(separator: ",")
            csvString.append(row + "\n")
        }
        
      

        // Save the CSV string to the file
        do {
            try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
            print("CSV file saved successfully at \(fileURL)")
            globalCsvURL = fileURL
            return fileURL
        } catch {
            print("Error: Could not save the CSV file: \(error)")
            return fileURL
        }
    }


    // Display a detected wrist point on the detectionOverlay
    private func displayBodyPoints(_ point: VNRecognizedPoint) {
        guard point.confidence > 0.3 else { return } // Ignore points with low confidence
        let wristPoint = CGPoint(x: 1 - point.location.x, y: 1 - point.location.y) // Convert the point's location
        var transform = CGAffineTransform.identity //
        // Set the transform based on the current device orientation
        switch UIDevice.current.orientation {
        case .portrait:
            transform = CGAffineTransform(scaleX: detectionOverlay.bounds.width, y: detectionOverlay.bounds.height)
        case .landscapeRight:
            transform = CGAffineTransform(rotationAngle: .pi / 2).concatenating(CGAffineTransform(scaleX: detectionOverlay.bounds.width, y: detectionOverlay.bounds.height))
        case .landscapeLeft:
            transform = CGAffineTransform(rotationAngle: -(.pi / 2)).concatenating(CGAffineTransform(scaleX: detectionOverlay.bounds.width, y: detectionOverlay.bounds.height))
        default:
            transform = CGAffineTransform(scaleX: detectionOverlay.bounds.width, y: detectionOverlay.bounds.height)
        }

        // Apply the transform to the point
        let convertedPoint = wristPoint.applying(transform)
        
        // Create a dot layer for the detected point
        let dot = CALayer()
        dot.bounds = CGRect(x: 0, y: 0, width: 12, height: 12)
        dot.cornerRadius = 6
        dot.backgroundColor = UIColor.green.cgColor
        dot.position = convertedPoint
        detectionOverlay.addSublayer(dot) // Add the dot layer to the detectionOverlay
    }

    // AVCaptureVideoDataOutputSampleBufferDelegate method for processing video frames
    // This is called EVERY SINGLE NEW FRAME
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        var exifOrientation: CGImagePropertyOrientation
        switch UIDevice.current.orientation {
            case .portraitUpsideDown: exifOrientation = .left
            case .landscapeRight: exifOrientation = .up
            case .landscapeLeft: exifOrientation = .down
            default: exifOrientation = .right
        }
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: exifOrientation, options: [:])
        do {
            try imageRequestHandler.perform(requests)
        } catch {
            print("Error: Failed to perform image request handler")
        }
    }
}

extension ViewController: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if let error = error {
            print("Error recording movie: \(error.localizedDescription)")
        } else {
            if saveType == "save" {
                let videoURL = saveVideoToDocumentsDirectory(inputFileURL: outputFileURL)
                //globalVideoURL = videoURL
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                let dateTime = dateFormatter.string(from: Date())
                uploadExerciseData(
                    accountId: accountId!,
                    exerciseType: "squat",
                    datetime: "\(dateTime)",
                    videoURL: videoURL!,
                    csvURL: csvURL!
                ) { result in
                    switch result {
                    case .success(let exercise):
                        print("Exercise uploaded successfully: \(exercise)")
                    case .failure(let error):
                        print("Error uploading exercise: \(error.localizedDescription)")
                    }
                }
//                if let url = saveVideoToDocumentsDirectory(inputFileURL: outputFileURL) {
//                    deleteVideoFile(at: url)
//                }
            } else if saveType == "delete"{
                if let url = saveVideoToDocumentsDirectoryDelete(inputFileURL: outputFileURL) {
                    deleteVideoFile(at: url)
                }
                //saveVideoToDocumentsDirectory(inputFileURL: outputFileURL)
            } else {
                print("Something has gone very wrong if you make it here")
            }
            //saveVideoToLibrary(outputFileURL: outputFileURL)
        }
    }
}
