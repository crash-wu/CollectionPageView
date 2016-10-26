//
//  CollectionSegmentView.swift
//  imapMobile
//
//  Created by Lee on 16/6/3.
//  Copyright © 2016年 crash. All rights reserved.
//

import UIKit

/// 集合标签视图代理
@objc public protocol CollectionSegmentViewDelegate: class {
    
    /**
     标签点击代理方法
     
     - parameter collectionSegmentView: 集合标签视图
     - parameter titleLabel:            点击的标题标签
     - parameter index:                 标签下标
     */
    optional func collectionSegmentView(collectionSegmentView: CollectionSegmentView, didSelectedTitle titleLabel: UILabel, index: Int)
}



/// 集合标签视图，竖屏适用，横屏效果不好
public class CollectionSegmentView: UIView {
    // 代理
    public weak var delegate: CollectionSegmentViewDelegate?
    
    public var style: CollectionSegmentStyle  // 样式
    
    // 标题是否可选
    public var titleSelectable = true
    
    // 背景图片
    public var backgroundImage: UIImage? {
        didSet {
            self.layer.contents = backgroundImage?.CGImage
        }
    }
    
    // 标题数组
    public var titles: [String] {
        didSet {
            // 清空之前的状态
            contentView.subviews.forEach { $0.removeFromSuperview() }
            cursor = nil
            titleLabels.removeAll()
            titleWidths.removeAll()
            separators.removeAll()
            
            // 重置状态
            currentIndex = 0
            oldIndex = 0
            setupUI()
            adjustUIWithAnimated(true)
            titleSelectable = true
        }
    }
    
    
    private var cursor: UIView?                // 标记符号（目前暂实现滚动条）
    private var contentView: UIScrollView!     // 内容视图
    private var titleLabels = [UILabel]()      // 标签
    private var titleWidths = [CGFloat]()      // 标题宽度
    private var separators  = [UIView]()       // 分割线
    private var currentIndex: Int = 0          // 当前标签下标
    private var oldIndex: Int = 0              // 上一次选择的标签下标
    
    private var currentWidth: CGFloat { return self.bounds.width }   // 当前视图宽度
    private var currentHeight: CGFloat { return self.bounds.height } // 当前视图高度
    private var titleLabelBasicTag: Int { return 4000 }   // 标签基础tag值
    private var triangleWidth: CGFloat { return 5.0 }     // 三角游标宽度
    private var triangleHeight: CGFloat { return 5.0 }    // 三角游标高度
    private var maskCursorMargin: CGFloat = 0.0  // 掩膜样式的左右延伸距离
    
    private var enableScroll = false
    
    // 标题默认的颜色RGBA值
    private lazy var normalRGBA: (r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat) = { [unowned self] in
        return self.rgbaWithColor(self.style.normalTitleColor) ?? (0, 0, 0, 0)
    }()
    
    // 标题选中时的颜色RGBA值
    private lazy var selectedRGBA: (r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat) = { [unowned self] in
        return self.rgbaWithColor(self.style.selectedTitleColor) ?? (0, 0, 0, 0)
    }()
    
    // 文字颜色渐变差值
    private lazy var rgbaDelta: (deltaR: CGFloat, deltaG: CGFloat, deltaB: CGFloat, deltaA: CGFloat) = {
        [unowned self] in
        
        guard let normalRGBA = self.rgbaWithColor(self.style.normalTitleColor),
            let selectedRGBA = self.rgbaWithColor(self.style.selectedTitleColor) else {
                return (0, 0, 0, 0)
        }
        
        let deltaR = normalRGBA.r - selectedRGBA.r
        let deltaG = normalRGBA.g - selectedRGBA.g
        let deltaB = normalRGBA.b - selectedRGBA.b
        let deltaA = normalRGBA.a - selectedRGBA.a
        
        return (deltaR, deltaG, deltaB, deltaA)
    }()
    
    
    //================================================================
    //  MARK: - Initializer
    //================================================================
    
    // 指定初始化方法
    public init(frame: CGRect, style: CollectionSegmentStyle = CollectionSegmentStyle(), titles: [String]) {
        
        self.style = style
        self.titles = titles
        
        super.init(frame: frame)
        
        setupUI()
    }
    
