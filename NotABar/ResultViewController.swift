//
//  ResultViewController.swift
//  NotABar
//
//  Created by Josh Lytle on 5/22/17.
//  Copyright © 2017 SoggyMop LLC. All rights reserved.
//

import UIKit
import SafariServices
import AWSRekognition

class ResultViewController: UIViewController {
    
    @IBOutlet weak var resultLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var labelsFoundLabel: UILabel!
    @IBOutlet weak var learnMoreButton: UIButton!
    
    var image: UIImage?
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setNeedsStatusBarAppearanceUpdate()
        
        imageView.image = image
        labelsFoundLabel.isHidden = true
        StoreHelper.takenPhotos += 1
        
        findLabels()
    }
    
    //MARK:- Other Methods
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
            resultLabel.text = "A Bar!"
        } else {
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
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func shareTapped(_ sender: UIButton) {
        let shareText = "\(resultLabel.text ?? "") #NotABar #NotABarApp http://bit.ly/NotABar"
        guard let image = image else { return }
        let shareSheet = UIActivityViewController(activityItems: [shareText, image], applicationActivities: nil)
        present(shareSheet, animated: true, completion: nil)
    }
    
    @IBAction func learnMoreTapped(_ sender: Any) {
        let url = URL(string: "http://bit.ly/NotABarOnRantt")!
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
}
