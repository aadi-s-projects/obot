//
//  ViewController.swift
//  Obot
//
//  Created by Aadi Gala on 5/22/20.
//  Copyright © 2020 Aadi Gala. All rights reserved.
//

import UIKit
import AVKit
import Vision
import SafariServices

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    override var prefersStatusBarHidden:Bool {
        return true
    }
    
    @IBOutlet weak var belowView: UIView!
    @IBOutlet weak var objectNameLabel: UILabel!
    @IBOutlet weak var searchButton: UIButton!
    
    var model = Resnet50().model
    var name = ""
    var newName = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchButton.layer.cornerRadius = 26.0
        let captureSession = AVCaptureSession()
        
        guard let captureDevice = AVCaptureDevice.default(for: .video) else { return }
        guard let input = try? AVCaptureDeviceInput(device: captureDevice) else { return }
        captureSession.addInput(input)
        
        captureSession.startRunning()
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        view.layer.addSublayer(previewLayer)
        previewLayer.frame = view.frame
        // The camera is now created!
        
        view.addSubview(belowView)
        
        belowView.clipsToBounds = true
        belowView.layer.cornerRadius = 15.0
        belowView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
        
        
        let  dataOutput = AVCaptureVideoDataOutput()
        dataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        captureSession.addOutput(dataOutput)
        
        
        
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        guard let model = try? VNCoreMLModel(for: model) else { return }
        let request = VNCoreMLRequest(model: model) { (finishedReq, err) in
            
            guard let results = finishedReq.results as? [VNClassificationObservation] else {return}
            guard let firstObservation = results.first else {return}
            
            self.name = firstObservation.identifier
            
            DispatchQueue.main.async {
                self.objectNameLabel.text = self.name
            }
            
        }
        
        try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([request])
        
    }

    @IBAction func searchButtonClicked(_ sender: Any) {
        newName = name.replacingOccurrences(of: " ", with: "%20")
        showSafariVC(for: "https://www.google.com/search?q=\(newName)")
    }
    
    func showSafariVC(for url: String) {
        guard let url = URL(string: url) else {
            //Show an invalid URL error alert
            return
        }
        
        let safariVC = SFSafariViewController(url: url)
        present(safariVC, animated: true)
    }
}

