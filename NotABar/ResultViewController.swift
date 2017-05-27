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

extension ResultViewController: GADInterstitialDelegate {
    func interstitialDidDismissScreen(_ ad: GADInterstitial) {
        dismiss(animated: true, completion: nil)
    }
}

class ResultViewController: UIViewController {
    
    @IBOutlet weak var resultLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var labelsFoundLabel: UILabel!
    
    var image: UIImage?
    var results: [(String, Float)] = []
    var interstitial: GADInterstitial?
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setNeedsStatusBarAppearanceUpdate()
        
        imageView.image = image
        
        var foundText = "Labels Found:\n"
        for (labelText, value) in results {
            foundText += "\(labelText) - \(value)\n"
            
            if ["bar", "pub"].contains(labelText.lowercased()) {
                Amplitude.instance().logEvent("Result_Is_Bar")
                resultLabel.text = "A Bar!"
            } else {
                Amplitude.instance().logEvent("Result_Not_Bar")
                resultLabel.text = "Not A Bar!"
            }
        }
        
        labelsFoundLabel.text = foundText
        interstitial = createAndLoadInterstitial()
    }
    
    func createAndLoadInterstitial() -> GADInterstitial {
        //Test Ad: ca-app-pub-3940256099942544/1033173712
        //Unit Ad: ca-app-pub-8210450346888283/5386544857
        let interstitial = GADInterstitial(adUnitID: "ca-app-pub-8210450346888283/5386544857")
        interstitial.delegate = self
        interstitial.load(GADRequest())
        return interstitial
    }

    @IBAction func tryAgainTapped(_ sender: UIButton) {
        Amplitude.instance().logEvent("TryAgain_Tapped")
        if let interstitial = interstitial, interstitial.isReady {
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

}