    public convenience init() { self.init(frame: CGRectZero, titles: []) }
    required public init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    
    //================================================================
    //  MARK: - Override
    //================================================================
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        
        setupTitleLabelsPosition()
        setupCursor()
    }
    
    //================================================================
    //  MARK: - Public Functions
    //================================================================
    
    /**
     根据标题和样式计算合适的大小
     
     - parameter titles: 标题
     - parameter style:  样式
     
     - returns: 合适的大小
     */
    public static func fitSizeWithTitles(titles: [String], style: CollectionSegmentStyle) -> CGSize {
        var segmentWidth = titles.reduce(0) { (width, title) -> CGFloat in
            let str = title as NSString
            let strSize = str.sizeWithAttributes([NSFontAttributeName: style.titleFont])
            
            return width + strSize.width + style.titleMargin
        }
        
        segmentWidth += style.titleMargin
        segmentWidth += CGFloat(titles.count)
        
        return CGSize(width: segmentWidth, height: style.segmentHeight)
    }
    
    /**
     根据下标选择标题
     
     - parameter index:    下标
     - parameter animated: true（有滚动动画），false（没有动画）
     */
    public func selectTitleWithIndex(index: Int, animated: Bool) {
        guard index >= 0 && index < titles.count else {
            return
        }
        
        if titleSelectable {
            currentIndex = index
            adjustUIWithAnimated(animated)
        }
    }
    
    
    /**
     根据进度调整UI
     
     - parameter progress: 进度（0.0~1.0）
     - parameter oldIndex: 旧下标
     - parameter newIndex: 新下标
     */
    public func adjustUIWithProgress(progress: CGFloat, oldIndex: Int, newIndex: Int) {
        
        let oldLabel = titleLabels[oldIndex]
        let currentLabel = titleLabels[newIndex]
        
        // 需要改变的距离 和 宽度
        let xDistance = currentLabel.frame.origin.x - oldLabel.frame.origin.x
        let wDistance = currentLabel.frame.size.width - oldLabel.frame.size.width
        
        let cursorX = oldLabel.frame.origin.x + xDistance * progress
        let cursorW = oldLabel.frame.size.width + wDistance * progress
        
        adjustCursor(x: cursorX, width: cursorW)
        
        // 文字颜色渐变
        if style.colorGradient {
            
            oldLabel.textColor = UIColor(red:   selectedRGBA.r + rgbaDelta.deltaR * progress,
                                         green: selectedRGBA.g + rgbaDelta.deltaG * progress,
                                         blue:  selectedRGBA.b + rgbaDelta.deltaB * progress,
                                         alpha: selectedRGBA.a + rgbaDelta.deltaA * progress)
            
            currentLabel.textColor = UIColor(red:   normalRGBA.r - rgbaDelta.deltaR * progress,
                                             green: normalRGBA.g - rgbaDelta.deltaG * progress,
                                             blue:  normalRGBA.b - rgbaDelta.deltaB * progress,
                                             alpha: normalRGBA.a - rgbaDelta.deltaA * progress)
        }
        
        self.oldIndex = oldIndex
        self.currentIndex = newIndex
    }
    
    /**
     调整标题位置
     
     - parameter index:    标题位置下标
     - parameter animated: true（有滚动动画），false（没有动画）
     */
    public func adjustTitleOffsetToCurrentIndex(index: Int, animated: Bool) {
        let label = titleLabels[index]
        
        // 确保当前的标签过半的时候才可能发生位移（可让标题居中）
        var contentOffsetX = label.center.x - (currentWidth / 2)
        
        // 确保在能显示最后一个标签时不再发生位移
        var maxOffsetX = contentView.contentSize.width - currentWidth
        
        if contentOffsetX < 0 { contentOffsetX = 0 }
        if maxOffsetX < 0 { maxOffsetX = 0 }
        if contentOffsetX > maxOffsetX { contentOffsetX = maxOffsetX }
        
        // 设置位移
        contentView.setContentOffset(CGPointMake(contentOffsetX, 0.0), animated: animated)
        
        titleLabels.forEach{$0.textColor = style.normalTitleColor}
        titleLabels[index].textColor = style.selectedTitleColor
    }
    
    //================================================================
    //  MARK: - Actions
    //================================================================
    
    // 标签点击事件
    @objc private func titleLabelDidTapped(tap: UITapGestureRecognizer) {
        guard let tappedLabel =  tap.view else {
            return
        }
        
        if titleSelectable {
            let index = tappedLabel.tag - titleLabelBasicTag
            
            // 确保下标合法
            switch index {
            case 0..<titles.count:
                currentIndex = index
                adjustUIWithAnimated(true)
            default:
                break
            }
        }
    }
    
    //================================================================
    //  MARK: - Private Functions
    //================================================================
    
    // 设置UI
    private func setupUI() {
        self.backgroundColor = style.segmentBackgroundColor
        
        setupContentView()
        setupTitleLabels()
        setupCursor()
        
    }
    
    // 设置内容视图
    private func setupContentView() {
        if contentView == nil {
            contentView = UIScrollView(frame: self.bounds)
            contentView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
            contentView.showsHorizontalScrollIndicator = false
            contentView.bounces = true
            contentView.pagingEnabled = false
            self.addSubview(contentView)
        }
    }
    
    // 设置标题标签
    private func setupTitleLabels() {
        // 当标题不为空 且 标签数组是空的时候才往下执行
        guard !titles.isEmpty && titleLabels.isEmpty else {
            return
        }
        
        for (index, title) in titles.enumerate() {
            let label = UILabel()
            label.tag = titleLabelBasicTag + index
            label.text = title
            label.textColor = style.normalTitleColor
            label.textAlignment = .Center
            label.font = style.titleFont
            
            label.userInteractionEnabled = true
            label.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(titleLabelDidTapped(_:))))
            
            titleLabels.append(label)
            contentView.addSubview(label)
            
            // 保存标题的大小
            let textSize = NSString(string: title).sizeWithAttributes([NSFontAttributeName: style.titleFont])
            titleWidths.append(textSize.width)
        }
        
        if style.showSeparator {
            let separatorCount = titleLabels.count - 1
            for _ in 0..<separatorCount {
                let separator = UIView()
                separator.backgroundColor = style.separatorColor
                
                separators.append(separator)
                contentView.addSubview(separator)
            }
        }
        
        setupTitleLabelsPosition()
        
        
        // 设置初始标题的颜色
        titleLabels.first?.textColor = style.selectedTitleColor
    }
    
    // 设置各个标签的位置
    private func setupTitleLabelsPosition() {
        var labelX: CGFloat = 0.0
        let labelY: CGFloat = 0.0
        var labelWidth: CGFloat = 0.0
        var labelHeight: CGFloat = 0.0
        
        switch style.cursorType {
        case .Line:
            let cursorHeight = style.cursorHeight < currentHeight ? style.cursorHeight : currentHeight / 3
            labelHeight = currentHeight - cursorHeight
        case .Triangle:
            labelHeight = currentHeight - triangleHeight
        default:
            labelHeight = currentHeight
        }
        
        func setupSeparatorPosition(index: Int) -> CGFloat {
            guard style.showSeparator && index < separators.count else {
                return 0
            }
            
            let sX = labelX
            let sY = (labelHeight * 0.4) / 2
            let sWidth = CGFloat(1)
            let sHeight = labelHeight * 0.6
            
            let separator = separators[index]
            separator.frame = CGRectMake(sX, sY, sWidth, sHeight)
            
            return sWidth
            
        }
        
        if titleWidths.count == titleLabels.count {
            
            var totalWidth = titleWidths.reduce(CGFloat(0)) { return $0.0 + $0.1 + style.titleMargin }
            totalWidth += style.titleMargin
            
            enableScroll = totalWidth >= currentWidth
            
            if enableScroll || !style.divideWhenSegmentSizeGreatTitles {
                // 根据标题的顺序以及大小设置各个标签的位置
                
                maskCursorMargin = style.titleMargin / 2
                labelX = style.titleMargin
                
                
                for (index, label) in titleLabels.enumerate() {
                    labelWidth = titleWidths[index]
                    label.frame = CGRectMake(labelX, labelY, labelWidth, labelHeight)
                    labelX += labelWidth + (style.titleMargin / 2)
                    
                    labelX += setupSeparatorPosition(index)
                    
                    labelX += (style.titleMargin / 2)
                }
            } else {
                // 平分宽度
                
                maskCursorMargin = 0.0
                labelWidth = currentWidth / CGFloat(titles.count)
                
                for (index, label) in titleLabels.enumerate() {
                    label.frame = CGRectMake(labelX, labelY, labelWidth, labelHeight)
                    labelX += labelWidth
                    
                    labelX += setupSeparatorPosition(index)
                }
            }
        }
        
        updateContentViewContentSize()
    }
    
    // 设置标记符号
    private func setupCursor() {
        guard currentIndex < titleLabels.count && style.cursorType != .None  else {
            return
        }
        
        if cursor == nil {
            cursor = UIView()
            contentView.addSubview(cursor!)
            contentView.sendSubviewToBack(cursor!)
        }
        
        let label = titleLabels[currentIndex]
        
        func frameAndCornerRadius() -> (CGRect, CGFloat) {
            let width = label.frame.size.width + (2 * maskCursorMargin)
            var height = style.titleFont.fontDescriptor().objectForKey("NSFontSizeAttribute") as? CGFloat
            
            if height == nil {
                height = 14.0
            } else {
                height! += 10.0
            }
            
            let x = label.frame.origin.x - maskCursorMargin
            let y = (currentHeight - height!) / 2
            
            let cornerRadius = style.cursorCornerRadius < 0.0 ? height! / 2 : style.cursorCornerRadius
            
            return (CGRectMake(x, y, width, height!), cornerRadius)
        }
        
        // TODO: 实现更多标记符号样式
        switch style.cursorType {
            
        case .Line:
            let width = label.frame.size.width
            let height = style.cursorHeight < currentHeight ? style.cursorHeight : currentHeight / 3
            let x = label.frame.origin.x
            let y = currentHeight - height
            
            
            cursor?.frame = CGRectMake(x, y, width, height)
            cursor!.backgroundColor = style.cursorColor
            
        case .Border:
            let (frame, cornerRadius) = frameAndCornerRadius()
            
            cursor?.frame = frame
            cursor!.backgroundColor = UIColor.clearColor()
            cursor?.layer.borderWidth = 1.0
            cursor?.layer.borderColor = style.cursorColor.CGColor
            cursor!.layer.cornerRadius = cornerRadius
            cursor!.layer.masksToBounds = true
            
        case .Mask:
            let (frame, cornerRadius) = frameAndCornerRadius()
            
            cursor?.frame = frame
            cursor!.backgroundColor = style.cursorColor
            cursor!.layer.cornerRadius = cornerRadius
            cursor!.layer.masksToBounds = true
            
        default: break
        }
    }
    
    
    
    // 更新内容视图大小
    private func updateContentViewContentSize() {
        if enableScroll {
            if let lastTitleLabel = titleLabels.last {
                contentView.contentSize = CGSizeMake(CGRectGetMaxX(lastTitleLabel.frame) + self.style.titleMargin, 0.0)
            }
        } else {
            contentView.contentSize = contentView.bounds.size
        }
    }
    
    // 调整UI
    private func adjustUIWithAnimated(animated: Bool) {
        // 当前页是新的标签时才调整UI，否则什么都不做
        guard currentIndex != oldIndex else {
            return
        }
        
        // 确保下标合法
        guard oldIndex < titleLabels.count && currentIndex < titleLabels.count else {
            return
        }
        
        // 调整状态中禁止触发用户交互事件
        titleSelectable = false
        
        // 不使用 userInteractionEnabled 是因为self禁止交互后
        // 交互会穿透 self ，让下一层生效
        //        self.userInteractionEnabled = false
        
        let oldLabel = titleLabels[oldIndex]
        let currentLabel = titleLabels[currentIndex]
        
        adjustTitleOffsetToCurrentIndex(currentIndex, animated: animated)
        
        let animatedDuration = animated ? 0.3 : 0.0
        
        // 渐变动画
        UIView.animateWithDuration(animatedDuration, animations: { [weak self] in
            // 调整游标
            self?.adjustCursor(x: currentLabel.frame.origin.x, width: currentLabel.frame.width)
            
        }) { [weak self] (_) in
            // 渐变动画执行完毕
            guard let strongSelf = self else { return }
            
            oldLabel.textColor = strongSelf.style.normalTitleColor
            currentLabel.textColor = strongSelf.style.selectedTitleColor
            
            // 可以触发用户交互事件
            strongSelf.titleSelectable = true
            strongSelf.oldIndex = strongSelf.currentIndex
            strongSelf.delegate?.collectionSegmentView?(strongSelf, didSelectedTitle: currentLabel, index: strongSelf.currentIndex)
        }
        
    }
    
    // 调整游标
    private func adjustCursor(x x: CGFloat, width: CGFloat) {
        guard let symbol = cursor else {
            return
        }
        
        // TODO: 更多样式
        switch style.cursorType {
        case .None, .Triangle:
            break
        case .Line:
            let frame = CGRectMake(x, symbol.frame.origin.y, width, symbol.frame.height)
            symbol.frame = frame
        case .Border, .Mask:
            let frame = CGRectMake(x - maskCursorMargin, symbol.frame.origin.y, width + (2 * maskCursorMargin), symbol.frame.height)
            symbol.frame = frame
        }
    }
    
    // 获取颜色的RGBA值
    private func rgbaWithColor(color: UIColor) -> (r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat)? {
        var redComponent: CGFloat   = 0
        var greenComponent: CGFloat = 0
        var blueComponent: CGFloat  = 0
        var alphaComponent: CGFloat = 0
        
        let success = color.getRed(&redComponent, green: &greenComponent, blue: &blueComponent, alpha: &alphaComponent)
        
        if success {
            return (redComponent, greenComponent, blueComponent, alphaComponent)
        }
        
        return nil
    }
}