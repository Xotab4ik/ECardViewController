//
//  ViewController.swift
//  PlasticCardView
//
//  Created by Алексей Милахин on 19.09.17.
//  Copyright © 2017 Alexey Milakhin. All rights reserved.
//

import UIKit

extension UIViewController: UIPopoverPresentationControllerDelegate {
    public func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
    
    open func createPlasticCard() -> EPlacticCardController {
        let popover = EPlacticCardController()
        popover.modalPresentationStyle = UIModalPresentationStyle.popover
        popover.popoverPresentationController?.delegate = self
        popover.popoverPresentationController?.sourceView = self.view
        popover.popoverPresentationController?.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
        let size: CGSize
        if self.view.frame.width > 375 {
            size = CGSize(width: 345, height: 287)
        } else {
            size = CGSize(width: self.view.frame.size.width-30, height: 287)
        }
        popover.preferredContentSize = size
        popover.popoverPresentationController?.permittedArrowDirections = .init(rawValue: 0)
        popover.popoverPresentationController?.backgroundColor = .clear
        return popover
    }
}

@objc public protocol EPlasticCardControllerDelegate: UIPopoverPresentationControllerDelegate {
    @objc optional func plasticCardDidClosed()
    @objc func plasticCardDoneAction(_ cardInfo: CardInfo)
}

open class EPlacticCardController: UIViewController {

    @IBOutlet weak var cardView: UIView!
    @IBOutlet private weak var expiresField: UITextField!
    @IBOutlet private weak var cardHolderField: UITextField!
    @IBOutlet private weak var cardNumberField: UITextField!
    @IBOutlet private weak var codeField: UITextField!
    @IBOutlet private weak var brandImageView: UIImageView!
    @IBOutlet private weak var bankLogoImageView: UIImageView!
    
    open var isNeedCardHolder: Bool = true
    open var delegate: EPlasticCardControllerDelegate?
    
    private var isDoneTapped: Bool = false
    
    private var issuer: Bank? {
        didSet {
            if issuer?.name != oldValue?.name && issuer != nil {
                setGradientBackground()
                setTextsColors()
                bankLogoImageView.image = UIImage(named: (issuer?.logoPng)!, in: Bundle(for: type(of: self)), compatibleWith: nil)
            }
            if issuer == nil {
                bankLogoImageView.image = UIImage()
            }
        }
    }
    
    private var brand: Brand? {
        didSet {
            if brand != nil {
                if issuer != nil {
                    let name = brand!.alias + "-" + issuer!.logoStyle
                    brandImageView.image = UIImage(named: name, in: Bundle(for: type(of: self)), compatibleWith: nil)
                } else {
                    brandImageView.image = UIImage(named: (brand?.image)!, in: Bundle(for: type(of: self)), compatibleWith: nil)
                }
                codeField.placeholder = brand?.codeName
            } else {
                brandImageView.image = UIImage()
            }
        }
    }
    
    public init() {
        let bundle = Bundle(for: type(of: self))
        super.init(nibName: "View", bundle: bundle)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setGradientBackground() {
        guard let issuer = issuer else { return }
        
        let gradientLayer = CAGradientLayer()
        var colors: [Any] = []
        for hexStringColor in issuer.backgroundColors {
            let color = UIColor(hex: hexStringColor).cgColor
            colors.append(color)
        }
        gradientLayer.colors = colors
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1.0, y: 1.0)
        gradientLayer.frame = cardView.frame
        
        if let gradient = cardView.layer.sublayers?.first as? CAGradientLayer {
            gradient.removeFromSuperlayer()
        }
        cardView.layer.insertSublayer(gradientLayer, at: 0)
    }
    
