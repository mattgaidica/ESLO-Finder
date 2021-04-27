//
//  UUIDKey.swift
//  ESLO Finder
//
//  Created by Matt Gaidica on 4/26/21.
//

import Foundation
import CoreBluetooth

// remember to whitelist chars in didDiscoverServices
class ESLOPeripheral: NSObject {
    public static let ESLOServiceUUID = CBUUID.init(string: "E000")
}
