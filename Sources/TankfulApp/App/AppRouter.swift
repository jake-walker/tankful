//
//  AppRouter.swift
//  tankful
//
//  Created by Jake Walker on 14/09/2026.
//

import Observation
import SkipFuse
import TankfulDomain

@Observable final class AppRouter {
    var path: [AppRoute] = []

    func push(_ route: AppRoute) {
        path.append(route)
    }

    func pop() {
        _ = path.popLast()
    }

    func popToRoot() {
        path.removeAll()
    }
}
