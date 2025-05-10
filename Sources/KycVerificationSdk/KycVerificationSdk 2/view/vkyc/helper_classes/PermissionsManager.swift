//
//  PermissionsManager.swift
//  KycVerificationSdk
//
//  Created by Renu Bisht on 22/04/25.
//
import AVFoundation
import CoreLocation
import UIKit

class PermissionsManager: NSObject, CLLocationManagerDelegate {
    private var locationManager: CLLocationManager?
    private var completion: ((Bool, Bool, Bool) -> Void)?
    private var cameraGranted = false
    private var micGranted = false
    private var locationGranted = false
    private var locationLeaveCalled = false

    private let group = DispatchGroup()

    // Entry point to check and request permissions
    func checkAndRequestPermissions(
        completion: @escaping (Bool, Bool, Bool) -> Void,
        from viewController: UIViewController,
        onSettingsRedirect: (() -> Void)? = nil
    ) {
        let cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
        let micStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        let locationStatus: CLAuthorizationStatus

        locationManager = CLLocationManager()
        if #available(iOS 14.0, *) {
            locationStatus = locationManager?.authorizationStatus ?? .notDetermined
        } else {
            locationStatus = CLLocationManager.authorizationStatus()
        }

        let cameraGranted = (cameraStatus == .authorized)
        let micGranted = (micStatus == .authorized)
        let locationGranted = (locationStatus == .authorizedWhenInUse || locationStatus == .authorizedAlways)

        var deniedPermissions: [String] = []
        if cameraStatus == .denied || cameraStatus == .restricted {
            deniedPermissions.append("Camera")
        }
        if micStatus == .denied || micStatus == .restricted {
            deniedPermissions.append("Microphone")
        }
        if locationStatus == .denied || locationStatus == .restricted {
            deniedPermissions.append("Location")
        }

        if deniedPermissions.isEmpty {
            // All permissions granted or requestable
            if cameraGranted && micGranted && locationGranted {
                completion(true, true, true)
            } else {
                requestPermissions(completion: completion)
            }
        } else {
            // Show alert to guide to settings
            showPermissionAlert(missingPermissions: deniedPermissions, from: viewController, onSettingsRedirect: onSettingsRedirect)
        }
    }

    private func requestPermissions(completion: @escaping (Bool, Bool, Bool) -> Void) {
        self.completion = completion
        locationLeaveCalled = false

        // Camera
        group.enter()
        AVCaptureDevice.requestAccess(for: .video) { granted in
            self.cameraGranted = granted
            self.group.leave()
        }

        // Microphone
        group.enter()
        AVCaptureDevice.requestAccess(for: .audio) { granted in
            self.micGranted = granted
            self.group.leave()
        }

        // Location
        group.enter()
        locationManager = CLLocationManager()
        locationManager?.delegate = self

        let status: CLAuthorizationStatus
        if #available(iOS 14.0, *) {
            status = locationManager?.authorizationStatus ?? .notDetermined
        } else {
            status = CLLocationManager.authorizationStatus()
        }

        if status == .notDetermined {
            locationManager?.requestWhenInUseAuthorization()
        } else {
            locationGranted = (status == .authorizedWhenInUse || status == .authorizedAlways)
            leaveLocationIfNeeded()
        }

        group.notify(queue: .main) { [self] in
            completion(cameraGranted, micGranted, locationGranted)
            locationManager?.delegate = nil
            locationManager = nil
        }
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status != .notDetermined {
            locationGranted = (status == .authorizedWhenInUse || status == .authorizedAlways)
            leaveLocationIfNeeded()
        }
    }

    private func leaveLocationIfNeeded() {
        if !locationLeaveCalled {
            locationLeaveCalled = true
            group.leave()
        }
    }

    // Location fetcher
    func fetchCurrentLocation(completion: @escaping (CLLocationCoordinate2D?) -> Void) {
        guard let locManager = locationManager else {
            completion(nil)
            return
        }
        let status: CLAuthorizationStatus
        if #available(iOS 14.0, *) {
            status = locManager.authorizationStatus
        } else {
            status = CLLocationManager.authorizationStatus()
        }

        if status == .authorizedWhenInUse || status == .authorizedAlways {
            completion(locManager.location?.coordinate)
        } else {
            completion(nil)
        }
    }

    // Show alert to guide to settings
    private func showPermissionAlert(
        missingPermissions: [String],
        from viewController: UIViewController,
        onSettingsRedirect: (() -> Void)? = nil
    ) {
        let message = "App requires permissions. Please enable the following in Settings:\n" + missingPermissions.joined(separator: ", ")
        let alert = UIAlertController(title: "Permissions Required", message: message, preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: "Go to Settings", style: .default) { _ in
            onSettingsRedirect?() // Trigger the callback when navigating to settings
            guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else { return }
            if UIApplication.shared.canOpenURL(settingsUrl) {
                UIApplication.shared.open(settingsUrl)
            }
        })

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        viewController.present(alert, animated: true)
    }
}
