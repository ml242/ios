//
//  HereViewController.swift
//  prkng-ios
//
//  Created by Cagdas Altinkaya on 19/04/15.
//  Copyright (c) 2015 PRKNG. All rights reserved.
//

import UIKit

class HereViewController: AbstractViewController, SpotDetailViewDelegate, PRKModalViewControllerDelegate, CLLocationManagerDelegate, UITextFieldDelegate, PRKVerticalGestureRecognizerDelegate, FilterViewControllerDelegate {

    var showFiltersOnAppear: Bool = false
    
    var mapMessageView: MapMessageView
    var canShowMapMessage: Bool = false

    var prkModalViewController: PRKModalDelegatedViewController?
    var firstUseMessageVC: HereFirstUseViewController?
    var detailView: SpotDetailView
    
    var filterVC: FilterViewController
    var carSharingInfoVC: CarSharingInfoViewController?

    var statusBar: UIView
    var modeSelection: PRKModeSlider
    var showModeSelection: Bool = true
    
    var activeDetailObject: DetailObject?
    var forceShowSpotDetails: Bool
    
    let viewHeight = UIScreen.mainScreen().bounds.height - CGFloat(Styles.Sizes.tabbarHeight)

    private var filterButtonImageName: String
    private var filterButtonText: String
    private var verticalRec: PRKVerticalGestureRecognizer
    private var isShowingModal: Bool
    private var timer: NSTimer?
    
    var delegate : HereViewControllerDelegate?

    init() {
        detailView = SpotDetailView()
        filterVC = FilterViewController()
        mapMessageView = MapMessageView()
        statusBar = UIView()
        filterButtonImageName = "icon_filter"
        filterButtonText = ""
        modeSelection = PRKModeSlider(titles: ["garages".localizedString, "on-street".localizedString, "car_sharing".localizedString])
        forceShowSpotDetails = false
        verticalRec = PRKVerticalGestureRecognizer()
        isShowingModal = false
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("NSCoding not supported")
    }
    
    override func loadView() {
        self.view = TouchForwardingView()
        setupViews()
        setupConstraints()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        modeSelection.setValue(Double(modeSelection.selectedIndex), animated: true)
        
        if (Settings.firstMapUse()) {
            Settings.setFirstMapUsePassed(true)
            NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: Selector("showFirstUseMessage"), userInfo: nil, repeats: false)
        } else {
            if showFiltersOnAppear {
                self.filterVC.showFilters(resettingTimeFilterValue: true)
                self.filterVC.makeActive()
                showFiltersOnAppear = false
            } else {
                self.filterVC.hideFilters(completely: false)
                self.delegate?.updateMapAnnotations(nil)
            }
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.screenName = "Here - General View"
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        NSLog("HereViewController disappeared")
        hideModalView()
        hideSpotDetails()
    }
    
    func setupViews () {

        verticalRec = PRKVerticalGestureRecognizer(view: detailView, superViewOfView: self.view)
        verticalRec.delegate = self
        
        detailView.delegate = self
        view.addSubview(detailView)
        
        self.filterVC.delegate = self
        self.view.addSubview(self.filterVC.view)
        self.filterVC.willMoveToParentViewController(self)
        
        modeSelection.addTarget(self, action: "modeSelectionValueChanged", forControlEvents: UIControlEvents.ValueChanged)
        view.addSubview(modeSelection)
        
        statusBar.backgroundColor = Styles.Colors.statusBar
        view.addSubview(statusBar)
        
        let mapMessageTapRec = UITapGestureRecognizer(target: self, action: "didTapMapMessage")
        mapMessageView.addGestureRecognizer(mapMessageTapRec)
        view.addSubview(mapMessageView)
    
    }
    
