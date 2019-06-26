//
//  Items.swift
//  UpcycleBuddy
//
//  Created by Ella Gryf-Lowczowska on 26/06/2019.
//  Copyright © 2019 Ella Gryf-Lowczowska. All rights reserved.
//

import Foundation
import Firebase

class Items {
    var itemArray: [Item] = []
    var db: Firestore!
    
    init() {
        db = Firestore.firestore()
    }
    
    func loadData(completed: @escaping () -> ())  {
        db.collection("items").addSnapshotListener { (querySnapshot, error) in
            guard error == nil else {
                print("*** ERROR: adding the snapshot listener \(error!.localizedDescription)")
                    return completed()
            }
            self.itemArray = []
            // there are querySnapshot!.documents.count documents in the snapshot
            for document in querySnapshot!.documents {
                let item = Item(dictionary: document.data())
                item.documentID = document.documentID
                self.itemArray.append(item)
            }
            completed()
        }
    }
}
