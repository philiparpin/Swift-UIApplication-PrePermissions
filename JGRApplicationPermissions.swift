//
//  JGRApplicationPermissions.swift
//  PrePermissions
//
//  Created by Jack Rostron on 10/08/2014.
//  Copyright (c) 2014 Jack Rostron. All rights reserved.
//

import Foundation
import UIKit
import EventKit
import AddressBook
import CoreLocation
import AVFoundation
import AssetsLibrary

//Enums
enum JGRApplicationPermissionCallback {
    case NoAction
    case Later
    case Denied
    case Granted
}

private enum JGRApplicationSystemAccessState {
    case Denied
    case Granted
    case Restricted
    case Unknown
}

class JGRApplicationPermissions: NSObject, CLLocationManagerDelegate {
    
    //Singleton
    class var sharedInstance: JGRApplicationPermissions {
    struct Static {
        static var instance: JGRApplicationPermissions?
        static var token: dispatch_once_t = 0
        }
        
        dispatch_once(&Static.token) {
            Static.instance = JGRApplicationPermissions()
        }
        
        return Static.instance!
    }
    
    //Properties
    private var calendarCallback: ((state: JGRApplicationPermissionCallback) -> Void)?
    private var cameraCallback: ((state: JGRApplicationPermissionCallback) -> Void)?
    private var contactsCallback: ((state: JGRApplicationPermissionCallback) -> Void)?
    private var locationCallback: ((state: JGRApplicationPermissionCallback) -> Void)?
    private var photosCallback: ((state: JGRApplicationPermissionCallback) -> Void)?
    private var remindersCallback: ((state: JGRApplicationPermissionCallback) -> Void)?
    
    private var locationManager = CLLocationManager()
    
    //Private Methods
    private func configureAlertWithTitle(title: String?, message: String?, denyButtonTitle: String?, grantButtonTitle: String?, completionCallback:(state: JGRApplicationPermissionCallback) -> Void, grantActionClosure:() -> Void) -> UIAlertController {
        
        var alertDeny = (denyButtonTitle != nil) ? denyButtonTitle : "Not Now"
        var alertGrant = (grantButtonTitle != nil) ? grantButtonTitle : "Give Access"
        
        let denyAction = UIAlertAction(title: alertDeny, style: UIAlertActionStyle.Cancel) { (UIAlertAction) -> Void in
            completionCallback(state: JGRApplicationPermissionCallback.Later)
        }

        let grantAction = UIAlertAction(title: alertGrant, style: UIAlertActionStyle.Default) { (UIAlertAction) -> Void in
            grantActionClosure()
        }
        
        let alertView = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alertView.addAction(denyAction)
        alertView.addAction(grantAction)
        
        return alertView;
    }
    
    private func configureAndShowAlertWithTitle(title: String?, message: String?, denyButtonTitle: String?, grantButtonTitle: String?, completionCallback:(state: JGRApplicationPermissionCallback) -> Void, grantActionClosure:() -> Void) {
        let alertView = self.configureAlertWithTitle(title, message: message, denyButtonTitle: denyButtonTitle, grantButtonTitle: grantButtonTitle, completionCallback: completionCallback, grantActionClosure: grantActionClosure);
        UIApplication.sharedApplication().keyWindow.rootViewController .presentViewController(alertView, animated: true, completion: nil);
    }

    
    //Alerts
    func showCalendarPermissions(title: String?, message: String?, denyButtonTitle: String?, grantButtonTitle: String?, completionClosure: (state: JGRApplicationPermissionCallback) -> Void) {
        
        switch hasCalendarAccess() {
        case .Granted:
            completionClosure(state: .NoAction)
        case .Denied:
            completionClosure(state: .Denied)
        case .Restricted:
            completionClosure(state: .Denied)
        default:
            var alertTitle = (title != nil) ? title : "Access Calendar?";
            var alertBody = (message != nil) ? message : "The current app is requesting access to your Calendar. Do you want to provide it access?"
            
            calendarCallback = completionClosure;
            
            configureAndShowAlertWithTitle(alertTitle, message: alertBody, denyButtonTitle: denyButtonTitle, grantButtonTitle: grantButtonTitle, completionCallback: completionClosure, grantActionClosure: { () -> Void in
                self.requestSystemPermissionForCalendar()
            });
        }
    }
    
    func showCameraPermissions(title: String?, message: String?, denyButtonTitle: String?, grantButtonTitle: String?, completionClosure: (state: JGRApplicationPermissionCallback) -> Void) {
        
        switch hasCameraAccess() {
        case .Granted:
            completionClosure(state: .NoAction)
        case .Denied:
            completionClosure(state: .Denied)
        case .Restricted:
            completionClosure(state: .Denied)
        default:
            var alertTitle = (title != nil) ? title : "Access Camera?";
            var alertBody = (message != nil) ? message : "The current app is requesting access to your Camera. Do you want to provide it access?"
            
            cameraCallback = completionClosure;
            
            configureAndShowAlertWithTitle(alertTitle, message: alertBody, denyButtonTitle: denyButtonTitle, grantButtonTitle: grantButtonTitle, completionCallback: completionClosure, grantActionClosure: { () -> Void in
                self.requestSystemPermissionForCamera()
            });
        }
    }
    
