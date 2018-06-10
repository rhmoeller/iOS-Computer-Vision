//
//  CameraVC.swift
//  vision-app-dev
//
//  Created by Robert Møller on 09/06/2018.
//  Copyright © 2018 Robert Møller. All rights reserved.
//

import UIKit
import AVFoundation
import CoreML
import Vision

enum FlashState {
    case off, on
}

class CameraVC: UIViewController {

    var captureSession: AVCaptureSession!
    var cameraOutput: AVCapturePhotoOutput!
    var previewLayer: AVCaptureVideoPreviewLayer!
    
    var photoData: Data?
    var flashState: FlashState = .off
    var speechSyntezier = AVSpeechSynthesizer()
    
    @IBOutlet weak var cameraView: UIImageView!
    @IBOutlet weak var capturedImageView: RoundedShadowImageView!
    @IBOutlet weak var informationView: RoundedShadowView!
    @IBOutlet weak var itemNameLabel: UILabel!
    @IBOutlet weak var confidenceLabel: UILabel!
    @IBOutlet weak var flashToggle: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        previewLayer.frame = cameraView.bounds
        speechSyntezier.delegate = self
        activityIndicator.isHidden = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapCameraView))
        tap.numberOfTapsRequired = 1
        
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .hd1920x1080
        
        let backCamera = AVCaptureDevice.default(for: .video)
        
        do {
            let input = try AVCaptureDeviceInput(device: backCamera!)
            
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            }
            
            cameraOutput = AVCapturePhotoOutput()
            
            if captureSession.canAddOutput(cameraOutput) {
                captureSession.addOutput(cameraOutput!)
                
                previewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
                previewLayer.videoGravity = .resizeAspect
                previewLayer.connection?.videoOrientation = AVCaptureVideoOrientation.portrait
                
                cameraView.layer.addSublayer(previewLayer!)
                cameraView.addGestureRecognizer(tap)
                captureSession.startRunning()
            }
        } catch {
            debugPrint(error)
        }
    }

    @objc func didTapCameraView()  {
        cameraView.isUserInteractionEnabled = false
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()
        
        let settings = AVCapturePhotoSettings()
        settings.previewPhotoFormat = settings.embeddedThumbnailPhotoFormat
        switch flashState {
        case .off:
            settings.flashMode = .off
        case .on:
            settings.flashMode = .on
        }
        cameraOutput.capturePhoto(with: settings, delegate: self)
    }
    
    func resultsMethod(request: VNRequest, error: Error?) {
        informationView.isHidden = false

        
        guard let results = request.results as? [VNClassificationObservation] else { return }
        for classification in results {
            if classification.confidence < 0.5 {
                let unknownMessage = "Try again.."
                
                self.itemNameLabel.text = unknownMessage
                synteziseSpeech(from: unknownMessage)
                self.confidenceLabel.text = ""
                break
            } else {
                let item = classification.identifier
                let confidence = Int(classification.confidence * 100)
                
                self.itemNameLabel.text = item
                self.confidenceLabel.text = "CONFIDENCE: \(confidence)%"
                
                let sentance = "This looks like a \(item)"
                synteziseSpeech(from: sentance)
                
                break
            }
        }
    }
    
    func synteziseSpeech(from string: String) {
        let speechUtterance = AVSpeechUtterance(string: string)
        speechSyntezier.speak(speechUtterance)
    }
    
    @IBAction func flashTogglePressed(_ sender: Any) {
        switch flashState {
        case .off:
            flashState = .on
            flashToggle.setTitle("🌝", for: .normal)
        case .on:
            flashState = .off
            flashToggle.setTitle("🌚", for: .normal)
        }
    }
    
    
}

extension CameraVC: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            debugPrint(error)
        } else {
            photoData = photo.fileDataRepresentation()
            
            do {
                let model = try VNCoreMLModel(for: SqueezeNet().model)
                let request = VNCoreMLRequest(model: model, completionHandler: resultsMethod)
                let handler = VNImageRequestHandler(data: photoData!)
                try handler.perform([request])
            } catch {
                debugPrint(error)
            }
            
            let image = UIImage(data: photoData!)
            self.capturedImageView.image = image
        }
    }
}

extension CameraVC: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        activityIndicator.stopAnimating()
        cameraView.isUserInteractionEnabled = true
        activityIndicator.isHidden = true
        
    }
}
