//
//  BundleToken.swift
//  EncoreSwiftUiKit
//
//  Created by Kanj on 21/01/26.
//
import Foundation

enum BundleToken {
    #if SWIFT_PACKAGE
        static let bundle = Bundle.module
    #else
        static let bundle = Bundle.main
    #endif
}
