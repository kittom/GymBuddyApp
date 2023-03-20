//
//  ViewController.swift
//  SquatDetectorTest4
//
//  Created by Felix Bernstein on 18/03/2023.
//

import UIKit
import AVFoundation
import Vision

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
    private let recognisedDot: CALayer = {
        let dot = CALayer()
        dot.bounds = CGRect(x: 0, y: 0, width: 12, height: 12)
        dot.cornerRadius = 6
        dot.backgroundColor = UIColor.green.cgColor
        return dot
    }()
    
    private let captureSession = AVCaptureSession() // Capture session for video input and output
    private var videoDataOutput = AVCaptureVideoDataOutput() // Video data output for capturing video frames
    private var videoDataOutputQueue = DispatchQueue(label: "VideoDataOutputQueue") // Queue for processing video frames
    
    private var requests = [VNRequest]() // Array of vision requests
    
    // Called when the view controller is loaded
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera() // Set up camera
        setupVision() // Set up Vision framework
        setupUI() // Set up UI
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.addSubview(cameraPreview) // Add camera preview view to the view controller's view
        // Add constraints for the camera preview view to match the view controller's view bounds
        // Without the constraints you get white borders like an older iPhone
        NSLayoutConstraint.activate([
            cameraPreview.topAnchor.constraint(equalTo: view.topAnchor),
            cameraPreview.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            cameraPreview.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            cameraPreview.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    // MARK: - Camera Setup
    private func setupCamera() {
        captureSession.sessionPreset = .hd1920x1080 // Set the capture session preset to 1080p
        
        // Get the back camera of the device
        // This can be changed to default camera however this can cause the phone to use the front camera sometimes
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
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

    // Process the wrist tracking request result
    private func processBodyTracking(request: VNRequest, error: Error?) {
        guard let results = request.results as? [VNHumanBodyPoseObservation] else { return }
        DispatchQueue.main.async { [weak self] in
            self?.detectionOverlay.sublayers?.forEach { $0.removeFromSuperlayer() } // Remove all sublayers from the detectionOverlay
            for observation in results {
                let allJointNames: [VNHumanBodyPoseObservation.JointName] = [
                    .nose, .leftEye, .rightEye, .leftEar, .rightEar,
                    .leftShoulder, .rightShoulder, .leftElbow, .rightElbow, .leftWrist, .rightWrist,
                    .leftHip, .rightHip, .leftKnee, .rightKnee, .leftAnkle, .rightAnkle,
                    .neck
                ]
                for key in allJointNames {
                    if let point = try? observation.recognizedPoint(key) {
                        self?.displayBodyPoints(point)
                    }
                }
            }
        }
    }

    // Display a detected wrist point on the detectionOverlay
    private func displayBodyPoints(_ point: VNRecognizedPoint) {
        guard point.confidence > 0.3 else { return } // Ignore points with low confidence

        let wristPoint = CGPoint(x: point.location.x, y: 1 - point.location.y) // Convert the point's location
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


