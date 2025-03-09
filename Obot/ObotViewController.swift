//
//  ObotViewController.swift
//  Obot
//
//  Created by Aadi Gala on 5/26/20.
//  Copyright © 2020 Aadi Gala. All rights reserved.
//

import UIKit
import Speech
import SafariServices
import WebKit
import SwiftSoup

class ObotViewController: UIViewController, SFSpeechRecognizerDelegate {
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var microphoneButton: UIButton!
    @IBOutlet weak var howCanIHelpMessage: UILabel!
    @IBOutlet weak var obotSmile: UIImageView!
    @IBOutlet weak var ShopButton: UIButton!
    
    let speechRecognizer: SFSpeechRecognizer? = SFSpeechRecognizer(locale: Locale.init(identifier:"en-us"))
    var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    var recognitionTask: SFSpeechRecognitionTask?
    let audioEngine = AVAudioEngine()
    var searchUp = ""
    var newSearchUp = ""
        
    override func viewDidLoad() {
        super.viewDidLoad()
        microphoneButton.layer.cornerRadius = 26.0
        ShopButton.layer.cornerRadius = 26.0
        ShopButton.isHidden = true
        howCanIHelpMessage.isHidden = true
        searchUp = ""
        speechRecognizer?.delegate = self
        SFSpeechRecognizer.requestAuthorization {
            status in
            var buttonState = false
            switch status {
            case .authorized:
                buttonState = true
                print("Permission received")
            case .denied:
                buttonState = false
                print("User did not give permission to use speech recognition")
            case .notDetermined:
                buttonState = false
                print("Speech recognition not allowed by user")
            case .restricted:
                buttonState = false
                print("Speech recognition not supported on this device")
            @unknown default: break
                
            }
            DispatchQueue.main.async {
                self.microphoneButton.isEnabled = buttonState
            }
        }
    }
    func startRecording() {
        if recognitionTask != nil { //used to track progress of a transcription or cancel it
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSession.Category(rawValue:
            convertFromAVAudioSessionCategory(AVAudioSession.Category.record)), mode: .default)
            try audioSession.setMode(AVAudioSession.Mode.measurement)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to setup audio session")
        }
    
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest() //read from buffer
        let inputNode = audioEngine.inputNode
        guard let recognitionRequest = recognitionRequest else {
            fatalError("Could not create request instance")
        }
        recognitionRequest.shouldReportPartialResults = true
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) {
            res, err in
            var isFinal = false
            if res != nil {
                self.textView.text = res?.bestTranscription.formattedString
                self.searchUp = (res?.bestTranscription.formattedString)!
                isFinal = (res?.isFinal)!
            }
                
            if err != nil || isFinal {  //10
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                    
                self.recognitionRequest = nil
                self.recognitionTask = nil
                    
                self.microphoneButton.isEnabled = true
            }
        }
            
        let format = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) {
            buffer, _ in
            self.recognitionRequest?.append(buffer)
        }
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
        } catch {
            print("Can't start the engine")
        }
            
        textView.text = "Say something, I'm listening!"
        
    }
    @IBAction func microphoneButtonClicked(_ sender: Any) {
        if audioEngine.isRunning {
            howCanIHelpMessage.isHidden = true
            obotSmile.isHidden = false
            newSearchUp = searchUp.replacingOccurrences(of: " ", with: "%20")
            audioEngine.stop()
            recognitionRequest?.endAudio()
            microphoneButton.isEnabled = false
            self.microphoneButton.setTitle("Record", for: .normal)
            self.ShopButton.isHidden = true
            view.addSubview(textView)
            textView.frame = CGRect(x: 20, y: 501, width: 374, height: 282)
            showSafariVC(for: "https://www.google.com/search?q=\(newSearchUp)")
        } else {
            searchUp = ""
            startRecording()
            howCanIHelpMessage.isHidden = false
            obotSmile.isHidden = true
            microphoneButton.setTitle("Search", for: .normal)
            self.ShopButton.isHidden = false
            view.addSubview(textView)
            textView.frame = CGRect(x: 20, y: 561, width: 374, height: 222)
        }
    }
    
    func showSafariVC(for url: String) {
        guard let url = URL(string: url) else {
            //Show an invalid URL error alert
            return
        }
        
        let safariVC = SFSafariViewController(url: url)
        present(safariVC, animated: true)
    }
    @IBAction func ShopButtonClicked(_ sender: Any)
    {
        textView.text = ""
        howCanIHelpMessage.isHidden = true
        obotSmile.isHidden = false
        newSearchUp = searchUp.replacingOccurrences(of: " ", with: "+")
        audioEngine.stop()
        recognitionRequest?.endAudio()
        microphoneButton.isEnabled = false
        self.microphoneButton.setTitle("Record", for: .normal)
        self.ShopButton.isHidden = true
        textView.frame = CGRect(x: 20, y: 501, width: 374, height: 282)
        showSafariVC(for: "https://www.amazon.com/s?k=\(newSearchUp)")
    }
}
fileprivate func convertFromAVAudioSessionCategory(_ input: AVAudioSession.Category) -> String {
    return input.rawValue
}
