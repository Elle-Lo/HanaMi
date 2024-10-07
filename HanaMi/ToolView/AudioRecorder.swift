import AVFoundation
import SwiftUI

class AudioRecorder: NSObject, AVAudioRecorderDelegate, ObservableObject {
    var audioRecorder: AVAudioRecorder?
    var audioPlayer: AVAudioPlayer?
    @Published var recordingURL: URL?
    @Published var currentVolume: Float = 0.0

    // 開始錄音，並刪除舊的錄音檔案
    func startRecording() {
        if let previousURL = recordingURL {
            try? FileManager.default.removeItem(at: previousURL) // 刪除舊錄音
        }

        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let audioFilename = paths[0].appendingPathComponent("\(UUID().uuidString).m4a")

        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,  // 常見的音質較好的取樣率
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        do {
            try setupAudioSession()
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.record()
            recordingURL = audioFilename // 更新錄音檔案 URL
//            startMonitoringVolume()
        } catch {
            print("錄音失敗：\(error.localizedDescription)")
        }
    }

    // 停止錄音
    func stopRecording() {
        audioRecorder?.stop()
        audioRecorder = nil
    }
    
    // 播放錄音
    func playRecording(from url: URL) {
            do {
                try setupAudioSession()  // 在播放之前設置音訊會話
                audioPlayer = try AVAudioPlayer(contentsOf: url)
                audioPlayer?.volume = 1.0  // 設置音量為最大
                audioPlayer?.play()
            } catch {
                print("播放錄音失敗: \(error.localizedDescription)")
            }
        }

    // 刪除本地錄音檔案
    func deleteRecordingLocally() {
        if let url = recordingURL {
            try? FileManager.default.removeItem(at: url)
            recordingURL = nil
        }
    }

    // 設置音訊會話
    func setupAudioSession() throws {
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playAndRecord, mode: .default)
        try audioSession.setActive(true)
    }

}
