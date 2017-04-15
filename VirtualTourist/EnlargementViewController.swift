//
//  EnlargementViewController.swift
//  VirtualTourist
//
//  Created by Lisa Litchfield on 4/14/17.
//  Copyright © 2017 Lisa Litchfield. All rights reserved.
//

import UIKit

class EnlargementViewController: UIViewController{
    var imageToBlowup:UIImage! = nil
    
    
    @IBOutlet weak var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imageView.image = imageToBlowup
        
    }
}
