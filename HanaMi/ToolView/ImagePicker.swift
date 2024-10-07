import SwiftUI
import UIKit
import AVFoundation
import UniformTypeIdentifiers // 使用此框架替代 MobileCoreServices

struct ImagePicker: UIViewControllerRepresentable {
    @Environment(\.presentationMode) var presentationMode
    @Binding var mediaURL: URL?
    @Binding var mediaType: MediaType?
    var sourceType: UIImagePickerController.SourceType = .camera

    enum MediaType {
        case photo
        case video
    }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        var parent: ImagePicker

        init(parent: ImagePicker) {
            self.parent = parent
        }

        // 当用户完成拍摄或选择媒体时调用
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            defer {
                parent.presentationMode.wrappedValue.dismiss()
            }

            // 检查媒体类型
            if let mediaType = info[.mediaType] as? String {
                if mediaType == UTType.image.identifier {
                    // 用户拍摄或选择了一张照片
                    if let image = info[.originalImage] as? UIImage {
                        // 将图像保存到临时目录并获取 URL
                        if let data = image.jpegData(compressionQuality: 1.0) {
                            let tempDirectory = FileManager.default.temporaryDirectory
                            let fileName = UUID().uuidString + ".jpg"
                            let fileURL = tempDirectory.appendingPathComponent(fileName)
                            do {
                                try data.write(to: fileURL)
                                parent.mediaURL = fileURL
                                parent.mediaType = .photo
                            } catch {
                                print("无法保存图像文件：\(error.localizedDescription)")
                            }
                        }
                    }
                } else if mediaType == UTType.movie.identifier {
                    // 用户拍摄或选择了一个视频
                    if let videoURL = info[.mediaURL] as? URL {
                        parent.mediaURL = videoURL
                        parent.mediaType = .video
                    }
                }
            }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType

        // 设置允许的媒体类型，包括照片和视频
        picker.mediaTypes = [UTType.image.identifier, UTType.movie.identifier]

        // 设置视频质量（可根据需要调整）
        picker.videoQuality = .typeHigh

        // 设置最大录制时长（可选）
        // picker.videoMaximumDuration = 60.0 // 最长录制60秒

        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        // 不需要更新
    }
}
