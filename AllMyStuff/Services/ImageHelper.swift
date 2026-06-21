import SwiftUI
import UIKit

struct ImageHelper {
    static func resizeImageData(_ data: Data, maxDimension: Int = 1024) -> Data? {
        guard let uiImage = UIImage(data: data) else { return nil }
        let size = uiImage.size
        let scale: CGFloat
        if size.width > CGFloat(maxDimension) || size.height > CGFloat(maxDimension) {
            let ratio = min(CGFloat(maxDimension) / size.width, CGFloat(maxDimension) / size.height)
            scale = ratio
        } else {
            scale = 1.0
        }
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        defer { UIGraphicsEndImageContext() }
        uiImage.draw(in: CGRect(origin: .zero, size: newSize))
        guard let resized = UIGraphicsGetImageFromCurrentImageContext() else { return nil }
        return resized.jpegData(compressionQuality: 0.75)
    }

    static func imageDataToImage(_ data: Data?) -> Image? {
        guard let data, let uiImage = UIImage(data: data) else { return nil }
        return Image(uiImage: uiImage)
    }
}
