//
//  BundleToken.swift
//  EncoreSwiftUiKit
//
//  Created by Kanj on 21/01/26.
//
import Foundation

final class BundleToken {
    private init() {}

    static let bundle: Bundle = {
        #if SWIFT_PACKAGE
            return Bundle.module
        #else
            return Bundle(for: BundleToken.self)
        #endif
    }()
}
