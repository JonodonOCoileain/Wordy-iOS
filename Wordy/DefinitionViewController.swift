//
//  WordDetailViewController.swift
//  Wordy
//
//  Created by Jonathan Collins on 11/26/17.
//  Copyright © 2017 JC. All rights reserved.
//

import UIKit

class DefinitionViewController: UIViewController {
    
    var definition:String = ""
    @IBOutlet weak var definitionLabel: UILabel!
    @IBOutlet weak var xButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.definitionLabel.text = definition
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func xButtonPressed(_ sender: UIButton) {
        self.dismiss(animated: true) {
            
        }
        
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
