//
//  DetailTableViewController.swift
//  UpcycleBuddy
//
//  Created by Ella Gryf-Lowczowska on 26/06/2019.
//  Copyright © 2019 Ella Gryf-Lowczowska. All rights reserved.
//

import UIKit
import GooglePlaces
import MapKit
import Firebase
import MessageUI

class DetailTableViewController: UITableViewController, MFMailComposeViewControllerDelegate {
    
    @IBOutlet weak var cancelBarButton: UIBarButtonItem!
    @IBOutlet weak var saveBarButton: UIBarButtonItem!
    @IBOutlet weak var sendButton: UIButton!
    
    @IBOutlet weak var itemTextView: UITextView!
    @IBOutlet weak var addressTextView: UITextView!
    @IBOutlet weak var emailTextView: UITextView!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var appImageView: UIImageView!
    
    
    var item: Item!
    let regionDistance: CLLocationDistance = 50000 // 50 km or 50,000 meters
    var imagePicker = UIImagePickerController()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if item == nil {
            item = Item()
        }
        imagePicker.delegate = self
        
        item.loadImage {
            self.appImageView.image = self.item.appImage
        }
        
        let region = MKCoordinateRegion(center: item.coordinate, latitudinalMeters: regionDistance, longitudinalMeters: regionDistance)
        
        mapView.setRegion(region, animated: true)
        updateUserInterfaace()
    }
    
    
    
    //MARK:- functions:
    func updateUserInterfaace() {
        itemTextView.text = item.itemName
        addressTextView.text = item.location
        emailTextView.text = item.email
        updateMap()
    }
    
    func updateMap() {
        mapView.removeAnnotations(mapView.annotations)
        mapView.addAnnotation(item)
        mapView.setCenter(item.coordinate, animated: true)
    }
    
    func updateDataFromInterface() {
        item.itemName = itemTextView.text!
        item.location =  addressTextView.text!
        item.email = emailTextView.text!
    }
    
    
    func leaveViewController() {
        let isPresentingInAddMode = presentingViewController is UINavigationController
        if isPresentingInAddMode {
            dismiss(animated: true, completion: nil)
        } else {
            navigationController?.popViewController(animated: true)
        }
    }
    
    func showAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let alertAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(alertAction)
        present(alertController, animated: true, completion: nil)
    }
    
    func cameraOrLibraryAlert() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let cameraAction = UIAlertAction(title: "Camera", style: .default) { _ in
            self.accessCamera()
        }
        let photoLibraryAction = UIAlertAction(title: "Photo Library", style: .default) { _ in
            self.accessLibrary()
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cameraAction)
        alertController.addAction(photoLibraryAction)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
    }
    
    func configuredMailComposeViewController() -> MFMailComposeViewController {
        let mailComposerVC = MFMailComposeViewController()
        mailComposerVC.mailComposeDelegate = self
        mailComposerVC.setToRecipients([emailTextView.text])
        mailComposerVC.setSubject("")
        mailComposerVC.setMessageBody("This is the message body", isHTML: false)
        return mailComposerVC
        
    }
    
    func showSendMailErrorAlert() {
        let sendMailErrorAlert = UIAlertView(title: "Could not send email", message: "Your device must have an active mail account.", delegate: self, cancelButtonTitle: "Ok")
        sendMailErrorAlert.show()
        
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    //MARK:- Actions:
    
    @IBAction func sendButtonPressed(_ sender: UIButton) {
        let mailComposeViewController = configuredMailComposeViewController()
        if MFMailComposeViewController.canSendMail() {
            self.present(mailComposeViewController, animated: true, completion: nil)
        } else {
            self.showSendMailErrorAlert()
        }
    }
    
    
    
    @IBAction func findLocationButtonPressed(_ sender: UIBarButtonItem) {
        let autocompleteController = GMSAutocompleteViewController()
        autocompleteController.delegate = self
        present(autocompleteController, animated: true, completion: nil)
    }
    
    @IBAction func addAppImageClicked(_ sender: UIBarButtonItem) {
        cameraOrLibraryAlert()
    }
    
    
    @IBAction func cancelButtonPressed(_ sender: UIBarButtonItem) {
        leaveViewController()
    }
    
    @IBAction func saveButtonPressed(_ sender: UIBarButtonItem) {
        self.updateDataFromInterface()
        item.saveData() { success in
            if success {
                self.item.saveImage { success in
                    if success {
                        self.leaveViewController()
                    } else {
                        print("WARNING: Image not stored")
                    }
                }
            } else {
                print("Can't segue because of the error")
            }
        }
    }
}

extension DetailTableViewController: GMSAutocompleteViewControllerDelegate {
    
    // Handle the user's selection.
    func viewController(_ viewController: GMSAutocompleteViewController, didAutocompleteWith place: GMSPlace) {
        item.location = place.name ?? "<place unnamed>"
        item.coordinate = place.coordinate
        dismiss(animated: true, completion: nil)
        updateUserInterfaace()
    }
    
    func viewController(_ viewController: GMSAutocompleteViewController, didFailAutocompleteWithError error: Error) {
        // TODO: handle the error.
        print("Error: ", error.localizedDescription)
    }
    
    // User canceled the operation.
    func wasCancelled(_ viewController: GMSAutocompleteViewController) {
        dismiss(animated: true, completion: nil)
    }
    
    // Turn the network activity indicator on and off again.
    func didRequestAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    
    func didUpdateAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
}


extension DetailTableViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        item.appImage = info[UIImagePickerController.InfoKey.originalImage] as! UIImage
        dismiss(animated: true) {
            self.appImageView.image = self.item.appImage
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    func accessLibrary() {
        imagePicker.sourceType = .photoLibrary
        present(imagePicker, animated: true, completion: nil)
    }
    
    func accessCamera() {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            imagePicker.sourceType = .camera
            present(imagePicker, animated: true, completion: nil)
        } else {
            showAlert(title: "Camera Not Available", message:
                "There is no camera available on this device.")
        }
    }
}
