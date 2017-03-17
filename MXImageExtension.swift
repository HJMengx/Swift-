//
//  MXImageExtension.swift
//  MXRefresh
//
//  Created by mx on 2017/3/17.
//  Copyright © 2017年 mengx. All rights reserved.
//

import UIKit
import ImageIO

struct MXImage {
    var width : Int = 0
    var height : Int = 0
    var images : [UIImage]!
}

struct MXImageKey {
    static let key = UnsafeRawPointer.init(bitPattern: "mxImage".hashValue)
}

//添加设置动态图的方法
extension UIImageView{
    
    var mxImage : MXImage? {
        get{
            return objc_getAssociatedObject(self, MXImageKey.key) as? MXImage
        }
        set{
            if let newValue = newValue {
                objc_setAssociatedObject(self,MXImageKey.key, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
            }
        }
    }
    
    func mx_setGifImage(with named : String){
        //获取到数组，可以做动画了
        let bundlePath = Bundle.main.path(forResource: "MXRefresh", ofType: "bundle")!
        
        let imagesPath = bundlePath.appendingFormat("/%@/%@", "Images",named)
        
        self.mx_getImage(with: URL.init(string: String.init(format: "file://%@", imagesPath))!)
        //时间人为定义
        self.animationImages = self.mxImage?.images
    }
    
    //因为是GIF图，所以大小都是一样的
    private func mx_getImage(with url : URL){
        
        let source = CGImageSourceCreateWithURL(url as CFURL, nil)
        
        guard source != nil else {
            return
        }
        
        let count = CGImageSourceGetCount(source!)
        
        var images = MXImage()
        
        var image : [UIImage] = [UIImage]()
        
        for index in 0..<count {
            let cgImage = CGImageSourceCreateImageAtIndex(source!, index, nil)
            
            if cgImage != nil {
                
                let width = cgImage!.width
                
                let height = cgImage!.height
                
                //可能是换新的图片
                if images.width == 0 {
                    
                    images.width = width
                    images.height = height
                }
                
                image.append(UIImage.init(cgImage: cgImage!))
                
            }
        }
        //获取数组
        images.images = image
        
        self.mxImage = images
    }
}