    func showContactsPermissions(title: String?, message: String?, denyButtonTitle: String?, grantButtonTitle: String?, completionClosure: (state: JGRApplicationPermissionCallback) -> Void) {
        
        switch hasContactsAccess() {
        case .Granted:
            completionClosure(state: .NoAction)
        case .Denied:
            completionClosure(state: .Denied)
        case .Restricted:
            completionClosure(state: .Denied)
        default:
            var alertTitle = (title != nil) ? title : "Access Contacts?";
            var alertBody = (message != nil) ? message : "The current app is requesting access to your Contacts. Do you want to provide it access?"
            
            contactsCallback = completionClosure;
            
            configureAndShowAlertWithTitle(alertTitle, message: alertBody, denyButtonTitle: denyButtonTitle, grantButtonTitle: grantButtonTitle, completionCallback: completionClosure, grantActionClosure: { () -> Void in
                self.requestSystemPermissionForContacts()
            });
        }
    }
    
    func showLocationPermissions(title: String?, message: String?, denyButtonTitle: String?, grantButtonTitle: String?, completionClosure: (state: JGRApplicationPermissionCallback) -> Void) {
        
        switch hasLocationAccess() {
        case .Granted:
            completionClosure(state: .NoAction)
        case .Denied:
            completionClosure(state: .Denied)
        case .Restricted:
            completionClosure(state: .Denied)
        default:
            var alertTitle = (title != nil) ? title : "Access Location?";
            var alertBody = (message != nil) ? message : "The current app is requesting access to your Location. Do you want to provide it access?"
            
            locationCallback = completionClosure;
            
            configureAndShowAlertWithTitle(alertTitle, message: alertBody, denyButtonTitle: denyButtonTitle, grantButtonTitle: grantButtonTitle, completionCallback: completionClosure, grantActionClosure: { () -> Void in
                self.locationManager.delegate = self;
                self.locationManager.requestAlwaysAuthorization()
            });
        }
    }
    
    func showPhotosPermissions(title: String?, message: String?, denyButtonTitle: String?, grantButtonTitle: String?, completionClosure: (state: JGRApplicationPermissionCallback) -> Void) {
        
        switch hasPhotosAccess() {
        case .Granted:
            completionClosure(state: .NoAction)
        case .Denied:
            completionClosure(state: .Denied)
        case .Restricted:
            completionClosure(state: .Denied)
        default:
            var alertTitle = (title != nil) ? title : "Access Photos?";
            var alertBody = (message != nil) ? message : "The current app is requesting access to your Photos. Do you want to provide it access?"
            
            photosCallback = completionClosure;
            
            configureAndShowAlertWithTitle(alertTitle, message: alertBody, denyButtonTitle: denyButtonTitle, grantButtonTitle: grantButtonTitle, completionCallback: completionClosure, grantActionClosure: { () -> Void in
                self.requestSystemPermissionForPhotos()
            });
        }
    }
    
    func showRemindersPermissions(title: String?, message: String?, denyButtonTitle: String?, grantButtonTitle: String?, completionClosure: (state: JGRApplicationPermissionCallback) -> Void) {
        
        switch hasRemindersAccess() {
        case .Granted:
            completionClosure(state: .NoAction)
        case .Denied:
            completionClosure(state: .Denied)
        case .Restricted:
            completionClosure(state: .Denied)
        default:
            var alertTitle = (title != nil) ? title : "Access Reminders?";
            var alertBody = (message != nil) ? message : "The current app is requesting access to your Reminders. Do you want to provide it access?"
            
            remindersCallback = completionClosure;
            
            configureAndShowAlertWithTitle(alertTitle, message: alertBody, denyButtonTitle: denyButtonTitle, grantButtonTitle: grantButtonTitle, completionCallback: completionClosure, grantActionClosure: { () -> Void in
                self.requestSystemPermissionForReminders()
            });
        }
    }
    
    //Permission Checks
    private func hasCalendarAccess() -> JGRApplicationSystemAccessState {
        switch EKEventStore.authorizationStatusForEntityType(EKEntityTypeEvent) {
        case .Authorized:
            return JGRApplicationSystemAccessState.Granted
        case .Denied:
            return JGRApplicationSystemAccessState.Denied
        case .Restricted:
            return JGRApplicationSystemAccessState.Restricted
        case .NotDetermined:
            return JGRApplicationSystemAccessState.Unknown
        }
    }
    
