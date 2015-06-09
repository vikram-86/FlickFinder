//
//  ViewController.swift
//  FlickFinder
//
//  Created by Suthananth Arulanantham on 13.05.15.
//  Copyright (c) 2015 Suthananth Arulanantham. All rights reserved.
//

import UIKit

class FlickFinderViewController: UIViewController, UITextFieldDelegate{

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var phraseTextfield: UITextField!
    @IBOutlet weak var latTextfield: UITextField!
    @IBOutlet weak var lonTextfield: UITextField!
    @IBOutlet weak var titleLabel: UILabel!
    
    // class constants
    let baseURL : String = "https://api.flickr.com/services/rest/"
    var keyValuePairs = [
        "method": "flickr.photos.search",
        "api_key": "79d75e61f9bab82ec8e8abce31798b48",
        "format": "json",
        "extras":"url_m",
        "nojsoncallback": "1"
    ]
    
    var tapRecognizer : UITapGestureRecognizer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.subscribeToKeyboardNotifications()
        self.phraseTextfield.delegate = self
        self.latTextfield.delegate = self
        self.lonTextfield.delegate = self
        self.addKeyboardDismissRecognizer()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.unsubscribeToKeyboardNotifications()
        self.removeKeyboardDismissRecognizer()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // Search Flick with a search phrase
    @IBAction func searchFlickByPhraseButtonPressed(sender: UIButton) {
        self.view.endEditing(true)
        let searchPhrase : String = self.phraseTextfield.text
        self.keyValuePairs["text"] = searchPhrase
        let url = self.createURL(self.keyValuePairs).URL!
        let session = NSURLSession.sharedSession()
        let request = NSURLRequest(URL: url)
        
        let task = session.dataTaskWithRequest(request, completionHandler: { (data, response, downloadError) -> Void in
            if let error = downloadError{
                println("Error occured during data request")
            }
            var parseError : NSError? = nil
            var parsedData = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments, error: &parseError) as! NSDictionary
            
            if let photosDictionary = parsedData["photos"] as? NSDictionary {
                if let photoArray = photosDictionary["photo"] as? NSArray {
                    let randomIndex = Int(arc4random_uniform(UInt32(photoArray.count)))
                    if let randomPhoto = photoArray[randomIndex] as? NSDictionary {
                        let title : String = randomPhoto["title"] as! String
                        let pictureData : NSData = NSData(contentsOfURL: NSURL(string: randomPhoto["url_m"] as! String)!)!
                        
                        if let image = UIImage(data: pictureData){
                            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                self.imageView.image = image
                                self.titleLabel.text = title
                            })
                        }else{
                            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                self.titleLabel.text = "Could not find any pictures. Please try again"
                            })
                        }
                        
                    }else{
                        println("Could not find the picture in photoArray")
                    }
                }
                else{
                    println("could not find 'photo' in photosDictionary")
                }
                
            }else{
                println("could not find 'photos' in parsedData")
            }
        })
        task.resume()
    }
    
    // Search Fick with latidude and longitude
    @IBAction func searchFlickByLatitudeAndLongitudeButtonPressed(sender: UIButton) {
        self.view.endEditing(true)
        let lat = NSNumberFormatter().numberFromString(self.latTextfield.text)?.doubleValue
        let lon = NSNumberFormatter().numberFromString(self.lonTextfield.text)?.doubleValue
        if self.checkLatAndLon(lat, lon: lon){
            let bboxString = self.createBBox(lat!, lon: lon!)
            self.keyValuePairs["bbox"] = bboxString
            let url = self.createURL(self.keyValuePairs).URL!
            let session = NSURLSession.sharedSession()
            let request = NSURLRequest(URL: url)
            
            let task = session.dataTaskWithRequest(request, completionHandler: { (data, response, downloadError) -> Void in
                if let error = downloadError{
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        self.titleLabel.text = "Error during task in lat/lon"
                    })
                }
                var parseError : NSError? = nil
                
                var parsedData = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments, error: &parseError) as! NSDictionary
                if let photosDictionary = parsedData["photos"] as? NSDictionary{
                    if let photoArray = photosDictionary["photo"] as? NSArray {
                        let randomIndex = Int(arc4random_uniform(UInt32(photoArray.count)))
                        if let randomPhoto = photoArray[randomIndex] as? NSDictionary{
                            let photoTitle : String = randomPhoto["title"] as! String
                            let photoData : NSData = NSData(contentsOfURL: NSURL(string: randomPhoto["url_m"] as! String)!)!
                            if let image = UIImage(data: photoData){
                                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                    self.imageView.image = image
                                    self.titleLabel.text = photoTitle
                                })
                            }else{
                                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                    self.titleLabel.text = "Could not find any photos.. Please try again"
                                })
                            }
                        }else{
                            println("could not find random photo")
                        }
                    }else{
                        println("could not find 'photo' in photosDictionary")
                    }
                    
                }else{
                    println("could not find 'photos' in parsedData")
                }
            })
            task.resume()
        }
        else{
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.titleLabel.text = "Invalid latitude(-90 - 90) or longitude(-180 - 180) values.. Please Try again"
            })
        }
    }
    
    
    /* ============================================================
    * Functional stubs for handling UI problems
    * ============================================================ */
    
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    /* 1 - Dismissing the keyboard */
    func addKeyboardDismissRecognizer() {
        self.tapRecognizer = UITapGestureRecognizer(target: self, action:"handleSingleTap:")
        self.view.addGestureRecognizer(self.tapRecognizer!)
    }
    
    func removeKeyboardDismissRecognizer() {
        self.view.removeGestureRecognizer(self.tapRecognizer!)
    }
    
    func handleSingleTap(recognizer: UITapGestureRecognizer) {
        self.view.endEditing(true)
    }
    
    /* 2 - Shifting the keyboard so it does not hide controls */
    func subscribeToKeyboardNotifications() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillHide:", name: UIKeyboardWillHideNotification, object: nil)
    }
    
    func unsubscribeToKeyboardNotifications() {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
    }
    
    func keyboardWillShow(notification: NSNotification) {
        self.view.frame.origin.y -= self.getKeyboardHeight(notification)
    }
    
    func keyboardWillHide(notification: NSNotification) {
        self.view.frame.origin.y += self.getKeyboardHeight(notification)
    }
    
    func getKeyboardHeight(notification: NSNotification) -> CGFloat {
        let userInfo = notification.userInfo!
        let keyboardSize = userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue
        return keyboardSize.CGRectValue().height
    }
    

    
    // creates a valid URL from the method Parameters
    func createURL(methodParameters: [String:String])->NSURLComponents{
        var url = NSURLComponents(string: self.baseURL)!
        var queries = [NSURLQueryItem]()
        for(key,value) in methodParameters {
            let query = NSURLQueryItem(name: key, value: value)
            queries.append(query)
        }
        url.queryItems = queries
        return url
    }
    
    // check if lat and lon are valid 
    func checkLatAndLon(lat : Double?, lon: Double?)->Bool{
        if (lat != nil) && (lon != nil){
            if (-90 ... 90 ~= lat!) && (-180 ... 180 ~= lon!){
                return true
            }else{
                return false
            }
        }
        return false
    }
    func createBBox(lat : Double, lon : Double) -> String{
        
        let minLat = max(lat - 1, -90)
        let minLon = max(lon-1, -180)
        let maxLat = min(lat + 1 , 90)
        let maxLon = min(lon + 1, 180)
        return "\(minLon),\(minLat),\(maxLon),\(maxLat)"
    }
}

