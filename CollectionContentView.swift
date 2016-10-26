//
//  CollectionContentView.swift
//  imapMobile
//
//  Created by Lee on 16/6/6.
//  Copyright © 2016年 crash. All rights reserved.
//

import UIKit

/// 集合内容视图代理协议
@objc public protocol CollectionContentViewDelegate: class {
    
    /**
     集合内容视图已滚动到指定页
     
     - parameter collectionContentView: 集合内容视图
     - parameter pageIndex:             指定页
     */
    optional func collectionContentView(collectionContentView: CollectionContentView, didScrollToPage pageIndex: Int)
    
    /**
     集合内容视图拖动的进度
     
     - parameter collectionContentView: 集合内容视图
     - parameter oldIndex:              拖动的旧下标
     - parameter newIndex:              拖动的新下标
     - parameter progress:              拖动的进度
     */
    optional func collectionContentView(collectionContentView: CollectionContentView, scrollFrom oldIndex: Int, to newIndex: Int, progress: CGFloat)
    
    /**
     集合内容视图开始拖动
     
     - parameter collectionContentView: 集合内容视图
     */
    optional func collectionContentViewWillBeginDragging(collectionContentView: CollectionContentView)
}





/// 集合内容视图
public class CollectionContentView: UIView {
    public weak var delegate: CollectionContentViewDelegate?
    
    public var scrollEnabled: Bool = true {
        didSet {
            collectionView.scrollEnabled = scrollEnabled
        }
    }
    
    private var childVCs: [UIViewController]
    weak private var parentVC: UIViewController?
    
    private var cellID: String { return "SGSCollectionContentViewCell" }
    
    private var flowLayout: UICollectionViewFlowLayout!
    private var collectionView: PageView!
    
    private var beginDragOffsetX:CGFloat = 0.0
    
    
    //================================================================
    //  MARK: - Initializer
    //================================================================
    
    // 指定初始化方法
    public init<T: SequenceType where T.Generator.Element: UIViewController>(frame: CGRect, childViewControllers: T  , parentViewController: UIViewController) {
        
        self.childVCs = childViewControllers.map {$0}
        self.parentVC = parentViewController
        
        super.init(frame: frame)
        
        // 将自控制器添加到父控制器中
        self.childVCs.forEach {
            self.parentVC?.addChildViewController($0)
            $0.didMoveToParentViewController(self.parentVC)
        }
        
        setupUI()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
        guard index < childVCs.count else {
            return
        }
        
        let offset = CGPointMake(CGFloat(index) * collectionView.bounds.width, 0)
        setContentOffset(offset, animated: animated)
    }
    
    
    /**
     设置内容视图的偏移量
     
     - parameter offset:   偏移量
     - parameter animated: true（有动画效果），false（无动画效果）
     */
    public func setContentOffset(offset: CGPoint, animated: Bool) {
        collectionView.setContentOffset(offset, animated: animated)
        
        if !animated {
            scrollViewDidEndDecelerating(collectionView)
        }
    }
    
    
    /**
     重新设置视图控制器集
     
     - parameter childViewControllers: 视图控制器组
     - parameter parentViewController: 视图控制器组的父控制器
     */
    public func resetChildViewControllers(childViewControllers: [UIViewController], parentViewController: UIViewController) {
        childVCs.forEach { (childVC) in
            childVC.willMoveToParentViewController(nil)
            childVC.view.removeFromSuperview()
            childVC.removeFromParentViewController()
        }
        
        childVCs = childViewControllers
        parentVC = parentViewController
        
        childVCs.forEach {
            parentVC?.addChildViewController($0)
            $0.didMoveToParentViewController(parentVC)
        }
        
        collectionView.reloadData()
    }
    
    //================================================================
    //  MARK: - Private Functions
    //================================================================
    
    // 设置UI
    private func setupUI() {
        self.backgroundColor = UIColor.whiteColor()
        
        // FlowLayout
        flowLayout = UICollectionViewFlowLayout()
        flowLayout.minimumLineSpacing = 0
        flowLayout.minimumInteritemSpacing = 0
        flowLayout.itemSize = self.bounds.size
        flowLayout.scrollDirection = .Horizontal
        flowLayout.sectionInset = UIEdgeInsetsZero
        
        
        // collectionView
        collectionView = PageView(frame: self.bounds, collectionViewLayout: flowLayout)
        collectionView.scrollEnabled = self.scrollEnabled
        collectionView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        collectionView.collectionViewLayout = self.flowLayout
        collectionView.backgroundColor = UIColor.whiteColor()
        
        collectionView.bounces = false
        collectionView.pagingEnabled = true
        collectionView.showsHorizontalScrollIndicator = false
        
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.registerClass(UICollectionViewCell.self, forCellWithReuseIdentifier: cellID)
        self.addSubview(collectionView)
        
        
    }
}


// MARK: - UIScrollViewDelegate
extension CollectionContentView: UIScrollViewDelegate {
    
    // 滑动
    final public func scrollViewDidScroll(scrollView: UIScrollView) {
        let offsetX = scrollView.contentOffset.x
        
        let temp = offsetX / bounds.size.width
        var progress = temp - floor(temp)
        
        var oldIndex = 0
        var newIndex = 0
        
        if offsetX - beginDragOffsetX >= 0 { // 手指左滑, 滑块右移
            
            // 滚动开始和滚动完成的时候不要继续
            if progress == 0.0 { return }
            oldIndex = Int(floor(offsetX / bounds.size.width))
            newIndex = oldIndex + 1
            
            // 防止越界
            if newIndex >= childVCs.count { return }
            
        } else { // 手指右滑, 滑块左移
            newIndex = Int(floor(offsetX / bounds.size.width))
            oldIndex = newIndex + 1
            if oldIndex >= childVCs.count { return }
            
            progress = 1.0 - progress
        }
        
        delegate?.collectionContentView?(self, scrollFrom: oldIndex, to: newIndex, progress: progress)
    }
    
    // 开始拖拽
    final public func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        beginDragOffsetX = scrollView.contentOffset.x
        delegate?.collectionContentViewWillBeginDragging?(self)
    }
    
    // 手动滑动结束
    final public func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        let index = Int(floor(scrollView.contentOffset.x / scrollView.bounds.width))
        delegate?.collectionContentView?(self, didScrollToPage: index)
    }
    
    // 动画滑动结束
    final public func scrollViewDidEndScrollingAnimation(scrollView: UIScrollView) {
        let index = Int(floor(scrollView.contentOffset.x / scrollView.bounds.width))
        delegate?.collectionContentView?(self, didScrollToPage: index)
    }
    
}

// MARK: - UICollectionViewDataSource
extension CollectionContentView: UICollectionViewDataSource {
    
    // numberOfItems
    final public func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return childVCs.count
    }
    
    // cell
    final public func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(cellID, forIndexPath: indexPath)
        
        for subview in cell.contentView.subviews {
            subview.removeFromSuperview()
        }
        
        let vc = childVCs[indexPath.row]
        vc.view.frame = cell.contentView.bounds
        vc.view.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        cell.contentView.addSubview(vc.view)
        
        return cell
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension CollectionContentView: UICollectionViewDelegateFlowLayout {
}



private class PageView: UICollectionView {
    private override var frame: CGRect {
        willSet {
            if let flowLayout = self.collectionViewLayout as? UICollectionViewFlowLayout {
                flowLayout.itemSize = newValue.size
            }
        }
    }
}