    private func hasCameraAccess() -> JGRApplicationSystemAccessState {
        switch AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeVideo) {
        case .Authorized:
            return JGRApplicationSystemAccessState.Granted
        case .Denied:
            return JGRApplicationSystemAccessState.Denied
        case .Restricted:
            return JGRApplicationSystemAccessState.Restricted
        case .NotDetermined:
            return JGRApplicationSystemAccessState.Unknown
        }
    }
    
    private func hasContactsAccess() -> JGRApplicationSystemAccessState {
        switch ABAddressBookGetAuthorizationStatus() {
        case .Authorized:
            return JGRApplicationSystemAccessState.Granted
        case .Denied:
            return JGRApplicationSystemAccessState.Denied
        case .Restricted:
            return JGRApplicationSystemAccessState.Restricted
        case .NotDetermined:
            return JGRApplicationSystemAccessState.Unknown
        }
    }
    
    private func hasLocationAccess() -> JGRApplicationSystemAccessState {
        switch CLLocationManager.authorizationStatus() {
        case .Authorized:
            return JGRApplicationSystemAccessState.Granted
        case .AuthorizedWhenInUse:
            return JGRApplicationSystemAccessState.Granted
        case .Denied:
            return JGRApplicationSystemAccessState.Denied
        case .Restricted:
            return JGRApplicationSystemAccessState.Restricted
        case .NotDetermined:
            return JGRApplicationSystemAccessState.Unknown
        }
    }
    
    private func hasPhotosAccess() -> JGRApplicationSystemAccessState {
        switch ALAssetsLibrary.authorizationStatus() {
        case .Authorized:
            return JGRApplicationSystemAccessState.Granted
        case .Denied:
            return JGRApplicationSystemAccessState.Denied
        case .Restricted:
            return JGRApplicationSystemAccessState.Restricted
        case .NotDetermined:
            return JGRApplicationSystemAccessState.Unknown
        }
    }
    
    private func hasRemindersAccess() -> JGRApplicationSystemAccessState {
        switch EKEventStore.authorizationStatusForEntityType(EKEntityTypeReminder) {
        case .Authorized:
            return JGRApplicationSystemAccessState.Granted
        case .Denied:
            return JGRApplicationSystemAccessState.Denied
        case .Restricted:
            return JGRApplicationSystemAccessState.Restricted
        case .NotDetermined:
            return JGRApplicationSystemAccessState.Unknown
        }
    }
    
    //Request Permission Dialogs
    private func requestSystemPermissionForCalendar() { //Calendar
        let eventStore = EKEventStore();
        eventStore.requestAccessToEntityType(EKEntityTypeEvent, completion: {(granted: Bool, error: NSError!) in
            (granted) ? self.calendarCallback!(state: JGRApplicationPermissionCallback.Granted) : self.calendarCallback!(state: JGRApplicationPermissionCallback.Denied)
        })
    }
    
    private func requestSystemPermissionForCamera() { //Camera
        AVCaptureDevice.requestAccessForMediaType(AVMediaTypeVideo, completionHandler: {(granted: Bool) -> Void in
            (granted) ? self.cameraCallback!(state: JGRApplicationPermissionCallback.Granted) : self.cameraCallback!(state: JGRApplicationPermissionCallback.Denied)
        })
    }
    
    private func requestSystemPermissionForContacts() { //Contacts
        var emptyDictionary: CFDictionaryRef?
        var addressBook = !ABAddressBookCreateWithOptions(emptyDictionary, nil)
        ABAddressBookRequestAccessWithCompletion(addressBook, {(success :Bool, error :CFError!) in
            (success) ? self.contactsCallback!(state: JGRApplicationPermissionCallback.Granted) : self.contactsCallback!(state: JGRApplicationPermissionCallback.Denied)
        })
    }
    
    private func requestSystemPermissionForPhotos() { //Photos
        let assetsLibrary = ALAssetsLibrary()
        assetsLibrary.enumerateGroupsWithTypes(ALAssetsGroupType(ALAssetsGroupAll), usingBlock: {(group: ALAssetsGroup!, stop: UnsafeMutablePointer<ObjCBool>) in
            self.photosCallback!(state: JGRApplicationPermissionCallback.Granted)
            }, failureBlock: {(error: NSError!) in
                self.photosCallback!(state: JGRApplicationPermissionCallback.Denied)
        });
    }
    
    private func requestSystemPermissionForReminders() { //Reminders
        let eventStore = EKEventStore();
        eventStore.requestAccessToEntityType(EKEntityTypeReminder, completion: {(granted: Bool, error: NSError!) in
            (granted) ? self.remindersCallback!(state: JGRApplicationPermissionCallback.Granted) : self.remindersCallback!(state: JGRApplicationPermissionCallback.Denied)
        })
    }
    
    //Location Manager Delegate
    func locationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        self.locationManager.stopUpdatingLocation()
        (status == CLAuthorizationStatus.Authorized) ? self.locationCallback!(state: JGRApplicationPermissionCallback.Granted) : self.locationCallback!(state: JGRApplicationPermissionCallback.Denied)
    }
    
    
    
    
}
