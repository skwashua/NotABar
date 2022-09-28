//
//  RemoteConfigHelper.swift
//  NotABar
//
//  Created by Josh Lytle on 2/25/19.
//  Copyright © 2019 SoggyMop LLC. All rights reserved.
//

/*
 
import Foundation
import Firebase

class RemoteConfigHelper {
    
    enum Parameters: String {
        case adsEnabled = "ads_enabled"
        case barFoundResponses = "bar_found_responses"
        case barNotFoundResponses = "bar_not_found_responses"
        
        static let supported: [Parameters] = [.adsEnabled, .barFoundResponses, .barNotFoundResponses]
        
        static var defaults: [String: NSObject] {
            var defaults: [String: NSObject] = [:]
            for parameter in supported {
                defaults[parameter.rawValue] = parameter.defaultValue
            }
            return defaults
        }
        
        var defaultValue: NSObject {
            switch self {
            case .adsEnabled:
                return false as NSNumber
            case .barFoundResponses:
                return "" as NSString
            case .barNotFoundResponses:
                return "" as NSString
            }
        }
        
        var currentValue: Any {
            let config = RemoteConfigHelper.remoteConfig
            
            switch self {
            case .adsEnabled:
                return config[rawValue].numberValue ?? defaultValue
            case .barFoundResponses, .barNotFoundResponses:
                return config[rawValue].stringValue ?? defaultValue
            }
        }
    }
    
    static let remoteConfig: RemoteConfig = {
        let config = RemoteConfig.remoteConfig()
        if DebugMode() {
            let settings = RemoteConfigSettings(developerModeEnabled: true)
            config.configSettings = settings
        }
        config.setDefaults(Parameters.defaults)
        return config
    }()
    
    private static var expirationDuration: TimeInterval {
        return remoteConfig.configSettings.isDeveloperModeEnabled ? 0.0 : 3600.0
    }
    
    static func fetch(forcedRefresh: Bool = false, completionHandler: @escaping (Bool) -> Void) {
        let expirationTime: TimeInterval = forcedRefresh ? 0.0 : expirationDuration
        remoteConfig.fetch(withExpirationDuration: expirationTime) { (status, error) in
            guard status == .success, error == nil else {
                completionHandler(false)
                return
            }
            
            self.remoteConfig.activateFetched()
            completionHandler(true)
        }
    }
}

*/
