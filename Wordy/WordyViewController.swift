//
//  WordyViewController.swift
//  Wordy
//
//  Created by Jonathan Collins on 11/22/17.
//  Copyright © 2017 JC. All rights reserved.
//

import UIKit
import CoreData
import GoogleMobileAds
import AVFoundation

class WordyViewController: UIViewController, GADBannerViewDelegate, GADInterstitialDelegate, GADAppEventDelegate, UIViewControllerPreviewingDelegate, UIGestureRecognizerDelegate, XMLParserDelegate  {
    
    #if DEBUG
        let debug = true
    #else
        let debug = false
    #endif
    
    @IBOutlet weak var wordLabel: UILabel!
    @IBOutlet weak var wordsCompletedLabel: UILabel!
    @IBOutlet weak var logoView: UIImageView!
    @IBOutlet weak var buttonA: UIButton!
    @IBOutlet weak var buttonB: UIButton!
    @IBOutlet weak var buttonC: UIButton!
    @IBOutlet weak var buttonD: UIButton!
    @IBOutlet weak var progressView: UIProgressView!
    
    let dictionaryFilename = "WordyDictionary"
    let dictionaryExtension = "json"

    let buttonLines = 5
    let buttonLinesMultiplier = 5
    let buttonCornerRadius = CGFloat(50)
    let buttonLeftAndRightContentEdgeInset = CGFloat(40)
    let defaultCornerRadius = CGFloat(0)
    let defaultContentEdgeInset = CGFloat(8)
    let correctText : String = "You are correct!"
    let correctTextColor : UIColor = UIColor(displayP3Red: 0.25, green: 0.85, blue: 0.25, alpha: 1.0)
    let wrongText : String = "You are wrong!"
    let wrongTextColor : UIColor = UIColor.red
    
    var buttonAFrame : CGRect =  CGRect()
    var buttonBFrame : CGRect =  CGRect()
    var buttonCFrame : CGRect =  CGRect()
    var buttonDFrame : CGRect =  CGRect()
    
    var words:[Word] = []
    var solvedWords:[String] = []
    
    var currentWord:Word? = Word()
    var currentIndex = -1
    var currentCorrectAnswerButton:UIButton!
    
    var wrongCounter = 0
    var wrongBeforeAd = 3
    
    var showingRightAnswer = false
    
    var player : AVAudioPlayer?
    
    var pronunciationURL = "https://en.wiktionary.org/w/index.php?title=WORD&printable=yes"
    
    
    //MARK: Animation properties
    
    var animator: UIDynamicAnimator!
    var gravity: UIGravityBehavior!
    let textFadeOutDuration = 0.50
    let textFadeInDuration = 1.0
    
    //MARK: Advertisement Properties
    
