//
//
// ConnectTazIDController.swift
//
// Created by Ringo Müller-Gromes on 23.07.20.
// Copyright © 2020 Ringo Müller-Gromes for "taz" digital newspaper. All rights reserved.
// 

import UIKit
import NorthLib

// MARK: - ConnectTazIDController
/// Presents Register TazID Form and Functionallity
/// ChildViews/Controller are pushed modaly
class ConnectTazIDController: FormsController {
  
  var aboId:String
  var aboIdPassword:String
  
  init(aboId:String, aboIdPassword:String) {
    self.aboId = aboId
    self.aboIdPassword = aboIdPassword
    super.init(nibName: nil, bundle: nil)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  var mailInput
    = FormularView.textField(placeholder: Localized("login_email_hint")
  )
  var passInput
    = FormularView.textField(placeholder: Localized("login_password_hint"),
                             textContentType: .password,
                             isSecureTextEntry: true)
  
  var pass2Input
    = FormularView.textField(placeholder: Localized("login_password_confirmation_hint"),
                             textContentType: .password,
                             isSecureTextEntry: true)
  
  var firstnameInput
    = FormularView.textField(placeholder: Localized("login_first_name_hint"))
  
  var lastnameInput
    = FormularView.textField(placeholder: Localized("login_surname_hint"))
  
  // MARK: viewDidLoad Action
  override func viewDidLoad() {
    self.contentView = FormularView()
    self.contentView?.views =   [
      FormularView.header(),
      FormularView.label(title:
        Localized("fragment_login_missing_credentials_header_registration")),
      FormularView.labelLikeButton(title: Localized("fragment_login_missing_credentials_switch_to_login"),
                                   paddingTop: 0,
                                   paddingBottom: 0,
                                   target: self,
                                   action: #selector(handleAlreadyHaveTazID)),
      mailInput,
      passInput,
      pass2Input,
      firstnameInput,
      lastnameInput,
      contentView!.agbAcceptTV,
      FormularView.button(title: Localized("login_button"),
                          target: self,
                          action: #selector(handleSend)),
      FormularView.outlineButton(title: Localized("cancel_button"),
                                 target: self,
                                 action: #selector(handleCancel)),
    ]
    super.viewDidLoad()
  }
  
  ///Validates the Form returns translated Errormessage String for Popup/Toast
  ///Mark issue fields with hints
  func validate() -> String?{
    return nil;
    var errors = false
    
    mailInput.bottomMessage = ""
    passInput.bottomMessage = ""
    pass2Input.bottomMessage = ""
    firstnameInput.bottomMessage = ""
    lastnameInput.bottomMessage = ""
    self.contentView?.agbAcceptTV.error = false
    
    if (mailInput.text ?? "").isEmpty {
      errors = true
      mailInput.bottomMessage = Localized("login_email_error_empty")
    } else if (mailInput.text ?? "").isValidEmail() == false {
      errors = true
      mailInput.bottomMessage = Localized("login_email_error_no_email")
    }
    
    if (passInput.text ?? "").isEmpty {
      errors = true
      passInput.bottomMessage = Localized("login_password_error_empty")
    }
    
    if (pass2Input.text ?? "").isEmpty {
      errors = true
      pass2Input.bottomMessage = Localized("login_password_error_empty")
    }
    else if pass2Input.text != pass2Input.text {
      pass2Input.bottomMessage = Localized("login_password_confirmation_error_match")
    }
    
    if (firstnameInput.text ?? "").isEmpty {
      errors = true
      firstnameInput.bottomMessage = Localized("login_first_name_error_empty")
    }
    
    if (lastnameInput.text ?? "").isEmpty {
      errors = true
      lastnameInput.bottomMessage = Localized("login_surname_error_empty")
    }
    
    if self.contentView?.agbAcceptTV.checked == false {
      self.contentView?.agbAcceptTV.error = true
      return Localized("register_validation_issue_agb")
    }
    
    if errors {
      return Localized("register_validation_issue")
    }
    
    return nil
  }
  
  // MARK: handleLogin Action
  @IBAction func handleSend(_ sender: UIButton) {
    sender.isEnabled = false
    
    if let errormessage = self.validate() {
      Toast.show(errormessage, .alert)
      sender.isEnabled = true
      return
    }
    
    let mail = mailInput.text ?? ""
    let pass = passInput.text ?? ""
    let lastname = lastnameInput.text ?? ""
    let firstname = firstnameInput.text ?? ""
       
    let dfl = Defaults.singleton
    let pushToken = dfl["pushToken"]
    let installationId = dfl["installationId"] ?? App.installationId
    
    //Start mutationSubscriptionId2tazId
    //spinner.enabler=true
    SharedFeeder.shared.feeder?.subscriptionId2tazId(tazId: mail, password: pass, aboId: self.aboId, aboIdPW: aboIdPassword, surname: lastname, firstName: firstname, installationId: installationId, pushToken: pushToken, closure: { (result) in
      //Re-Enable Button if needed
      sender.isEnabled = true
//      spinner.enabler=false
      switch result {
        case .success(let info):
          //ToDo #900
          switch info.status {
            /// we are waiting for eMail confirmation (using push/poll)
            case .waitForMail:
              self.showResultWith(message: Localized("fragment_login_confirm_email_header"),
                                  backButtonTitle: Localized("fragment_login_success_login_back_article"),
                                  dismissType: .all)
            /// valid authentication
            case .valid:
              self.showResultWith(message: Localized("fragment_login_registration_successful_header"),
                                  backButtonTitle: Localized("fragment_login_success_login_back_article"),
                                  dismissType: .all)
            /// valid tazId connected to different AboId
            case .alreadyLinked:
              self.showResultWith(message: Localized("subscriptionId2tazId_alreadyLinked"),
                                  backButtonTitle: Localized("back_to_login"),
                                  dismissType: .leftFirst)
            /// invalid mail address (only syntactic check)
            case .invalidMail:
              self.mailInput.bottomMessage = Localized("login_email_error_no_email")
              Toast.show(Localized("register_validation_issue"))
            /// tazId not verified
            case .tazIdNotValid:
              Toast.show(Localized("toast_login_failed_retry"))//ToDo
            /// AboId not verified
            case .subscriptionIdNotValid:
              fallthrough
            /// AboId valid but connected to different tazId
            case .invalidConnection:
              fallthrough
            /// server will confirm later (using push/poll)
            case .waitForProc:
              fallthrough
            /// user probably didn't confirm mail
            case .noPollEntry:
              fallthrough
            /// account provided by token is expired
            case .expired:
              fallthrough
            /// no surname provided - seems to be necessary fro trial subscriptions
            case .noSurname:
              fallthrough
            /// no firstname provided
            case .noFirstname:
              fallthrough
            case .unknown:  /// decoded from unknown string
              fallthrough
            default:
              Toast.show(Localized("toast_login_failed_retry"))
              print("Succeed with status: \(info.status) message: \(info.message ?? "-")")
        }
        case .failure:
          Toast.show("ein Fehler...")
      }
    })
  }
  
  
  fileprivate func showResultWith(message:String, backButtonTitle:String,dismissType:dismissType){
    let successCtrl
       = ConnectTazID_Result_Controller(message: message,
                                        backButtonTitle: backButtonTitle,
                                       dismissType: dismissType)
     successCtrl.modalPresentationStyle = .overCurrentContext
     successCtrl.modalTransitionStyle = .flipHorizontal
     self.present(successCtrl, animated: true, completion:nil)
  }
  
  // MARK: handleLogin Action
  @IBAction func handleCancel(_ sender: UIButton) {
    self.dismiss(animated: true, completion: nil)
  }
  
  @IBAction func handleAlreadyHaveTazID(_ sender: UIButton) {
    let child = LoginWithTazIDController()
    child.modalPresentationStyle = .overCurrentContext
    child.modalTransitionStyle = .flipHorizontal
    self.present(child, animated: true, completion: nil)
  }
}

fileprivate enum dismissType {case all, current, leftFirst}

// MARK: - ConnectTazID_WaitForMail_Controller
class ConnectTazID_WaitForMail_Controller: FormsController {
  override func viewDidLoad() {
    self.contentView = FormularView()
    self.contentView?.views =  [
      FormularView.header(),
      FormularView.label(title: Localized("fragment_login_confirm_email_header"),
                         paddingTop: 30,
                         paddingBottom: 30
      ),
      FormularView.button(title: Localized("fragment_login_success_login_back_article"),
                          target: self, action: #selector(handleBack)),
      
    ]
    super.viewDidLoad()
  }
  
  // MARK: handleBack Action
  @IBAction func handleBack(_ sender: UIButton) {
    let parent = self.presentingViewController as? PwForgottController
    self.dismiss(animated: true, completion: nil)
    parent?.dismiss(animated: false, completion: nil)
  }
}


// MARK: - ConnectTazID_WaitForMail_Controller
class ConnectTazID_Result_Controller: FormsController {
  
  let message:String
  let backButtonTitle:String
  fileprivate let dismissType:dismissType
  
  fileprivate init(message:String, backButtonTitle:String, dismissType:dismissType) {
    self.message = message
    self.backButtonTitle = backButtonTitle
    self.dismissType = dismissType
    super.init(nibName: nil, bundle: nil)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  
  override func viewDidLoad() {
    self.contentView = FormularView()
    self.contentView?.views =  [
      FormularView.header(),
      FormularView.label(title: message,
                         paddingTop: 30,
                         paddingBottom: 30
      ),
      FormularView.button(title: backButtonTitle,
                          target: self, action: #selector(handleBack)),
      
    ]
    super.viewDidLoad()
  }
  
  // MARK: handleBack Action
  @IBAction func handleBack(_ sender: UIButton) {
    var stack = self.modalStack
    switch dismissType {
      case .all:
        _ = stack.popLast()//removes self
        stack.forEach { $0.view.isHidden = true }
        self.dismiss(animated: true) {
          stack.forEach { $0.dismiss(animated: false, completion: nil)}
        }
      case .leftFirst:
        _ = stack.popLast()//removes self
        _ = stack.pop()//removes first
        stack.forEach { $0.view.isHidden = true }
        self.dismiss(animated: true) {
          stack.forEach { $0.dismiss(animated: false, completion: nil)}
        }
      case .current:
        self.dismiss(animated: true, completion: nil)
    }
  }
}

extension UIViewController{
  var rootPresentingViewController : UIViewController {
    get{
      var vc = self
      while true {
        if let pvc = vc.presentingViewController {
          vc = pvc
        }
        return vc
      }
    }
  }
    
  var rootModalViewController : UIViewController? {
    get{
      return self.rootPresentingViewController.presentedViewController
    }
  }
  
  var modalStack : [UIViewController] {
     get{
       var stack:[UIViewController] = []
        var vc:UIViewController = self
        while true {
          if let pc = vc.presentingViewController {
            stack.append(vc)
            vc = pc
          }
          else {
            return stack.reversed()
          }
      }
     }
   }
}
