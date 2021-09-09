//
//  ShareController.swift
//  ShareController
//
//  Created by Yang Xu on 2021/9/9.
//

import CloudKit
import Foundation
import SwiftUI
import UIKit

struct CloudSharingView: UIViewControllerRepresentable {
    let share: CKShare
    let container: CKContainer
    let note:Note

    func makeCoordinator() -> CloudSharingCoordinator {
        CloudSharingCoordinator.shared
    }

    func makeUIViewController(context: Context) -> UICloudSharingController {
        share[CKShare.SystemFieldKey.title] = note.name
        let controller = UICloudSharingController(share: share, container: container)
        controller.modalPresentationStyle = .formSheet
        controller.delegate = context.coordinator
        context.coordinator.note = note
        return controller
    }

    func updateUIViewController(_ uiViewController: UICloudSharingController, context: Context) {

    }
}

class CloudSharingCoordinator:NSObject,UICloudSharingControllerDelegate{
    func cloudSharingController(_ csc: UICloudSharingController, failedToSaveShareWithError error: Error) {
        print("failed to save share\(error)")
    }

    func itemTitle(for csc: UICloudSharingController) -> String? {
        note?.name
    }

    func cloudSharingControllerDidSaveShare(_ csc: UICloudSharingController){
        
    }

    func cloudSharingControllerDidStopSharing(_ csc: UICloudSharingController){
       // 应该处理掉ckshare,不过目前没有官方的解决方案。还在寻找中。
        print("remove from share")
    }
    static let shared = CloudSharingCoordinator()
    var note:Note?
}


