//
//  IntroViewController.swift
//  NotABar
//
//  Created by Josh Lytle on 2/4/19.
//  Copyright © 2019 SoggyMop LLC. All rights reserved.
//

import UIKit
import AVFoundation

class IntroViewController: UIViewController {
    @IBOutlet weak var enableCameraButton: UIButton!
    @IBOutlet weak var errorLabel: UILabel!
    
    var currentAuthStatus: AVAuthorizationStatus {
        return AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        enableCameraButton.layer.cornerRadius = 4.0
        enableCameraButton.layer.masksToBounds = true
        
        errorLabel.isHidden = true
        updateForAuthStatus()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        updateForAuthStatus()
    }
    
    //MARK:- Actions
    @IBAction func authorizedTapped(_ sender: UIButton) {
        if currentAuthStatus == .notDetermined {
            AVCaptureDevice.requestAccess(for: .video) { _ in
                DispatchQueue.main.async {
                    self.updateForAuthStatus()
                }
            }
        } else {            
            let settingsUrl = URL(string: UIApplication.openSettingsURLString)!
            UIApplication.shared.open(settingsUrl, options: [:], completionHandler: nil)
        }
    }
    
    private func updateForAuthStatus() {
        switch currentAuthStatus {
        case .authorized:
            dismiss(animated: true, completion: nil)
        case .denied, .restricted:
            errorLabel.isHidden = false
            enableCameraButton.setTitle("Open Settings", for: .normal)
        default:
            enableCameraButton.setTitle("Enable Camera", for: .normal)
        }
    }
}
