//
//  ViewController.swift
//  Wordy
//
//  Created by Jonathan Collins on 11/22/17.
//  Copyright © 2017 JC. All rights reserved.
//

import UIKit
import CoreData
import GoogleMobileAds
import AudioToolbox

class WordyViewController: UIViewController, GADBannerViewDelegate, GADInterstitialDelegate, GADAppEventDelegate, UIViewControllerPreviewingDelegate  {
    
    var development = false
    
    @IBOutlet weak var wordLabel: UILabel!
    @IBOutlet weak var wordsCompletedLabel: UILabel!
    
    @IBOutlet weak var logoView: UIImageView!
    @IBOutlet weak var buttonA: UIButton!
    @IBOutlet weak var buttonB: UIButton!
    @IBOutlet weak var buttonC: UIButton!
    @IBOutlet weak var buttonD: UIButton!
    
    var words:[Word] = []
    var word:Word?
    
    var allWords:[String:String] = [:]
    var wordsRemaining:[String:String] = [:]
    
    var currentIndex = -1
    var wrongCounter = 0
    
    var saving = false
    
    @IBOutlet weak var progressView: UIProgressView!
    
    var bannerView: GADBannerView!
    var interstitial: GADInterstitial!
    var testBannerID = "ca-app-pub-3940256099942544/2934735716"
    var testInterstitialID = "ca-app-pub-3940256099942544/4411468910"
    var bannerID = "ca-app-pub-5330908290289818/7870941385"
    var interstitialID = "ca-app-pub-5330908290289818/9635449191"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if(traitCollection.forceTouchCapability == .available){
            registerForPreviewing(with: self, sourceView: view)
        }
        
        
        self.progressView.setProgress(0, animated: true)
        
        self.wordLabel.isHidden = true
        self.buttonA.isHidden = true
        self.buttonB.isHidden = true
        self.buttonC.isHidden = true
        self.buttonD.isHidden = true
        self.progressView.isHidden = true
        
