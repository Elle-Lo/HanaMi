import AVFoundation
import SwiftUI

class AudioRecorder: NSObject, AVAudioRecorderDelegate, ObservableObject {
    var audioRecorder: AVAudioRecorder?
    @Published var recordingURL: URL?

    // 开始录音
    func startRecording() {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let audioFilename = paths[0].appendingPathComponent("recording.m4a")
        
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record()
            print("录音开始")
        } catch {
            print("录音失败：\(error.localizedDescription)")
        }
    }

    // 停止录音
    func stopRecording() {
        audioRecorder?.stop()
        audioRecorder = nil
        print("录音结束")

        // 保存录音文件路径
        if let audioURL = audioRecorder?.url {
            self.recordingURL = audioURL
        }
    }
    
    // 获取录音文件路径
    func getAudioFilePath() -> URL? {
        return audioRecorder?.url
    }
}
