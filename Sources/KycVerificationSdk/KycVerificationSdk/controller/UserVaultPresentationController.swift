//
//  UserVaultPresentationController.swift
//  KycVerificationSdk
//
//  Created by Renu Bisht on 03/10/24.
//

import UIKit

class UserVaultPresentationController: UIPresentationController {
    
    override var frameOfPresentedViewInContainerView: CGRect {
        guard let containerView = containerView else { return .zero }
        
        let height = containerView.bounds.height * 0.7  // 80% of the screen height
        let width = containerView.bounds.width
        return CGRect(x: 0, y: containerView.bounds.height - height, width: width, height: height)
    }
    
    override func presentationTransitionWillBegin() {
        super.presentationTransitionWillBegin()
        
        
        presentedView?.layer.cornerRadius = 16
        presentedView?.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        presentedView?.clipsToBounds = true
        
        
        if let containerView = containerView {
            let dimmingView = UIView(frame: containerView.bounds)
            dimmingView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
            dimmingView.alpha = 0
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleBackgroundTap))
                dimmingView.addGestureRecognizer(tapGesture)
            containerView.insertSubview(dimmingView, at: 0)
            
            presentedViewController.transitionCoordinator?.animate(alongsideTransition: { _ in
                dimmingView.alpha = 1
            }, completion: nil)
        }
    }
    
    override func dismissalTransitionWillBegin() {
        super.dismissalTransitionWillBegin()
        
        
        containerView?.subviews.first?.alpha = 1
        presentedViewController.transitionCoordinator?.animate(alongsideTransition: { _ in
            self.containerView?.subviews.first?.alpha = 0
        }, completion: { _ in
            self.containerView?.subviews.first?.removeFromSuperview()
        })
    }
    @objc private func handleBackgroundTap() {
         presentedViewController.dismiss(animated: true, completion: nil)
         if let vaultVC = presentedViewController as? UserVaultViewController {
             vaultVC.notifyBackgroundTap()
         }
     }
}
