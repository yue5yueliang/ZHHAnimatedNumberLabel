//
//  RootViewController.swift
//  ZHHAnimatedNumberLabel
//
//  Created by 桃色三岁 on 04/26/2025.
//  Copyright (c) 2025 桃色三岁. All rights reserved.
//

import UIKit

final class RootViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "示例入口"

        let swiftBtn = UIButton(type: .system)
        swiftBtn.setTitle("Swift 示例", for: .normal)
        swiftBtn.frame = CGRect(x: 40, y: 200, width: view.bounds.width - 80, height: 44)
        swiftBtn.autoresizingMask = [.flexibleWidth, .flexibleBottomMargin]
        swiftBtn.addTarget(self, action: #selector(openSwiftDemo), for: .touchUpInside)

        let ocBtn = UIButton(type: .system)
        ocBtn.setTitle("OC 示例", for: .normal)
        ocBtn.frame = CGRect(x: 40, y: 260, width: view.bounds.width - 80, height: 44)
        ocBtn.autoresizingMask = [.flexibleWidth, .flexibleBottomMargin]
        ocBtn.addTarget(self, action: #selector(openOCDemo), for: .touchUpInside)
        
        let swiftUIBtn = UIButton(type: .system)
        swiftUIBtn.setTitle("SwiftUI 示例", for: .normal)
        swiftUIBtn.frame = CGRect(x: 40, y: 320, width: view.bounds.width - 80, height: 44)
        swiftUIBtn.autoresizingMask = [.flexibleWidth, .flexibleBottomMargin]
        swiftUIBtn.addTarget(self, action: #selector(openSwiftUIDemo), for: .touchUpInside)

        view.addSubview(swiftBtn)
        view.addSubview(ocBtn)
        view.addSubview(swiftUIBtn)
    }

    @objc private func openSwiftDemo() {
        navigationController?.pushViewController(SwiftDemoViewController(), animated: true)
    }

    @objc private func openOCDemo() {
        navigationController?.pushViewController(OCDemoViewController(), animated: true)
    }
    
    @objc private func openSwiftUIDemo() {
        navigationController?.pushViewController(SwiftUIHostViewController(), animated: true)
    }
}
