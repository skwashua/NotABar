//
//  ResultViewController.swift
//  NotABar
//
//  Created by Josh Lytle on 5/22/17.
//  Copyright © 2017 SoggyMop LLC. All rights reserved.
//

import UIKit
import SafariServices
import StoreKit
import CoreML
import Vision

extension CGImagePropertyOrientation {
    init(_ uiOrientation: UIImage.Orientation) {
        switch uiOrientation {
        case .up: self = .up
        case .upMirrored: self = .upMirrored
        case .down: self = .down
        case .downMirrored: self = .downMirrored
        case .left: self = .left
        case .leftMirrored: self = .leftMirrored
        case .right: self = .right
        case .rightMirrored: self = .rightMirrored
        @unknown default:
            self = .up
        }
    }
}

class ResultViewController: UIViewController {
    
    @IBOutlet weak var resultLabel: UILabel!
    @IBOutlet weak var resultImageView: UIImageView!
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var labelsFoundLabel: UILabel!
    @IBOutlet weak var learnMoreButton: UIButton!
    @IBOutlet weak var shareButton: UIButton!
    @IBOutlet weak var findAResultButton: UIButton!
    
    var image: UIImage?
    var testImage: UIImage?
    var labels: [(String, VNConfidence)] = []
    var barFound: Bool = false
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setNeedsStatusBarAppearanceUpdate()
        
        setGradientBackground()
        
        imageView.image = image
        imageView.layer.shadowColor = UIColor.black.cgColor
        imageView.layer.shadowRadius = 26.0
        imageView.layer.shadowOffset = CGSize(width: 0.0, height: 2.0)
        imageView.layer.cornerRadius = 18.0
        
        StoreHelper.takenPhotos += 1
                
        findLabels()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        if segue.identifier == "ShowInfoSegue", let infoViewController = segue.destination as? InfoViewController {
            infoViewController.labels = self.labels
        }
    }
    
    //MARK:- Other Methods
    func findLabels() {
        guard let orientation = testImage?.imageOrientation,
              let image = testImage,
              let model = try? VNCoreMLModel(for: NotABar30hr(configuration: MLModelConfiguration()).model),
              let resizedImage = resizeImage(image: image, newWidth: 299.0).cgImage
            else { return }
        
        let request = VNCoreMLRequest(model: model) { (request, error) in
            self.processClassifications(for: request, error: error)
        }
        request.imageCropAndScaleOption = .centerCrop
        DispatchQueue.global(qos: .userInitiated).async {
            let handler = VNImageRequestHandler(cgImage: resizedImage, orientation: CGImagePropertyOrientation(orientation), options: [:])
            do {
                try handler.perform([request])
            } catch {
                
            }
        }
    }
    
    func processClassifications(for request: VNRequest, error: Error?) {
        DispatchQueue.main.async {
            guard let results = request.results else {
                self.resultLabel.text = "Unable to classify image.\n\(error?.localizedDescription ?? "")"
                return
            }
            
            // The `results` will always be `VNClassificationObservation`s, as specified by the Core ML model in this project.
            let classifications: [VNClassificationObservation] = results.compactMap { $0 as? VNClassificationObservation }
            self.labels = classifications.sorted { $0.confidence > $1.confidence }.prefix(upTo: 3).map { ($0.identifier, $0.confidence) }
            self.showResults()
        }
    }
    
    func showResults() {
        var foundText = "Labels Found:\n"
        for (labelText, value) in labels {
            foundText += "\(labelText) - \(value)\n"
            
            if ["bar", "pub", "pub-indoor", "sushi_bar", "wet_bar"].contains(labelText.lowercased()) {
                barFound = true
                break
            }
        }
        
        if barFound {
            resultImageView.image = UIImage(named: "Result-Is-A-Bar")
            resultLabel.text = "Congrats! You found a bar. Drink responsibly."
            findAResultButton.setTitle("Find a restaurant", for: .normal)
            
            if let windowScene = view.window?.windowScene {
                SKStoreReviewController.requestReview(in: windowScene)
            }
        } else {
            resultImageView.image = UIImage(named: "Result-Not-A-Bar")
            findAResultButton.setTitle("Find a bar", for: .normal)
            
            var notFoundText = "Phew, it’s not a bar. You’re safe… for now."
            if let (label, value) = labels.first {
                let label = label.replacingOccurrences(of: "_", with: " ").replacingOccurrences(of: "-", with: " - ")
                let resultFormat = "\nWe're %.1f%% sure it's a %@"
                let resultsString = String(format: resultFormat, value * 100.0, label)
                notFoundText += resultsString
            }
            resultLabel.text = notFoundText
        }
        
        labelsFoundLabel.text = foundText
        view.setNeedsLayout()
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
    
    func setGradientBackground() {
        let colorTop =  UIColor(named: "nbGradientDark")!.cgColor
        let colorBottom = UIColor(named: "nbGradientLight")!.cgColor
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [colorTop, colorBottom]
        gradientLayer.locations = [0.0, 1.0]
        gradientLayer.frame = view.bounds
        
        view.layer.insertSublayer(gradientLayer, at: 0)
    }

    //MARK:- IBActions
    @IBAction func tryAgainTapped(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func shareTapped(_ sender: UIButton) {
        guard let bottomImage = image,
              let resultImage = resultImageView.image else { return }
        let topImage = resultImage.maskWithColor(color: .white)

        UIGraphicsBeginImageContext(bottomImage.size)
        let watermarkRatio = topImage.size.height / topImage.size.width
        let watermarkWidth = bottomImage.size.width * 0.3
        let watermarkHeight = watermarkWidth * watermarkRatio
        
        let areaSize = CGRect(x: 0, y: 0, width: bottomImage.size.width, height: bottomImage.size.height)
        bottomImage.draw(in: areaSize)
        let bottomCorner = CGRect(x: bottomImage.size.width - watermarkWidth - 50,
                                  y: bottomImage.size.height - watermarkHeight - 50,
                                  width: watermarkWidth,
                                  height: watermarkHeight)
        
        topImage.draw(in: bottomCorner, blendMode: .overlay, alpha: 0.9)
        
        let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        let shareText = "#NotABar #NotABarApp http://bit.ly/NotABar"
        let shareSheet = UIActivityViewController(activityItems: [shareText, newImage], applicationActivities: nil)
        present(shareSheet, animated: true, completion: nil)
    }
    
    @IBAction func findAResultTapped(_ sender: Any) {
        guard let vc = storyboard?.instantiateViewController(withIdentifier: "FindAResultViewController") as? FindAResultViewController else { return }
        vc.searchTerm = barFound ? "Restaurants" : "Bars"
        navigationController?.pushViewController(vc, animated: true)
    }
}
