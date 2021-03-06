//
//  LCRefresh.swift
//  LCRefresh
//
//  Created by 刘通超 on 16/8/2.
//  Copyright © 2016年 West. All rights reserved.
//

import UIKit

/** 动态绑定属性 **/
extension UIScrollView{
    /** 是否有观察者 **/
    var isHaveObserver: Bool {
        get{
            let result = getAssociated(key: "isHaveObserver")
            guard result != nil else {
                return false
            }
            return result as! Bool
        }
        set{
            setAssociated(key: "isHaveObserver", object: newValue)
        }
        
    }
    /** 当前刷新 header of footer **/
    var refreshObj: LCRefreshObject {
        get{
            let result = getAssociated(key: "refreshObj")
            guard result != nil else {
                return .none
            }
            return result as! LCRefreshObject
        }
        set{
            setAssociated(key: "refreshObj", object: newValue)
        }
        
    }
    /** 上次刷新对象 **/
    var lastRefreshObj: LCRefreshObject {
        get{
            let result = getAssociated(key: "lastRefreshObj")
            guard result != nil else {
                return .none
            }
            return result as! LCRefreshObject
        }
        set{
            setAssociated(key: "lastRefreshObj", object: newValue)
        }
        
    }
    
    /** header **/
    public var refreshHeader: LCBaseRefreshHeader? {
        get{
            let result = getAssociated(key: "refreshHeader") as? LCBaseRefreshHeader

            return result
        }
        set{
            guard newValue != nil else {
                print("header 为空")
                return
            }
            setAssociated(key: "refreshHeader", object: newValue!)
            
            let result = getAssociated(key: "refreshHeader") as? LCBaseRefreshHeader
            if result != nil {
                self.addSubview(result!)
            }
            //添加滑动监测
            addOffsetObserver()
            weak var weakSelf = self
            weakSelf!.panGestureRecognizer.addTarget(weakSelf!, action: #selector(UIScrollView.scrollViewDragging(_:)))
        }
        
    }
    /** footer **/
    public var refreshFooter: LCRefreshFooter? {
        get{
            let result = getAssociated(key: "refreshFooter") as? LCRefreshFooter

            return result
        }
        set{
            guard newValue != nil else {
                print("footer 为空")
                return
            }
            setAssociated(key: "refreshFooter", object: newValue!)

            let result = getAssociated(key: "refreshFooter") as? LCRefreshFooter
            if result != nil {
                self.addSubview(result!)
            }
            //添加滑动监测
            addOffsetObserver()
            weak var weakSelf = self
            weakSelf!.panGestureRecognizer.addTarget(weakSelf!, action: #selector(UIScrollView.scrollViewDragging(_:)))
        }
        
    }
}

extension UIScrollView{
    /** 动态绑定相关 **/
    
    fileprivate func getAssociated(key:String) -> Any?{
        let assKey = UnsafeRawPointer.init(bitPattern: key.hashValue)
        let result = objc_getAssociatedObject(self, assKey!)
        return result
    }
    
    fileprivate func setAssociated(key:String, object:Any){
        let assKey = UnsafeRawPointer.init(bitPattern: key.hashValue)
        objc_setAssociatedObject(self, assKey!, object, .OBJC_ASSOCIATION_RETAIN)
    }
}

extension UIScrollView{
    //MARK: /** Header 相关 */
    /** header 刷新状态 */
    public func isHeaderRefreshing() -> Bool {
        guard self.refreshHeader != nil else{
            return false
        }
        
        return self.refreshHeader!.refreshStatus == .refreshing ? true: false
    }
    
    /** header 结束刷新 */
    public func endHeaderRefreshing() {

        guard self.refreshHeader != nil else{
            return
        }
        weak var weakSelf = self

        //在nav下会产生top偏移
        var insetTop = self.contentInset.top
        if #available(iOS 11.0, *) {//适配iOS 11
            insetTop = self.adjustedContentInset.top
        }
        if self.lastRefreshObj == .header || self.lastRefreshObj == .none{
            weakSelf!.setContentOffset(CGPoint(x: 0, y: -insetTop), animated: true)
        }
        self.refreshHeader!.setRefreshStatus(status: .end)

        lastRefreshObj = .header
    }
    
    func addOffsetObserver() {
        if(!self.isHaveObserver){
            weak var weakSelf = self
            self.addObserver(weakSelf!, forKeyPath: "contentOffset", options: NSKeyValueObservingOptions.new, context: nil)
            isHaveObserver = true;
        }
    }
    
    public func removeOffsetObserver() {
        if self.isHaveObserver {
            weak var weakSelf = self
            self.removeObserver(weakSelf!, forKeyPath: "contentOffset", context: nil)
            isHaveObserver = false
        }
    }
}

extension UIScrollView{
    //MARK: /** Footer 相关 */
    /** footer 刷新状态 */
    public func isFooterRefreshing() -> Bool {
        guard self.refreshFooter != nil else{
            return false
        }
        
        return self.refreshFooter!.refreshStatus == .refreshing ? true: false
    }

