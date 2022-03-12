//
//  UiUtilities.swift
//  Harvest-Business
//
//  Created by Lihan Zhu on 2021/2/9.
//

import Foundation
import UIKit

class UIUtilities {
    static func setRoundButtonWithShadow(button: UIButton) {
        button.layer.cornerRadius = 10
//        button.layer.borderWidth = 1
        button.layer.shadowColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.25).cgColor
        button.layer.shadowOffset = CGSize(width: 0.0, height: 2.0)
        button.layer.shadowOpacity = 1.0
        button.layer.shadowRadius = 0.0
        button.layer.masksToBounds = false
        
        let blur = UIVisualEffectView(effect: UIBlurEffect(style:
                    UIBlurEffect.Style.light))
        blur.frame = button.bounds
        blur.clipsToBounds = true
        blur.isUserInteractionEnabled = false //This allows touches to forward to the button.
        button.insertSubview(blur, at: 0)
    }
}

extension String {
    
    /// Check if a string is a valid email
    func isValidEmail() -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: self)
    }
    
}

extension UIStackView {
    func customize(cornerRadius: CGFloat = 0, borderColor: CGColor, borderWidth: CGFloat, opacity: Float = 1) {
        let subView = UIView(frame: bounds)
        subView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        subView.layer.cornerRadius = cornerRadius
        subView.layer.borderColor = borderColor
        subView.layer.borderWidth = borderWidth
        subView.layer.opacity = opacity
        subView.layer.masksToBounds = true
        subView.clipsToBounds = true
        insertSubview(subView, at: 0)
    }
}

extension Date {
    func dayOfTheWeek() -> String? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE"
        return dateFormatter.string(from: self as Date)
    }
}

extension Dictionary {
    subscript(i: Int) -> (key: Key, value: Value) {
        get {
            return self[index(startIndex, offsetBy: i)]
        }
    }
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
