//
//  Item.swift
//  UpcycleBuddy
//
//  Created by Ella Gryf-Lowczowska on 26/06/2019.
//  Copyright © 2019 Ella Gryf-Lowczowska. All rights reserved.
//

import Foundation
import CoreLocation
import Firebase
import MapKit

class Item: NSObject, MKAnnotation {
    var itemName: String
    var location: String
    var coordinate: CLLocationCoordinate2D
    var appImage: UIImage
    var appImageUUID: String
    var createdOn: Date
    var postingUserID: String
    var documentID: String
    
    var latitude: CLLocationDegrees {
        return coordinate.latitude
    }
    var longitude: CLLocationDegrees {
        return coordinate.longitude
    }
    
    var dictionary: [String: Any] {
        let timeIntervalDate = createdOn.timeIntervalSince1970
        return ["itemName": itemName, "location": location, "longitude": longitude, "latitude": latitude, "appImageUUID": appImageUUID, "createdOn": timeIntervalDate, "postingUserID": postingUserID]
    }
    
    
    var title: String? {
        return itemName
    }
    
    var subtitle: String? {
        return location
    }
    
    init(itemName: String, location: String, coordinate: CLLocationCoordinate2D, appImage: UIImage, appImageUUID: String, createdOn: Date, postingUserID: String, documentID: String) {
        self.itemName = itemName
        self.location = location
        self.coordinate = coordinate
        self.appImage = appImage
        self.appImageUUID = appImageUUID
        self.createdOn = createdOn
        self.postingUserID = postingUserID
        self.documentID = documentID
    }
    
    convenience override init() {
        self.init(itemName: "", location: "", coordinate: CLLocationCoordinate2D(), appImage: UIImage(), appImageUUID: "", createdOn: Date(), postingUserID: "", documentID: "")
    }
    
    convenience init(dictionary: [String: Any]) {
        let itemName = dictionary["itemName"] as! String? ?? ""
        let location = dictionary["location"] as! String? ?? ""
        let latitude = dictionary["latitude"] as! CLLocationDegrees? ?? 0.0
        let longitude = dictionary["longitude"] as! CLLocationDegrees? ?? 0.0
        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let appImage = UIImage()
        let appImageUUID = dictionary["appImageUUID"] as! String? ?? ""
        let timeIntervalDate = dictionary["date"] as! TimeInterval? ?? TimeInterval()
        let createdOn = Date(timeIntervalSince1970: timeIntervalDate)
        let postingUserID = dictionary["postingUserID"] as! String? ?? ""
        self.init(itemName: itemName, location: location, coordinate: coordinate, appImage: appImage, appImageUUID: appImageUUID, createdOn: createdOn, postingUserID: postingUserID, documentID: "")
    }
    
    func saveData(completion: @escaping (Bool) -> () ) {
        let db = Firestore.firestore()
        // Grab the user ID
        guard let postingUserID = (Auth.auth().currentUser?.uid) else {
            print("*** ERROR: Could not save data because we don't have a valid postingUserID")
            return completion(false)
        }
        self.postingUserID = postingUserID
        // Create the dictionary representing data we want to save
        let dataToSave: [String: Any] = self.dictionary
        // if we HAVE saved a record, we'll have an ID
        if self.documentID != "" {
            let ref = db.collection("teams").document(self.documentID)
            ref.setData(dataToSave) { (error) in
                if let error = error {
                    print("ERROR: updating document \(error.localizedDescription)")
                    completion(false)
                } else { // It worked!
                    completion(true)
                }
            }
        } else { // Otherwise create a new document via .addDocument
            var ref: DocumentReference? = nil // Firestore will create a new ID for us
            ref = db.collection("teams").addDocument(data: dataToSave) { (error) in
                if let error = error {
                    print("ERROR: adding document \(error.localizedDescription)")
                    completion(false)
                } else { // It worked! Save the documentID in Spot’s documentID property
                    self.documentID = ref!.documentID
                    completion(true)
                }
            }
        }
    }
    
    func saveImage(completed: @escaping (Bool) -> ()) {
        let db = Firestore.firestore()
        let storage = Storage.storage()
        // convert photo.image to a Data type so it can be saved by Firebase Storage
        guard let imageToSave = self.appImage.jpegData(compressionQuality: 0.5) else {
            print("*** ERROR: couuld not convert image to data format")
            return completed(false)
        }
        let uploadMetadata = StorageMetadata()
        uploadMetadata.contentType = "image/jpeg"
        if appImageUUID == "" {
            appImageUUID = UUID().uuidString // generate a unique ID to use for the photo image's name
        } // otherwise we already have a UUID and we want to overright the old image with this name.
        // create a ref to upload storage to spot.documentID's folder (bucket), with the name we created.
        let storageRef = storage.reference().child(documentID).child(self.appImageUUID)
        let uploadTask = storageRef.putData(imageToSave, metadata: uploadMetadata) {metadata, error in
            guard error == nil else {
                print("😡 ERROR during .putData storage upload for reference \(storageRef). Error: \(error!.localizedDescription)")
                return
            }
            print("😎 Upload worked! Metadata is \(metadata)")
        }
        
        uploadTask.observe(.success) { (snapshot) in
            // Create the dictionary representing the data we want to save
            let dataToSave = self.dictionary
            // This will either create a new doc at documentUUID or update the existing doc with that name
            let ref = db.collection("teams").document(self.documentID)
            ref.setData(dataToSave) { (error) in
                if let error = error {
                    print("*** ERROR: updating document \(self.appImageUUID) in spot \(self.documentID) \(error.localizedDescription)")
                    completed(false)
                } else {
                    print("^^^ Document updated with ref ID \(ref.documentID)")
                    completed(true)
                }
            }
        }
        
        uploadTask.observe(.failure) { (snapshot) in
            if let error = snapshot.error {
                print("*** ERROR: \(error.localizedDescription) upload task for file \(self.appImageUUID) failed, in document \(self.documentID)")
            }
            return completed(false)
        }
    }
    
    func loadImage(completed: @escaping () -> ())  {
        let storage = Storage.storage()
        let storageRef = storage.reference().child(self.documentID).child(self.appImageUUID)
        // there are querySnapshot!.documents.count documents in the spots snapshot
        storageRef.getData(maxSize: 25 * 1025 * 1025) { data, error in
            if let error = error {
                print("*** ERROR: An error occurred while reading data from file ref: \(storageRef) \(error.localizedDescription)")
                completed()
            } else {
                print("!!! Image successfully loaded!")
                let image = UIImage(data: data!)
                self.appImage = image!
                completed()
            }
        }
    }
    
    
}
