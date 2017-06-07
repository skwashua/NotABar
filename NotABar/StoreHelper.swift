//
//  StoreHelper.swift
//  NotABar
//
//  Created by Josh Lytle on 5/26/17.
//  Copyright © 2017 SoggyMop LLC. All rights reserved.
//

import UIKit

func DebugMode() -> Bool {
    var isDebug = false
    
    #if DEBUG
        isDebug = true
    #endif
    
    return isDebug
}

class StoreHelper {
    private static var takenKey = "PHOTOSTAKEN"
    
    class var takenPhotos: Int {
        get {
            return UserDefaults.standard.integer(forKey: takenKey)
        } set {
            UserDefaults.standard.set(newValue, forKey: takenKey)
        }
    }
}
