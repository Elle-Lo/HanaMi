import SwiftUI
import UIKit
import AVFoundation
import UniformTypeIdentifiers

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

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            defer {
                parent.presentationMode.wrappedValue.dismiss()
            }

            if let mediaType = info[.mediaType] as? String {
                if mediaType == UTType.image.identifier {
                   
                    if let image = info[.originalImage] as? UIImage {
                       
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

        picker.mediaTypes = [UTType.image.identifier, UTType.movie.identifier]

        picker.videoQuality = .typeHigh

        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
    }
}
