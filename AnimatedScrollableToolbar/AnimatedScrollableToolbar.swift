//
//  AnimatedScrollableToolbar.swift
//  AnimatedScrollableToolbar
//
//  Created by mrahmiao on 6/30/16.
//  Copyright © 2016 EWStudio. All rights reserved.
//

import UIKit

// MARK: AnimatedScrollableToolbar
public class AnimatedScrollableToolbar: UIView {

  public weak var delegate: AnimatedScrollableToolbarDelegate?

  public override var backgroundColor: UIColor? {
    set { /* Do nothing */ }
    get { return scrollView.backgroundColor }
  }
  public private(set) var selectedItemIndex: Int = 0
  public var isSelectionEnabled: Bool = false {
    didSet { isSelectionEnabledDidSet() }
  }
  public var style: AnimatedScrollableToolbarStyle = .light {
    didSet { styleDidSet() }
  }
  public var isBlurEffectEnabled: Bool = true {
    didSet { isBlurEffectEnabledDidSet() }
  }

  /// When set to `true`, tapping on subitems will result in swapping item and subitem.
  public var isItemExchangeEnabled: Bool = false

  /// When set to `true`, subitem views will disappear if any tap on subitems.
  public var isDismissedOnSubitemTapped: Bool = false

  private var visualEffectView: UIVisualEffectView
  private var scrollView: UIScrollView
  private var contentView: UIView
  private var animationImageView: UIImageView // Used for background image animation
  private var tapGesture: UITapGestureRecognizer!
  private var animating: Bool = false
  private var itemWidth: CGFloat = 0.0
  private var itemViews: [ActionItemView] = []
  private var previousSelectedIndex: Int = -1
  private var heightConstraint: NSLayoutConstraint!

  private var subitemScrollView: UIScrollView?
  private var subitemContentView: UIView?
  private var subitemViews: [ActionItemView] = []
  private var subitemTapGesture: UITapGestureRecognizer?

  public convenience init(items: [AnimatedScrollableToolbarActionItem]) {

    self.init(frame: CGRect.zero)

    let screenWidth = UIScreen.main().bounds.width
    self.itemWidth = items.count < AnimatedScrollableToolbar.maximumItemCount ? screenWidth / CGFloat(items.count) : screenWidth / CGFloat(AnimatedScrollableToolbar.maximumItemCount)
    setupActionItemViews(items: items)
  }

  private override init(frame: CGRect) {

    let width = UIScreen.main().bounds.width
    let height = AnimatedScrollableToolbar.defaultHeight

    scrollView = UIScrollView(frame: CGRect.zero)
    contentView = UIView(frame: CGRect.zero)
    animationImageView = UIImageView(frame: CGRect.zero)
    visualEffectView = UIVisualEffectView()

    super.init(frame: CGRect(origin: frame.origin, size: CGSize(width: width, height: height)))
    super.backgroundColor = .clear()

    setupBlurView()
    setupScrollView()
    setupContentView()
    setupContainerConstraints()
    setupGestures()
  }

  public required init?(coder aDecoder: NSCoder) {
    fatalError("\(#function) is not implemented yet.")
  }

  public func dismissSubitems(sender: AnyObject?) {
    if subitemScrollView != nil {
      delegate?.toolbarWillHideSubitems(toolbar: self)
      subitemViews.removeAll()
      subitemScrollView?.removeFromSuperview()
      subitemScrollView = nil
      heightConstraint.constant = AnimatedScrollableToolbar.defaultHeight
      setNeedsLayout()
      delegate?.toolbarDidHideSubitems(toolbar: self)
    }
  }
}

// MARK:
// MARK: AnimatedScrollableToolbarDelegate
public protocol AnimatedScrollableToolbarDelegate: class {
  func toolbar(_ toolbar: AnimatedScrollableToolbar, willSelect item: AnimatedScrollableToolbarActionItem)
  func toolbar(_ toolbar: AnimatedScrollableToolbar, didSelect item: AnimatedScrollableToolbarActionItem)

  func toolbarWillHideSubitems(toolbar: AnimatedScrollableToolbar)
  func toolbarDidHideSubitems(toolbar: AnimatedScrollableToolbar)

