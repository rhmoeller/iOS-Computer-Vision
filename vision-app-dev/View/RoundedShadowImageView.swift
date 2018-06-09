//
//  RoundedShadowImageView.swift
//  vision-app-dev
//
//  Created by Robert Møller on 09/06/2018.
//  Copyright © 2018 Robert Møller. All rights reserved.
//

import UIKit

class RoundedShadowImageView: UIImageView {
    override func awakeFromNib() {
        self.layer.shadowColor = UIColor.darkGray.cgColor
        self.layer.shadowRadius = 15
        self.layer.shadowOpacity = 0.75
        self.layer.cornerRadius = 15
    }
}