    var bannerView: GADBannerView!
    var interstitial: GADInterstitial!
    var testBannerID = "ca-app-pub-3940256099942544/2934735716"
    var testInterstitialID = "ca-app-pub-3940256099942544/4411468910"
    var bannerID = "ca-app-pub-5330908290289818/7870941385"
    var interstitialID = "ca-app-pub-5330908290289818/9635449191"
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryAmbient)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch let error {
            print(error.localizedDescription)
        }
      
        if(traitCollection.forceTouchCapability == .available){
            registerForPreviewing(with: self, sourceView: view)
        }
        
        self.progressView.setProgress(0, animated: true)
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(screenTapped))
        tapRecognizer.delegate = self
        self.view.addGestureRecognizer(tapRecognizer)
        
        self.progressView.isHidden = true
        
        self.buttonA.layer.cornerRadius = buttonCornerRadius
        self.buttonA.layer.borderColor = UIColor.blue.cgColor
        self.buttonA.titleLabel?.numberOfLines = buttonLines
        
        self.buttonB.layer.cornerRadius = buttonCornerRadius
        self.buttonB.layer.borderColor = UIColor.orange.cgColor
        self.buttonB.titleLabel?.numberOfLines = buttonLines
        
        self.buttonC.layer.cornerRadius = buttonCornerRadius
        self.buttonC.layer.borderColor = UIColor.red.cgColor
        self.buttonC.titleLabel?.numberOfLines = buttonLines
        
        self.buttonD.layer.cornerRadius = buttonCornerRadius
        self.buttonD.layer.borderColor = UIColor.purple.cgColor
        self.buttonD.titleLabel?.numberOfLines = buttonLines
        
        if (UIScreen.main.nativeBounds.height < 1334) {
            self.buttonA.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(longPressedButton(sender:))))
            self.buttonB.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(longPressedButton(sender:))))
            self.buttonC.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(longPressedButton(sender:))))
            self.buttonD.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(longPressedButton(sender:))))
        }
        
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
        
        if (self.words.isEmpty) {
            if let path = Bundle.main.path(forResource: self.dictionaryFilename, ofType: self.dictionaryExtension) {
                do {
                    let wordsData = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                    let wordsDictionary = try JSONSerialization.jsonObject(with: wordsData, options: [.allowFragments, .mutableLeaves]) as! [String:String]
                    self.saveWordsAndSetUp(wordsDictionary: wordsDictionary, withDictionaryMigration: false)
                } catch let error{
                    print(error.localizedDescription)
                }
            } else {
                print("Invalid filename/path.")
            }
        } else {
            if (self.words.count == 86036 && self.dictionaryFilename == "WordyDictionary") {
                if let path = Bundle.main.path(forResource: self.dictionaryFilename, ofType: self.dictionaryExtension) {
                    do {
                        let wordsData = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                        let wordsDictionary = try JSONSerialization.jsonObject(with: wordsData, options: [.allowFragments, .mutableLeaves]) as! [String:String]
                        self.saveWordsAndSetUp(wordsDictionary: wordsDictionary, withDictionaryMigration: true)
                    } catch let error{
                        print(error.localizedDescription)
                    }
                } else {
                    print("Invalid filename/path.")
                }
            } else {
                
                self.setWordsCompletedLabel()
                self.setUp()
            }
        }
        
        DispatchQueue.main.async {
            self.logoView.isHidden = true
        }
        self.bannerView = GADBannerView(adSize: kGADAdSizeBanner)
        self.bannerView.delegate = self
        
        addBannerViewToView(self.bannerView)
        if (debug)  {
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
        
        self.animator = UIDynamicAnimator(referenceView: view)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc func setUp() {
        let randomInt = Int(arc4random_uniform(UInt32(self.words.filter({ $0.passed == false }).count)))
        
        self.currentWord = self.words.filter({ $0.passed == false })[randomInt]
        self.currentIndex = randomInt
        
        DispatchQueue.global(qos: .background).async {
            self.saveData()
        }
        
        let randomButton = Int(arc4random_uniform(4))
        
        
        DispatchQueue.main.async {
            let animation = CATransition()
            animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
            animation.type = kCATransitionFade
            animation.duration = self.textFadeOutDuration
            self.wordLabel.layer.add(animation, forKey: kCATransitionFade)
            if (self.currentWord?.word != nil) {
                self.wordLabel.text = self.currentWord?.word
            }
            self.resetButtons()
            switch (randomButton) {
            case 0:
                self.currentCorrectAnswerButton = self.buttonA
                self.buttonA.setTitle(self.currentWord?.definition!,
                                                for: .normal)
                self.buttonB.setTitle(self.words[Int(arc4random_uniform(UInt32(self.words.count)))].definition!,
                                            for: .normal)
                self.buttonC.setTitle(self.words[Int(arc4random_uniform(UInt32(self.words.count)))].definition!,
                                                for: .normal)
                self.buttonD.setTitle(self.words[Int(arc4random_uniform(UInt32(self.words.count)))].definition!,
                                                for: .normal)
            case 1:
                    self.currentCorrectAnswerButton = self.buttonB
                    self.buttonB.setTitle(self.currentWord?.definition!,
                                      for: .normal)
                self.buttonA.setTitle(self.words[Int(arc4random_uniform(UInt32(self.words.count)))].definition!,
                                      for: .normal)
                self.buttonC.setTitle(self.words[Int(arc4random_uniform(UInt32(self.words.count)))].definition!,
                                      for: .normal)
                self.buttonD.setTitle(self.words[Int(arc4random_uniform(UInt32(self.words.count)))].definition!,
                                      for: .normal)
            case 2:
                    self.currentCorrectAnswerButton = self.buttonC
                    self.buttonC.setTitle(self.currentWord?.definition!,
                                      for: .normal)
                self.buttonA.setTitle(self.words[Int(arc4random_uniform(UInt32(self.words.count)))].definition!,
                                      for: .normal)
                self.buttonB.setTitle(self.words[Int(arc4random_uniform(UInt32(self.words.count)))].definition!,
                                      for: .normal)
                self.buttonD.setTitle(self.words[Int(arc4random_uniform(UInt32(self.words.count)))].definition!,
                                      for: .normal)
            case 3:
                    self.currentCorrectAnswerButton = self.buttonD
                    self.buttonD.setTitle(self.currentWord?.definition!,
                                      for: .normal)
                self.buttonA.setTitle(self.words[Int(arc4random_uniform(UInt32(self.words.count)))].definition!,
                                      for: .normal)
                self.buttonB.setTitle(self.words[Int(arc4random_uniform(UInt32(self.words.count)))].definition!,
                                      for: .normal)
                self.buttonC.setTitle(self.words[Int(arc4random_uniform(UInt32(self.words.count)))].definition!,
                                      for: .normal)
            default: break
                
            }
            self.progressView.setProgress((Float(self.words.filter({ $0.passed == true }).count)/Float(self.words.count)), animated: true)

            self.wordLabel.isHidden = false
            
            self.progressView.isHidden = false
            self.wordsCompletedLabel.isHidden = false
        }
    }

    func saveWordsAndSetUp(wordsDictionary: Dictionary<String, String>, withDictionaryMigration: Bool) {
        
        if (withDictionaryMigration) {
            self.solvedWords = self.words.filter{ $0.passed == true }.map { $0.word! }
            self.deleteWords()
        }
        
        var counter = 0
        
        DispatchQueue.main.async {
            guard let appDelegate =
                UIApplication.shared.delegate as? AppDelegate else {
                    return
                }
        
            let managedContext =
                appDelegate.persistentContainer.viewContext
        
            for wordInDictionary in wordsDictionary {
       
                let entity = NSEntityDescription.entity(forEntityName: "Word", in: managedContext)!
        
                let wordInContext = NSManagedObject(entity: entity, insertInto: managedContext)
        
                wordInContext.setValue(wordInDictionary.key, forKeyPath: "word")
                wordInContext.setValue(wordInDictionary.value, forKeyPath: "definition")
                wordInContext.setValue(counter, forKeyPath: "id")
                wordInContext.setValue(false, forKeyPath: "passed")
                if (withDictionaryMigration) {
                    for word in self.solvedWords {
                        if(word.caseInsensitiveCompare(wordInDictionary.key) == ComparisonResult.orderedSame){
                            wordInContext.setValue(true, forKeyPath: "passed")
                        }
                    }
                }
                    
                self.words.append(wordInContext as! Word)
                
                counter += 1
            }
            
            do {
                try managedContext.save()
            } catch let error as NSError {
                print("Could not save. \(error), \(error.userInfo)")
            }
            
            self.solvedWords = []
            
            
            if let path = Bundle.main.path(forResource: self.dictionaryFilename, ofType: self.dictionaryExtension) {
                do {
                    try FileManager.default.removeItem(atPath: path)
                } catch let error{
                    print(error.localizedDescription)
                }
            } else {
                print("Invalid filename/path.")
            }
            
            self.setWordsCompletedLabel()
            self.setUp()
        }
    }
    
    func resetButtons() {
        var colorArray = [UIColor.blue, UIColor.orange, UIColor.purple, UIColor.red]
        self.showButtons()
        
        DispatchQueue.main.async {
            
            self.buttonA.translatesAutoresizingMaskIntoConstraints = false
            self.buttonB.translatesAutoresizingMaskIntoConstraints = false
            self.buttonC.translatesAutoresizingMaskIntoConstraints = false
            self.buttonD.translatesAutoresizingMaskIntoConstraints = false
            
            self.view.layoutIfNeeded()
            
            self.animator.removeAllBehaviors()
            
            self.buttonA.backgroundColor = colorArray.remove(at:Int(arc4random_uniform(UInt32(colorArray.count))))
            self.buttonB.backgroundColor = colorArray.remove(at:Int(arc4random_uniform(UInt32(colorArray.count))))
            self.buttonC.backgroundColor = colorArray.remove(at:Int(arc4random_uniform(UInt32(colorArray.count))))
            self.buttonD.backgroundColor = colorArray.remove(at:Int(arc4random_uniform(UInt32(colorArray.count))))
            self.buttonA.setTitleColor(UIColor.white, for:.normal)
            self.buttonB.setTitleColor(UIColor.white, for:.normal)
            self.buttonC.setTitleColor(UIColor.white, for:.normal)
            self.buttonD.setTitleColor(UIColor.white, for:.normal)
            self.buttonA.contentVerticalAlignment = .center
            self.buttonB.contentVerticalAlignment = .center
            self.buttonC.contentVerticalAlignment = .center
            self.buttonD.contentVerticalAlignment = .center
            self.buttonA.titleLabel?.numberOfLines = self.buttonLines
            self.buttonB.titleLabel?.numberOfLines = self.buttonLines
            self.buttonC.titleLabel?.numberOfLines = self.buttonLines
            self.buttonD.titleLabel?.numberOfLines = self.buttonLines
            self.buttonA.contentEdgeInsets.left = self.buttonLeftAndRightContentEdgeInset
            self.buttonA.contentEdgeInsets.right = self.buttonLeftAndRightContentEdgeInset
            self.buttonB.contentEdgeInsets.left = self.buttonLeftAndRightContentEdgeInset
            self.buttonB.contentEdgeInsets.right = self.buttonLeftAndRightContentEdgeInset
            self.buttonC.contentEdgeInsets.left = self.buttonLeftAndRightContentEdgeInset
            self.buttonC.contentEdgeInsets.right = self.buttonLeftAndRightContentEdgeInset
            self.buttonD.contentEdgeInsets.left = self.buttonLeftAndRightContentEdgeInset
            self.buttonD.contentEdgeInsets.right = self.buttonLeftAndRightContentEdgeInset
            self.buttonA.layer.cornerRadius = self.buttonCornerRadius
            self.buttonB.layer.cornerRadius = self.buttonCornerRadius
            self.buttonC.layer.cornerRadius = self.buttonCornerRadius
            self.buttonD.layer.cornerRadius = self.buttonCornerRadius
        }
    }
    
    //MARK: Saved
    
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
    
    //MARK: Button pressed
    
    @IBAction func buttonPressed(_ sender: UIButton) {
        if (!showingRightAnswer) {
            if (self.words.filter({ $0.passed == false }).count > 0) {
                self.handleAnswer(correct: (sender.title(for: .normal) == self.currentWord?.definition))
            } else {
                self.gameOver()
            }
        } else {
            self.screenTapped()
        }
        
    }
    
    func handleAnswer(correct: Bool) {
        self.animateFeedback(correct: correct)
        if (correct) {
            self.currentWord?.passed = true
            self.saveData()
            wrongCounter = 0
            self.playCorrectSound()
            self.setUp()
        } else {
            self.playWrongSound()
            self.hideWrongButtonsToShowAnswer()
            self.animateAnswer()
            self.wrongCounter += 1
        }
    }
    
    //MARK: Ads
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
        if (debug) {
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
    //MARK: Definition View
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
        definitionViewController?.definition = button.title(for: .normal)!
        self.present(definitionViewController!, animated: true) {
            definitionViewController?.xButton.isHidden =  false
        }
    }
    
    @objc func showButtons() {
        DispatchQueue.main.async {
            self.buttonA.isHidden = false
            self.buttonB.isHidden = false
            self.buttonC.isHidden = false
            self.buttonD.isHidden = false
            self.buttonA.alpha = 1.0
            self.buttonB.alpha = 1.0
            self.buttonC.alpha = 1.0
            self.buttonD.alpha = 1.0
        }
    }
    
    func hideButtons() {
        DispatchQueue.main.async {
            self.buttonA.isHidden = true
            self.buttonB.isHidden = true
            self.buttonC.isHidden = true
            self.buttonD.isHidden = true
        }
    }
    
    func hideWrongButtonsToShowAnswer() {
        DispatchQueue.main.async {
            self.wordsCompletedLabel.textColor = self.wrongTextColor
        }
        var buttonsToDrop : [UIButton] = []
        
        if(self.buttonA != self.currentCorrectAnswerButton) {
            buttonsToDrop.append(self.buttonA)
        }
        if(self.buttonB != self.currentCorrectAnswerButton) {
            buttonsToDrop.append(self.buttonB)
        }
        if(self.buttonC != self.currentCorrectAnswerButton) {
            buttonsToDrop.append(self.buttonC)
        }
        if(self.buttonD != self.currentCorrectAnswerButton) {
            buttonsToDrop.append(self.buttonD)
        }
        
        UIView.animate(withDuration: 0.5,
                                   delay: 0,
                                   options: UIViewAnimationOptions.curveLinear,
                                   animations: {
                                    for button in buttonsToDrop {
                                        button.alpha = 0
                                    }
        }, completion: nil)
        
        self.gravity = UIGravityBehavior(items: buttonsToDrop)
        self.animator.addBehavior(gravity)
        
        self.showingRightAnswer = true
    }
    
    func animateAnswer() {
        self.view.bringSubview(toFront: self.currentCorrectAnswerButton)
        self.wordLabel.translatesAutoresizingMaskIntoConstraints = true
        self.currentCorrectAnswerButton.translatesAutoresizingMaskIntoConstraints = true
        UIView.animate(withDuration: 0.5, animations:{
            self.view.layoutIfNeeded()
            self.currentCorrectAnswerButton.contentVerticalAlignment = .top
            self.currentCorrectAnswerButton.layer.cornerRadius = self.defaultCornerRadius
            self.currentCorrectAnswerButton.backgroundColor = nil
            self.currentCorrectAnswerButton.titleLabel?.numberOfLines = self.buttonLines * self.buttonLinesMultiplier
            self.currentCorrectAnswerButton.contentEdgeInsets.left = self.defaultContentEdgeInset
            self.currentCorrectAnswerButton.contentEdgeInsets.right = self.defaultContentEdgeInset
            self.currentCorrectAnswerButton.setTitle(self.currentWord?.definition, for: .normal)
            self.currentCorrectAnswerButton.setTitleColor(UIColor.black, for: .normal)
            self.currentCorrectAnswerButton.frame = CGRect(x: self.view.frame.origin.x,
                                                           y: (self.wordLabel.frame.origin.y + self.wordLabel.frame.size.height),
                                                           width: self.view.frame.size.width,
                                                           height: self.view.frame.size.height - (self.wordLabel.frame.origin.y + self.wordLabel.frame.size.height))
        })
    }
    
    func animateFeedback(correct: Bool) {
        DispatchQueue.main.async {
            if (correct) {
                let animation = CATransition()
                animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
                animation.type = kCATransitionFade
                animation.duration = self.textFadeOutDuration
                self.wordsCompletedLabel.layer.add(animation, forKey: kCATransitionFade)
                self.wordsCompletedLabel.text = self.correctText
                self.wordsCompletedLabel.textColor = self.correctTextColor
            } else {
                let animation = CATransition()
                animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
                animation.type = kCATransitionFade
                animation.duration = self.textFadeOutDuration
                self.wordsCompletedLabel.layer.add(animation, forKey: kCATransitionFade)
                self.wordsCompletedLabel.text = self.wrongText
                self.wordsCompletedLabel.textColor = self.wrongTextColor
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {
                self.setWordsCompletedLabel()
            })
        }
    }
    
    func playCorrectSound() {
        let filename = "bing"
        let ext = "mp3"
        self.playSound(filename: filename, ext: ext)
    }
    
    func playWrongSound() {
        let filename = "bloop"
        let ext = "mp3"
        self.playSound(filename: filename, ext: ext)
    }
    
    func playSound(filename: String, ext: String) {
        
        guard let url = Bundle.main.url(forResource: filename, withExtension: ext) else { return }
        
        do {
            self.player = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileType.wav.rawValue)
            self.player?.prepareToPlay()
            self.player?.play()
            self.player?.volume = 0.05
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    @objc func presentInterstitial() {
        self.interstitial.present(fromRootViewController: self)
    }
    
    func gameOver() {
        DispatchQueue.main.async {
            self.wordLabel.isHidden = true
            self.buttonA.isHidden = true
            self.buttonB.isHidden = true
            self.buttonC.isHidden = true
            self.buttonD.isHidden = true
            
            self.progressView.setProgress((Float(self.words.filter({ $0.passed == true }).count)/Float(self.words.count)), animated: true)
            
            self.wordsCompletedLabel.text  = "You are a Word Wizard!"
        }
    }
    
    @objc func screenTapped() {
        if (self.showingRightAnswer) {
            if (self.wrongCounter >= self.wrongBeforeAd) {
                if self.interstitial.isReady {
                    self.presentInterstitial()
                } else {
                    print("Ad wasn't ready")
                }
                self.wrongCounter = 0
            }
            
            self.setUp()
            
            self.showingRightAnswer = false
        }
    }
    
    func deleteWords() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let managedContext = appDelegate.persistentContainer.viewContext
        for managedObject in self.words {
            let managedObjectData:NSManagedObject = managedObject as NSManagedObject
            managedContext.delete(managedObjectData)
        }
    }
    
    func setWordsCompletedLabel() {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = NumberFormatter.Style.decimal
        let formattedWordsCount = numberFormatter.string(from: NSNumber(value:self.words.count))
        let animation = CATransition()
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        animation.type = kCATransitionFade
        animation.duration = self.textFadeInDuration
        self.wordsCompletedLabel.layer.add(animation, forKey: kCATransitionFade)
        DispatchQueue.main.async {
            self.wordsCompletedLabel.textColor = UIColor.black
            self.wordsCompletedLabel.text = "\(self.words.count - self.words.filter({ $0.passed == false }).count) of " + formattedWordsCount! + " correct"
        }
    }
}
