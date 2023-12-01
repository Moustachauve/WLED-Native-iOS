//
//  String.swift
//  wled-native-macOS
//
//  Created by Robert Brune on 01.12.23.
//

import Foundation
import WledLib

extension String: WledHost {
    public var hostname: String {
        return self
    }
}
