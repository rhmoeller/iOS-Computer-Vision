//
//  RoundedShadowView.swift
//  vision-app-dev
//
//  Created by Robert Møller on 09/06/2018.
//  Copyright © 2018 Robert Møller. All rights reserved.
//

import UIKit

class RoundedShadowView: UIView {
    override func awakeFromNib() {
        self.layer.shadowColor = UIColor.darkGray.cgColor
        self.layer.shadowRadius = 15
        self.layer.shadowOpacity = 0.75
        self.layer.cornerRadius = self.frame.height / 2
    }
}
