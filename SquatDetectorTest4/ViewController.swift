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

//typealias SquatClassifier = SquatClassifierTest1_1
//typealias SquatClassifier = TheSquatClassifier_1
typealias SquatClassifier = TheSquatClassifier_2_1

// MARK: - ViewController
class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    // Camera preview view which shows the live feed from the device's camera

    
    private let cameraPreview: UIView = {
            let view = UIView() // Uses the default UIView pre made by Xcode
            view.translatesAutoresizingMaskIntoConstraints = false // Stops constraints being automatically made
            return view
        }()

    
    
    
    private var detectionOverlay: CALayer! // Layer for showing detected recognized points
    private var rootLayer: CALayer! // Bottom layer for the cameraPreview view
    
    // Properties of the dot showng recognised points
    
    
    private let captureSession = AVCaptureSession() // Capture session for video input and output
    private var videoDataOutput = AVCaptureVideoDataOutput() // Video data output for capturing video frames
    private var videoDataOutputQueue = DispatchQueue(label: "VideoDataOutputQueue") // Queue for processing video frames
    
    private var requests = [VNRequest]() // Array of vision requests
    
    private var didPrintSizeAndResolution = false

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
            let model = try TheSquatClassifier_2_1(configuration: MLModelConfiguration())
            return model
        } catch {
            fatalError("Error initializing SquatClassifier: \(error)")
        }
    }()


    

    
    
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
        //print("the views resolution\(cameraPreview.frame.size.height) x \(cameraPreview.frame.size.width)")
        //view.addSubview(shareButton)
        NSLayoutConstraint.activate([
        //    shareButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        //    shareButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20)
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

        captureSession.startRunning() // Start the capture session
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


                
                

                if let prediction = try? self?.squatClassifier.prediction(input: TheSquatClassifier_2_1Input(poses: mlArray!)) {
                 
                                    
                    if prediction.labelProbabilities["Squats"] != nil {
                        
                        //print("SQUATS probability: \(String(describing: prediction.labelProbabilities["Squats"]))")
                        //print("The input array: \(inputArray) of length \(inputArray.count)")
                        //if prediction.labelProbabilities["Squats"]! > 0.00020 {
                        //    print("Squat Detected")
                        //    self?.saveCSV(inputArray: inputArray)
                        //}
                        print(self!.noSquatFrameCounter)
                        print(prediction.labelProbabilities["Squats"]!)
                        if prediction.labelProbabilities["Squats"]! > 0.0020 {
                            print("SQUAT DETECTED SQUAT DETECTED SQUAT DETECTED SQUAT DETECTED")
                            if !self!.isSquatOngoing {
                                self!.isSquatOngoing = true
                                self!.squatNumber += 1
                                self!.squatData = []
                            }
                            if (self!.previousPoints.count != 0) {
                                self!.squatData.append(contentsOf: self!.previousPoints)
                                self!.previousPoints.removeAll()
                            }
                            self!.squatData.append(inputArray)
                            self!.noSquatFrameCounter = 0
                                                    
                            } else {// If squat is not detected
                                if (self!.previousPoints.count > 5) {
                                    self!.previousPoints.removeAll()
                                }
                                self!.previousPoints.append(inputArray)
                                
                                if self!.isSquatOngoing {
                                    self!.noSquatFrameCounter += 1

                                    if self!.noSquatFrameCounter >= 10 {
                                            self!.isSquatOngoing = false
                                            self!.saveCSV(inputArrays: self!.squatData)
                                            self!.squatData.removeAll()
                                    }
                                }
                       //     if !self!.isSquatOngoing {
                       //         self!.isSquatOngoing = true
                       //         self!.squatNumber += 1
                       //     }
                       //     self!.squatData.append(inputArray)
                       // } else if self!.isSquatOngoing {
                       //     self!.isSquatOngoing = false
                       //     self!.saveCSV(inputArrays: self!.squatData)
                       //     self!.squatData.removeAll()
                            
                            
                            
                            
                        }

                    }
                }
            }
        }
    }
    
    func saveCSV(inputArrays: [[Float]]) {
        // Get the app's documents directory
        let fileManager = FileManager.default
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Error: Could not find the app's documents directory")
            return
        }

        // Check if the documents directory exists and create it if it doesn't
        if !fileManager.fileExists(atPath: documentsURL.path) {
            do {
                try fileManager.createDirectory(at: documentsURL, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("Error: Could not create the app's documents directory: \(error)")
                return
            }
        }

        // Create the CSV file
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
        let dateString = dateFormatter.string(from: Date())
        let fileName = "squat_\(dateString).csv"
        let fileURL = documentsURL.appendingPathComponent(fileName)

        // Convert the inputArrays to a CSV string
        var csvString = ""
        for inputArray in inputArrays {
            let row = inputArray.map { String($0) }.joined(separator: ",")
            csvString.append(row + "\n")
        }

        // Save the CSV string to the file
        do {
            try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
            print("CSV file saved successfully at \(fileURL)")
        } catch {
            print("Error: Could not save the CSV file: \(error)")
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
        
        
        //print("Recognized point x: \(wristPoint.x), y: \(wristPoint.y)")

        
        
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


