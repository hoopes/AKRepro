import UIKit
import AudioKit

class ViewController: UIViewController {
    
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var playbackButton: UIButton! {
        didSet {
            playbackButton.isHidden = true
        }
    }
    
    var recording = false {
        didSet {
            update(recordingState: recording)
        }
    }
    
    let mic = AKMicrophone()
    let micMixer = AKMixer()
    let outputMixer = AKMixer()
    lazy var recorder: AKNodeRecorder? = try? AKNodeRecorder(node: micMixer)
    let recordingOutputMixer: AKMixer = {
        let mixer = AKMixer()
        mixer.volume = 0
        return mixer
    }()
    
    var player = AVAudioPlayerNode()
    var audioFile: AVAudioFile?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        AKSettings.defaultToSpeaker = true
        
        // Setup the microphone
        mic.connect(to: micMixer)
            .connect(to: recordingOutputMixer)
            .connect(to: outputMixer)
        
        player.connect(to: outputMixer)
        
        AudioKit.output = outputMixer
        
        // Start AudioKit
        do {
            try AudioKit.start()
        } catch {
            print("AudioKit did not start! \(error)")
        }
        
    }
    
    @IBAction func toggleRecording(_ sender: UIButton) {
        
        recording = !recording
    }
    
    
    
    @IBAction func togglePlaying(_ sender: UIButton) {
        
        if player.isPlaying {
            player.stop()
            sender.setTitle("Play Recording", for: .normal)
            recordButton.isHidden = false
        } else {
            recordButton.isHidden = true
            if let audioFile = self.audioFile {
                player.scheduleFile(audioFile, at: nil, completionHandler: nil)
                player.play()
            }
            sender.setTitle("Stop", for: .normal)
        }
    }
    
    func update(recordingState: Bool) {
        
        if recordingState {
            
            playbackButton.isHidden = true
            recordButton.setTitle("Recording", for: .normal)
            
            do {
                try recorder?.record()
            } catch {
                print(error)
            }
            
        } else {
            recordButton.setTitle("Record", for: .normal)
            
            recorder?.stop()
            
            if let recordedFile = recorder?.audioFile {
                
                audioFile = recordedFile
                
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

