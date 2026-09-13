//
//  Item.swift
//  NBABettingSimulator
//
//  Created by Karriem Lang on 9/13/26.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
