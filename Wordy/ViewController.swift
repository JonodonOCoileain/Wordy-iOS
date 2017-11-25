//
//  ViewController.swift
//  Wordy
//
//  Created by Jonathan Collins on 11/22/17.
//  Copyright © 2017 JC. All rights reserved.
//

import UIKit
import CoreData

class ViewController: UIViewController {

    
    @IBOutlet weak var wordLabel: UILabel!
    @IBOutlet weak var wordsCompletedLabel: UILabel!
    
    @IBOutlet weak var buttonA: UIButton!
    @IBOutlet weak var buttonB: UIButton!
    @IBOutlet weak var buttonC: UIButton!
    @IBOutlet weak var buttonD: UIButton!
    
    var allWords:[String:String] = [:]
    var wordsRemaining:[String:String] = [:]
    
    var currentWord = ""
    var currentDefinition = ""
    var currentIndex = -1
    
    var saving = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(save), name: .UIApplicationWillTerminate, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(save), name: .UIApplicationWillResignActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(save), name: .UIApplicationDidEnterBackground, object: nil)
        
        self.wordLabel.isHidden = true
        self.buttonA.isHidden = true
        self.buttonB.isHidden = true
        self.buttonC.isHidden = true
        self.buttonD.isHidden = true
        
        if ((UserDefaults.standard.object(forKey: "wordsRemaining")) != nil) {
            
            self.allWords = UserDefaults.standard.object(forKey: "allWords") as! [String : String]
            self.wordsRemaining = UserDefaults.standard.object(forKey: "wordsRemaining") as! [String : String]
            self.currentWord = UserDefaults.standard.object(forKey: "currentWord") as! String
            self.currentDefinition = UserDefaults.standard.object(forKey: "currentDefinition") as! String
            self.currentIndex = UserDefaults.standard.object(forKey: "currentIndex") as! Int
            
            self.setup()
        } else {
            let url = URL(string: "https://raw.githubusercontent.com/adambom/dictionary/master/dictionary.json")
            URLSession.shared.dataTask(with:url!, completionHandler: {(data, response, error) in
                guard let data = data, error == nil else { return }
            
                do {
                    self.wordsRemaining = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String:String]
                    self.allWords = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String:String]
                    DispatchQueue.global(qos: .background).async {
                        UserDefaults.standard.set(self.allWords, forKey: "allWords")
                    }
                    self.saveWords(wordsData: data)
                    self.setup()
                } catch let error as NSError {
                    print(error)
                }
            }).resume()
        }
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setup() {

        let randomInt = Int(arc4random_uniform(UInt32(self.wordsRemaining.count)))
        
        self.currentWord = Array(self.wordsRemaining.keys)[randomInt]
        self.currentDefinition = self.wordsRemaining[currentWord]!
        self.currentIndex = randomInt
        
        DispatchQueue.global(qos: .background).async {
            UserDefaults.standard.set(self.currentIndex, forKey: "currentIndex")
            UserDefaults.standard.set(self.currentWord, forKey: "currentWord")
            UserDefaults.standard.set(self.currentDefinition, forKey: "currentDefinition")
        }
        
        let randomButton = Int(arc4random_uniform(4))

        DispatchQueue.main.async {
            self.wordLabel.text = self.currentWord
            
            switch (randomButton) {
                case 0:
                    self.buttonA.setTitle(self.currentDefinition, for: .normal)
                    self.buttonB.setTitle(Array(self.allWords.values)[Int(arc4random_uniform(UInt32(self.allWords.count)))], for: .normal)
                    self.buttonC.setTitle(Array(self.allWords.values)[Int(arc4random_uniform(UInt32(self.allWords.count)))], for: .normal)
                    self.buttonD.setTitle(Array(self.allWords.values)[Int(arc4random_uniform(UInt32(self.allWords.count)))], for: .normal)
                case 1:
                    self.buttonB.setTitle(self.currentDefinition, for: .normal)
                    self.buttonA.setTitle(Array(self.allWords.values)[Int(arc4random_uniform(UInt32(self.allWords.count)))], for: .normal)
                    self.buttonC.setTitle(Array(self.allWords.values)[Int(arc4random_uniform(UInt32(self.allWords.count)))], for: .normal)
                    self.buttonD.setTitle(Array(self.allWords.values)[Int(arc4random_uniform(UInt32(self.allWords.count)))], for: .normal)
                case 2:
                    self.buttonC.setTitle(self.currentDefinition, for: .normal)
                    self.buttonA.setTitle(Array(self.allWords.values)[Int(arc4random_uniform(UInt32(self.allWords.count)))], for: .normal)
                    self.buttonB.setTitle(Array(self.allWords.values)[Int(arc4random_uniform(UInt32(self.allWords.count)))], for: .normal)
                    self.buttonD.setTitle(Array(self.allWords.values)[Int(arc4random_uniform(UInt32(self.allWords.count)))], for: .normal)
                case 3:
                    self.buttonD.setTitle(self.currentDefinition, for: .normal)
                    self.buttonA.setTitle(Array(self.allWords.values)[Int(arc4random_uniform(UInt32(self.allWords.count)))], for: .normal)
                    self.buttonB.setTitle(Array(self.allWords.values)[Int(arc4random_uniform(UInt32(self.allWords.count)))], for: .normal)
                    self.buttonC.setTitle(Array(self.allWords.values)[Int(arc4random_uniform(UInt32(self.allWords.count)))], for: .normal)
                default: break
                
            }
        }
        
        DispatchQueue.main.async {
            self.wordLabel.isHidden = false
            self.buttonA.isHidden = false
            self.buttonB.isHidden = false
            self.buttonC.isHidden = false
            self.buttonD.isHidden = false
            
            self.wordsCompletedLabel.text = "\(self.allWords.count - self.wordsRemaining.count) of \(self.allWords.count) correct"
        }
    }


    @objc func save(_ notification: NSNotification) {
        if (!saving) {
            self.saving = true
            DispatchQueue.global(qos: .background).async {
                UserDefaults.standard.set(self.wordsRemaining, forKey: "wordsRemaining")
                self.saving = false
            }
        }
    }
    
    func saveWords(wordsData: Data) {
        var counter = 0
        
        DispatchQueue.main.async {
            guard let appDelegate =
                UIApplication.shared.delegate as? AppDelegate else {
                    return
                }
        
            let managedContext =
                appDelegate.persistentContainer.viewContext
        
            do {
                let wordsDictionary = try JSONSerialization.jsonObject(with: wordsData, options: .allowFragments) as! [String:String]
        
                for wordInDictionary in wordsDictionary {
       
                    let entity =
                        NSEntityDescription.entity(forEntityName: "Word",
                                                   in: managedContext)!
        
                    let wordInContext = NSManagedObject(entity: entity,
                                     insertInto: managedContext)
        
                    wordInContext.setValue(wordInDictionary.key, forKeyPath: "word")
                    wordInContext.setValue(wordInDictionary.value, forKeyPath: "definition")
                    wordInContext.setValue(counter, forKeyPath: "id")
                    wordInContext.setValue(false, forKeyPath: "passed")
                
                    counter += 1
                }
        
            } catch let error as NSError {
                print(error)
            }
            
            do {
                try managedContext.save()
            } catch let error as NSError {
                print("Could not save. \(error), \(error.userInfo)")
            }
        }
    }
    
    @IBAction func buttonPressed(_ sender: UIButton) {
        if(sender.title(for: .normal) == self.currentDefinition) {
            self.wordsRemaining.removeValue(forKey: self.currentWord)
            self.wordsCompletedLabel.textColor = UIColor.green
        } else {
            self.wordsCompletedLabel.textColor = UIColor.red
        }
        
        self.setup()
        
    }
}

