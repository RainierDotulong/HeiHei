//
//  FirebaseStorage.swift
//  broilerfarm
//
//  Created by Troy Dotulong on 3/23/20.
//  Copyright © 2020 Troy Dotulong. All rights reserved.
//

import Foundation
import FirebaseStorage

class FirebaseStorage {
    func uploadImagetoFirebaseStorage(imageRef : String, jpegData : Data) {
        //Upload to Firebase Storage
        let storageRef = Storage.storage().reference()
        let imageRef = storageRef.child(imageRef)
        // Create the file metadata
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        // Upload file and metadata to the object
        let jpegData = jpegData
        let uploadTask = imageRef.putData(jpegData, metadata: metadata)
        // Listen for state changes, errors, and completion of the upload.
        uploadTask.observe(.resume) { snapshot in
          // Upload resumed, also fires when the upload starts
        }
        uploadTask.observe(.failure) { snapshot in
            if let error = snapshot.error as NSError? {
            switch (StorageErrorCode(rawValue: error.code)!) {
            case .objectNotFound:
                // File doesn't exist
                print("File does not exist")
              break
            case .unauthorized:
              // User doesn't have permission to access file
                print("User doesn't have permission to access file")
              break
            case .cancelled:
              // User canceled the upload
                print("User canceled the upload")
              break
            case .unknown:
              // Unknown error occurred, inspect the server response
                print("Unknown error occurred, inspect the server response")
              break
            default:
              // A separate error occurred. This is a good place to retry the upload.
                imageRef.putData(jpegData, metadata: metadata)
              break
            }
          }
        }
        uploadTask.observe(.success) { snapshot in
          // Upload completed successfully
            print("Image Upload completed successfully")
        }
    }
    
    func uploadPDFtoFirebaseStorage(pdfRef : String, filePath : String) {
        //Upload to Firebase Storage
        let storageRef = Storage.storage().reference()
        let pdfRef = storageRef.child(pdfRef)
        // Create the file metadata
        let metadata = StorageMetadata()
        metadata.contentType = "application/pdf"
        
        // Upload file and metadata to the object
        let uploadTask = pdfRef.putFile(from: URL(fileURLWithPath: filePath), metadata: metadata)
        // Listen for state changes, errors, and completion of the upload.
        uploadTask.observe(.resume) { snapshot in
          // Upload resumed, also fires when the upload starts
        }
        uploadTask.observe(.failure) { snapshot in
            if let error = snapshot.error as NSError? {
            switch (StorageErrorCode(rawValue: error.code)!) {
            case .objectNotFound:
                // File doesn't exist
                print("File does not exist")
              break
            case .unauthorized:
              // User doesn't have permission to access file
                print("User doesn't have permission to access file")
              break
            case .cancelled:
              // User canceled the upload
                print("User canceled the upload")
              break
            case .unknown:
              // Unknown error occurred, inspect the server response
                print("Unknown error occurred, inspect the server response")
              break
            default:
              // A separate error occurred. This is a good place to retry the upload.
                pdfRef.putFile(from: URL(fileURLWithPath: filePath), metadata: metadata)
              break
            }
          }
        }
        uploadTask.observe(.success) { snapshot in
          // Upload completed successfully
            print("Image Upload completed successfully")
        }
    }
}