    /** footer 结束刷新 */
    public func endFooterRefreshing() {
        weak var weakSelf = self
        guard self.refreshFooter != nil else{
            return
        }
        let size = weakSelf!.contentSize
        weakSelf!.contentSize = CGSize(width: size.width, height: size.height - LCRefreshFooterHeight)
        
        /** 1、数据没有充满屏幕
            2、数据已经填充满屏幕 **/
 
        if size.height < weakSelf!.bounds.size.height {
            weakSelf!.setContentOffset(CGPoint(x: 0, y: 0), animated: true)
        }else{
            let offSet = weakSelf!.contentSize.height-weakSelf!.bounds.size.height
            weakSelf!.setContentOffset(CGPoint(x: 0, y: offSet), animated: true)
        }
        self.refreshFooter!.setStatus(LCRefreshFooterStatus.normal)
        
        lastRefreshObj = .footer
    }
}

extension UIScrollView{
    //MARK: /** 数据加载完毕状态 **/
    public func setDataLoadover() {
        weak var weakSelf = self
        guard self.refreshFooter != nil else{
            return
        }
        let size = weakSelf!.contentSize
        self.refreshFooter!.frame = CGRect(x: LCRefreshFooterX, y: size.height, width: LCRefreshScreenWidth, height: LCRefreshFooterHeight)
        
//        weakSelf!.contentSize = CGSize(width: size.width, height: size.height + LCRefreshFooterHeight)
        self.refreshFooter!.setStatus(.loadover)
        
        if size.height < weakSelf!.bounds.size.height {
            self.refreshFooter!.isHidden = true
        }else{
            self.refreshFooter!.isHidden = false
        }
        
    }
    
    /** 初始化状态 **/
    public func resetDataLoad() {
        guard self.refreshFooter != nil else{
            return
        }
        self.refreshFooter!.isHidden = true
        self.refreshFooter!.setStatus(.normal)
    }
}

extension UIScrollView{
    //MARK: 滑动监测
    
    open override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "contentOffset" {
            let offSet = self.contentOffset.y
            let scrollHeight = self.bounds.size.height
            var inset = self.contentInset
            if #available(iOS 11.0, *) {//适配iOS 11
                inset = self.adjustedContentInset
            }
            
            print("offSet:\(offSet)")
            print("inset:\(inset)")

            var currentOffset = offSet + scrollHeight - inset.bottom
            let maximumOffset = self.contentSize.height
            
            /** 数据未充满屏幕的情况 **/
            if maximumOffset < scrollHeight {
                currentOffset = offSet + maximumOffset - inset.bottom
            }
            
