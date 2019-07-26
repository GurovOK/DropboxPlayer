//
//  TopCornersView.swift
//  DropboxPlayer
//
//  Created by iOS Developer on 23/07/2019.
//  Copyright © 2019 Kuktu. All rights reserved.
//

import UIKit

class TopCornersView: UIView {

    // MARK: - Properties

    private let backgroundMaskLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        return layer
    }()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    // MARK: - Overrides

    override func layoutSubviews() {
        super.layoutSubviews()
        backgroundMaskLayer.frame = bounds
        backgroundMaskLayer.path = UIBezierPath(roundedRect: bounds,
                                                byRoundingCorners: [.topLeft, .topRight],
                                                cornerRadii: CGSize(width: 16, height: 16)).cgPath
    }

    // MARK: - Private methods

    private func setup() {
        layer.mask = backgroundMaskLayer
    }
}
