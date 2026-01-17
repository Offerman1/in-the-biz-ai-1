import Flutter
import UIKit
import EventKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let eventStore = EKEventStore()
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    // Set up calendar permission method channel
    if let controller = self.window?.rootViewController as? FlutterViewController {
      let calendarChannel = FlutterMethodChannel(
        name: "com.inthebiz.app/calendar",
        binaryMessenger: controller.binaryMessenger
      )
      
      calendarChannel.setMethodCallHandler { [weak self] (call, result) in
        guard let self = self else { return }
        
        switch call.method {
        case "requestCalendarPermission":
          self.requestCalendarPermissions { granted, error in
            if let error = error {
              result(FlutterError(code: "PERMISSION_ERROR", message: error, details: nil))
            } else {
              result(granted)
            }
          }
        case "checkCalendarPermission":
          let status = self.checkCalendarPermissions()
          result(status)
        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  private func requestCalendarPermissions(completion: @escaping (Bool, String?) -> Void) {
    if #available(iOS 17.0, *) {
      // iOS 17+ requires requestFullAccessToEvents
      eventStore.requestFullAccessToEvents { granted, error in
        completion(granted, error?.localizedDescription)
      }
    } else {
      // iOS 16 and below
      eventStore.requestAccess(to: .event) { granted, error in
        completion(granted, error?.localizedDescription)
      }
    }
  }
  
  private func checkCalendarPermissions() -> String {
    if #available(iOS 17.0, *) {
      let status = EKEventStore.authorizationStatus(for: .event)
      switch status {
      case .fullAccess:
        return "fullAccess"
      case .writeOnly:
        return "writeOnly"
      case .notDetermined:
        return "notDetermined"
      case .restricted:
        return "restricted"
      case .denied:
        return "denied"
      @unknown default:
        return "unknown"
      }
    } else {
      let status = EKEventStore.authorizationStatus(for: .event)
      switch status {
      case .authorized:
        return "authorized"
      case .notDetermined:
        return "notDetermined"
      case .restricted:
        return "restricted"
      case .denied:
        return "denied"
      @unknown default:
        return "unknown"
      }
    }
  }
}