    func setupConstraints() {
        
        mapMessageView.snp_makeConstraints { (make) -> () in
            make.left.equalTo(self.view)
            make.right.equalTo(self.view)
            make.bottom.equalTo(self.view.snp_top)
        }

        statusBar.snp_makeConstraints { (make) -> () in
            make.top.equalTo(self.view)
            make.left.equalTo(self.view)
            make.right.equalTo(self.view)
            make.height.equalTo(20)
        }
        
        detailView.snp_makeConstraints { (make) -> () in
            make.bottom.equalTo(self.view).offset(180)
            make.left.equalTo(self.view)
            make.right.equalTo(self.view)
            make.height.equalTo(Styles.Sizes.spotDetailViewHeight)
        }

        self.filterVC.view.snp_makeConstraints { (make) -> () in
            make.top.equalTo(self.mapMessageView.snp_bottom)
            make.left.equalTo(self.view)
            make.right.equalTo(self.view)
            make.bottom.equalTo(self.view)
        }
        
        modeSelection.snp_makeConstraints { (make) -> () in
            make.height.equalTo(60)
            make.left.equalTo(self.view)
            make.right.equalTo(self.view)
            make.bottom.equalTo(self.view)
        }
        
    }
    
    
    func showFirstUseMessage() {
        
        
        firstUseMessageVC = HereFirstUseViewController()
        
        self.addChildViewController(firstUseMessageVC!)
        self.view.addSubview(firstUseMessageVC!.view)
        firstUseMessageVC!.didMoveToParentViewController(self)
        
        firstUseMessageVC!.view.snp_makeConstraints(closure: { (make) -> () in
            make.edges.equalTo(self.view)
        })
        
        let tap = UITapGestureRecognizer(target: self, action: "dismissFirstUseMessage")
        firstUseMessageVC!.view.addGestureRecognizer(tap)
        
        firstUseMessageVC!.view.alpha = 0.0
        
        UIView.animateWithDuration(0.2, animations: { () -> Void in
            self.firstUseMessageVC!.view.alpha = 1.0
        })
        
    }
    
    func dismissFirstUseMessage() {
        
        if let firstUse = self.firstUseMessageVC {
            
            UIView.animateWithDuration(0.2, animations: { () -> Void in
                firstUse.view.alpha = 0.0
                }, completion: { (finished) -> Void in
                    firstUse.removeFromParentViewController()
                    firstUse.view.removeFromSuperview()
                    firstUse.didMoveToParentViewController(nil)
                    self.firstUseMessageVC = nil
            })
            
        }
        
        
    }
    
