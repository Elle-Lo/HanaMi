import SwiftUI

//extension Color {
//    init(hex: String) {
//        let scanner = Scanner(string: hex)
//        scanner.currentIndex = hex.startIndex
//        var rgbValue: UInt64 = 0
//        scanner.scanHexInt64(&rgbValue)
//        
//        let red = Double((rgbValue >> 16) & 0xff) / 255
//        let green = Double((rgbValue >> 8) & 0xff) / 255
//        let blue = Double(rgbValue & 0xff) / 255
//        
//        self.init(red: red, green: green, blue: blue)
//    }
//}
extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        _ = scanner.scanString("#") // 跳過 #
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        let r = Double((rgb >> 16) & 0xFF) / 255.0
        let g = Double((rgb >> 8) & 0xFF) / 255.0
        let b = Double(rgb & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}

extension View {
    func snapshot() -> UIImage {
        let controller = UIHostingController(rootView: self)
        let view = controller.view
        
        let targetSize = controller.view.intrinsicContentSize
        view?.bounds = CGRect(origin: .zero, size: targetSize)
        view?.backgroundColor = .clear
        
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            view?.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
        }
    }
    
    func asImage() -> UIImage {
            let controller = UIHostingController(rootView: self)
            let view = controller.view

            let targetSize = controller.view.intrinsicContentSize
            view?.bounds = CGRect(origin: .zero, size: targetSize)
            view?.backgroundColor = .clear

            let renderer = UIGraphicsImageRenderer(size: targetSize)
            return renderer.image { _ in
                view?.drawHierarchy(in: view!.bounds, afterScreenUpdates: true)
            }
        }
}

extension UIView {

    func asImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        return renderer.image { rendererContext in
            layer.render(in: rendererContext.cgContext)
        }
    }
    
    func snapshot() -> UIImage {
            let renderer = UIGraphicsImageRenderer(bounds: bounds)
            return renderer.image { rendererContext in
                layer.render(in: rendererContext.cgContext)
            }
        }
}

extension UIImage {
    // 缩放图片到指定尺寸
    func resized(to size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        self.draw(in: CGRect(origin: .zero, size: size))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resizedImage
    }
}

extension Date {
    func isWithinPast(minutes: Int) -> Bool {
        let now = Date()
        let timeAgo = Date().addingTimeInterval(-1 * TimeInterval(60 * minutes))
        let range = timeAgo...now
        return range.contains(self)
    }
}
