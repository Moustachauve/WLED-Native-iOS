//
//  CollectionProvider.swift
//  wled-osx
//
//  Created by Robert Brune on 26.11.23.
//

import Foundation
import SwiftUI

@MainActor
protocol CollectionProvider: ObservableObject {
    associatedtype T: DeviceProvider
    var devices:[T] { get set }
}