    func topContainerTapped() {

        if activeDetailObject?.compact == true {
            return
        }

        if let lot = activeDetailObject as? Lot {
            if lot.isParkingPanda {
                ParkingPandaOperations.login(username: nil, password: nil, completion: {(user, error) -> Void in
                    if user != nil {
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            let lotBookingVC = LotBookingViewController(lot: lot, user: user!, view: self.view)
                            self.showModalView(self.activeDetailObject, modalVC: lotBookingVC)
                        })
                    } else {
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            let ppIntroVC = PPIntroViewController()
                            ppIntroVC.presentWithVC(self)
                        })
                    }
                })
            } else {
                showModalView(activeDetailObject, modalVC: LotViewController(lot: lot, view: self.view))
            }
        } else {
            checkin()
        }
    }
    
    func bottomContainerTapped() {
        
        if activeDetailObject?.compact == true {
            return
        }

        if activeDetailObject != nil {
            showModalView(activeDetailObject, modalVC: nil)
        }
    }
    
    
    //MARK: PRKVerticalGestureRecognizerDelegate methods
    
    func shouldIgnoreSwipe(beginTap: CGPoint) -> Bool {
        if activeDetailObject?.compact == true {
            return true
        }
        if let lot = activeDetailObject as? Lot where lot.isParkingPanda {
            return true
        }
        return false
    }
    
    func swipeDidBegin() {
        if activeDetailObject != nil {
            setupModalView(activeDetailObject, modalVC: nil)
        }

    }
    
    func swipeInProgress(yDistanceFromBeginTap: CGFloat) {
        adjustSpotDetailsWithDistanceFromBottom(-yDistanceFromBeginTap, animated: false)
        
        //parallax for the top image/street view!
        let topViewOffset = (yDistanceFromBeginTap / prkModalViewController!.FULL_HEIGHT) * prkModalViewController!.TOP_PARALLAX_HEIGHT
        prkModalViewController?.topParallaxView?.snp_updateConstraints { (make) -> () in
            make.top.equalTo(self.prkModalViewController!.view).offset(prkModalViewController!.TOP_PARALLAX_HEIGHT - topViewOffset)
        }
        prkModalViewController?.topParallaxView?.layoutIfNeeded()

    }
    
    func swipeDidEndUp() {
        animateModalView()
    }
    
    func swipeDidEndDown() {
        showSpotDetails()
    }
    
    // MARK: Schedule/Agenda/Modal methods
    func showModalView(detailObject : DetailObject?, modalVC: PRKModalDelegatedViewController?) {
        setupModalView(detailObject, modalVC: modalVC)
        animateModalView()
    }
    
    func setupModalView(detailObject : DetailObject?, modalVC: PRKModalDelegatedViewController?) {
        
        //this prevents the "double modal view" bug that we sometimes see
        self.prkModalViewController?.view.removeFromSuperview()
        self.prkModalViewController?.willMoveToParentViewController(nil)
        self.prkModalViewController?.removeFromParentViewController()
        self.prkModalViewController = nil
        
        if let spot = detailObject as? ParkingSpot {
            self.prkModalViewController = modalVC ?? PRKModalViewController(spot: spot, view: self.view)
            self.view.addSubview(self.prkModalViewController!.view)
            self.prkModalViewController!.willMoveToParentViewController(self)
            self.prkModalViewController!.delegate = self
            
            self.prkModalViewController!.view.snp_makeConstraints(closure: { (make) -> () in
                make.top.equalTo(self.detailView.snp_bottom)
                make.size.equalTo(self.view)
                make.left.equalTo(self.view)
                make.right.equalTo(self.view)
            })
            
            self.prkModalViewController!.view.layoutIfNeeded()
            
        } else if let lot = detailObject as? Lot {
            self.prkModalViewController = modalVC ?? LotViewController(lot: lot, view: self.view)
            self.view.addSubview(self.prkModalViewController!.view)
            self.prkModalViewController!.willMoveToParentViewController(self)
            self.prkModalViewController!.delegate = self
            
            self.prkModalViewController!.view.snp_makeConstraints(closure: { (make) -> () in
                make.top.equalTo(self.detailView.snp_bottom)
                make.size.equalTo(self.view)
                make.left.equalTo(self.view)
                make.right.equalTo(self.view)
            })
            
            self.prkModalViewController!.view.layoutIfNeeded()
            
        }
    }
    
    func animateModalView() {
        
        adjustSpotDetailsWithDistanceFromBottom(-viewHeight, animated: true)
        isShowingModal = true
        
        //fix parallax effect just in case
        prkModalViewController?.topParallaxView?.snp_updateConstraints { (make) -> () in
            make.top.equalTo(self.prkModalViewController!.view)
        }
        UIView.animateWithDuration(0.2,
            animations: { () -> Void in
                self.prkModalViewController?.topParallaxView?.updateConstraints()
            },
            completion: nil
        )

    }
    
    
    func hideModalView () {
        
        if(self.prkModalViewController == nil) {
            return
        }
        
        detailView.snp_updateConstraints {
            (make) -> () in
            make.bottom.equalTo(self.view).offset(0)
        }
        
        self.prkModalViewController?.view.snp_updateConstraints(closure: { (make) -> () in
            make.top.equalTo(self.detailView.snp_bottom).offset(0)
        })
        
        UIView.animateWithDuration(0.2, animations: { () -> Void in
            self.detailView.alpha = 1
            self.view.layoutIfNeeded()
            }, completion: { (Bool) -> Void in
                
                self.prkModalViewController!.view.removeFromSuperview()
                self.prkModalViewController!.willMoveToParentViewController(nil)
                self.prkModalViewController!.removeFromParentViewController()
                self.prkModalViewController = nil
                self.isShowingModal = false
        })
        
    }
    
    func shouldAdjustTopConstraintWithOffset(distanceFromTop: CGFloat, animated: Bool) {
        let height = UIScreen.mainScreen().bounds.height - CGFloat(Styles.Sizes.tabbarHeight)
        let distanceFromBottom = height - distanceFromTop
        adjustSpotDetailsWithDistanceFromBottom(-distanceFromBottom, animated: animated)

    }
    
    func checkin() {
        
        if let activeSpot = activeDetailObject as? ParkingSpot {
            
            //OLD RULE FOR WHETHER WE COULD/COULDN'T CHECK-IN:
            //            let checkedInSpotID = Settings.checkedInSpotId()
            //            if (activeDetailObject != nil && checkedInSpotID != nil) {
            //                checkinButton.enabled = checkedInSpotID != activeDetailObject?.identifier
            //            } else {
            //                checkinButton.enabled = true
            //            }
            
            
            SVProgressHUD.setBackgroundColor(UIColor.clearColor())
            SVProgressHUD.show()
            
            Settings.checkOut()
            
            SpotOperations.checkin(activeSpot.identifier, completion: { (completed) -> Void in
                
                Settings.saveCheckInData(activeSpot, time: NSDate())
                
                if (Settings.notificationTime() > 0) {
                    Settings.cancelScheduledNotifications()
                    if activeSpot.currentlyActiveRuleType != .Paid && activeSpot.currentlyActiveRuleType != .PaidTimeMax && !activeSpot.isAlwaysAuthorized() {
                        Settings.scheduleNotification(NSDate(timeIntervalSinceNow: activeSpot.availableTimeInterval() - NSTimeInterval(Settings.notificationTime() * 60)))
                    }
                }
                
                Settings.scheduleNotification(activeSpot)
                
                SVProgressHUD.dismiss()
                self.delegate?.loadMyCarTab()
                
                if Settings.shouldPromptUserToRateApp() {
                    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
                    let dialogVC = PRKDialogViewController(titleIconName: "icon_review", headerImageName: "review_header", titleText: "review_title_text".localizedString, subTitleText: "review_message_text".localizedString, messageText: "", buttonLabels: ["review_rate_us".localizedString, "review_feedback".localizedString, "dismiss".localizedString])
                    dialogVC.delegate = appDelegate
                    dialogVC.showOnViewController(appDelegate.window!.rootViewController!)
                }
                
                
            })
            
        }
        
    }
    
    //start here
    func updateDetailsTime() {
        
        if self.activeDetailObject != nil {
            
            detailView.leftBottomLabel.attributedText = self.activeDetailObject!.bottomLeftPrimaryText
            detailView.rightTopLabel.text = self.activeDetailObject!.bottomRightTitleText
            detailView.rightBottomLabel.attributedText = self.activeDetailObject!.bottomRightPrimaryText
        }
    }
    
    func updateDetails(detailObject: DetailObject?) {
        
        self.activeDetailObject = detailObject
        
        if detailObject != nil {
            
            forceShowSpotDetails = true
            
            if (activeDetailObject != nil) {
                print("selected spot/lot : " + activeDetailObject!.identifier)
            }
            
            detailView.checkinImageView.image = UIImage(named: detailObject!.headerIconName)
            detailView.checkinImageLabel.text = detailObject!.headerIconSubtitle
            detailView.bottomLeftContainer.snp_updateConstraints(closure: { (make) -> () in
                make.width.equalTo(detailObject!.showsBottomLeftContainer ? detailObject!.bottomLeftWidth : 0)
            })
            if let iconName = detailObject!.bottomRightIconName {
                if let colorForIcon = detailObject?.bottomRightIconColor {
                    let image = UIImage(named: iconName)
                    detailView.scheduleImageView.image = image?.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
                    detailView.scheduleImageView.tintColor = colorForIcon
                } else {
                    detailView.scheduleImageView.image = UIImage(named:iconName)
                }
            } else {
                detailView.scheduleImageView.image = UIImage()
            }
            if let iconName = detailObject!.bottomLeftIconName {
                detailView.bottomLeftImageView.image = UIImage(named:iconName)
            } else {
                detailView.bottomLeftImageView.image = UIImage()
            }
            detailView.leftTopLabel.text = detailObject!.bottomLeftTitleText
                

            detailView.topText = activeDetailObject!.headerText
            updateDetailsTime()
            if detailObject!.doesHeaderIconWiggle {
                detailView.checkinImageView.layer.wigglewigglewiggle()
            } else {
                detailView.checkinImageView.layer.removeAllAnimations()
            }

            hideModeSelection()
            
            showSpotDetails()
            
            self.timer?.invalidate()
            self.timer = NSTimer.scheduledTimerWithTimeInterval(60, target: self, selector: "updateDetailsTime", userInfo: nil, repeats: true)
            
        } else {
            self.activeDetailObject = nil
            self.timer?.invalidate()
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(10 * NSEC_PER_MSEC)), dispatch_get_main_queue(), {
                self.hideSpotDetails()
            })
        }
        
    }
    
    //end here
    
    private func showSpotDetails() {
        adjustSpotDetailsWithDistanceFromBottom(0, animated: true)
    }
    
    private func hideSpotDetails() {
        adjustSpotDetailsWithDistanceFromBottom(180, animated: true)
    }

    private func adjustSpotDetailsWithDistanceFromBottom(distance: CGFloat, animated: Bool) {
        
        let fullLayout = distance == 0 || distance == 180 || distance == viewHeight || distance == -viewHeight
        
        let alpha = abs(distance) / self.viewHeight
        
        let parallaxOffset = fullLayout ? 0 : alpha * CGFloat(Styles.Sizes.spotDetailViewHeight)
        
        if isShowingModal {
            
            detailView.snp_updateConstraints {
                (make) -> () in
                make.bottom.equalTo(self.view).offset(distance + parallaxOffset)
            }

            self.prkModalViewController?.view.snp_updateConstraints(closure: { (make) -> () in
                make.top.equalTo(self.detailView.snp_bottom).offset(-parallaxOffset)
            })
        } else {
            
            detailView.snp_updateConstraints {
                (make) -> () in
                make.bottom.equalTo(self.view).offset(distance)
            }

            self.prkModalViewController?.view.snp_updateConstraints(closure: { (make) -> () in
                make.top.equalTo(self.detailView.snp_bottom).offset(-2*parallaxOffset)
            })
        }

        let changeView = { () -> () in
            if fullLayout {
                self.view.layoutIfNeeded()
            } else {
                self.view.updateConstraints()
            }
            if self.isShowingModal {
                self.detailView.alpha = (self.viewHeight/2 - abs(distance)) / (self.viewHeight/2)
            } else {
                self.detailView.alpha = (self.viewHeight/3 - abs(distance)) / (self.viewHeight/3)
            }
        }
        
        if animated {
            UIView.animateWithDuration(0.2,
                animations: { () -> Void in
                    self.showModeSelection(false)
                    changeView()
                },
                completion: { (completed: Bool) -> Void in
                    self.showModeSelection(false)
            })
        } else {
            changeView()
        }

    }
    
    func isSpotDetailsHidden() -> Bool {
        //we know if the view is hidden based on the bottom offset, as can be seen in the two methods above
        //make.bottom.equalTo(self.view).offset(180) is to hide it and
        //make.bottom.equalTo(self.view).offset(0) is to show it

        for constraint: LayoutConstraint in detailView.snp_installedLayoutConstraints {
            if constraint.firstItem.isEqual(self.detailView)
                && (constraint.secondItem != nil && constraint.secondItem!.isEqual(self.view))
                && Float(constraint.constant) == 180 {
                    return true
            }
        }

        return false
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
    }
    
    
    // MARK: Helper Methods
    
    func hideModeSelection() {
        modeSelection.hidden = true
    }
    
    func showModeSelection(forceShow: Bool) {
        
        //only shows the button if the searchField is 'hidden'
        if !forceShow
            && !self.isSpotDetailsHidden() {
                    return
        }

        modeSelection.hidden = false
    }
    
    func modeSelectionValueChanged() {
        
        var mapMode = MapMode.StreetParking
        let tracker = GAI.sharedInstance().defaultTracker
        
        switch(self.modeSelection.selectedIndex) {
        case 0:
            //oh em gee you wanna see garages!
            mapMode = .Garage
            self.screenName = "Here - General View - ParkingLot"
            tracker.send(GAIDictionaryBuilder.createEventWithCategory("Here - General View", action: "Mode Slider Value Changed", label: "Parking Lot", value: nil).build() as [NSObject: AnyObject])
            filterVC.showingCarSharingTabBar = false
            Settings.setShouldFilterForCarSharing(mapMode == .CarSharing)
            self.delegate?.didSelectMapMode(mapMode)
            self.filterVC.hideFilters(completely: false, resettingTimeFilterValue: true)
            filterVC.shouldShowTimeFilter = false
            break
        case 1:
            //oh. em. gee. you wanna see street parking!
            mapMode = .StreetParking
            self.screenName = "Here - General View - On-Street"
            tracker.send(GAIDictionaryBuilder.createEventWithCategory("Here - General View", action: "Mode Slider Value Changed", label: "On Street", value: nil).build() as [NSObject: AnyObject])
            filterVC.showingCarSharingTabBar = false
            Settings.setShouldFilterForCarSharing(mapMode == .CarSharing)
            self.delegate?.didSelectMapMode(mapMode)
            self.filterVC.hideFilters(completely: false, resettingTimeFilterValue: true)
            filterVC.shouldShowTimeFilter = true
            break
        case 2:
            //oh. em. geeeeeeee you wanna see car sharing spots!
            mapMode = .CarSharing
            if Settings.firstCarSharingUse() {
                Settings.setFirstCarSharingUsePassed(true)
                showCarSharingInfo()
            }
            self.screenName = "Here - General View - CarSharing"
            tracker.send(GAIDictionaryBuilder.createEventWithCategory("Here - General View", action: "Mode Slider Value Changed", label: "CarSharing", value: nil).build() as [NSObject: AnyObject])
            filterVC.showingCarSharingTabBar = true
            filterVC.shouldShowTimeFilter = false
            Settings.setShouldFilterForCarSharing(mapMode == .CarSharing)
            self.delegate?.didSelectMapMode(mapMode)
            self.filterVC.hideFilters(completely: false, resettingTimeFilterValue: true)
            break
        default:break
        }
        
        AnalyticsOperations.sendMapModeChange(mapMode)

    }
    
    // MARK: TimeFilterViewDelegate
    
    func filterValueWasChanged(hours hours:Float?, selectedLabelText: String, permit: Bool, fromReset: Bool) {
        self.delegate?.updateMapAnnotations(nil)
//        filterButtonText = selectedLabelText
//        filterButton.setLabelText(selectedLabelText)
//        hideFilters(alsoHideFilterButton: false)
    }
    
    func filterLabelUpdate(labelText: String) {
//        filterButtonText = labelText
//        filterButton.setLabelText(labelText)
    }
    
    func didTapCarSharing() {
        self.delegate?.loadSettingsTab()
    }
    
    func didTapTrackUserButton() {
        self.delegate?.didTapTrackUserButton()
    }
    
    func didTapMapMessage() {
        if (mapMessageView.mapMessageLabel.text ?? "") == "map_message_too_zoomed_out".localizedString {
            self.delegate?.setDefaultMapZoom()
        } else if (mapMessageView.mapMessageLabel.text ?? "") == "map_message_no_carsharing".localizedString {
            self.delegate?.loadSettingsTab()
        } else if (mapMessageView.mapMessageLabel.text ?? "") == "map_message_no_parking".localizedString {
            self.delegate?.updateMapAnnotations(1)
        } else if (mapMessageView.mapMessageLabel.text ?? "") == "map_message_no_cars".localizedString {
            self.delegate?.updateMapAnnotations(1)
        }
    }

    func didChangeCarSharingMode(mode: CarSharingMode) {
        self.delegate?.setDefaultMapZoom()
        //zooming should automatically generate an update, so we don't have to do it manually
        self.delegate?.updateMapAnnotations(1)
    }
    
    // MARK: Car sharing popup
    
    func showCarSharingInfo() {
        
        carSharingInfoVC = CarSharingInfoViewController()
        
        self.addChildViewController(carSharingInfoVC!)
        self.view.addSubview(carSharingInfoVC!.view)
        carSharingInfoVC!.didMoveToParentViewController(self)
        
        carSharingInfoVC!.view.snp_makeConstraints(closure: { (make) -> () in
            make.edges.equalTo(self.view)
        })
        
        let tap = UITapGestureRecognizer(target: self, action: "dismissCarSharingInfo")
        carSharingInfoVC!.view.addGestureRecognizer(tap)
        
        carSharingInfoVC!.view.alpha = 0.0
        
        UIView.animateWithDuration(0.2, animations: { () -> Void in
            self.carSharingInfoVC!.view.alpha = 1.0
        })
        
    }
    
    func dismissCarSharingInfo() {
        
        if let carShareingInfo = self.carSharingInfoVC {
            
            UIView.animateWithDuration(0.2, animations: { () -> Void in
                carShareingInfo.view.alpha = 0.0
                }, completion: { (finished) -> Void in
                    carShareingInfo.removeFromParentViewController()
                    carShareingInfo.view.removeFromSuperview()
                    carShareingInfo.didMoveToParentViewController(nil)
                    self.carSharingInfoVC = nil
            })
            
        }
        
        
    }
    

}


protocol HereViewControllerDelegate {
    func loadMyCarTab()
    func loadSettingsTab()
    func updateMapAnnotations(returnNearestAnnotations: Int?)
    func cityDidChange(fromCity fromCity: City, toCity: City)
    func didSelectMapMode(mapMode: MapMode)
    func setDefaultMapZoom()
    func didTapTrackUserButton()
}
