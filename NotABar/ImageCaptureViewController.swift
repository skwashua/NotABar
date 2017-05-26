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
        guard let buffer = photoSampleBuffer else { return }
        guard let data = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: buffer, previewPhotoSampleBuffer: previewPhotoSampleBuffer) else { return }
        
        let dataProvider = CGDataProvider(data: data as CFData)
        let cgImageRef: CGImage! = CGImage(jpegDataProviderSource: dataProvider!, decode: nil, shouldInterpolate: true, intent: .defaultIntent)
        
        let image = UIImage(cgImage: cgImageRef, scale: 0.5, orientation: UIImageOrientation.right)
        
        imageView.image = image
        imageView.isHidden = false
        previewView.isHidden = true
        
        print("Image captured!")

        findLabels(image: image)
    }
}

class ImageCaptureViewController: UIViewController {
    
    @IBOutlet weak var previewView: UIView!
    @IBOutlet weak var captureButton: UIButton!
    @IBOutlet weak var imageView: UIImageView!
    
    var session: AVCaptureSession?
    var stillImageOutput: AVCapturePhotoOutput?
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    
    //MARK:- Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
        
        imageView.isHidden = true
        previewView.isHidden = false
        
        session?.startRunning()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        session?.stopRunning()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        videoPreviewLayer!.frame = previewView.frame
    }
    
    //MARK:- IBActions
    @IBAction func captureButtonTapped(_ sender: UIButton) {
        Amplitude.instance().logEvent("CapturePhoto_Tapped")
        
        let settings = AVCapturePhotoSettings(format: [AVVideoCodecKey : AVVideoCodecJPEG, AVVideoCompressionPropertiesKey: [AVVideoQualityKey : NSNumber(value: 0.7)]])
        settings.flashMode = .off
        settings.isAutoStillImageStabilizationEnabled = true
        
        stillImageOutput?.connection(withMediaType: AVMediaTypeVideo)?.videoOrientation = AVCaptureVideoOrientation.portrait
        stillImageOutput?.capturePhoto(with: settings, delegate: self)
    }
    
    //MARK:- Other Methods
    func findLabels(image: UIImage) {
        let client = AWSRekognition.default()
        
        guard let request = AWSRekognitionDetectLabelsRequest() else {
            print("Unable to create AWS Rek Request.")
            return
        }
        
        guard let requestImage = AWSRekognitionImage() else {
            print("Unable to create AWS image.")
            return
        }
        let resizedImage = resizeImage(image: image, newWidth: 400.0)
        requestImage.bytes = UIImageJPEGRepresentation(resizedImage, 0.7)
        request.image = requestImage
        request.maxLabels = 8
        request.minConfidence = 80
        
        client.detectLabels(request) { (labelResponse, error) in
            guard let labelResponse = labelResponse, error == nil else {
                print("There was an error.")
                return
            }
            
            var labels: [(String, Float)] = []
            for label in labelResponse.labels! {
                print("label found! \(label.name!):\(label.confidence!)")
                labels.append((label.name!, label.confidence!.floatValue))
            }
            
            DispatchQueue.main.async {
                let resultVC = self.storyboard?.instantiateViewController(withIdentifier: "ResultViewController") as! ResultViewController
                resultVC.results = labels
                resultVC.image = resizedImage
                self.present(resultVC, animated: true, completion: nil)
            }
        }
    }
    
    func resizeImage(image: UIImage, newWidth: CGFloat) -> UIImage {
        let scale = newWidth / image.size.width
        let newHeight = image.size.height * scale
        UIGraphicsBeginImageContext(CGSize(width: newWidth, height: newHeight))
        image.draw(in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }

}
