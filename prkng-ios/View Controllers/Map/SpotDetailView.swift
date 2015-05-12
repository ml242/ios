//
//  SpotDetailView.swift
//  prkng-ios
//
//  Created by Cagdas Altinkaya on 26/03/15.
//  Copyright (c) 2015 PRKNG. All rights reserved.
//

import UIKit

class SpotDetailView: UIView {

    var topContainer: UIView
    var titleLabel: UILabel

    var bottomContainer: UIView
    var availableTextLabel: UILabel
    var availableTimeLabel: UILabel
    var scheduleButton: UIButton

    var didSetupSubviews: Bool
    var didSetupConstraints: Bool
    
    var delegate : SpotDetailViewDelegate?
    
    convenience init() {
        self.init(frame: CGRectZero)
    }

    override init(frame: CGRect) {

        topContainer = UIView()
        titleLabel = UILabel()
        bottomContainer = UIView()
        availableTextLabel = UILabel()
        availableTimeLabel = UILabel()
        scheduleButton = ViewFactory.scheduleButton()

        didSetupSubviews = false
        didSetupConstraints = false
        
        super.init(frame: frame)
        
        setupSubviews()
        self.setNeedsUpdateConstraints()
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("NSCoding not supported")
    }
    
//    override func layoutSubviews() {
//        if(!self.didSetupSubviews)
//    }
    
    override func updateConstraints() {
        if(!self.didSetupConstraints) {
            setupConstraints()
        }
        
        super.updateConstraints()
    }

    func setupSubviews() {
        topContainer.backgroundColor = Styles.Colors.stone
        addSubview(topContainer)

        titleLabel.font = Styles.FontFaces.light(27)
        titleLabel.textColor = Styles.Colors.petrol2
        titleLabel.textAlignment = NSTextAlignment.Center
        topContainer.addSubview(titleLabel)

        bottomContainer.backgroundColor = Styles.Colors.red2
        addSubview(bottomContainer)

        availableTextLabel.font = Styles.FontFaces.light(12)
        availableTextLabel.textColor = Styles.Colors.cream1
        availableTextLabel.textAlignment = NSTextAlignment.Center
        availableTextLabel.numberOfLines = 0
        availableTextLabel.text = NSLocalizedString("spot_available_for", comment: "")
        availableTextLabel.textAlignment = NSTextAlignment.Left
        availableTimeLabel.sizeToFit()
        bottomContainer.addSubview(availableTextLabel)

        availableTimeLabel.font = Styles.FontFaces.regular(40)
        availableTimeLabel.textColor = Styles.Colors.cream1
        availableTimeLabel.textAlignment = NSTextAlignment.Center
        availableTimeLabel.text = "00:00" //FIXME
        bottomContainer.addSubview(availableTimeLabel)

        scheduleButton.addTarget(self, action: "scheduleButtonTapped:", forControlEvents: UIControlEvents.TouchUpInside)        
        bottomContainer.addSubview(scheduleButton)

        didSetupSubviews = true
    }

    func setupConstraints() {

        topContainer.snp_makeConstraints {
            (make) -> () in
            make.top.equalTo(self)
            make.left.equalTo(self)
            make.right.equalTo(self)
            make.height.equalTo(90)
        }

        titleLabel.snp_makeConstraints {
            (make) -> () in
            make.left.equalTo(self.topContainer).with.offset(15)
            make.right.equalTo(self.topContainer).with.offset(-15)
            make.bottom.equalTo(self.topContainer).with.offset(-15)
        }

        bottomContainer.snp_makeConstraints {
            (make) -> () in
            make.top.equalTo(self.topContainer.snp_bottom)
            make.left.equalTo(self)
            make.right.equalTo(self)
            make.bottom.equalTo(self)
        }

        availableTextLabel.snp_makeConstraints {
            (make) -> () in
            make.left.equalTo(self.bottomContainer).with.offset(25);
            make.centerY.equalTo(self.bottomContainer)
        }
        
        availableTimeLabel.snp_makeConstraints { (make) -> () in
            make.center.equalTo(self.bottomContainer)
            return
        }
        
        self.scheduleButton.snp_makeConstraints { (make) -> () in
            make.size.equalTo(CGSizeMake(24, 22))
            make.centerY.equalTo(self.bottomContainer)
            make.right.equalTo(self.bottomContainer).with.offset(-25)
        }

        didSetupConstraints = true
    }
    
    
    func scheduleButtonTapped (sender : AnyObject?) {

        if(delegate != nil) {
            delegate!.scheduleButtonTapped()
        }
    }
}



protocol SpotDetailViewDelegate {
    
    func scheduleButtonTapped()
    func checkinButtonTapped()
    
}