//
//  CalendarView.swift
//  Calendar
//
//  Created by Lancy on 02/06/15.
//  Copyright (c) 2015 Lancy. All rights reserved.
//

import UIKit

// 12 months - base date - 12 months
let kMonthRange = 12

@objc protocol CalendarViewDelegate: class {
    func didSelectDate(date: NSDate)
    optional func didChangeSelectedDates(selectedDates: [NSDate])
}

class CalendarView: UIView, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIScrollViewDelegate, MonthCollectionCellDelegate {
    
    var monthYearLabel: UILabel!
    var collectionView: UICollectionView!
    var nextButton: UIButton!
    var previousButton: UIButton!
    weak var delegate: CalendarViewDelegate?

    private var collectionData = [CalendarLogic]()
    var baseDate: NSDate? {
        didSet {
            collectionData = [CalendarLogic]()
            if baseDate != nil {
                var dateIter1 = baseDate!, dateIter2 = baseDate!
                var set = Set<CalendarLogic>()
                set.insert(CalendarLogic(date: baseDate!))
                // advance one year
                for var i = 0; i < kMonthRange; i++ {
                    dateIter1 = dateIter1.firstDayOfFollowingMonth
                    dateIter2 = dateIter2.firstDayOfPreviousMonth
                    
                    set.insert(CalendarLogic(date: dateIter1))
                    set.insert(CalendarLogic(date: dateIter2))
                }
                collectionData = Array(set).sort(<)
            }
            
            updateHeader()
            collectionView.reloadData()
        }
    }
    
    var selectedDates: [NSDate] = [NSDate]() {
        didSet {
            collectionView.reloadData()
            dispatch_async(dispatch_get_main_queue()){
                self.moveToSelectedDate(false)
                if self.delegate != nil && self.selectedDates.count > 0 {
                    self.delegate!.didSelectDate(self.selectedDates.last!)
                    self.delegate!.didChangeSelectedDates?(self.selectedDates)
                }
            }
        }
    }

    var allowMultipleSelections = false
    
    init() {
        super.init(frame: CGRect(x: 0, y: 0, width: 315, height: 268))
        
        self.backgroundColor = UIColor.redColor()
        
        let flow = UICollectionViewFlowLayout()
        flow.itemSize = CGSize(width: 315, height: 224)
        flow.scrollDirection = .Horizontal
        flow.sectionInset = UIEdgeInsetsZero
        flow.minimumInteritemSpacing = 0
        flow.minimumLineSpacing = 0
        
        collectionView = UICollectionView(frame: CGRect(x: 0, y: 44, width: 315, height: 224), collectionViewLayout: flow)
        collectionView.pagingEnabled = true
        collectionView.bounces = true
        
        monthYearLabel = UILabel()
        nextButton = UIButton()
        previousButton = UIButton()
        
        nextButton.setTitle("Next", forState: .Normal)
        previousButton.setTitle("Prev", forState: .Normal)
        monthYearLabel.text = "Label"
        
        nextButton.addTarget(self, action: Selector("advanceToFollowingMonth:"), forControlEvents: .TouchUpInside)
        previousButton.addTarget(self, action: Selector("retreatToPreviousMonth:"), forControlEvents: .TouchUpInside)

        nextButton.frame = CGRect(x: 255, y: 0, width: 60, height: 44)
        previousButton.frame = CGRect(x: 0, y: 0, width: 60, height: 44)

        monthYearLabel.frame = CGRect(x: 60, y: 0, width: 195, height: 44)
        
        let nib = UINib(nibName: "MonthCollectionCell", bundle: nil)
        self.collectionView.registerNib(nib, forCellWithReuseIdentifier: "MonthCollectionCell")
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        addSubview(collectionView)
        addSubview(nextButton)
        addSubview(previousButton)
        addSubview(monthYearLabel)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    class func instance(baseDate: NSDate, selectedDate: NSDate) -> CalendarView {
        return instance(baseDate, selectedDates: [selectedDate])
    }
    
    class func instance(baseDate: NSDate, selectedDates: [NSDate]) -> CalendarView {
        let calendarView = CalendarView()
        //NSBundle.mainBundle().loadNibNamed("CalendarView", owner: nil, options: nil).first as! CalendarView
         selectedDates.forEach({ (date) -> () in
            calendarView.selectedDates.append(date.startOfDay)
        })
        if calendarView.selectedDates.count == 0 {
            calendarView.selectedDates.append(NSDate().startOfDay)
        }
        calendarView.baseDate = baseDate
        return calendarView
    }


    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return collectionData.count
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("MonthCollectionCell", forIndexPath: indexPath) as! MonthCollectionCell
        
        cell.monthCellDelgate = self
        
        cell.logic = collectionData[indexPath.item]
        cell.selectedDates.removeAll()
        for date in selectedDates {
            if cell.logic!.isVisible(date) {
                cell.selectedDates.append(Date(date: date))
            }
        }
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return collectionView.frame.size
    }
    
    func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if (!decelerate) {
            updateHeader()
        }
    }
    
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        updateHeader()
    }
    
    func updateHeader() {
        let pageNumber = Int(collectionView.contentOffset.x / collectionView.frame.width)
        updateHeader(pageNumber)
    }
    
    func updateHeader(pageNumber: Int) {
        if collectionData.count > pageNumber {
            let logic = collectionData[pageNumber]
            monthYearLabel.text = logic.currentMonthAndYear as String
        }
    }
    
    @IBAction func retreatToPreviousMonth(button: UIButton) {
        advance(-1, animate: true)
    }
    
    @IBAction func advanceToFollowingMonth(button: UIButton) {
        advance(1, animate: true)
    }
    
    func advance(byIndex: Int, animate: Bool) {
        var visibleIndexPath = self.collectionView.indexPathsForVisibleItems().first as NSIndexPath!
        
        if (visibleIndexPath.item == 0 && byIndex == -1) ||
           ((visibleIndexPath.item + 1) == collectionView.numberOfItemsInSection(0) && byIndex == 1) {
           return
        }
        
        visibleIndexPath = NSIndexPath(forItem: visibleIndexPath.item + byIndex, inSection: visibleIndexPath.section)
        updateHeader(visibleIndexPath.item)
        collectionView.scrollToItemAtIndexPath(visibleIndexPath, atScrollPosition: .CenteredHorizontally, animated: animate)
    }
    
    func moveToSelectedDate(animated: Bool) {
        var index = -1
        for var i = 0; i < collectionData.count; i++  {
            let logic = collectionData[i]
            if selectedDates.count > 0 && logic.containsDate(selectedDates.last!) {
                index = i
                break
            }
        }
        
        if index != -1 {
            let indexPath = NSIndexPath(forItem: index, inSection: 0)
            updateHeader(indexPath.item)
            collectionView.scrollToItemAtIndexPath(indexPath, atScrollPosition: .CenteredHorizontally, animated: animated)
        }
    }
    
    //MARK: Month cell delegate.
    func didSelect(date: Date) {
        if !allowMultipleSelections {
            selectedDates[0] = date.nsdate.startOfDay
        }
        else {
            selectedDates.append(date.nsdate.startOfDay)
        }
    }
    
    func didDeselect(date: Date) {
        if selectedDates.count == 1 {
            return
        }
        
        for aDate in selectedDates {
            if aDate.isSameDay(date.nsdate.startOfDay) {
                if let index = selectedDates.indexOf(aDate) {
                    selectedDates.removeAtIndex(index)
                }
            }
        }
    }
}
