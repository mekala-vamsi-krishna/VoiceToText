//
//  ViewController.swift
//  VoiceToText
//
//  Created by Mekala Vamsi Krishna on 02/01/23.
//

// MARK: ViewController
import UIKit
import Speech
import AVKit
import SwiftUI
import AVFoundation

class ViewController: UIViewController {

    @IBOutlet weak var btnStart : UIButton!
    @IBOutlet weak var lblText : UITextView!
    @IBOutlet weak var languageButton: UIBarButtonItem!
    
    var speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    var recognitionRequest : SFSpeechAudioBufferRecognitionRequest?
    var recognitionTask : SFSpeechRecognitionTask?
    let audioEngine = AVAudioEngine()
    let synthesizer = AVSpeechSynthesizer()
    
    private var texts:[ScanData] = []
    private var showScannerSheet = false

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
            try audioSession.setCategory(AVAudioSession.Category.playAndRecord, mode: AVAudioSession.Mode.measurement, options: AVAudioSession.CategoryOptions.defaultToSpeaker)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("audioSession properties weren't set because of an error.")
            let alert = UIAlertController(title: "Error", message: "audiosession properties weren't set because of an error", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true)
        }

        self.recognitionRequest = SFSpeechAudioBufferRecognitionRequest()

        let inputNode = audioEngine.inputNode

        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
        }

        recognitionRequest.shouldReportPartialResults = true
        recognitionRequest.requiresOnDeviceRecognition = false

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
            let alert = UIAlertController(title: "Error", message: "audio engine couldn't start because of an error", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true)
        }

        self.lblText.text = "Say something, I'm listening!"
        navigationItem.leftBarButtonItem?.image = UIImage(systemName: "square.on.square")
    }

    @IBAction func speakerButtonTapped(_ sender: UIBarButtonItem) {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        } else {
            let speechUtterance = AVSpeechUtterance(string: lblText.text)
            speechUtterance.rate = AVSpeechUtteranceDefaultSpeechRate
            synthesizer.speak(speechUtterance)
        }
    }
    
    @IBAction func changeLanguageTapped(_ sender: UIBarButtonItem) {
        let actionSheet = UIAlertController(title: "Choose Langauge", message: "", preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "English", style: .default, handler: { _ in
            self.title = "Speak in English"
            self.languageButton.title = "English"
            self.lblText.text = "Say something, I'm listening!"
            self.speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
            self.btnStart.setTitle("Start Recording", for: .normal)
        }))
        actionSheet.addAction(UIAlertAction(title: "Hindi", style: .default, handler: { _ in
            self.title = "हिंदी मे बोलो"
            self.languageButton.title = "Hindi"
            self.lblText.text = "कुछ तो बोलो, मैं सुन रहा हूँ!"
            self.speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "hi"))
            self.btnStart.setTitle("Start Recording", for: .normal)
        }))
        actionSheet.addAction(UIAlertAction(title: "French", style: .default, handler: { _ in
            self.title = "parle en francais"
            self.languageButton.title = "French"
            self.lblText.text = "direquelque chose, je t'écoute!"
            self.speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "fr-FR"))
            self.btnStart.setTitle("Start Recording", for: .normal)
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(actionSheet, animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Speak in English"
        setupSpeech()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if showScannerSheet {
            presentScannerViewController()
        }
    }
    
    @IBAction func copyButtonTapped(_ sender: UIBarButtonItem) {
        UIPasteboard.general.string = lblText.text
        sender.image = UIImage(systemName: "checkmark.circle.fill")
    }
    
    @IBAction func scanButtonTapped(_ sender: UIBarButtonItem) {
        presentScannerViewController()
    }
    
    private func presentScannerViewController() {
        let scannerView = ScannerView { textPerPage in
            // Handle the recognized text as needed
            if let outputText = textPerPage?.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines) {
                // Process the recognized text, update UI, or perform any other actions
                let newScanData = ScanData(content: outputText)
                self.texts.append(newScanData)
                DispatchQueue.main.async {
                    self.lblText.text = newScanData.content
                }
            } else {
                // Handle the case where no text is recognized
                let alert = UIAlertController(title: "Empty Page", message: "no text is recognised from the image", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(alert, animated: true)
            }
        }
        
        let hostingController = UIHostingController(rootView: scannerView)
        present(hostingController, animated: true, completion: nil)
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