  func toolbar(_ toolbar: AnimatedScrollableToolbar, willShow subitems: [AnimatedScrollableToolbarActionItem], atIndex index: Int)
  func toolbar(_ toolbar: AnimatedScrollableToolbar, didShow subitems: [AnimatedScrollableToolbarActionItem], atIndex index: Int)
}

// MARK:
// MARK: AnimatedScrollableToolbarActionItem
public struct AnimatedScrollableToolbarActionItem {

  public let identifier: String
  public let image: UIImage
  public let title: String?
  public let action: Selector?
  public weak var target: AnyObject?
  public var subItems: [AnimatedScrollableToolbarActionItem] = []
  public var tintColor: UIColor?
  public var isExchangeable: Bool = true

  public init(identifier: String, image: UIImage, title: String? = nil, target: AnyObject? = nil, action: Selector? = nil) {
    self.identifier = identifier
    self.image = image
    self.target = target
    self.action = action
    self.title = title

  }
}

// MARK:
// MARK: AnimatedScrollableToolbarCustomStyle
public struct AnimatedScrollableToolbarCustomStyle {
  public let backgroundColor: UIColor
  public let blurEffect: UIBlurEffect

  /// Tint color of selected item
  public let tintColor: UIColor
  /// Tint color of unselected color
  public let unselectedItemTintColor: UIColor
  public let selectionIndicatorImage: UIImage

  public init(backgroundColor: UIColor, blurEffect: UIBlurEffect, tintColor: UIColor, unselectedItemTintColor: UIColor, selectionIndicatorImage: UIImage) {
    self.backgroundColor = backgroundColor
    self.blurEffect = blurEffect
    self.tintColor = tintColor
    self.unselectedItemTintColor = unselectedItemTintColor
    self.selectionIndicatorImage = selectionIndicatorImage
  }
}

// MARK:
// MARK: AnimatedScrollableToolbarStyle
public enum AnimatedScrollableToolbarStyle {
  case light, dark, custom(AnimatedScrollableToolbarCustomStyle)

  private var backgroundColor: UIColor {
    switch self {
    case .light:
      return .clear()
    case .dark:
      return UIColor(white: 0.2, alpha: 0.2)
    case .custom(let style):
      return style.backgroundColor
    }
  }

  private var blueEffect: UIBlurEffect {
    switch self {
    case .light:
      return UIBlurEffect(style: .light)
    case .dark:
      return UIBlurEffect(style: .dark)
    case .custom(let style):
      return style.blurEffect
    }
  }

  private var tintColor: UIColor? {
    switch self {
    case .light, .dark:
      return .white()
    case .custom(let style):
      return style.tintColor
    }
  }

  private var unselectedItemTintColor: UIColor? {
    switch self {
    case .light, .dark:
      return .white()
    case .custom(let style):
      return style.unselectedItemTintColor
    }
  }

  private var selectionIndicatorImage: UIImage? {
    switch self {
    case .light:
      return UIColor(white: 0.8, alpha: 0.3).generatedImage
    case .dark:
      return UIColor(white: 0.6, alpha: 0.6).generatedImage
    case .custom(let style):
      return style.selectionIndicatorImage
    }
  }
}

// MARK:
// MARK: Gesture Handler
extension AnimatedScrollableToolbar {

  // Change selection and fire the animation.
  func handleTapGesture(_ gesture: UITapGestureRecognizer) {

    guard let (newIndex, previousItemView, selectedItemView) = itemViewsUnderGesture(gesture), actionItem = selectedItemView.actionItem else {
      return
    }

    // Tap on the same item
    if previousItemView == selectedItemView {

      // Show the subitems
      if subitemScrollView == nil && !selectedItemView.actionItem.subItems.isEmpty {
        popupSubitems(selectedItemView.actionItem.subItems, atIndex: newIndex)
        return
      } else {
        dismissSubitems(sender: self)
        return
      }
    }

    delegate?.toolbar(self, willSelect: actionItem)
    selectedItemIndex = newIndex
    dismissSubitems(sender: self)

    if isSelectionEnabled {

      animating = true
      setAnimationInitialState(for: previousItemView, and: selectedItemView)

      let finalRect = contentView.convert(selectedItemView.backgroundImageView.frame, from: selectedItemView)


      UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 5, options: [.curveEaseIn, .curveEaseOut, .beginFromCurrentState], animations: {

        // Move the fake background image and change the tint color
        self.animationImageView.frame.origin.x = finalRect.origin.x
        selectedItemView.iconImageView.tintColor = actionItem.tintColor ?? self.style.tintColor

        }, completion: { finished in
          selectedItemView.backgroundImageView.image = self.style.selectionIndicatorImage
          self.animationImageView.image = nil
          self.animating = false
      })
    }

