//
//  TestViewController.swift
//  bossjock
//
//  Created by Tim Richardson on 02/06/2018.
//  Copyright © 2018 TRCO Apps. All rights reserved.
//

import UIKit
import AudioKit

class ViewController: UIViewController {
    
    @IBOutlet weak var cartButton: UIButton!
    @IBOutlet weak var micButton: UIButton!
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var playbackButton: UIButton! {
        didSet {
            playbackButton.isHidden = true
        }
    }
    
    var micOn = false {
        didSet {
            update(micState: micOn)
        }
    }
    
    var cartOn = false {
        didSet {
            update(cartState: cartOn)
        }
    }
    
    var recording = false {
        didSet {
            update(recordingState: recording)
        }
    }
    
    var mic: AKMicrophone = AKMicrophone()
    var micMixer: AKMixer!
    var micBooster: AKBooster!
    
    var cartMixer: AKMixer!
    var cartPlayer: AKPlayer?
    
    var outputMixer: AKMixer!
    
    var recorder: AKNodeRecorder?
    var recordingMixer: AKMixer!
    var recordingOutputMixer: AKMixer!
    
    var player: AKPlayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Session settings
        do {
            AKSettings.bufferLength = .short // 128 samples
            try AKSettings.setSession(category: .playAndRecord, with: .allowBluetoothA2DP)
        } catch {
            AKLog("Could not set session category.")
        }
        
        AKSettings.defaultToSpeaker = true
        
        // Setup the microphone
        micMixer = AKMixer(mic)
        micBooster = AKBooster(micMixer)
        micBooster.gain = 0
        
        // Load the cart playing object
        let path = Bundle.main.path(forResource: "audio1", ofType: ".wav")
        let url = URL(fileURLWithPath: path!)
        cartPlayer = AKPlayer(url: url)
        cartPlayer?.isLooping = true
        
        // Setup the cart mixer
        cartMixer = AKMixer(cartPlayer)
        
        // The recorder should record the Mic, and the Cart
        recordingMixer = AKMixer(cartMixer, micBooster)
        recorder = try? AKNodeRecorder(node: recordingMixer)
        
        // Pass the recording mixer through an output mixer whose volume
        // is 0 so it's not heard in the output. If we don't do this, audio
        // is not pulled through the recording mixer at all
        recordingOutputMixer = AKMixer(recordingMixer)
        recordingOutputMixer.volume = 0
        
        // Setup the output mixer
        outputMixer = AKMixer(cartMixer, recordingOutputMixer)
        
        // Pass the output mixer to AudioKit
        AudioKit.output = outputMixer
        
        // Start AudioKit
        do {
            try AudioKit.start()
        } catch {
            print("AudioKit did not start! \(error)")
        }
    }
    
    @IBAction func toggleMic(_ sender: UIButton) {
        
        // for now, only allow toggling when recording
        guard recording else {
            return
        }
        
        micOn = !micOn
    }
    
    @IBAction func toggleRecording(_ sender: UIButton) {
        
        recording = !recording
    }
    
    @IBAction func toggleCart(_ sender: UIButton) {
        
        // for now, only allow toggling when recording
        guard recording else {
            return
        }
        
        cartOn = !cartOn
    }
    
    @IBAction func togglePlaying(_ sender: UIButton) {
        
        if player?.isPlaying == true {
            player?.stop()
            sender.setTitle("Play Recording", for: .normal)
            recordButton.isHidden = false
        } else {
            recordButton.isHidden = true
            player?.play()
            sender.setTitle("Stop", for: .normal)
        }
    }
    
    func update(micState: Bool) {
        
        if micState {
            micButton.setTitle("Mic On", for: .normal)
            micBooster.gain = 1
            cartMixer.volume = 0.2
        } else {
            micButton.setTitle("Mic Off", for: .normal)
            micBooster.gain = 0
            cartMixer.volume = 1
        }
    }
    
    func update(cartState: Bool) {
        
        if cartState {
            cartButton.setTitle("Cart On", for: .normal)
            cartMixer.volume = 1
            
            cartPlayer?.play()
            
        } else {
            cartButton.setTitle("Cart Off", for: .normal)
            cartMixer.volume = 0
            
            cartPlayer?.stop()
        }
    }
    
    func update(recordingState: Bool) {
        
        micOn = false
        cartOn = false
        
        if recordingState {
            
            playbackButton.isHidden = true
            recordButton.setTitle("Recording", for: .normal)
            
            
            try? recorder?.record()
            
        } else {
            recordButton.setTitle("Record", for: .normal)
            
            recorder?.stop()
            
            if let recordedFile = recorder?.audioFile {
                
                if player == nil {
                    
                    player = AKPlayer(audioFile: recordedFile)
                    outputMixer.connect(input: player!)
                    
                    player?.completionHandler = {
                        DispatchQueue.main.async {
                            self.playbackButton.setTitle("Play Recording", for: .normal)
                            self.recordButton.isHidden = false
                        }
                    }
                    
                    
                } else {
                    player?.load(audioFile: recordedFile)
                }
                
                playbackButton.isHidden = false
                
                recordedFile.exportAsynchronously(name: "test.caf", baseDir: .documents, exportFormat: .caf) { (audioFile, error) in
                    
                    if let error = error {
                        print("Failed to export! \(error)")
                    } else {
                        print("Successfully exported the audio file")
                        try? self.recorder?.reset()
                    }
                }
            }
        }
    }
}
