//
//  CollectionSegmentStyle.swift
//  imapMobile
//
//  Created by Lee on 16/6/3.
//  Copyright © 2016年 crash. All rights reserved.
//

import UIKit



/**
 标签的游标样式
 
 - None:     不使用游标
 - Line:     滚动条样式
 - Triangle: 三角标样式（暂不支持）
 - Border:   外边框样式
 - Mask:     掩膜样式
 */
public enum CollectionSegmentCursorType {
    case None, Line, Triangle, Border, Mask
}


/**
 *  标签栏样式
 */
public struct CollectionSegmentStyle {
    // 标签栏默认高度
    public var segmentHeight: CGFloat = 44.0
    
    // 标签栏默认背景颜色
    public var segmentBackgroundColor: UIColor = UIColor.whiteColor()
    
    // 是否让标题颜色渐变
    public var colorGradient: Bool = true
    
    // 默认标题颜色
    public var normalTitleColor: UIColor = UIColor.grayColor()
    
    // 选中时的标题颜色
    public var selectedTitleColor: UIColor = UIColor.redColor()
    
    // 标题字体
    public var titleFont: UIFont = UIFont.systemFontOfSize(17.0)
    
    // 标签间距
    public var titleMargin: CGFloat = 10.0
    
    // 显示分割线
    public var showSeparator: Bool = true
    
    // 分割线颜色
    public var separatorColor: UIColor = UIColor.lightGrayColor()
    
    // 当标签栏的尺寸比所有标题都大时，平分各标签的宽度
    public var divideWhenSegmentSizeGreatTitles: Bool = true
    
    // 标签的游标样式
    public var cursorType: CollectionSegmentCursorType = .Line
    
    // 游标高度，只对滚动条样式有效
    public var cursorHeight: CGFloat = 2.0
    
    // 游标圆角，只对外边框和掩膜样式有效，负数时表示自适应
    public var cursorCornerRadius: CGFloat = -1.0
    
    // 游标颜色
    public var cursorColor: UIColor = UIColor.cyanColor()
}