    if let action = actionItem.action, target = actionItem.target {
      UIApplication.shared().sendAction(action, to: target, from: self, for: nil)
    }

    delegate?.toolbar(self, didSelect: actionItem)

  }

  func handleSubitemTapGesture(_ gesture: UITapGestureRecognizer) {

    func exchangeMainItemView(_ mainItemView: ActionItemView, with subitemView: ActionItemView, atIndex index: Int) {
      var mainActionItem = mainItemView.actionItem!
      var subitem = subitemView.actionItem
      var originalSubitems = mainActionItem.subItems

      mainActionItem.subItems = []
      originalSubitems[index] = mainActionItem
      subitem?.subItems = originalSubitems

      mainItemView.actionItem = subitem
      subitemView.actionItem = mainActionItem
    }

    let location = gesture.location(in: subitemScrollView!)
    let mainItemView = itemViews[selectedItemIndex]

    for (index, itemView) in subitemViews.enumerated() where itemView.frame.contains(location) {

      defer {
        delegate?.toolbar(self, didSelect: itemView.actionItem)
        if isDismissedOnSubitemTapped {
          dismissSubitems(sender: self)
        }
      }

      delegate?.toolbar(self, willSelect: itemView.actionItem)

      if isItemExchangeEnabled {
        exchangeMainItemView(mainItemView, with: itemView, atIndex: index)
      }

      guard let action = itemView.actionItem.action, target = itemView.actionItem.target else {
        return
      }

      UIApplication.shared().sendAction(action, to: target, from: self, for: nil)
      return

    }
  }

}

// MARK:
// MARK: UIGestureRecognizerDelegate
extension AnimatedScrollableToolbar: UIGestureRecognizerDelegate {
  public override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    guard gestureRecognizer == tapGesture else {
      return true
    }

    return !animating
  }
}

// MARK:
// MARK: Helpers
private extension AnimatedScrollableToolbar {

  func setupBlurView() {
    visualEffectView.effect = style.blueEffect
    visualEffectView.translatesAutoresizingMaskIntoConstraints = false
    addSubview(visualEffectView)
  }

  func setupScrollView() {
    scrollView.translatesAutoresizingMaskIntoConstraints = false
    scrollView.showsVerticalScrollIndicator = false
    scrollView.showsHorizontalScrollIndicator = false
    scrollView.backgroundColor = style.backgroundColor
    addSubview(scrollView)
  }

  func setupContentView() {
    contentView.translatesAutoresizingMaskIntoConstraints = false
    contentView.backgroundColor = .clear()
    contentView.addSubview(animationImageView)
    scrollView.addSubview(contentView)
  }

  func setupActionItemViews(items: [AnimatedScrollableToolbarActionItem]) {

    if items.isEmpty {
      return
    }

    var layoutViews = [String: AnyObject]()
    var constraints = [NSLayoutConstraint]()

    var layoutAttendees = [String]()
    for (index, item) in items.enumerated() {

      let itemView = ActionItemView(item: item)
      itemView.translatesAutoresizingMaskIntoConstraints = false
      itemView.iconTintColor = style.unselectedItemTintColor
      itemViews.append(itemView)

      let viewName = "view\(index)"
      layoutAttendees.append("[\(viewName)(\(itemWidth))]")

      layoutViews[viewName] = itemView
      contentView.addSubview(itemView)

      // Only sets vertical layout of the first item view, others will
      // be set later on.
      if index == 0 {
        itemView.iconImageView.tintColor = item.tintColor ?? style.tintColor
        constraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:|[\(viewName)]|", options: [], metrics: nil, views: layoutViews))
      }

      constraints.append(contentsOf: itemView.layoutConstraints)
    }

    // [view0(itemWidth)][view1(itemWidth)][view2(itemWidth)]…
    let format = layoutAttendees.joined(separator: "")

    // Use alignment options to align all the item views
    constraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:|\(format)|", options: [.alignAllTop, .alignAllBottom], metrics: nil, views: layoutViews))

    NSLayoutConstraint.activate(constraints)
  }

