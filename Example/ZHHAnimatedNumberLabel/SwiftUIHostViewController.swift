//
//  SwiftUIHostViewController.swift
//  ZHHAnimatedNumberLabel
//
//  Created by 桃色三岁 on 04/26/2025.
//  Copyright (c) 2025 桃色三岁. All rights reserved.
//

import SwiftUI
import UIKit

final class SwiftUIHostViewController: UIHostingController<SwiftUIDemoView> {
    init() {
        super.init(rootView: SwiftUIDemoView())
    }

    @MainActor @objc required dynamic init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder, rootView: SwiftUIDemoView())
    }
}
