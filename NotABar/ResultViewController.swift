//
//  ResultViewController.swift
//  NotABar
//
//  Created by Josh Lytle on 5/22/17.
//  Copyright © 2017 SoggyMop LLC. All rights reserved.
//

import UIKit
import Amplitude_iOS

class ResultViewController: UIViewController {
    
    @IBOutlet weak var resultLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var labelsFoundLabel: UILabel!
    
    var image: UIImage?
    var results: [(String, Float)] = []
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
    }

    @IBAction func tryAgainTapped(_ sender: UIButton) {
        Amplitude.instance().logEvent("TryAgain_Tapped")
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func shareTapped(_ sender: UIButton) {
        Amplitude.instance().logEvent("Share_Tapped")
        
        let shareText = "\(resultLabel.text ?? "") #NotABar #NotABarApp http://bit.ly/NotABar"
        guard let image = image else { return }
        let shareSheet = UIActivityViewController(activityItems: [shareText, image], applicationActivities: nil)
        present(shareSheet, animated: true, completion: nil)
    }

}