    override open func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if let delegate = delegate, isDoneTapped == false {
            if delegate.plasticCardDidClosed != nil {
                delegate.plasticCardDidClosed!()
            }
        }
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        if UIScreen.main.bounds.size.width < 370 {
            cardHolderField.font = UIFont(name: "Halter", size: 15)
            cardNumberField.font = UIFont(name: "Halter", size: 15)
            codeField.font = UIFont(name: "Halter", size: 15)
            expiresField.font = UIFont(name: "Halter", size: 15)
        }
        cardHolderField.isHidden = !isNeedCardHolder
    }
    
    private func setTextsColors() {
        codeField.textColor = UIColor(hex: (issuer?.text)!)
        codeField.text = codeField.text
        cardNumberField.textColor = UIColor(hex: (issuer?.text)!)
        cardNumberField.text = cardNumberField.text
        expiresField.textColor = UIColor(hex: (issuer?.text)!)
        expiresField.text = expiresField.text
        cardHolderField.textColor = UIColor(hex: (issuer?.text)!)
        cardHolderField.text = cardHolderField.text
    }
    
    @IBAction private func cardNumberDidChange(_ sender: UITextField) {
        CardInfo.current.cardNumber = sender.text?.replacingOccurrences(of: " ", with: "")

        issuer = CardInfo.current.getIssuer()
        brand = CardInfo.current.getBrand()
    }

    @IBAction func codeFieldDidChaged(_ sender: UITextField) {
        CardInfo.current.cvvCode = sender.text
    }
    
    @IBAction func doneAction(_ sender: Any) {
        if let delegate = delegate {
            delegate.plasticCardDoneAction(CardInfo.current)
            isDoneTapped = true
            self.dismiss(animated: true)
        }
    }
    
    @IBAction func closeAction(_ sender: Any) {
        isDoneTapped = false
        self.dismiss(animated: true)
    }
    
}

extension EPlacticCardController: UITextFieldDelegate {
    
    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField.isEqual(cardNumberField) {
            if Int(string) == nil, string != "" {
                return false
            }
            if let brand = brand, string != "" {
                var text = textField.text!.replacingOccurrences(of: " ", with: "")
                for (i,gap) in brand.gaps.enumerated() {
                    if text.count >= gap+i {
                        text.insert(" ", at: String.Index(encodedOffset: gap+i))
                        textField.text = text
                    }
                }
            }
        }
        else if textField.isEqual(expiresField) {
            if Int(string) == nil && string != "" {
                return false
            }
            var text = textField.text!.appending(string).replacingOccurrences(of: "/", with: "")
            if text.count >= 2 && string != "" {
                if text.count == 5 {
                    return false
                }
                text.insert("/", at: String.Index(encodedOffset: 2))
                textField.text = text
                let separated = text.split(separator: "/")
                if let month = separated.first, let year = separated.last {
                    if let monthInt = Int(month), let yearInt = Int(year), let yearComponent = Calendar.current.dateComponents([.year], from: Date()).year {
                        let currentYear = yearComponent%1000
                        if monthInt == 0 || monthInt > 12 || yearInt > currentYear+20 || yearInt < currentYear {
                            expiresField.textColor = .red
                        } else {
                            expiresField.textColor = UIColor(hex: (issuer?.text)!)
                        }
                        expiresField.text = expiresField.text
                        
                    }
                    var expires = Expires()
                    expires.month = String(month)
                    expires.year = String(year)
                    CardInfo.current.expires = expires
                }
                CardInfo.current.expiresStr = text
                return false
            }
        }
        else if textField.isEqual(cardHolderField) && string != "" {
            let uppercasedString = string.uppercased()
            let regex = NSPredicate(format: "SELF MATCHES %@", "[A-Za-z ]+")
            let regexResult = regex.evaluate(with: uppercasedString)
            if regexResult {
                let text = textField.text!.appending(uppercasedString)
                textField.text = text
                CardInfo.current.cardHolder = text
                return false
            } else {
                return false
            }
        }
        else if textField.isEqual(codeField) {
            if let brand = brand {
                if textField.text!.count >= brand.codeLength {
                    return false
                }
            }
            if Int(string) == nil && string != "" {
                return false
            }
        }
        return true
    }
}
