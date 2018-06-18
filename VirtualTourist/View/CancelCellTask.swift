//
//  CancelCellTask.swift
//  VirtualTourist
//
//  Created by Kyle Stokes on 6/14/18.
//  with attribution to nsutanto
//  https://github.com/nsutanto/ios-VirtualTourist/blob/master/VirtualTourist/Utility/CellCancelTask.swift
//  Copyright © 2018 Kyle Stokes. All rights reserved.
//

import Foundation

import UIKit

class CancelCellTask : UICollectionViewCell {
    
    var taskToCancelIfCellIsReused: URLSessionTask? {
        
        didSet {
            if let taskToCancel = oldValue {
                taskToCancel.cancel()
            }
        }
    }
}