        self.buttonA.layer.borderWidth = 1.0
        self.buttonA.layer.cornerRadius = 20
        self.buttonA.layer.borderColor = UIColor.blue.cgColor
        self.buttonA.titleLabel?.numberOfLines = 5
        self.buttonA.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(longPressedButton(sender:))))
        
        self.buttonB.layer.borderWidth = 1.0
        self.buttonB.layer.cornerRadius = 20
        self.buttonB.layer.borderColor = UIColor.orange.cgColor
        self.buttonB.titleLabel?.numberOfLines = 5
        self.buttonB.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(longPressedButton(sender:))))
        
        self.buttonC.layer.borderWidth = 1.0
        self.buttonC.layer.cornerRadius = 20
        self.buttonC.layer.borderColor = UIColor.red.cgColor
        self.buttonC.titleLabel?.numberOfLines = 5
        self.buttonC.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(longPressedButton(sender:))))
        
        self.buttonD.layer.borderWidth = 1.0
        self.buttonD.layer.cornerRadius = 20
        self.buttonD.layer.borderColor = UIColor.purple.cgColor
        self.buttonD.titleLabel?.numberOfLines = 5
        self.buttonD.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(longPressedButton(sender:))))
        
        guard let appDelegate =
            UIApplication.shared.delegate as? AppDelegate else {
                return
        }
        
        let managedContext =
            appDelegate.persistentContainer.viewContext
        
        let fetchRequest =
            NSFetchRequest<NSManagedObject>(entityName: "Word")
        
        do {
            self.words = try managedContext.fetch(fetchRequest) as! [Word]
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        
        if (self.words.count > 0) {
            self.setUp()
        } else {
            if let path = Bundle.main.path(forResource: "dictionary", ofType: "json") {
                do {
                    let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                    self.saveWordsAndSetUp(wordsData: data)
                } catch let error{
                    print(error.localizedDescription)
                }
            } else {
                print("Invalid filename/path.")
            }
        }
        // Do any additional setup after loading the view, typically from a nib.
        self.bannerView = GADBannerView(adSize: kGADAdSizeBanner)
        self.bannerView.delegate = self
        
        addBannerViewToView(self.bannerView)
        if (development)  {
            self.bannerView.adUnitID = testBannerID
            self.interstitial = GADInterstitial(adUnitID: testInterstitialID)
        } else {
            self.bannerView.adUnitID = bannerID
            self.interstitial = GADInterstitial(adUnitID: interstitialID)
        }
        self.bannerView.rootViewController = self
        self.bannerView.load(GADRequest())
        let request = GADRequest()
        
        self.interstitial.delegate = self
        self.interstitial.load(request)
        self.interstitial = createAndLoadInterstitial()
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setUp() {
        
        let randomInt = Int(arc4random_uniform(UInt32(self.words.filter({ $0.passed == false }).count)))
        
        self.word = self.words.filter({ $0.passed == false })[randomInt]
        self.currentIndex = randomInt
        
        DispatchQueue.global(qos: .background).async {
            self.saveData()
        }
        
        let randomButton = Int(arc4random_uniform(4))
        
        DispatchQueue.main.async {
            self.wordLabel.text = self.word?.word
            
            switch (randomButton) {
            case 0:
                self.buttonA.setTitle(self.word?.definition!,
                                                for: UIControlState.normal)
                self.buttonB.setTitle(self.words[Int(arc4random_uniform(UInt32(self.words.count)))].definition!,
                                            for: .normal)
                self.buttonC.setTitle(self.words[Int(arc4random_uniform(UInt32(self.words.count)))].definition!,
                                                for: .normal)
                self.buttonD.setTitle(self.words[Int(arc4random_uniform(UInt32(self.words.count)))].definition!,
                                                for: .normal)
            case 1:
                self.buttonB.setTitle(self.word?.definition!,
                                      for: UIControlState.normal)
                self.buttonA.setTitle(self.words[Int(arc4random_uniform(UInt32(self.words.count)))].definition!,
                                      for: .normal)
                self.buttonC.setTitle(self.words[Int(arc4random_uniform(UInt32(self.words.count)))].definition!,
                                      for: .normal)
                self.buttonD.setTitle(self.words[Int(arc4random_uniform(UInt32(self.words.count)))].definition!,
                                      for: .normal)
            case 2:
                self.buttonC.setTitle(self.word?.definition!,
                                      for: UIControlState.normal)
                self.buttonA.setTitle(self.words[Int(arc4random_uniform(UInt32(self.words.count)))].definition!,
                                      for: .normal)
                self.buttonB.setTitle(self.words[Int(arc4random_uniform(UInt32(self.words.count)))].definition!,
                                      for: .normal)
                self.buttonD.setTitle(self.words[Int(arc4random_uniform(UInt32(self.words.count)))].definition!,
                                      for: .normal)
            case 3:
                self.buttonD.setTitle(self.word?.definition!,
                                      for: UIControlState.normal)
                self.buttonA.setTitle(self.words[Int(arc4random_uniform(UInt32(self.words.count)))].definition!,
                                      for: .normal)
                self.buttonB.setTitle(self.words[Int(arc4random_uniform(UInt32(self.words.count)))].definition!,
                                      for: .normal)
                self.buttonC.setTitle(self.words[Int(arc4random_uniform(UInt32(self.words.count)))].definition!,
                                      for: .normal)
            default: break
                
            }
            let numberFormatter = NumberFormatter()
            numberFormatter.numberStyle = NumberFormatter.Style.decimal
            let formattedWordsCount = numberFormatter.string(from: NSNumber(value:self.words.count))
            self.wordsCompletedLabel.text = "\(self.words.count - self.words.filter({ $0.passed == false }).count) of " + formattedWordsCount! + " correct"
            self.progressView.setProgress((Float(self.words.filter({ $0.passed == true }).count)/Float(self.words.count) * 100), animated: true)
            
            self.buttonA.titleLabel?.frame = self.buttonA.frame
            self.buttonB.titleLabel?.frame = self.buttonB.frame
            self.buttonC.titleLabel?.frame = self.buttonC.frame
            self.buttonD.titleLabel?.frame = self.buttonD.frame
            
            self.wordLabel.isHidden = false
            self.buttonA.isHidden = false
            self.buttonB.isHidden = false
            self.buttonC.isHidden = false
            self.buttonD.isHidden = false
            self.progressView.isHidden = false
            self.wordsCompletedLabel.isHidden = false
            self.logoView.isHidden = true
        }
    }

    func saveWordsAndSetUp(wordsData: Data) {
        var counter = 0
        
        DispatchQueue.main.async {
            guard let appDelegate =
                UIApplication.shared.delegate as? AppDelegate else {
                    return
                }
        
            let managedContext =
                appDelegate.persistentContainer.viewContext
        
            do {
                let wordsDictionary = try JSONSerialization.jsonObject(with: wordsData, options: [.allowFragments, .mutableLeaves]) as! [String:String]
        
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
                    
                    self.words.append(wordInContext as! Word)
                
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
            self.setUp()
        }
    }
    
    func saveData() {
        DispatchQueue.main.async {
            guard let appDelegate =
                UIApplication.shared.delegate as? AppDelegate else {
                    return
            }
            
            let managedContext =
                appDelegate.persistentContainer.viewContext
            
            do {
                try managedContext.save()
            } catch let error as NSError {
                print("Could not save. \(error), \(error.userInfo)")
            }
        }
    }
    
    @IBAction func buttonPressed(_ sender: UIButton) {
        if(sender.title(for: .normal) == self.word?.definition) {
            self.word?.passed = true
            self.saveData()
            self.wordsCompletedLabel.textColor = UIColor.green
            wrongCounter = 0
            let filename = "bing"
            let ext = "wav"
            
            if let soundUrl = Bundle.main.url(forResource: filename, withExtension: ext) {
                var soundId: SystemSoundID = 0
                
                AudioServicesCreateSystemSoundID(soundUrl as CFURL, &soundId)
                
                AudioServicesAddSystemSoundCompletion(soundId, nil, nil, { (soundId, clientData) -> Void in
                    AudioServicesDisposeSystemSoundID(soundId)
                }, nil)
                
                AudioServicesPlaySystemSound(soundId)
            }
        } else {
            let filename = "bloop"
            let ext = "wav"
            
            if let soundUrl = Bundle.main.url(forResource: filename, withExtension: ext) {
                var soundId: SystemSoundID = 0
                
                AudioServicesCreateSystemSoundID(soundUrl as CFURL, &soundId)
                
                AudioServicesAddSystemSoundCompletion(soundId, nil, nil, { (soundId, clientData) -> Void in
                    AudioServicesDisposeSystemSoundID(soundId)
                }, nil)
                
                AudioServicesPlaySystemSound(soundId)
            }
            self.wordsCompletedLabel.textColor = UIColor.red
            wrongCounter += 1
            if (wrongCounter >= 5) {
                if interstitial.isReady {
                    interstitial.present(fromRootViewController: self)
                } else {
                    print("Ad wasn't ready")
                }
                wrongCounter = 0
            }
        }
        
        if (self.words.filter({ $0.passed == false }).count > 0) {
            self.setUp()
        } else {
            DispatchQueue.main.async {
                self.wordLabel.isHidden = true
                self.buttonA.isHidden = true
                self.buttonB.isHidden = true
                self.buttonC.isHidden = true
                self.buttonD.isHidden = true
               
                self.progressView.setProgress((Float(self.words.filter({ $0.passed == true }).count)/Float(self.words.count) * 100), animated: true)
                
                self.wordsCompletedLabel.text  = "You are word wizard!"
            }
        }
        
    }
    
    //#pragma mark - Google Mobile Ad Banner
    func addBannerViewToView(_ bannerView: GADBannerView) {
        bannerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bannerView)
        if #available(iOS 11.0, *) {
            // In iOS 11, we need to constrain the view to the safe area.
            positionBannerViewFullWidthAtTopOfSafeArea(bannerView)
        }
        else {
            // In lower iOS versions, safe area is not available so we use
            // bottom layout guide and view edges.
            positionBannerViewFullWidthAtTopOfView(bannerView)
        }
    }
    
    // MARK: - view positioning
    @available (iOS 11, *)
    func positionBannerViewFullWidthAtTopOfSafeArea(_ bannerView: UIView) {
        // Position the banner. Stick it to the bottom of the Safe Area.
        // Make it constrained to the edges of the safe area.
        let guide = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            guide.leftAnchor.constraint(equalTo: bannerView.leftAnchor),
            guide.rightAnchor.constraint(equalTo: bannerView.rightAnchor),
            guide.topAnchor.constraint(equalTo: bannerView.topAnchor)
            ])
    }
    
    func positionBannerViewFullWidthAtTopOfView(_ bannerView: UIView) {
        view.addConstraint(NSLayoutConstraint(item: bannerView,
                                              attribute: .leading,
                                              relatedBy: .equal,
                                              toItem: view,
                                              attribute: .leading,
                                              multiplier: 1,
                                              constant: 0))
        view.addConstraint(NSLayoutConstraint(item: bannerView,
                                              attribute: .trailing,
                                              relatedBy: .equal,
                                              toItem: view,
                                              attribute: .trailing,
                                              multiplier: 1,
                                              constant: 0))
        view.addConstraint(NSLayoutConstraint(item: bannerView,
                                              attribute: .top,
                                              relatedBy: .equal,
                                              toItem: topLayoutGuide,
                                              attribute: .top,
                                              multiplier: 1,
                                              constant: 0))
    }
    
    /// Tells the delegate an ad request loaded an ad.
    func adViewDidReceiveAd(_ bannerView: GADBannerView) {
        print("adViewDidReceiveAd")
        // Add banner to view and add constraints as above.
        addBannerViewToView(bannerView)
        bannerView.alpha = 0
        UIView.animate(withDuration: 1, animations: {
            bannerView.alpha = 1
        })
    }
    
    /// Tells the delegate an ad request failed.
    func adView(_ bannerView: GADBannerView,
                didFailToReceiveAdWithError error: GADRequestError) {
        print("adView:didFailToReceiveAdWithError: \(error.localizedDescription)")
    }
    
    /// Tells the delegate that a full screen view will be presented in response
    /// to the user clicking on an ad.
    func adViewWillPresentScreen(_ bannerView: GADBannerView) {
        print("adViewWillPresentScreen")
    }
    
    /// Tells the delegate that the full screen view will be dismissed.
    func adViewWillDismissScreen(_ bannerView: GADBannerView) {
        print("adViewWillDismissScreen")
    }
    
    /// Tells the delegate that the full screen view has been dismissed.
    func adViewDidDismissScreen(_ bannerView: GADBannerView) {
        print("adViewDidDismissScreen")
    }
    
    /// Tells the delegate that a user click will open another app (such as
    /// the App Store), backgrounding the current app.
    func adViewWillLeaveApplication(_ bannerView: GADBannerView) {
        print("adViewWillLeaveApplication")
    }
    
    func createAndLoadInterstitial() -> GADInterstitial {
        var interstitial = GADInterstitial(adUnitID: interstitialID)
        if (development) {
            interstitial = GADInterstitial(adUnitID: testInterstitialID)
        }
        interstitial.delegate = self
        interstitial.load(GADRequest())
        return interstitial
    }
    
    func interstitialDidDismissScreen(_ ad: GADInterstitial) {
        interstitial = createAndLoadInterstitial()
    }
    
    /// Tells the delegate an ad request succeeded.
    func interstitialDidReceiveAd(_ ad: GADInterstitial) {
        print("interstitialDidReceiveAd")
    }
    
    /// Tells the delegate an ad request failed.
    func interstitial(_ ad: GADInterstitial, didFailToReceiveAdWithError error: GADRequestError) {
        print("interstitial:didFailToReceiveAdWithError: \(error.localizedDescription)")
    }
    
    /// Tells the delegate that an interstitial will be presented.
    func interstitialWillPresentScreen(_ ad: GADInterstitial) {
        print("interstitialWillPresentScreen")
    }
    
    /// Tells the delegate the interstitial is to be animated off the screen.
    func interstitialWillDismissScreen(_ ad: GADInterstitial) {
        print("interstitialWillDismissScreen")
    }
    
    /// Tells the delegate that a user click will open another app
    /// (such as the App Store), backgrounding the current app.
    func interstitialWillLeaveApplication(_ ad: GADInterstitial) {
        print("interstitialWillLeaveApplication")
    }
    //#pragma mark - PreviewingDelegate
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        let storyboard = UIStoryboard(name: "DefinitionViewController", bundle: nil)
        guard let definitionViewController = storyboard.instantiateViewController(withIdentifier: "DefinitionViewController") as? DefinitionViewController else { return nil }
        if (self.buttonA.frame.contains(location)) {
            definitionViewController.definition = self.buttonA.title(for: .normal)!
            return definitionViewController
        } else if (self.buttonB.frame.contains(location)) {
            definitionViewController.definition = self.buttonB.title(for: .normal)!
            return definitionViewController
        } else if (self.buttonC.frame.contains(location)) {
            definitionViewController.definition = self.buttonC.title(for: .normal)!
            return definitionViewController
        } else if (self.buttonD.frame.contains(location)) {
            definitionViewController.definition = self.buttonD.title(for: .normal)!
            return definitionViewController
        }
        return nil
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        if let vc = viewControllerToCommit as? DefinitionViewController {
            vc.xButton.isHidden =  false
        }
        present(viewControllerToCommit, animated: true, completion: nil)
    }
    
    @objc func longPressedButton(sender: UILongPressGestureRecognizer)
    {
        guard let button = sender.view as? UIButton else { return }
        let storyboard = UIStoryboard(name: "DefinitionViewController", bundle: nil)
        let definitionViewController = storyboard.instantiateViewController(withIdentifier: "DefinitionViewController") as? DefinitionViewController
        present(definitionViewController!, animated: true) {
            definitionViewController?.xButton.isHidden =  false
            definitionViewController?.definitionLabel.text = button.title(for: .normal)
        }
    }
}

