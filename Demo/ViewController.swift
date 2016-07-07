//
//  ViewController.swift
//  Demo
//
//  Created by mrahmiao on 7/2/16.
//  Copyright © 2016 EWStudio. All rights reserved.
//

import UIKit
import AnimatedScrollableToolbar

class ViewController: UIViewController {

  @IBOutlet weak var scrollView: UIScrollView!

  override func viewDidLoad() {
    super.viewDidLoad()

    let imageView = UIImageView(image: UIImage(named: "landscape"))
    scrollView.addSubview(imageView)

    var constraints: [NSLayoutConstraint] = []

    constraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:|[imageView]|", options: [], metrics: nil, views: ["imageView": imageView]))
    constraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:|[imageView]|", options: [], metrics: nil, views: ["imageView": imageView]))

    let cameraImage = UIImage(named: "Camera")!.withRenderingMode(.alwaysTemplate)
    let cameraItem = AnimatedScrollableToolbar.ActionItem(image: cameraImage, target: self, action: #selector(ViewController.handleToolbarTap(toolbar:)))
    var actionItem = AnimatedScrollableToolbar.ActionItem(image: UIImage(named: "Action")!.withRenderingMode(.alwaysTemplate), target: self, action: #selector(ViewController.handleToolbarTap(toolbar:)))
    actionItem.subItems = [cameraItem, actionItem, cameraItem, cameraItem, actionItem, cameraItem, cameraItem, actionItem, cameraItem]
    let items = [cameraItem, actionItem, cameraItem, actionItem, cameraItem, actionItem, cameraItem, actionItem]

    let toolbar = AnimatedScrollableToolbar(items: items)
    toolbar.translatesAutoresizingMaskIntoConstraints = false
    toolbar.isSelectionEnabled = true
    toolbar.isDismissedOnSubitemTapped = true
    toolbar.isItemExchangeEnabled = true
    
    view.addSubview(toolbar)

    constraints.append(contentsOf: [
      toolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      toolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      toolbar.bottomAnchor.constraint(equalTo: view.bottomAnchor)
    ])

    NSLayoutConstraint.activate(constraints)

  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }

  func handleToolbarTap(toolbar: AnimatedScrollableToolbar) {
    print(toolbar.selectedItemIndex)
  }

}