  func setupContainerConstraints() {

    let layoutViews = [
      "scrollView": scrollView,
      "contentView": contentView,
      "blurView": visualEffectView
    ]

    var constraints = [NSLayoutConstraint]()

    for format in ["H:|[blurView]|", "V:[blurView(\(AnimatedScrollableToolbar.defaultHeight))]|", "H:|[scrollView]|", "V:[scrollView(\(AnimatedScrollableToolbar.defaultHeight))]|", "H:|[contentView]|", "V:|[contentView(\(AnimatedScrollableToolbar.defaultHeight))]|"] {
      constraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: format, options: [], metrics: nil, views: layoutViews))
    }

    heightConstraint = NSLayoutConstraint(item: self, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: AnimatedScrollableToolbar.defaultHeight)
    constraints.append(heightConstraint)

    NSLayoutConstraint.activate(constraints)
  }

  func setupGestures() {

    tapGesture = UITapGestureRecognizer(target: self, action: #selector(AnimatedScrollableToolbar.handleTapGesture(_:)))
    tapGesture.delegate = self
    scrollView.addGestureRecognizer(tapGesture)

  }

  func styleDidSet() {
    scrollView.backgroundColor = style.backgroundColor
    visualEffectView.effect = style.blueEffect

    for (index, itemView) in itemViews.enumerated() {
      if index == selectedItemIndex {
        itemView.iconImageView.tintColor = style.tintColor
        itemView.backgroundImageView.image = style.selectionIndicatorImage
      } else {
        itemView.iconImageView.tintColor = style.unselectedItemTintColor
      }
    }
  }

  func isBlurEffectEnabledDidSet() {
    if isBlurEffectEnabled {
      visualEffectView.isHidden = false
    } else {
      visualEffectView.isHidden = true
    }
  }

  func isSelectionEnabledDidSet() {
    let bgImageView = itemViews[selectedItemIndex].backgroundImageView
    if isSelectionEnabled {
      bgImageView.image = style.selectionIndicatorImage
    } else {
      bgImageView.image = nil
    }
  }

  // return (Index, OldSelectedItemView, NewSelectedItemView)
  func itemViewsUnderGesture(_ gesture: UIGestureRecognizer) -> (Int, ActionItemView, ActionItemView)? {
    let pointInScrollView = gesture.location(in: scrollView)
    let newIndex = Int(floor(pointInScrollView.x / itemWidth))

    if scrollView.bounds.contains(pointInScrollView) {
      return (newIndex, itemViews[selectedItemIndex], itemViews[newIndex])
    } else {
      return nil
    }

  }

  func setAnimationInitialState(for previousItemView: ActionItemView, and selectedItemView: ActionItemView) {
    let initialRect = contentView.convert(previousItemView.backgroundImageView.frame, from: previousItemView)
    animationImageView.frame = initialRect
    animationImageView.image = style.selectionIndicatorImage
    previousItemView.backgroundImageView.image = nil
    previousItemView.iconImageView.tintColor = self.style.unselectedItemTintColor
  }

  func popupSubitems(_ subitems: [AnimatedScrollableToolbarActionItem], atIndex index: Int) {

    var constraints: [NSLayoutConstraint] = []

    func addSubitemScrollView() {

      let subitemScrollView = UIScrollView(frame: CGRect.zero)
      self.subitemScrollView = subitemScrollView
      subitemScrollView.translatesAutoresizingMaskIntoConstraints = false
      subitemScrollView.showsHorizontalScrollIndicator = false
      subitemScrollView.showsVerticalScrollIndicator = false
      subitemScrollView.backgroundColor = .clear()

      let subitemContentView = UIView(frame: CGRect.zero)
      self.subitemContentView = subitemContentView
      subitemContentView.translatesAutoresizingMaskIntoConstraints = false
      subitemContentView.backgroundColor = .clear()

      subitemScrollView.addSubview(subitemContentView)
      addSubview(subitemScrollView)

      let views = ["subitemContentView": subitemContentView,
                   "subitemScrollView": subitemScrollView,
                   "scrollView": scrollView]

      for format in ["H:|[subitemContentView]|", "V:|[subitemContentView]|", "H:|[subitemScrollView]|", "V:[subitemScrollView(\(AnimatedScrollableToolbar.defaultSubitemWidth))]-[scrollView]"] {
        constraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: format, options: [], metrics: nil, views: views))
      }

      var layoutAttendees = [String]()
      var layoutViews = [String: AnyObject]()

      for (index, item) in subitems.enumerated() {
        let itemView = buildSubitemView(for: item, atIndex: index)
        let viewName = "view\(index)"
        layoutViews[viewName] = itemView
        layoutAttendees.append("[\(viewName)]")
        subitemViews.append(itemView)
        subitemContentView.addSubview(itemView)
        constraints.append(contentsOf: itemView.layoutConstraints)
      }

      constraints.append(NSLayoutConstraint(item: subitemViews[0], attribute: .top, relatedBy: .equal, toItem: subitemContentView, attribute: .top, multiplier: 1, constant: 0))
      constraints.append(NSLayoutConstraint(item: subitemViews[0], attribute: .bottom, relatedBy: .equal, toItem: subitemContentView, attribute: .bottom, multiplier: 1, constant: 0))

      let margin = calcMargin()
      constraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:|-<=\(margin)-\(layoutAttendees.joined(separator: "-\(AnimatedScrollableToolbar.subitemLeadingGap)-"))-<=\(margin)-|", options: [.alignAllTop, .alignAllBottom], metrics: nil, views: layoutViews))
    }

    func buildSubitemView(for item: AnimatedScrollableToolbarActionItem, atIndex index: Int) -> ActionItemView {
      let itemView = ActionItemView(item: item)
      itemView.translatesAutoresizingMaskIntoConstraints = false
      itemView.iconImageView.image = item.image
      itemView.iconTintColor = style.unselectedItemTintColor
      itemView.layer.cornerRadius = 6
      itemView.clipsToBounds = true
      itemView.backgroundImageView.image = UIColor(white: 0.6, alpha: 0.6).generatedImage

      constraints.append(NSLayoutConstraint(item: itemView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: AnimatedScrollableToolbar.defaultSubitemWidth))
      constraints.append(NSLayoutConstraint(item: itemView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: AnimatedScrollableToolbar.defaultSubitemWidth))

      return itemView
    }

    func setupSubitemGestures() {
      let subitemTapGesture = UITapGestureRecognizer(target: self, action: #selector(AnimatedScrollableToolbar.handleSubitemTapGesture(_:)))
      subitemScrollView?.addGestureRecognizer(subitemTapGesture)
      self.subitemTapGesture = subitemTapGesture
    }

    func calcMargin() -> CGFloat {
      let screenWidth = UIScreen.main().bounds.width
      let count = CGFloat(subitems.count)
      if subitems.count > AnimatedScrollableToolbar.maximumItemCount {
        return AnimatedScrollableToolbar.subitemLeadingGap
      } else {
        return (screenWidth - AnimatedScrollableToolbar.subitemLeadingGap * (count - 1) - AnimatedScrollableToolbar.defaultSubitemWidth * count) / 2
      }
    }

    func playAppearAnimation() {
      let opacity = CABasicAnimation(keyPath: "opacity")
      opacity.fromValue = 0.0
      opacity.toValue = 1.0

      let scale = CASpringAnimation(keyPath: "transform.scale")
      scale.damping = 60.0
      scale.mass = 2
      scale.stiffness = 1500.0
      scale.initialVelocity = 100.0
      scale.fromValue = 1.8
      scale.toValue = 1.0

      let animationGroup = CAAnimationGroup()
      animationGroup.animations = [opacity, scale]
      animationGroup.duration = scale.settlingDuration
      animationGroup.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn)
      animationGroup.fillMode = kCAFillModeBoth

      let base = CACurrentMediaTime()
      var accumulativeTime: CFTimeInterval = 0.0

      for itemView in subitemViews {
        accumulativeTime += 0.05
        animationGroup.beginTime = base + accumulativeTime
        itemView.layer.add(animationGroup, forKey: nil)
      }
    }

    delegate?.toolbar(self, willShow: subitems, atIndex: index)

    addSubitemScrollView()
    setupSubitemGestures()
    heightConstraint.constant = AnimatedScrollableToolbar.expandedToolbarHeight
    setNeedsLayout()
    NSLayoutConstraint.activate(constraints)
    playAppearAnimation()

    delegate?.toolbar(self, didShow: subitems, atIndex: index)
  }
}

