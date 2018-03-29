//
//  ViewController.swift
//  MyFirstNeuralNetworkApp
//
//  Created by Olga Maslova on 27/03/2018.
//  Copyright © 2018 Olga Maslova. All rights reserved.
//

import UIKit
import CoreML
import Vision
import AVFoundation
import CoreVideo

class ViewController: UIViewController, FrameExtractorDelegate {
    var frameExtractor: FrameExtractor!
    var settingImage = false
    var frameCount: Int = 0
    
    @IBOutlet weak var previewView: UIView!
    @IBOutlet weak var predictionLabel: UILabel!
    
    var previewLayer:AVCaptureVideoPreviewLayer?
    let model = is_receipt_googleNet()
    
    var videoCapture: VideoCapture!
    var request: VNCoreMLRequest!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        predictionLabel.text = ""    
        
        frameExtractor = FrameExtractor()
        frameExtractor.delegate = self
        //Test with a ticket image
        /*
        if let uiExamle = UIImage(named: "ticket"), let example = CIImage(image: uiExamle) {
            self.detect(image: example)
        }
         */
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func previewLayer(previewLayer: AVCaptureVideoPreviewLayer) {
        DispatchQueue.main.async {
            self.previewLayer = previewLayer
            self.previewLayer!.frame = self.previewView.bounds
            print(self.previewLayer!.debugDescription)
            self.previewLayer!.videoGravity = .resizeAspectFill
            self.previewView.layer.addSublayer(self.previewLayer!)
            if self.previewLayer!.connection!.isVideoOrientationSupported {
                self.previewLayer!.connection!.videoOrientation = .portrait
            }
        }
    }
    
    
    func detect(image: CIImage) {
        guard let visionModel = try? VNCoreMLModel(for: model.model) else {
            print("Error: could not create Vision model")
            return
        }
        
        // Create a Vision request with completion handler
        let request = VNCoreMLRequest(model: visionModel) { [unowned self] request, error in
            guard let results = request.results as? [VNClassificationObservation],
                let _ = results.first else {
                    self.settingImage = false
                    return
            }
            // print(results)
            if let first = results.first {
                //print(first.identifier)
                DispatchQueue.main.async {
                    if Int(first.confidence * 100) > 1 {
                        let labelText: String
                        if (first.identifier == "noTicket") {
                            labelText = "Ceci n'est pas un ticket"
                        } else {
                            labelText = "Bingo! C'est un ticket!"
                        }
                        self.predictionLabel.text = "\(labelText) \(String(format: "%.2f", first.confidence * 100))%"
                        self.settingImage = false
                    }
                }
                
            }
        }
        
        let handler = VNImageRequestHandler(ciImage: image)
        DispatchQueue.global(qos: .userInteractive).async {
            do {
                try handler.perform([request])
            } catch {
                print(error)
            }
        }
        
    }
    
    func captured(image: UIImage) {
        //we run image detection every 5th frame
        if (frameCount < 5) {
             frameCount += 1
        } else {
            frameCount = 0
            if let cgImage = image.cgImage {
                DispatchQueue.global(qos: .userInteractive).async {[unowned self] in
                    self.settingImage = true
                    self.detect(image: CIImage(cgImage: cgImage))
                }
            }
        }
    }
}



