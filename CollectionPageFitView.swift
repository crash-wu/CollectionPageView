//
//  CollectionPageFitView.swift
//  imapMobile
//
//  Created by Lee on 16/6/28.
//  Copyright © 2016年 crash. All rights reserved.
//

import UIKit

/**
 *  segment带有背景视图，并且可以自定义segment的size
 *  segment会自动居中显示
 */
public class CollectionPageFitView: CollectionPageView {
    
    // segment背景视图
    public var segmentBackgroundView: UIView!
    
    // 是否隐藏segment
    public override var hideSegment: Bool {
        didSet {
            let defaultHeiht = segmentBGViewHeight
            
            if hideSegment {
                UIView.animateWithDuration(0.3) {
                    [weak self] in
                    self?.segmentBGViewTopConstraint.constant = -defaultHeiht
                }
            } else {
                UIView.animateWithDuration(0.3) {
                    [weak self] in
                    self?.segmentBGViewTopConstraint.constant = 0
                }
            }
        }
    }
    
    // segment背景视图高度
    private var segmentBGViewHeight: CGFloat = 0
    
    // segment背景视图顶部约束
    private var segmentBGViewTopConstraint: NSLayoutConstraint!

    /**
     指定初始化方法
     
     - parameter frame:                该视图的frame
     - parameter segmentSize:          segment的大小
     - parameter style:                segment样式，其中segmentHeight将作用于segmentBackgroundView
     - parameter titles:               segment标题
     - parameter childViewControllers: 视图控制器集合
     - parameter parentViewController: 父控制器，弱引用
     
     - returns: CollectionPageFitView,  当titles的个数与childViewControllers个数不一致时将返回nil
     */
    public init?(frame: CGRect,
                 segmentSize: CGSize,
                 style: CollectionSegmentStyle = CollectionSegmentStyle(),
                 titles: [String],
                 childViewControllers: [UIViewController],
                 parentViewController: UIViewController)
    {
        super.init(frame: frame, style: style, titles: titles, childViewControllers: childViewControllers, parentViewController: parentViewController)
        
        segmentBGViewHeight = style.segmentHeight
        
        // segment背景视图
        segmentBackgroundView = UIView(frame: CGRect(x: 0, y: 0, width: self.bounds.width, height: segmentBGViewHeight))
        segmentBackgroundView.backgroundColor = UIColor.whiteColor()
        segmentBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(segmentBackgroundView)

        
        // 将segment添加到segment背景视图上
        segment.removeFromSuperview()
        segmentBackgroundView.addSubview(segment)
        
        // segment约束 - CenterX
        let segmentCenterX = NSLayoutConstraint(item: segment, attribute: .CenterX, relatedBy: .Equal, toItem: segmentBackgroundView, attribute: .CenterX, multiplier: 1.0, constant: 0.0)
        segmentBackgroundView.addConstraint(segmentCenterX)
        
        // segment约束 - CenterY
        let segmentCenterY = NSLayoutConstraint(item: segment, attribute: .CenterY, relatedBy: .Equal, toItem: segmentBackgroundView, attribute: .CenterY, multiplier: 1.0, constant: 0.0)
        segmentBackgroundView.addConstraint(segmentCenterY)
        
        // segment约束 - Width
        let segmentWidth = NSLayoutConstraint(item: segment, attribute: .Width, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1.0, constant: segmentSize.width)
        segmentBackgroundView.addConstraint(segmentWidth)
        
        // segment约束 - Height
        let segmentHeight = NSLayoutConstraint(item: segment, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1.0, constant: segmentSize.height)
        segmentBackgroundView.addConstraint(segmentHeight)
        
        
        // 绑定视图
        let bindingViews = ["segmentBG": segmentBackgroundView, "contentView": contentView]
        let metrics = ["segmentBGHeight": segmentBGViewHeight]
        
        // segment背景视图顶部约束
        segmentBGViewTopConstraint = NSLayoutConstraint(item: segmentBackgroundView, attribute: .Top, relatedBy: .Equal, toItem: self, attribute: .Top, multiplier: 1.0, constant: 0.0)
        self.addConstraint(segmentBGViewTopConstraint)
        
        
        // 垂直方向约束
        let constraintV = NSLayoutConstraint.constraintsWithVisualFormat("V:[segmentBG(==segmentBGHeight)]-0-[contentView]-0-|", options: [.AlignAllLeft, .AlignAllRight], metrics: metrics, views: bindingViews)
        self.addConstraints(constraintV)
        
        // 水平方向约束
        let constraintH = NSLayoutConstraint.constraintsWithVisualFormat("H:|-0-[segmentBG]-0-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: bindingViews)
        self.addConstraints(constraintH)
        
        self.layoutIfNeeded()
        
        
    }
    
    public override func drawRect(rect: CGRect) {
        super.drawRect(rect)
        
        segmentBackgroundView.layer.shadowColor = UIColor.lightGrayColor().CGColor
        segmentBackgroundView.layer.shadowOpacity = 1
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
