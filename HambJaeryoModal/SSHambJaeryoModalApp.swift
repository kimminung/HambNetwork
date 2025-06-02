//
//  SSHambJaeryoModalApp.swift
//  SSHambJaeryoModal
//
//  Created by coulson on 5/28/25.
//

import SwiftUI
import SwiftData
import FirebaseCore


class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()
        return true
    }
}


@main
struct SSHambJaeryoModalApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    
    var body: some Scene {
        WindowGroup {
            SSMenuMainView()
                .modelContainer(for: [
                    SSIngredientEntity.self
                ])
        }
    }
}
