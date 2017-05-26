//
//  StoreHelper.swift
//  NotABar
//
//  Created by Josh Lytle on 5/26/17.
//  Copyright © 2017 SoggyMop LLC. All rights reserved.
//

import UIKit

class StoreHelper {
    private static var takenKey = "PHOTOSTAKEN"
    private static var photosAvailableKey = "PHOTOSAVAIL"
    
    class var takenPhotos: Int {
        get {
            return UserDefaults.standard.integer(forKey: takenKey)
        } set {
            UserDefaults.standard.set(newValue, forKey: takenKey)
        }
    }
    
    class var photosAvailable: Int {
        get {
            if UserDefaults.standard.value(forKey: photosAvailableKey) == nil {
                //TODO: Save this to the Keychain if it becomes an issue.
                UserDefaults.standard.set(10, forKey: photosAvailableKey)
            }
            
            return UserDefaults.standard.integer(forKey: photosAvailableKey)
        }
    }
    
    class func buyPhotos() {
        UserDefaults.standard.set(250, forKey: photosAvailableKey)
    }
}
