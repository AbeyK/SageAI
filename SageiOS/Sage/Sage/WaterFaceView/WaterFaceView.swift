//
//  WaterFaceView.swift
//  Sage
//
//  Created by hassan Khan on 4/30/25.
//

import UIKit


public class WaterFaceView: UIView {
    private let containerLayer = CALayer()
    private let circleLayer = CAShapeLayer()
    private let leftEyeLayer = CAShapeLayer()
    private let rightEyeLayer = CAShapeLayer()
    private let smileLayer = CAShapeLayer()
    private let waterAnimationLayer = CAShapeLayer()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        // Container layer for clipping
        containerLayer.masksToBounds = true
        layer.addSublayer(containerLayer)
        
        // Main circle
        circleLayer.fillColor = UIColor(red: 0.4, green: 0.6, blue: 1.0, alpha: 1.0).cgColor
        containerLayer.addSublayer(circleLayer)
        
        // Water animation layer
        waterAnimationLayer.fillColor = UIColor(red: 0.5, green: 0.7, blue: 1.0, alpha: 0.3).cgColor
        containerLayer.addSublayer(waterAnimationLayer)
        
        // Eyes and smile on top of water
        leftEyeLayer.fillColor = UIColor.black.cgColor
        rightEyeLayer.fillColor = UIColor.black.cgColor
        smileLayer.fillColor = nil
        smileLayer.strokeColor = UIColor.black.cgColor
        smileLayer.lineWidth = 3
        
        layer.addSublayer(leftEyeLayer)
        layer.addSublayer(rightEyeLayer)
        layer.addSublayer(smileLayer)
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        let size = min(bounds.width, bounds.height)
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        
        // Update container frame and mask
        containerLayer.frame = bounds
        let maskLayer = CAShapeLayer()
        let circlePath = UIBezierPath(arcCenter: center,
                                    radius: size/2,
                                    startAngle: 0,
                                    endAngle: 2 * .pi,
                                    clockwise: true)
        maskLayer.path = circlePath.cgPath
        containerLayer.mask = maskLayer
        
        // Main circle
        circleLayer.frame = bounds
        circleLayer.path = circlePath.cgPath
        
        // Eyes
        let eyeSize: CGFloat = size * 0.08
        let eyeY = center.y - size * 0.05
        let eyeSpacing = size * 0.15
        
        let leftEyePath = UIBezierPath(ovalIn: CGRect(x: center.x - eyeSpacing - eyeSize/2,
                                                     y: eyeY - eyeSize/2,
                                                     width: eyeSize,
                                                     height: eyeSize))
        leftEyeLayer.path = leftEyePath.cgPath
        
        let rightEyePath = UIBezierPath(ovalIn: CGRect(x: center.x + eyeSpacing - eyeSize/2,
                                                      y: eyeY - eyeSize/2,
                                                      width: eyeSize,
                                                      height: eyeSize))
        rightEyeLayer.path = rightEyePath.cgPath
        
        // Smile
        let smilePath = UIBezierPath()
        let smileWidth = size * 0.3
        let smileHeight = size * 0.15
        let smileY = center.y + size * 0.1
        
        smilePath.move(to: CGPoint(x: center.x - smileWidth/2, y: smileY))
        smilePath.addQuadCurve(to: CGPoint(x: center.x + smileWidth/2, y: smileY),
                              controlPoint: CGPoint(x: center.x, y: smileY + smileHeight))
        smileLayer.path = smilePath.cgPath
        
        // Start water animation
        startWaterAnimation()
    }
    
    private func startWaterAnimation() {
        waterAnimationLayer.removeAllAnimations()
        
        let size = min(bounds.width, bounds.height)
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        
        // Create wave paths
        let createWavePath = { (phase: CGFloat) -> CGPath in
            let path = UIBezierPath()
            let width = size
            let height = size
            
            path.move(to: CGPoint(x: 0, y: height))
            
            // Draw the wave
            let wavelength = width / 2
            let amplitude = height * 0.05
            let midHeight = height * 0.6 // Position the waves at 60% from the top
            
            var x: CGFloat = 0
            while x <= width {
                let y = midHeight + amplitude * sin((x / wavelength) * 2 * .pi + phase)
                path.addLine(to: CGPoint(x: x, y: y))
                x += 1
            }
            
            // Complete the path
            path.addLine(to: CGPoint(x: width, y: height))
            path.addLine(to: CGPoint(x: 0, y: height))
            path.close()
            
            return path.cgPath
        }
        
        // Create animation
        let animation = CABasicAnimation(keyPath: "path")
        animation.fromValue = createWavePath(0)
        animation.toValue = createWavePath(.pi * 2)
        animation.duration = 2
        animation.timingFunction = CAMediaTimingFunction(name: .linear)
        animation.repeatCount = .infinity
        
        waterAnimationLayer.frame = bounds
        waterAnimationLayer.path = createWavePath(0)
        waterAnimationLayer.add(animation, forKey: "waterAnimation")
    }
}
