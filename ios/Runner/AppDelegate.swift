import UIKit
import Flutter
import flutter_local_notifications

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    FlutterLocalNotificationsPlugin.register(with: self.registrar(forPlugin: "FlutterLocalNotificationsPlugin"))

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
