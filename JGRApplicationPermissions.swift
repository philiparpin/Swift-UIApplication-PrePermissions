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

class JGRApplicationPermissions: NSObject {
    
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
    
    //Initialiser
    override init() {
        println("Init called")
        super.init()
    }
    
    //Properties
    private var calendarCallback: ((state: JGRApplicationPermissionCallback) -> Void)?
//    private var calendarAlertView: UIAlertController?
//    private var cameraAlertView: UIAlertController?
//    private var contactsAlertView: UIAlertController?
//    private var locationAlertView: UIAlertController?
//    private var photosAlertView: UIAlertController?
//    private var remindersAlertView: UIAlertController?
    
    //Private Methods
    private func configureAlertWithTitle(title: String?, message: String?, denyButtonTitle: String?, grantButtonTitle: String?, completionCallback:(state: JGRApplicationPermissionCallback) -> Void, grantActionClosure:() -> Void) -> UIAlertController {
        
        let denyAction = UIAlertAction(title: denyButtonTitle, style: UIAlertActionStyle.Cancel) { (UIAlertAction) -> Void in
            completionCallback(state: JGRApplicationPermissionCallback.NoAction)
        }

        let grantAction = UIAlertAction(title: grantButtonTitle, style: UIAlertActionStyle.Default) { (UIAlertAction) -> Void in
            grantActionClosure()
        }
        
        let alertView = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alertView.addAction(denyAction)
        alertView.addAction(grantAction)
        
        return alertView;
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
            var alertDeny = (denyButtonTitle != nil) ? denyButtonTitle : "Not Now"
            var alertGrant = (grantButtonTitle != nil) ? grantButtonTitle : "Give Access"
            
            calendarCallback = completionClosure;
            
            let calendarAlertView = configureAlertWithTitle(alertTitle, message: alertBody, denyButtonTitle: alertDeny, grantButtonTitle: alertGrant, completionCallback: completionClosure, grantActionClosure: { () -> Void in
                self.requestSystemPermissionForCalendar()
            });
            
            UIApplication.sharedApplication().keyWindow.rootViewController .presentViewController(calendarAlertView, animated: true, completion: nil);
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
    
    //Request Permission Dialogs
    private func requestSystemPermissionForCalendar() {
        let eventStore = EKEventStore();
        eventStore.requestAccessToEntityType(EKEntityTypeEvent, completion: {(granted: Bool, error: NSError!) in
            (granted) ? self.calendarCallback!(state: JGRApplicationPermissionCallback.Granted) : self.calendarCallback!(state: JGRApplicationPermissionCallback.Denied)
        })
    }
    
    
    
    
}