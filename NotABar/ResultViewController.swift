//
//  ResultViewController.swift
//  NotABar
//
//  Created by Josh Lytle on 5/22/17.
//  Copyright © 2017 SoggyMop LLC. All rights reserved.
//

import UIKit
import Amplitude_iOS
import GoogleMobileAds
import SafariServices
import AWSRekognition

extension ResultViewController: GADInterstitialDelegate {
    func interstitialDidDismissScreen(_ ad: GADInterstitial) {
        dismiss(animated: true, completion: nil)
    }
}

class ResultViewController: UIViewController {
    
    @IBOutlet weak var resultLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var labelsFoundLabel: UILabel!
    @IBOutlet weak var learnMoreButton: UIButton!
    
    var image: UIImage?
    var interstitial: GADInterstitial?
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setNeedsStatusBarAppearanceUpdate()
        
        imageView.image = image
        labelsFoundLabel.isHidden = true // DebugMode() == false
        
        StoreHelper.takenPhotos += 1
        
        interstitial = createAndLoadInterstitial()
        
        findLabels()
    }
    
    //MARK:- Other Methods
    func createAndLoadInterstitial() -> GADInterstitial {
        //Test Ad: ca-app-pub-3940256099942544/1033173712
        //Unit Ad: ca-app-pub-8210450346888283/5386544857
        let adUnit = DebugMode() ? "ca-app-pub-3940256099942544/1033173712" : "ca-app-pub-8210450346888283/5386544857"
        let interstitial = GADInterstitial(adUnitID: adUnit)
        interstitial.delegate = self
        interstitial.load(GADRequest())
        return interstitial
    }
    
    func findLabels() {
        let client = AWSRekognition.default()
        
        guard let request = AWSRekognitionDetectLabelsRequest() else {
            print("Unable to create AWS Rek Request.")
            return
        }
        
        guard let requestImage = AWSRekognitionImage() else {
            print("Unable to create AWS image.")
            return
        }
        
        guard let image = image else { return }
        let resizedImage = resizeImage(image: image, newWidth: 400.0)
        requestImage.bytes = UIImageJPEGRepresentation(resizedImage, 0.7)
        request.image = requestImage
        request.maxLabels = 8
        request.minConfidence = 75
        
        client.detectLabels(request) { (labelResponse, error) in
            guard let labelResponse = labelResponse, error == nil else {
                print("There was an error.")
                return
            }
            
            var labels: [(String, Float)] = []
            for label in labelResponse.labels! {
                labels.append((label.name!, label.confidence!.floatValue))
            }
            
            DispatchQueue.main.async {
                self.showResults(labels: labels)
            }
        }
    }
    
    func showResults(labels: [(String, Float)]) {
        var foundText = "Labels Found:\n"
        var barFound: Bool = false
        for (labelText, value) in labels {
            foundText += "\(labelText) - \(value)\n"
            
            if ["bar", "pub"].contains(labelText.lowercased()) {
                barFound = true
                break
            }
        }
        
        if barFound {
            Amplitude.instance().logEvent("Result_Is_Bar")
            resultLabel.text = "A Bar!"
            
            if #available(iOS 10.3, *) {
                SKStoreReviewController.requestReview()
            }
        } else {
            Amplitude.instance().logEvent("Result_Not_Bar")
            resultLabel.text = "Not A Bar!"
        }
        
        labelsFoundLabel.text = foundText
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

    //MARK:- IBActions
    @IBAction func tryAgainTapped(_ sender: UIButton) {
        Amplitude.instance().logEvent("TryAgain_Tapped")
        if let interstitial = interstitial, interstitial.isReady, StoreHelper.takenPhotos > 3 {
            interstitial.present(fromRootViewController: self)
        } else {
            dismiss(animated: true, completion: nil)
        }
    }
    
    @IBAction func shareTapped(_ sender: UIButton) {
        Amplitude.instance().logEvent("Share_Tapped")
        
        let shareText = "\(resultLabel.text ?? "") #NotABar #NotABarApp http://bit.ly/NotABar"
        guard let image = image else { return }
        let shareSheet = UIActivityViewController(activityItems: [shareText, image], applicationActivities: nil)
        present(shareSheet, animated: true, completion: nil)
    }
    
    @IBAction func learnMoreTapped(_ sender: Any) {
        Amplitude.instance().logEvent("LearnMore_Tapped")
        let url = URL(string: "")!
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
    

}
