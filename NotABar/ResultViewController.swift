//
//  ResultViewController.swift
//  NotABar
//
//  Created by Josh Lytle on 5/22/17.
//  Copyright © 2017 SoggyMop LLC. All rights reserved.
//

import UIKit

class ResultViewController: UIViewController {
    
    @IBOutlet weak var resultLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var labelsFoundLabel: UILabel!
    
    var image: UIImage?
    var results: [(String, Float)] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imageView.image = image
        
        var foundText = "Labels Found:\n"
        for (labelText, value) in results {
            foundText += "\(labelText) - \(value)\n"
            
            if ["bar", "pub"].contains(labelText.lowercased()) {
                resultLabel.text = "It's A Bar!"
            }
        }
        labelsFoundLabel.text = foundText
    }

    @IBAction func tryAgainTapped(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func shareTapped(_ sender: UIButton) {
        //TODO: Share!
    }

}
