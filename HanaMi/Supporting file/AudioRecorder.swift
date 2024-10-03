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
            AVSampleRateKey: 12000,
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
            startMonitoringVolume()
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
            audioPlayer = try AVAudioPlayer(contentsOf: url)
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

    // 監控音量
    func startMonitoringVolume() {
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            if self.audioRecorder?.isRecording == true {
                self.audioRecorder?.updateMeters()
                let power = self.audioRecorder?.averagePower(forChannel: 0) ?? -160
                self.currentVolume = self.normalizedPowerLevel(fromDecibels: power)
            } else {
                timer.invalidate()
            }
        }
    }

    // 將音量分貝轉換為 0 到 1 的範圍
    func normalizedPowerLevel(fromDecibels decibels: Float) -> Float {
        let minDb: Float = -80
        if decibels < minDb {
            return 0.0
        } else if decibels >= 0 {
            return 1.0
        } else {
            return (decibels + abs(minDb)) / abs(minDb)
        }
    }
}
