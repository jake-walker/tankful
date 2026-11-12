//
//  Array+Display.swift
//  tankful
//
//  Created by Jake Walker on 12/11/2026.
//

import Foundation

extension Array where Element == String {
    func displayOrList() -> String {
        switch count {
        case 0:
            return ""
        case 1:
            return self[0]
        default:
            let allButLast = dropLast().joined(separator: ", ")
            return String(
                format: NSLocalizedString("%@ or %@", comment: "One or more items joined with 'or'"),
                allButLast, last!
            )
        }
    }
}
