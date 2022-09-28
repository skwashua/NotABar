//
//  InfoViewController.swift
//  NotABar
//
//  Created by Josh Lytle on 2/17/19.
//  Copyright © 2019 SoggyMop LLC. All rights reserved.
//

import UIKit
import SafariServices

class InfoViewController: UIViewController {
    
    @IBOutlet weak var resultsLabel: UILabel!
    
    var labels: [(String, Float)] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let resultFormat = "%@: %.1f%%\n"
        
        var resultsString = ""
        for (label, value) in labels.prefix(upTo: 3) {
            let label = label.replacingOccurrences(of: "_", with: " ").replacingOccurrences(of: "-", with: " - ")
            resultsString += String(format: resultFormat, label, value * 100.0)
        }
        
        resultsLabel.text = resultsString
    }
    
    @IBAction func backTapped(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func sendResultsTapped(_ sender: Any) {
        
    }
    
    @IBAction func aboutLawTapped(_ sender: Any) {
        let safari = SFSafariViewController(url: URL(string: "https://www.sltrib.com/news/2017/04/28/mixed-up-about-whether-youre-in-a-bar-or-restaurant-with-alcohol-theres-now-a-sign-for-that-in-utah/")!)
        present(safari, animated: true, completion: nil)
    }
}
