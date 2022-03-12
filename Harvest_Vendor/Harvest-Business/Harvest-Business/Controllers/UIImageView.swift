//
//  UIImageView.swift
//  Harvest-Business
//
//  Created by Denny Shen on 2021/2/10.
//

import UIKit

extension UIImageView {
    func roundedImage() -> Void {
        self.layer.cornerRadius = self.frame.size.width / 10
        self.clipsToBounds = true
    }
}