// MARK: Constants
private extension AnimatedScrollableToolbar {
  static let maximumItemCount: Int = 6
  static let defaultHeight: CGFloat = 44.0
  static let defaultSubitemWidth: CGFloat = 36.0
  static let subitemLeadingGap: CGFloat = 12.0
  static let expandedToolbarHeight: CGFloat = 44 + 36 + 6
}

private extension AnimatedScrollableToolbar {

  // MARK:
  // MARK: - ActionItemView
  class ActionItemView: UIView {

    static let defaultIconWidth: CGFloat = 22.0

    // For the sake of performance, constraints should be activated by superview
    var layoutConstraints: [NSLayoutConstraint] = []
    var iconTintColor: UIColor? {
      set { iconImageView.tintColor = newValue }
      get { return iconImageView.tintColor }
    }

    var actionItem: AnimatedScrollableToolbarActionItem! {
      didSet { iconImageView.image = actionItem.image }
    }
    let backgroundImageView: UIImageView
    let iconImageView: UIImageView

    convenience init(item: AnimatedScrollableToolbarActionItem) {
      self.init(frame: CGRect.zero)
      self.actionItem = item
      self.iconImageView.image = item.image
    }

    private override init(frame: CGRect) {

      backgroundImageView = UIImageView(frame: CGRect.zero)
      backgroundImageView.translatesAutoresizingMaskIntoConstraints = false
      backgroundImageView.backgroundColor = .clear()

      iconImageView = UIImageView(frame: CGRect.zero)
      iconImageView.contentMode = .scaleAspectFit
      iconImageView.translatesAutoresizingMaskIntoConstraints = false

      super.init(frame: frame)

      addSubview(backgroundImageView)
      addSubview(iconImageView)

      setupConstraints()
    }

