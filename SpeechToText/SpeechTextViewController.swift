//
//  SpeechTextViewController.swift
//  SpeechToText
//
//  Created by Roger Zhang on 2017-05-07.
//  Copyright © 2017 Roger Zhang. All rights reserved.
//

import UIKit
import Speech

class SpeechTextViewController: UIViewController, SFSpeechRecognizerDelegate {

    @IBOutlet weak var textView: UITextView? {
        didSet {
            textView?.text = ""
        }
    }
    
    @IBOutlet weak var microphoneButton: UIButton?
    
    var text: String = "" {
        didSet {
            textView?.text = text
        }
    }
    
    var masterView: TranscriptViewController!
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "en-US"))!
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.automaticallyAdjustsScrollViewInsets = false
        
        microphoneButton?.isEnabled = false
        
        speechRecognizer.delegate = self
        
        SFSpeechRecognizer.requestAuthorization { (authStatus) in
            OperationQueue.main.addOperation() {
                var isButtonEnabled = false
                
                switch authStatus {
                    case .authorized:
                        isButtonEnabled = true
                        
                    case .denied:
                        isButtonEnabled = false
                        print("User denied access to speech recognition")
                        
                    case .restricted:
                        isButtonEnabled = false
                        print("Speech recognition restricted on this device")
                        
                    case .notDetermined:
                        isButtonEnabled = false
                        print("Speech recognition not yet authorized")
                }
                self.microphoneButton?.isEnabled = isButtonEnabled
            }
        }
        textView?.text = text
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let text = textView?.text {
            masterView.newRowText = text
        }
    }
    
    private func startRecording() {
        
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSessionCategoryRecord)
            try audioSession.setMode(AVAudioSessionModeMeasurement)
            try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
        } catch {
            print("audioSession properties weren't set because of an error.")
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let inputNode = audioEngine.inputNode else {
            fatalError("Audio engine has no input node")
        }
        
        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in
            
            var isFinal = false
            
            if result != nil {
                self.setText(with: result!.bestTranscription.formattedString)
                isFinal = result!.isFinal
            }
            
            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                self.microphoneButton?.isEnabled = true
            }
        })
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
        } catch {
            print("audioEngine couldn't start because of an error.")
        }
    }
    
    func setText(with noteText: String) {
        text = noteText
    }
    
    // MARK: -- speech recognition delegate
    
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            microphoneButton?.isEnabled = true
        } else {
            microphoneButton?.isEnabled = false
        }
    }
    
    @IBAction func microphoneTapped(_ sender: UIButton) {
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            microphoneButton?.isEnabled = false
            microphoneButton?.setTitle("Start Recording", for: .normal)
            microphoneButton?.setTitleColor(UIColor.blue, for: .normal)
        } else {
            startRecording()
            microphoneButton?.setTitle("Stop Recording", for: .normal)
            microphoneButton?.setTitleColor(UIColor.red, for: .normal)
        }
    }
}
