//
//  ViewController.swift
//  Calendar
//
//  Created by Lancy on 01/06/15.
//  Copyright (c) 2015 Lancy. All rights reserved.
//

import UIKit

class ViewController: UIViewController, CalendarViewDelegate {
    
    @IBOutlet var placeholderView: UIView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // todays date.
        let date = NSDate()
        
        // create an instance of calendar view with 
        // base date (Calendar shows 12 months range from current base date)
        // selected date (marked dated in the calendar)
        let calendarView = CalendarView.instance(date, selectedDate: date)
        calendarView.delegate = self
        calendarView.translatesAutoresizingMaskIntoConstraints = false
        
//        calendarView.allowMultipleSelections = true   //Allows selection of multiple dates. Defaults to false
        
        placeholderView.addSubview(calendarView)
        
        // Constraints for calendar view - Fill the parent view.
        placeholderView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[calendarView]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["calendarView": calendarView]))
        placeholderView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[calendarView]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["calendarView": calendarView]))
    }
    
    //REQUIRED: Will be called whether allowMultipleSelections is true or false.
    //Also will be called in cases of selection and deselection.
    // Will return the last SELECTED date available
    func didSelectDate(date: NSDate) {
        print("\(date.year)-\(date.month)-\(date.day)")
    }
    
    //OPTIONAL: Will return all selected dates. Useful when allowMultipleSelections is true
    /*
    func didChangeSelectedDates(selectedDates: [NSDate]) {
        print("Selected Dates: {")
        selectedDates.forEach { (date) -> () in
            print("\(date.year)-\(date.month)-\(date.day)")
        }
        print("}")
    }
    */
}

