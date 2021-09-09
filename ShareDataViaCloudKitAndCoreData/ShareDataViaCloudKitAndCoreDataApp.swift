//
//  ShareDataViaCloudKitAndCoreDataApp.swift
//  ShareDataViaCloudKitAndCoreData
//
//  Created by Yang Xu on 2021/9/9.
//

import SwiftUI

@main
struct ShareDataViaCloudKitAndCoreDataApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    let stack = CoreDataStack.shared
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, stack.persistentContainer.viewContext)
        }
    }
}
