//
//  WaterFaceView.swift
//  Sage
//
//  Created by hassan Khan on 4/30/25.
//

import UIKit

public class WaterFaceView: UIView {
    
    private let waveLayer = CAShapeLayer()
    private let gradientLayer = CAGradientLayer()
    private var displayLink: CADisplayLink?
    private var startTime: CFTimeInterval = 0
    
    private let faceLayer = CAShapeLayer()
    private let leftEyeLayer = CAShapeLayer()
    private let rightEyeLayer = CAShapeLayer()
    private let mouthLayer = CAShapeLayer()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayers()
        startWaveAnimation()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayers()
        startWaveAnimation()
    }
    
    private func setupLayers() {
        // Set up gradient
        gradientLayer.colors = [
            UIColor(red: 0.4, green: 0.8, blue: 1.0, alpha: 1.0).cgColor,
            UIColor(red: 0.2, green: 0.6, blue: 0.9, alpha: 1.0).cgColor
        ]
        gradientLayer.locations = [0.0, 1.0]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
        
        // Set up wave
        waveLayer.fillColor = UIColor.clear.cgColor
        waveLayer.strokeColor = UIColor.white.cgColor
        waveLayer.lineWidth = 2.0
        
        // Set up face components
        faceLayer.fillColor = UIColor.clear.cgColor
        faceLayer.strokeColor = UIColor.clear.cgColor
        faceLayer.lineWidth = 0.0
        
        leftEyeLayer.fillColor = UIColor.black.cgColor
        leftEyeLayer.strokeColor = UIColor.black.cgColor
        
        rightEyeLayer.fillColor = UIColor.black.cgColor
        rightEyeLayer.strokeColor = UIColor.black.cgColor
        
        mouthLayer.fillColor = UIColor.clear.cgColor
        mouthLayer.strokeColor = UIColor.black.cgColor
        mouthLayer.lineWidth = 4.0
        
        layer.addSublayer(gradientLayer)
        layer.addSublayer(waveLayer)
        layer.addSublayer(faceLayer)
        layer.addSublayer(leftEyeLayer)
        layer.addSublayer(rightEyeLayer)
        layer.addSublayer(mouthLayer)
        
        // Apply mask to wave layer
        waveLayer.mask = faceLayer
        
        layer.cornerRadius = bounds.width / 2
        clipsToBounds = true
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        gradientLayer.frame = bounds

        // Draw face
        let facePath = UIBezierPath(ovalIn: bounds)
        faceLayer.path = facePath.cgPath

        // Ensure the view is circular
        layer.cornerRadius = bounds.width / 2
        clipsToBounds = true

        // Draw eyes
        let eyeSize = CGSize(width: bounds.width * 0.08, height: bounds.width * 0.12)
        let eyeY = bounds.height * 0.35

        let leftEyeRect = CGRect(
            x: bounds.width * 0.3,
            y: eyeY,
            width: eyeSize.width,
            height: eyeSize.height
        )
        let rightEyeRect = CGRect(
            x: bounds.width * 0.6,
            y: eyeY,
            width: eyeSize.width,
            height: eyeSize.height
        )

        leftEyeLayer.path = UIBezierPath(ovalIn: leftEyeRect).cgPath
        rightEyeLayer.path = UIBezierPath(ovalIn: rightEyeRect).cgPath

        // Draw mouth
        let mouthPath = UIBezierPath()
        let mouthY = bounds.height * 0.7
        mouthPath.move(to: CGPoint(x: bounds.width * 0.3, y: mouthY))
        mouthPath.addQuadCurve(
            to: CGPoint(x: bounds.width * 0.7, y: mouthY),
            controlPoint: CGPoint(x: bounds.width * 0.5, y: mouthY + bounds.height * 0.15)
        )
        mouthLayer.path = mouthPath.cgPath
    }
    
    private func startWaveAnimation() {
        startTime = CACurrentMediaTime()
        displayLink = CADisplayLink(target: self, selector: #selector(updateWave))
        displayLink?.add(to: .main, forMode: .common)
    }
    
    @objc private func updateWave() {
        let currentTime = CACurrentMediaTime()
        let elapsedTime = currentTime - startTime
        
        let path = UIBezierPath()
        let width = bounds.width
        let height = bounds.height
        let midHeight = height * 0.7
        
        path.move(to: CGPoint(x: 0, y: height))
        
        for x in stride(from: 0, through: width, by: 1) {
            let relativeX = x / width
            let normalizedX = relativeX * .pi * 2
            
            let y = midHeight + sin(normalizedX + elapsedTime * 2) * 10
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        path.addLine(to: CGPoint(x: width, y: height))
        path.close()
        
        waveLayer.path = path.cgPath
    }
    
    deinit {
        displayLink?.invalidate()
    }
} 