    required init?(coder aDecoder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
    }

    private func setupConstraints() {

      // Centering the icon image view
      layoutConstraints.append(contentsOf: [
        iconImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
        iconImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
        iconImageView.widthAnchor.constraint(equalToConstant: ActionItemView.defaultIconWidth),
        iconImageView.heightAnchor.constraint(equalToConstant: ActionItemView.defaultIconWidth),
        backgroundImageView.leadingAnchor.constraint(equalTo: leadingAnchor),
        backgroundImageView.trailingAnchor.constraint(equalTo: trailingAnchor),
        backgroundImageView.topAnchor.constraint(equalTo: topAnchor),
        backgroundImageView.bottomAnchor.constraint(equalTo: bottomAnchor)
      ])

    }
  }
}

// MARK:
// MARK: AnimatedScrollableToolbarDelegate default empty implementations
public extension AnimatedScrollableToolbarDelegate {
  func toolbar(_ toolbar: AnimatedScrollableToolbar, willSelect item: AnimatedScrollableToolbarActionItem) {}
  func toolbar(_ toolbar: AnimatedScrollableToolbar, didSelect item: AnimatedScrollableToolbarActionItem) {}

  func toolbarWillHideSubitems(toolbar: AnimatedScrollableToolbar) {}
  func toolbarDidHideSubitems(toolbar: AnimatedScrollableToolbar) {}

  func toolbar(_ toolbar: AnimatedScrollableToolbar, willShow subitems: [AnimatedScrollableToolbarActionItem], atIndex index: Int) {}
  func toolbar(_ toolbar: AnimatedScrollableToolbar, didShow subitems: [AnimatedScrollableToolbarActionItem], atIndex index: Int) {}
}

// MARK: UIColor
private extension UIColor {
  var generatedImage: UIImage? {
    let rect = CGRect(x: 0, y: 0, width: 1, height: 1)

    UIGraphicsBeginImageContextWithOptions(rect.size, false, UIScreen.main().scale)
    let context = UIGraphicsGetCurrentContext()
    context?.setFillColor(cgColor)
    context?.fill(rect)

    let image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()

    return image
  }
}
