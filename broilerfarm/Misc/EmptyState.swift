//
//  EmptyState.swift
//  broilerfarm
//
//  Created by Troy Dotulong on 10/7/20.
//  Copyright © 2020 Troy Dotulong. All rights reserved.
//

import Foundation
import EmptyStateKit

enum State: CustomState {

    case noData
    case noSearch
    case noInternet
    case noList

    var image: UIImage? {
        switch self {
        case .noData: return UIImage(named: "redLogo")
        case .noSearch: return UIImage(named: "redLogo")
        case .noInternet: return UIImage(named: "redLogo")
        case .noList: return UIImage(named: "redLogo")
        }
    }

    var title: String? {
        switch self {
        case .noData: return "No Data"
        case .noSearch: return "No results"
        case .noInternet: return "We’re Sorry"
        case .noList: return "No Data Added yet"
        }
    }

    var description: String? {
        switch self {
        case .noData: return "No data found on Database."
        case .noSearch: return "Please try another search item"
        case .noInternet: return "Our staff is still working on the issue for better experience"
        case .noList: return "Please Add Data"
        }
    }

    var titleButton: String? {
        switch self {
        case .noData: return "Retry"
        case .noSearch: return "Go back"
        case .noInternet: return "Try again?"
        case .noList: return "Add"
        }
    }
}
