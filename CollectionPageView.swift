//
//  CollectionPageView.swift
//  imapMobile
//
//  Created by Lee on 16/6/3.
//  Copyright © 2016年 crash. All rights reserved.
//

import UIKit

/// 集合页面视图代理
@objc public protocol CollectionPageViewDelegate: class {
    
    /**
     集合页面视图 页面滚动代理方法
     
     - parameter collectionPageView: 集合页面视图
     - parameter pageIndex:          页面滚动后的下标
     */
    optional func collectionPageView(collectionPageView: CollectionPageView, didScrollToPage pageIndex: Int)
}


/// 集合页面视图
public class CollectionPageView: UIView {
    
    public weak var delegate: CollectionPageViewDelegate?
    
    public var segment: CollectionSegmentView
    public var contentView: CollectionContentView
    
    public var scrollEnabled: Bool = true {
        didSet {
            contentView.scrollEnabled = scrollEnabled
        }
    }
    
    public var hideSegment: Bool = false {
        didSet {
            if hideSegment {
                segmentTopConstraint.constant = -segmentHeight
            } else {
                segmentTopConstraint.constant = 0
            }
        }
    }
    
    private var segmentHeight: CGFloat
    private var segmentTopConstraint: NSLayoutConstraint!
    private var currentIndex = 0
    
    //================================================================
    //  MARK: - Initializer
    //================================================================
    
    public init?(frame: CGRect,
                 style: CollectionSegmentStyle = CollectionSegmentStyle(),
                 titles: [String],
                 childViewControllers: [UIViewController],
                 parentViewController: UIViewController)
    {
        guard titles.count == childViewControllers.count else {
            debugLog("标题的个数必须和子控制器的个数相同")
            return nil
        }
        
        self.segmentHeight = style.segmentHeight
        
        let segmentFrame = CGRectMake(0, 0, frame.size.width, self.segmentHeight)
        let contentViewFrame = CGRectMake(0, self.segmentHeight, frame.size.width, frame.size.height - self.segmentHeight)
        
        self.segment = CollectionSegmentView(frame: segmentFrame, style: style, titles: titles)
        
        self.contentView = CollectionContentView(frame: contentViewFrame, childViewControllers: childViewControllers, parentViewController: parentViewController)
        self.contentView.scrollEnabled = self.scrollEnabled
        
        super.init(frame: frame)
        
        setupUI()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //================================================================
    //  MARK: - Override
    //================================================================
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        // 调整位置
        segment.adjustUIWithProgress(1.0, oldIndex: currentIndex, newIndex: currentIndex)
        segment.adjustTitleOffsetToCurrentIndex(currentIndex, animated: true)
        
        contentView.scrollPage(to: currentIndex, animated: true)
    }
    
    //================================================================
    //  MARK: - Public Functions
    //================================================================
    
    /**
     滚动到指定页面
     
     - parameter index:    页面下标
     - parameter animated: true（有动画效果），false（无动画效果）
     */
    public func scrollPage(to index: Int, animated: Bool) {
        segment.selectTitleWithIndex(index, animated: animated)
        contentView.scrollPage(to: index, animated: animated)
    }
    
    /**
     重新设置内容
     
     - parameter titles:      标题
     - parameter newChildVCs: 内容视图控制器组
     - parameter newParentVC: 内容视图控制器组的父控制器
     */
    public func resetWithTitles(
        titles: [String],
        newChildVCs: [UIViewController],
        newParentVC: UIViewController)
    {
        segment.titles = titles
        contentView.resetChildViewControllers(newChildVCs, parentViewController: newParentVC)
    }
    
    
    //================================================================
    //  MARK: - Private Functions
    //================================================================
    
    // 设置UI
    private func setupUI() {
        self.backgroundColor = UIColor.whiteColor()
        
        segment.delegate = self
        contentView.delegate = self
        self.addSubview(segment)
        self.addSubview(contentView)
        
        segment.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        let bindingViews = ["segment": segment, "contentView": contentView]
        let metrics = ["segmentHeight": segmentHeight]
        
        let segmentConstraintH = NSLayoutConstraint.constraintsWithVisualFormat("H:|-0-[segment]-0-|", options: .AlignAllCenterX, metrics: nil, views: bindingViews)
        self.addConstraints(segmentConstraintH)
        
        let contentViewConstraintH = NSLayoutConstraint.constraintsWithVisualFormat("H:|-0-[contentView]-0-|", options: .AlignAllCenterX, metrics: nil, views: bindingViews)
        self.addConstraints(contentViewConstraintH)
        
        let constraintV = NSLayoutConstraint.constraintsWithVisualFormat("V:[segment(==segmentHeight)]-0-[contentView]-0-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: metrics, views: bindingViews)
        self.addConstraints(constraintV)
        
        let segmentTop = NSLayoutConstraint(item: segment, attribute: .Top, relatedBy: .Equal, toItem: self, attribute: .Top, multiplier: 1.0, constant: 0.0)
        self.addConstraint(segmentTop)
        
        self.segmentTopConstraint = segmentTop
        
        self.layoutIfNeeded()
    }
    
}

// MARK: - CollectionSegmentViewDelegate
extension CollectionPageView: CollectionSegmentViewDelegate {
    
    final public func collectionSegmentView(
        collectionSegmentView: CollectionSegmentView,
        didSelectedTitle titleLabel: UILabel,
                         index: Int)
    {
        contentView.scrollPage(to: index, animated: false)
    }
}

// MARK: - CollectionContentViewDelegate
extension CollectionPageView: CollectionContentViewDelegate {
    
    final public func collectionContentView(
        collectionContentView: CollectionContentView,
        didScrollToPage pageIndex: Int)
    {
        currentIndex = pageIndex
        
        // 恢复标题可选
        segment.titleSelectable = true
        
        // 调整标题位置
        segment.adjustUIWithProgress(1.0, oldIndex: pageIndex, newIndex: pageIndex)
        segment.adjustTitleOffsetToCurrentIndex(pageIndex, animated: true)
        
        // 触发代理方法
        delegate?.collectionPageView?(self, didScrollToPage: pageIndex)
    }
    
    final public func collectionContentView(
        collectionContentView: CollectionContentView,
        scrollFrom oldIndex: Int,
        to newIndex: Int,
        progress: CGFloat)
    {
        segment.adjustUIWithProgress(progress, oldIndex: oldIndex, newIndex: newIndex)
    }
    
    final public func collectionContentViewWillBeginDragging(collectionContentView: CollectionContentView) {
        // 开始滑动的时候不能选择，直至滑动完毕为止
        segment.titleSelectable = false
    }
}