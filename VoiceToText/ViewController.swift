//
//  ViewController.swift
//  VoiceToText
//
//  Created by Mekala Vamsi Krishna on 02/01/23.
//

import UIKit
import Speech
import AVKit

class ViewController: UIViewController {

    @IBOutlet weak var btnStart : UIButton!
    @IBOutlet weak var lblText : UILabel!
    @IBOutlet weak var languageButton: UIBarButtonItem!
    
    var speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    var recognitionRequest : SFSpeechAudioBufferRecognitionRequest?
    var recognitionTask : SFSpeechRecognitionTask?
    let audioEngine = AVAudioEngine()

    @IBAction func btnStartSpeechToText(_ sender: UIButton) {

        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            btnStart.isEnabled = false
            btnStart.setTitle("Start Recording", for: .normal)
        } else {
            startRecording()
            btnStart.setTitle("Stop Recording", for: .normal)
        }
    }

    func setupSpeech() {

        btnStart.isEnabled = false
        speechRecognizer?.delegate = self

        SFSpeechRecognizer.requestAuthorization { (authStatus) in

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

            OperationQueue.main.addOperation() {
                self.btnStart.isEnabled = isButtonEnabled
            }
        }
    }

    func startRecording() {

        // Clear all previous session data and cancel task
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }

        // Create instance of audio session to record voice
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSession.Category.record, mode: AVAudioSession.Mode.measurement, options: AVAudioSession.CategoryOptions.defaultToSpeaker)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("audioSession properties weren't set because of an error.")
        }

        self.recognitionRequest = SFSpeechAudioBufferRecognitionRequest()

        let inputNode = audioEngine.inputNode

        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
        }

        recognitionRequest.shouldReportPartialResults = true

        self.recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest, resultHandler: { [self] (result, error) in

            var isFinal = false

            if result != nil {

                self.lblText.text = result?.bestTranscription.formattedString
                isFinal = (result?.isFinal)!
            }

            if error != nil || isFinal {

                audioEngine.stop()
                inputNode.removeTap(onBus: 0)

                self.recognitionRequest = nil
                self.recognitionTask = nil

                self.btnStart.isEnabled = true
            }
        })

        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            self.recognitionRequest?.append(buffer)
        }

        self.audioEngine.prepare()

        do {
            try self.audioEngine.start()
        } catch {
            print("audioEngine couldn't start because of an error.")
        }

        self.lblText.text = "Say something, I'm listening!"
    }

    @IBAction func changeLanguageTapped(_ sender: UIBarButtonItem) {
        let actionSheet = UIAlertController(title: "Choose Langauge", message: "", preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "English", style: .default, handler: { _ in
            self.title = "Speak in English"
            self.languageButton.title = "English"
            self.lblText.text = "Say something, I'm listening!"
            self.speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        }))
        actionSheet.addAction(UIAlertAction(title: "Hindi", style: .default, handler: { _ in
            self.title = "हिंदी मे बोलो"
            self.languageButton.title = "Hindi"
            self.lblText.text = "कुछ तो बोलो, मैं सुन रहा हूँ!"
            self.speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "hi"))
        }))
        actionSheet.addAction(UIAlertAction(title: "French", style: .default, handler: { _ in
            self.title = "parle en francais"
            self.languageButton.title = "French"
            self.lblText.text = "direquelque chose, je t'écoute!"
            self.speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "fr-FR"))
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(actionSheet, animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Speak in English"
        
        setupSpeech()
    }
}

extension ViewController: SFSpeechRecognizerDelegate {

    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            btnStart.isEnabled = true
        } else {
            btnStart.isEnabled = false
        }
    }
}

