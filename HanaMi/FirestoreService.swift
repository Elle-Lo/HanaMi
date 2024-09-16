//
//  FirestoreService.swift
//  HanaMi
//
//  Created by Tzu ning Lo on 2024/9/17.
//

import SwiftUI
import FirebaseFirestore
import MapKit

class FirestoreService {
    private let db = Firestore.firestore()
    
    func saveData(userID: String, coordinate: CLLocationCoordinate2D, locationName: String, category: String, isPublic: Bool, completion: @escaping (Result<Void, Error>) -> Void) {
        let data: [String: Any] = [
            "latitude": coordinate.latitude,
            "longitude": coordinate.longitude,
            "locationName": locationName,
            "category": category,
            "isPublic": isPublic,
            "timestamp": Timestamp() // 添加時間戳
        ]
        
        db.collection("Users").document(userID).setData(data, merge: true) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
}