            if offSet < 0 {
                /** 下拉刷新 */
                guard self.refreshHeader != nil else{
                    return
                }
                scrollHeader(offSet)
                self.refreshObj = LCRefreshObject.header
                
            }else if currentOffset - maximumOffset > 0 && maximumOffset >= scrollHeight {
                /** 上拉刷新 */
                guard self.refreshFooter != nil else{
                    return
                }
                guard self.refreshFooter!.refreshStatus != .loadover else {
                    return
                }

                scrollFooter(currentOffset - maximumOffset)
                self.refreshObj = .footer
                
            }else{
                weak var weakSelf = self
                self.refreshFooter!.frame = CGRect(x: LCRefreshFooterX, y: weakSelf!.contentSize.height, width: LCRefreshScreenWidth, height: LCRefreshFooterHeight)

                /** 无刷新对象 */
                self.refreshObj = .none
            }

        }
    }
    
    func scrollHeader(_ offSet: CGFloat) {//参数为负数
        guard self.refreshHeader != nil else{
            print("Header加载失败")
            return
        }
        guard self.refreshHeader!.refreshStatus != .refreshing else{
            return
        }
        //在nav下会产生top偏移
        var insetTop = self.contentInset.top
        if #available(iOS 11.0, *) {//适配iOS 11
            insetTop = self.adjustedContentInset.top
        }
        if offSet + insetTop < -LCRefreshHeaderHeight {
            self.refreshHeader!.setRefreshStatus(status: .waitRefresh)
        }else if offSet + insetTop == 0 {
            
            self.refreshHeader!.setRefreshStatus(status: .normal)

        }else {
            guard self.refreshHeader!.refreshStatus != .end else{
                return
            }
            self.refreshHeader!.setRefreshStatus(status: .normal)
        }

    }
    
    func scrollFooter(_ offSet: CGFloat) {
        weak var weakSelf = self
        guard self.refreshFooter != nil else{
            print("Footer加载失败")
            return
        }
        guard self.refreshFooter!.refreshStatus != .refreshing || self.refreshFooter!.refreshStatus != .loadover else{
            return
        }
        
        self.refreshFooter!.isHidden = false
        self.refreshFooter!.frame = CGRect(x: LCRefreshFooterX, y: weakSelf!.contentSize.height, width: LCRefreshScreenWidth, height: LCRefreshFooterHeight)
        
        if offSet > LCRefreshFooterHeight {
            self.refreshFooter!.setStatus(.waitRefresh)
        }else{
            self.refreshFooter!.setStatus(.normal)
        }

    }
    
    /** 拖拽相关 */
    @objc func scrollViewDragging(_ pan: UIPanGestureRecognizer){
        if pan.state == .ended{
            if self.refreshObj == .header {
                draggHeader()

            }else if self.refreshObj == .footer{
                draggFooter()
            }
        }
    }
    
    func draggHeader(){
        
        weak var weakSelf = self
        guard self.refreshHeader != nil else{
            print("Header加载失败")
            return
        }
        //在nav下会产生top偏移
        var insetTop = self.contentInset.top
        if #available(iOS 11.0, *) {//适配iOS 11
            insetTop = self.adjustedContentInset.top
        }
        
        if self.refreshHeader!.refreshStatus == .waitRefresh {
            weakSelf!.setContentOffset(CGPoint(x: 0, y: -(LCRefreshHeaderHeight+insetTop)), animated: true)
            self.refreshHeader!.setRefreshStatus(status: .refreshing)
            if self.refreshHeader!.refreshBlock != nil {
                self.refreshHeader!.refreshBlock!()
            }
        }
    }
    
    func draggFooter() {
        weak var weakSelf = self
        guard self.refreshFooter != nil else{
            print("Footer加载失败")
            return
        }
        if self.refreshFooter!.refreshStatus == .waitRefresh {
            /** 设置scroll的contentsize 以及滑动offset **/
            let size = weakSelf!.contentSize
            weakSelf!.contentSize = CGSize(width: size.width, height: size.height + LCRefreshFooterHeight)
            /** 1、数据没有充满屏幕
             2、数据已经填充满屏幕
             **/
            if size.height < weakSelf!.bounds.size.height {
                weakSelf!.setContentOffset(CGPoint(x: 0, y: 0), animated: true)
            }else{
                let offSet = weakSelf!.contentSize.height-weakSelf!.bounds.size.height
                weakSelf!.setContentOffset(CGPoint(x: 0, y: offSet), animated: true)
            }
            /** 切换状态 **/
            self.refreshFooter!.setStatus(.refreshing)
            
            if self.refreshFooter!.refreshBlock != nil {
                self.refreshFooter!.refreshBlock!()
            }
        }
    }
    
}

