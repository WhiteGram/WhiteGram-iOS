import Foundation
import Display
import UIKit
import AsyncDisplayKit

import LegacyComponents

private final class IconSwitchNodeViewLayer: CALayer {
    override func setNeedsDisplay() {
    }
}

private final class IconSwitchNodeView: TGIconSwitchView {
    override class var layerClass: AnyClass {
        if #available(iOS 26.0, *) {
            return super.layerClass
        } else {
            return IconSwitchNodeViewLayer.self
        }
    }
}

private func configureSwitchAppearance(_ switchView: UISwitch, frameColor: UIColor, contentColor: UIColor, backgroundColor: UIColor?) {
    if #available(iOS 26.0, *) {
        switchView.backgroundColor = .clear
        switchView.tintColor = nil
        switchView.onTintColor = nil
        switchView.thumbTintColor = nil
    } else {
        switchView.backgroundColor = backgroundColor
        switchView.tintColor = frameColor
        switchView.onTintColor = contentColor
    }
}

open class IconSwitchNode: ASDisplayNode {
    public var valueUpdated: ((Bool) -> Void)?
    
    public var frameColor = UIColor(rgb: 0xe0e0e0) {
        didSet {
            if self.isNodeLoaded {
                if #available(iOS 26.0, *) {
                } else {
                    (self.view as! UISwitch).tintColor = self.frameColor
                }
            }
        }
    }
    public var handleColor = UIColor(rgb: 0xffffff) {
        didSet {
            if self.isNodeLoaded {
                //(self.view as! UISwitch).thumbTintColor = self.handleColor
            }
        }
    }
    public var contentColor = UIColor(rgb: 0x42d451) {
        didSet {
            if self.isNodeLoaded {
                if #available(iOS 26.0, *) {
                } else {
                    (self.view as! UISwitch).onTintColor = self.contentColor
                }
            }
        }
    }
    public var positiveContentColor = UIColor(rgb: 0x00ff00) {
        didSet {
            if self.isNodeLoaded {
                (self.view as? IconSwitchNodeView)?.setPositiveContentColor(self.positiveContentColor)
            }
        }
    }
    public var negativeContentColor = UIColor(rgb: 0xff0000) {
        didSet {
            if self.isNodeLoaded {
                (self.view as? IconSwitchNodeView)?.setNegativeContentColor(self.negativeContentColor)
            }
        }
    }
    
    private var _isOn: Bool = false
    public var isOn: Bool {
        get {
            return self._isOn
        } set(value) {
            if (value != self._isOn) {
                self._isOn = value
                if self.isNodeLoaded {
                    (self.view as! UISwitch).setOn(value, animated: false)
                }
            }
        }
    }
    
    private var _isLocked: Bool = false
    
    override public init() {
        super.init()
        
        self.setViewBlock({
            if #available(iOS 26.0, *) {
                return UISwitch()
            } else {
                return IconSwitchNodeView()
            }
        })
    }
    
    override open func didLoad() {
        super.didLoad()
        
        configureSwitchAppearance(self.view as! UISwitch, frameColor: self.frameColor, contentColor: self.contentColor, backgroundColor: self.backgroundColor)
        (self.view as? TGIconSwitchView)?.updateIsLocked(self._isLocked)
        (self.view as? IconSwitchNodeView)?.setNegativeContentColor(self.negativeContentColor)
        (self.view as? IconSwitchNodeView)?.setPositiveContentColor(self.positiveContentColor)
        
        (self.view as! UISwitch).setOn(self._isOn, animated: false)
        
        (self.view as! UISwitch).addTarget(self, action: #selector(switchValueChanged(_:)), for: .valueChanged)
    }
    
    public func setOn(_ value: Bool, animated: Bool) {
        self._isOn = value
        if self.isNodeLoaded {
            (self.view as! UISwitch).setOn(value, animated: animated)
        }
    }
    
    public func updateIsLocked(_ value: Bool) {
        if self._isLocked == value {
            return
        }
        self._isLocked = value
        if self.isNodeLoaded {
            (self.view as? TGIconSwitchView)?.updateIsLocked(value)
        }
    }
    
    override open func calculateSizeThatFits(_ constrainedSize: CGSize) -> CGSize {
        if #available(iOS 26.0, *) {
            let switchView = UISwitch()
            switchView.sizeToFit()
            return switchView.bounds.size
        } else {
            return CGSize(width: 51.0, height: 31.0)
        }
    }
    
    @objc func switchValueChanged(_ view: UISwitch) {
        self.valueUpdated?(view.isOn)
    }
}
