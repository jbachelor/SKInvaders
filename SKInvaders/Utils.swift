//
//  Utils.swift
//  SKInvaders
//
//  Created by Jon Bachelor on 7/20/16.
//  Copyright © 2016 Razeware. All rights reserved.
//

import Foundation


func logFn(file file: String, function: String, message: String = "") {
    
    var fileString = file.componentsSeparatedByString("/").last!
    fileString = fileString.componentsSeparatedByString(".").first!
    
    var logMessage = "\(fileString) --> \(function)"
    
    if !message.isEmpty {
        logMessage += ":  \(message)"
    }
    
    print(logMessage)
}