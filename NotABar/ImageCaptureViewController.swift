//
//  ImageCaptureViewController.swift
//  NotABar
//
//  Created by Josh Lytle on 5/22/17.
//  Copyright © 2017 SoggyMop LLC. All rights reserved.
//

import UIKit
import AVFoundation

extension ImageCaptureViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        DispatchQueue.main.async {
            self.captureButton.isEnabled = true
        
            guard error == nil else { return }
            guard let cgImage = photo.cgImageRepresentation() else { return }
            let image = UIImage(cgImage: cgImage, scale: 1.0, orientation: UIImage.Orientation.right)
        
            self.imageView.image = image
            self.imageView.isHidden = false
            self.previewView.isHidden = true
            
            let renderer = UIGraphicsImageRenderer(size: self.imageView.bounds.size)
            let viewFinderImage = renderer.image { _ in
                self.imageView.drawHierarchy(in: self.imageView.bounds, afterScreenUpdates: true)
            }
            let testImage = self.cropImage(viewFinderImage, toRect: self.croppingView.frame, viewWidth: self.imageView.bounds.width, viewHeight: self.imageView.bounds.height)
            
            let resultVC = self.storyboard?.instantiateViewController(withIdentifier: "ResultViewController") as! ResultViewController
            resultVC.image = image
            resultVC.testImage = testImage

            self.navigationController?.pushViewController(resultVC, animated: true)
        }
    }
}

class ImageCaptureViewController: UIViewController {
    
    @IBOutlet weak var previewView: UIView!
    @IBOutlet weak var captureButton: UIButton!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var croppingView: UIView!
    
    var session: AVCaptureSession?
    var stillImageOutput: AVCapturePhotoOutput?
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    var hasCamera: Bool = true

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    //MARK:- Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        setNeedsStatusBarAppearanceUpdate()
        styleLayers()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        guard AVCaptureDevice.authorizationStatus(for: AVMediaType.video) == .authorized else {
            performSegue(withIdentifier: "ShowIntro", sender: nil)
            return
        }
        
        navigationController?.setNavigationBarHidden(true, animated: true)
        
        imageView.isHidden = true
        previewView.isHidden = false
        setupCamera()
        session?.startRunning()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        session?.stopRunning()
        imageView.image = nil
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        previewView.layoutIfNeeded()
        videoPreviewLayer?.frame = previewView.bounds
    }
    
    //MARK:- IBActions
    @IBAction func captureButtonTapped(_ sender: UIButton) {
        captureButton.isEnabled = false
        
        guard hasCamera == true else {
            let resultVC = self.storyboard?.instantiateViewController(withIdentifier: "ResultViewController") as! ResultViewController
            let someImage = UIImage(named: "bar-sample")
//            let someImage = UIImage(named: "table-sample")

            imageView.image = someImage
            imageView.isHidden = false
            previewView.isHidden = true
            let renderer = UIGraphicsImageRenderer(size: self.imageView.bounds.size)
            let viewFinderImage = renderer.image { _ in
                self.imageView.drawHierarchy(in: self.imageView.bounds, afterScreenUpdates: true)
            }
            resultVC.image = someImage
            let testImage = self.cropImage(viewFinderImage, toRect: self.croppingView.frame, viewWidth: self.imageView.bounds.width, viewHeight: self.imageView.bounds.height)
            resultVC.testImage = testImage
            navigationController?.pushViewController(resultVC, animated: true)
            return
        }
        
        let settings = AVCapturePhotoSettings(format: [AVVideoCodecKey : AVVideoCodecType.jpeg, AVVideoCompressionPropertiesKey: [AVVideoQualityKey : NSNumber(value: 0.7)]])
        settings.flashMode = .off
        
        stillImageOutput?.connection(with: .video)?.videoOrientation = .portrait
        stillImageOutput?.capturePhoto(with: settings, delegate: self)
    }
    
    private func styleLayers() {
        let borderWidth: CGFloat = 2.0
        
        captureButton.layer.cornerRadius = captureButton.frame.width * 0.5
        captureButton.layer.masksToBounds = true
        captureButton.layer.borderColor = UIColor(named: "nbSecondary")?.cgColor
        captureButton.layer.borderWidth = borderWidth
        captureButton.backgroundColor = UIColor.white
        
        if let buttonSuperview = captureButton.superview {
            buttonSuperview.layer.cornerRadius = buttonSuperview.frame.width * 0.5
            buttonSuperview.layer.masksToBounds = true
            buttonSuperview.layer.borderColor = UIColor.white.cgColor
            buttonSuperview.layer.borderWidth = borderWidth + 2
        }
    }
    
    private func cropImage(_ inputImage: UIImage, toRect cropRect: CGRect, viewWidth: CGFloat, viewHeight: CGFloat) -> UIImage? {
        let imageViewScale = max((inputImage.size.width * inputImage.scale) / viewWidth,
                                 (inputImage.size.height * inputImage.scale) / viewHeight)

        // Scale cropRect to handle images larger than shown-on-screen size
        let cropZone = CGRect(x:cropRect.origin.x * imageViewScale,
                              y:cropRect.origin.y * imageViewScale,
                              width:cropRect.size.width * imageViewScale,
                              height:cropRect.size.height * imageViewScale)

        // Perform cropping in Core Graphics
        guard let cutImageRef: CGImage = inputImage.cgImage?.cropping(to:cropZone) else { return nil }

        // Return image to UIImage
        let croppedImage: UIImage = UIImage(cgImage: cutImageRef)
        return croppedImage
    }
    
    private func setupCamera() {
        guard let backCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: AVCaptureDevice.Position.back) else {
            //TODO: No back camera available.
            self.hasCamera = false
            return
        }
        
        if session == nil {
            session = AVCaptureSession()
        }
        
        guard let session = session else { return }
        session.beginConfiguration()
        session.sessionPreset = .photo
        
        var error: NSError?
        var input: AVCaptureDeviceInput!
        
        do {
            input = try AVCaptureDeviceInput(device: backCamera)
        } catch let error1 as NSError {
            error = error1
            input = nil
            print(error!.localizedDescription)
        }
        
        if error == nil && session.canAddInput(input) {
            session.addInput(input)
            
            let photoSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg, AVVideoCompressionPropertiesKey: [AVVideoQualityKey : NSNumber(value: 0.7)]])
            stillImageOutput = AVCapturePhotoOutput()
            
            guard let stillImageOutput = stillImageOutput else { return }
            stillImageOutput.setPreparedPhotoSettingsArray([photoSettings], completionHandler: nil)
            session.addOutput(stillImageOutput)
            
            view.layoutSubviews()
            
            if videoPreviewLayer != nil {
                videoPreviewLayer = nil
            }
            
            videoPreviewLayer = AVCaptureVideoPreviewLayer(session: session)
            videoPreviewLayer?.videoGravity = .resizeAspectFill
            videoPreviewLayer?.connection?.videoOrientation = AVCaptureVideoOrientation.portrait

            previewView.layer.insertSublayer(videoPreviewLayer!, at: 0)
            
            previewView.setNeedsLayout()
            view.setNeedsLayout()
        }
        session.commitConfiguration()
        session.startRunning()
    }
}
