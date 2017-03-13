//
//  notifyUser.swift
//  OnTheMap
//
//  Created by Lisa Litchfield on 12/15/16.
//  Copyright © 2016 Lisa Litchfield. All rights reserved.
//  This method is used from within completion handlers to present an alert to the user
//  on the Main queue.

import Foundation
import UIKit

// Method to show user alert from on background queue
func notifyUser(_ viewController: UIViewController, message:String){
    DispatchQueue.main.sync {
        sendAlert(viewController, message: message)
    }
}

// Method to show user alert from on main queue
func sendAlert(_ viewController: UIViewController, message:String){
    
    let controller = UIAlertController()
    controller.message = message
    let dismissAction = UIAlertAction(title: "Dismiss", style: .default){ action in
    controller.dismiss(animated: true, completion: nil)
    }
    controller.addAction(dismissAction)
    viewController.present(controller, animated: true, completion: nil)
}
