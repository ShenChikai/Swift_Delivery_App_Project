//
//  Extensions.swift
//  Harvest
//
//  Created by Lihan Zhu on 2021/3/2.
//

import Foundation
import UIKit

extension String {
    
    /// Check if a string is a valid email
    func isValidEmail() -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: self)
    }
    
}

extension UIImage {
    
    /// Return the blurred image
    func blur(_ radius: Double) -> UIImage {
        let context = CIContext(options: nil)
        let currentFilter = CIFilter(name: "CIGaussianBlur")
        let beginImage = CIImage(image: self)
        currentFilter!.setValue(beginImage, forKey: kCIInputImageKey)
        currentFilter!.setValue(10, forKey: kCIInputRadiusKey)
        
        let cropFilter = CIFilter(name: "CICrop")
        cropFilter!.setValue(currentFilter!.outputImage, forKey: kCIInputImageKey)
        cropFilter!.setValue(CIVector(cgRect: beginImage!.extent), forKey: "inputRectangle")
        
        let output = cropFilter!.outputImage
        let cgimg = context.createCGImage(output!, from: output!.extent)
        let processedImage = UIImage(cgImage: cgimg!)
        return processedImage
    }
}

extension UITextField {
    
    /// Apply shadow effect with a corner radius
    func applyShadow(color: UIColor = UIColor.gray, cornerRadius: CGFloat) {
        self.borderStyle = .none
        self.backgroundColor = UIColor.white
        self.layer.masksToBounds = false
        self.layer.shadowColor = color.cgColor
        self.layer.shadowOffset = CGSize(width: 0, height: 0)
        self.layer.shadowOpacity = 0.5
        self.backgroundColor = .white
        self.layer.cornerRadius = cornerRadius
        self.layer.sublayerTransform = CATransform3DMakeTranslation(cornerRadius, 0, 0)
    }
    
    /// Set the shadow color
    func setShadowColor(color: UIColor = UIColor.gray) {
        self.layer.shadowColor = color.cgColor
    }
    
}

extension Notification.Name {
    static let produceBackgroundTapped = Notification.Name("produceBackgroundTapped")
}

extension UIView {
    
    /// Apply drop shadow effect
    func dropShadow() {
        self.layer.masksToBounds = false
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowOffset = CGSize(width: 0, height: 0)
        self.layer.shadowOpacity = 0.5
    }
    
    /// Apply corner radius
    func cornerRadius(cornerRadius: CGFloat) {
        self.layer.cornerRadius = cornerRadius
        self.layer.masksToBounds = false
    }
    
    /// Start tapping animation with a completion called at the end
    func tapAnimation(_ completion: @escaping () -> Void) {
        isUserInteractionEnabled = false
        UIView.animate(withDuration: 0.1,
                       delay: 0,
                       options: .curveLinear,
                       animations: { [weak self] in
                        self?.transform = CGAffineTransform.init(scaleX: 0.95, y: 0.95)
                       }) {  (done) in
            UIView.animate(withDuration: 0.1,
                           delay: 0,
                           options: .curveLinear,
                           animations: { [weak self] in
                            self?.transform = CGAffineTransform.init(scaleX: 1, y: 1)
                           }) { [weak self] (_) in
                self?.isUserInteractionEnabled = true
                completion()
            }
                       }
    }
}
