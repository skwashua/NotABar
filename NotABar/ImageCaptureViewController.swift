//
//  ImageCaptureViewController.swift
//  NotABar
//
//  Created by Josh Lytle on 5/22/17.
//  Copyright © 2017 SoggyMop LLC. All rights reserved.
//

import UIKit
import AWSRekognition
import AVFoundation
import Amplitude_iOS

extension ImageCaptureViewController: AVCapturePhotoCaptureDelegate {
    func capture(_ captureOutput: AVCapturePhotoOutput, didFinishProcessingPhotoSampleBuffer photoSampleBuffer: CMSampleBuffer?, previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?) {
        captureButton.isEnabled = true
        
        guard let buffer = photoSampleBuffer else { return }
        guard let data = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: buffer, previewPhotoSampleBuffer: previewPhotoSampleBuffer) else { return }
        
        let dataProvider = CGDataProvider(data: data as CFData)
        let cgImageRef: CGImage! = CGImage(jpegDataProviderSource: dataProvider!, decode: nil, shouldInterpolate: true, intent: .defaultIntent)
        
        let image = UIImage(cgImage: cgImageRef, scale: 0.5, orientation: UIImageOrientation.right)
        
        imageView.image = image
        imageView.isHidden = false
        previewView.isHidden = true
        
        print("Image captured!")

        DispatchQueue.main.async {
            let resultVC = self.storyboard?.instantiateViewController(withIdentifier: "ResultViewController") as! ResultViewController
            resultVC.image = image
            self.present(resultVC, animated: true, completion: nil)
        }
    }
}

class ImageCaptureViewController: UIViewController {
    
    @IBOutlet weak var previewView: UIView!
    @IBOutlet weak var captureButton: UIButton!
    @IBOutlet weak var imageView: UIImageView!
    
    var session: AVCaptureSession?
    var stillImageOutput: AVCapturePhotoOutput?
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    
//    let debugImage: UIImage = #imageLiteral(resourceName: "bar-sample")
//    let debugImage: UIImage = #imageLiteral(resourceName: "table-sample")

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    //MARK:- Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        setNeedsStatusBarAppearanceUpdate()
        
        captureButton.layer.cornerRadius = captureButton.frame.width * 0.5
        captureButton.layer.masksToBounds = true
        captureButton.layer.borderColor = UIColor.white.cgColor
        captureButton.layer.borderWidth = 4.0
        
        session = AVCaptureSession()
        session?.sessionPreset = AVCaptureSessionPresetPhoto
        
        let backCamera = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
        
        var error: NSError?
        var input: AVCaptureDeviceInput!
        
        do {
            input = try AVCaptureDeviceInput(device: backCamera)
        } catch let error1 as NSError {
            error = error1
            input = nil
            print(error!.localizedDescription)
        }
        
        if error == nil && session!.canAddInput(input) {
            session!.addInput(input)
            
            let photoSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecJPEG, AVVideoCompressionPropertiesKey: [AVVideoQualityKey : NSNumber(value: 0.7)]])
            stillImageOutput = AVCapturePhotoOutput()
            stillImageOutput?.setPreparedPhotoSettingsArray([photoSettings], completionHandler: nil)
            session?.addOutput(stillImageOutput)
            
            videoPreviewLayer = AVCaptureVideoPreviewLayer(session: session)
            videoPreviewLayer!.videoGravity = AVLayerVideoGravityResizeAspect
            videoPreviewLayer!.connection.videoOrientation = AVCaptureVideoOrientation.portrait
            previewView.layer.insertSublayer(videoPreviewLayer!, at: 0)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        checkCameraAuthorization { authorized in
            guard authorized else {
                
                let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
                let openSettings = UIAlertAction(title: "Show Settings", style: .default, handler: { _ in
                    let settingsUrl = URL(string: UIApplicationOpenSettingsURLString)!
                    UIApplication.shared.open(settingsUrl, options: [:], completionHandler: nil)
                })
                
                let alert = UIAlertController(title: "Camera Required", message: "The camera is required to take a photo.\nOpen Settings > Privacy > Camera and allow NotABar", preferredStyle: .alert)
                alert.addAction(cancelAction)
                alert.addAction(openSettings)
                
                self.present(alert, animated: true, completion: nil)
                return
            }
            
            self.imageView.isHidden = true
            self.previewView.isHidden = false
            
            self.session?.startRunning()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        session?.stopRunning()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        videoPreviewLayer?.frame = previewView.frame
    }
    
    //MARK:- IBActions
    @IBAction func captureButtonTapped(_ sender: UIButton) {
        captureButton.isEnabled = false
        
//        guard !DebugMode() && hasCamera == true else {
//            let resultVC = self.storyboard?.instantiateViewController(withIdentifier: "ResultViewController") as! ResultViewController
//            resultVC.image = debugImage
//            
//            self.present(resultVC, animated: true, completion: nil)
//            return
//        }
        
        Amplitude.instance().logEvent("CapturePhoto_Tapped")
        
        let settings = AVCapturePhotoSettings(format: [AVVideoCodecKey : AVVideoCodecJPEG, AVVideoCompressionPropertiesKey: [AVVideoQualityKey : NSNumber(value: 0.7)]])
        settings.flashMode = .off
        settings.isAutoStillImageStabilizationEnabled = true
        
        stillImageOutput?.connection(withMediaType: AVMediaTypeVideo)?.videoOrientation = AVCaptureVideoOrientation.portrait
        stillImageOutput?.capturePhoto(with: settings, delegate: self)
    }
    
    func checkCameraAuthorization(_ completionHandler: @escaping ((_ authorized: Bool) -> Void)) {
        switch AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo) {
        case .authorized:
            //The user has previously granted access to the camera.
            completionHandler(true)
        case .notDetermined:
            // The user has not yet been presented with the option to grant video access so request access.
            AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeVideo, completionHandler: { success in
                completionHandler(success)
            })
        case .denied:
            // The user has previously denied access.
            completionHandler(false)
        case .restricted:
            // The user doesn't have the authority to request access e.g. parental restriction.
            completionHandler(false)
        }
    }

}
