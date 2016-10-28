//
//  MXBarCodeUtils.swift
//  MXBarCodeUtils
//
//  Created by mx on 2016/10/28.
//  Copyright © 2016年 mengx. All rights reserved.
//

import UIKit
import AVFoundation
import CoreImage

let ScreenWidth = UIScreen.main.bounds.width

let ScreenHeight = UIScreen.main.bounds.height

let IconSize : CGFloat = 15

let LouKongRect = CGRect.init(x: ScreenWidth / 2 - ScreenWidth / 3,y: ScreenHeight / 2 - ScreenWidth / 3,width: ScreenWidth / 3 * 2,height: ScreenWidth / 3 * 2)

let LineLength : CGFloat = 10

class MXBarCodeUtils: NSObject,AVCaptureMetadataOutputObjectsDelegate{
    
    //整个显示的View
    private var scanView : UIView = UIView.init(frame: UIScreen.main.bounds)
    
    private var imageInput : AVCaptureDeviceInput!
    
    private var metaDataOutput : AVCaptureMetadataOutput!
    
    private var videoSession : AVCaptureSession!
    
    private var preLayer : AVCaptureVideoPreviewLayer!
    
    private var scanBorderLayer : CAShapeLayer!
    //遮板
    private var maskView : UIView = UIView.init(frame: UIScreen.main.bounds)

    private static var instance : MXBarCodeUtils = MXBarCodeUtils.init()
    
    private var scanLayer : CAShapeLayer!
    
    private var scanBarLayer : CAShapeLayer!

    private static var isFirst : Bool = true
    
    //设置了之后就会在扫描到数据的时候调用,在主线程中执行
    var completion : ((_ ScanValue : String) -> Void)?
    //私有化构造方法
    private override init(){
        super.init()
    }
    
    class func shareInstance()->MXBarCodeUtils{
        return instance;
    }
    
    //MARK: scan code
    func StartScanBarCode(){
        let KeyWindow = UIApplication.shared.keyWindow
        
        if KeyWindow == nil {
            return
        }
        
        
        self.metaDataOutput = AVCaptureMetadataOutput.init()
        do{
            self.imageInput = try AVCaptureDeviceInput.init(device: AVCaptureDevice.defaultDevice   (withMediaType: AVMediaTypeVideo))
        }catch{
            print("捕获到了异常")
            //提示信息
            return
        }
        
        self.metaDataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.global())
   
        self.videoSession = AVCaptureSession.init()
        
        if self.videoSession.canAddInput(self.imageInput){
            self.videoSession.addInput(self.imageInput)
        }
        
        if self.videoSession.canAddOutput(self.metaDataOutput){
            self.videoSession.addOutput(self.metaDataOutput)
        }
        
        //设置读取类型
        self.metaDataOutput.metadataObjectTypes = [AVMetadataObjectTypeQRCode,
                                           AVMetadataObjectTypeEAN13Code,
                                           AVMetadataObjectTypeEAN8Code,
                                           AVMetadataObjectTypeCode128Code]
        
        self.preLayer = AVCaptureVideoPreviewLayer.init(session: self.videoSession)
        
        self.preLayer.videoGravity = AVLayerVideoGravityResizeAspectFill//自适应
        
        //屏幕正中间
        self.preLayer.frame = self.scanView.bounds
        
        self.scanView.layer.addSublayer(self.preLayer)
        
        self.InitMask()
        
        self.AddScanBar()
        
        //或者这个页面使用UIViewController
        //添加到窗口
        KeyWindow!.addSubview(self.scanView)
        
        self.videoSession.startRunning()
    }
    //MARK:绘制扫描线条
    func AddScanBar(){
        self.scanLayer = CAShapeLayer.init()
        self.scanBarLayer = CAShapeLayer.init()
        //设置为这个范围
        self.scanLayer.frame = LouKongRect
        self.scanBarLayer.frame = LouKongRect
        //四个角
        let aroundPath = UIBezierPath.init()
        //左上角
        aroundPath.move(to: CGPoint.init(x: 0, y: LineLength))
        aroundPath.addLine(to: CGPoint.init(x: 0, y: 0))
        aroundPath.addLine(to: CGPoint.init(x: LineLength, y: 0))
        
        //右上角
        aroundPath.move(to: CGPoint.init(x: LouKongRect.size.width - LineLength, y: 0))
        aroundPath.addLine(to: CGPoint.init(x: LouKongRect.size.width, y: 0))
        aroundPath.addLine(to: CGPoint.init(x: LouKongRect.size.width, y: LineLength))
        
        //右下角
        aroundPath.move(to: CGPoint.init(x: LouKongRect.size.width - LineLength, y: LouKongRect.size.height))
        aroundPath.addLine(to: CGPoint.init(x: LouKongRect.size.width, y: LouKongRect.size.height))
        aroundPath.addLine(to: CGPoint.init(x: LouKongRect.size.width , y: LouKongRect.size.height - LineLength))
        
        //左下角
        aroundPath.move(to: CGPoint.init(x: 0, y: LouKongRect.size.height - LineLength))
        aroundPath.addLine(to: CGPoint.init(x: 0, y: LouKongRect.size.height))
        aroundPath.addLine(to: CGPoint.init(x: LineLength, y: LouKongRect.size.height))
        
        self.scanLayer.path = aroundPath.cgPath
        self.scanLayer.strokeColor = UIColor.green.cgColor
        
        self.scanLayer.lineWidth = 3
        //中间线条
        let movePath = UIBezierPath.init()
        
        movePath.move(to: CGPoint.init(x: 0, y: LineLength / 2))
        
        movePath.addLine(to: CGPoint.init(x : LouKongRect.size.width,y : LineLength / 2))
        
        self.scanBarLayer.path = movePath.cgPath
        
        self.scanBarLayer.strokeColor = UIColor.green.cgColor
        
        self.scanBarLayer.lineWidth = 3
        //中间线条动画
        let moveAnimation = CABasicAnimation.init(keyPath: "position.y")
        moveAnimation.toValue = LouKongRect.size.height + self.scanBarLayer.position.y - LineLength / 2
        moveAnimation.fromValue = self.scanBarLayer.position.y
        //LouKongRect.height is 250.0 and position.y is 333.5
        moveAnimation.autoreverses = false
        moveAnimation.repeatCount = MAXFLOAT
        moveAnimation.duration = 2
        moveAnimation.fillMode = kCAFillModeForwards
        
        self.scanBarLayer.add(moveAnimation, forKey: "Move")
        
        if MXBarCodeUtils.isFirst{
            self.scanView.layer.addSublayer(self.scanLayer)
        }
        
        MXBarCodeUtils.isFirst = false
        
        self.scanView.layer.addSublayer(self.scanBarLayer)
    }
    
    //MARK:设置遮板
    private func InitMask(){
        self.maskView.alpha = 0.6
        
        self.maskView.backgroundColor = UIColor.black
        
        let maskLayer = CAShapeLayer.init()
        
        let  layerPath = UIBezierPath.init(rect : LouKongRect)
        
        let mainPath = UIBezierPath.init(rect: UIScreen.main.bounds)

        mainPath.append(layerPath.reversing())
        
        maskLayer.path = mainPath.cgPath
        
        self.maskView.layer.mask = maskLayer
        
        self.scanView.addSubview(self.maskView)
    }
    
    //MARK: delegate
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [Any]!, from connection: AVCaptureConnection!) {
        if(metadataObjects.count > 0){
            //停止扫描
            self.videoSession.stopRunning()
            //去除扫描条
            self.scanBarLayer.removeFromSuperlayer()
            self.scanBarLayer.removeAnimation(forKey: "Move")
            //然后分析数据
            let metaData = metadataObjects[0] as! AVMetadataMachineReadableCodeObject
            //执行回调
            if self.completion != nil {
                DispatchQueue.main.async(execute: {
                    self.completion!(metaData.stringValue)
                })
            }
        }
    }
    
    //MARK: generate Code
    func GenerateQRCode(message : String,middleIcon : UIImage?,WH Size : CGFloat)->UIImage?{
        //二维码生成器
        let QRCodeFilter = CIFilter.init(name: "CIQRCodeGenerator")
        
        if QRCodeFilter == nil{
            return nil
        }
        //默认设置
        QRCodeFilter!.setDefaults()
        
        //设置信息
        QRCodeFilter!.setValue(message.data(using: String.Encoding.utf8), forKey: "inputMessage")
        //设置高检错率
        QRCodeFilter!.setValue("H", forKey: "inputCorrectionLevel")
        
        //输出图片
        let blurImage = QRCodeFilter!.outputImage!
        
        //获取高清图片
        let resultImage = self.TransFromHighQuantityImage(QRImage: blurImage, ImageWidthAndHeight: Size)
        
        if middleIcon != nil{
            //添加小图标
            return self.AppendIconWithHighImage(HighImage: resultImage, Icon: middleIcon!)
        }
        
        return resultImage
    }
    
    //MARK: detect qrcode
    func DetectQRCode(from image : UIImage,completion : (([String]?)->Void))->UIImage?{
        let ciContext = CIContext.init(options: nil)
        
        let ciDetector = CIDetector.init(ofType: CIDetectorTypeQRCode, context: ciContext, options: nil)!
        
        let ciImage = CIImage.init(image: image)
        
        if ciImage == nil{
            return nil
        }
        
        let features = ciDetector.features(in: ciImage!)
        
        var resultString = [String]()
        
        var returnImage : UIImage!
        
        for feature in features{
            //提供信息
            resultString.append((feature as! CIQRCodeFeature).messageString!)
            
            returnImage = self.DrawFrameWithInterstArea(feature: feature, sourceImage: image)
        }
        //回调方法
        DispatchQueue.main.sync {
            completion(resultString)
        }
        
        return returnImage
    }
    //MARK: 绘制边框
    private func DrawFrameWithInterstArea(feature : CIFeature,sourceImage : UIImage)->UIImage{
        //特征是以左下角为0，0原点的
        let featureBounds = feature.bounds
        
        let imageSize = sourceImage.size
        
        UIGraphicsBeginImageContext(imageSize)
        
        sourceImage.draw(in: CGRect.init(x: 0, y: 0, width: imageSize.width, height: imageSize.height))
        
        let cgContext = UIGraphicsGetCurrentContext()!
        // 3.反转上下文坐标系
        cgContext.scaleBy(x: 1, y: -1)
        
        cgContext.translateBy(x: 0, y: -imageSize.height)
        
        //绘制边框
        let borderPath = UIBezierPath.init(rect: featureBounds)
        
        borderPath.lineWidth = 8
        //设置颜色
        UIColor.green.setStroke()
        
        borderPath.stroke()
        
        let borderImage = UIGraphicsGetImageFromCurrentImageContext()!
        
        UIGraphicsEndImageContext()
        
        return borderImage
    }
    
    //MARK: generate high quantiry Image
    private func TransFromHighQuantityImage(QRImage : CIImage!,ImageWidthAndHeight : CGFloat)->UIImage{
        //默认大小
        let extentRect = QRImage.extent.integral
        
        let scale = min(ImageWidthAndHeight / extentRect.width, ImageWidthAndHeight / extentRect.height)
        
        let width = extentRect.width * scale
        
        let height = extentRect.height * scale
        
        let colorSpace : CGColorSpace = CGColorSpaceCreateDeviceGray()
        
        let bitMapContext = CGContext.init(data: nil, width: Int(width), height: Int(height), bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: CGImageAlphaInfo.none.rawValue)!
        
        let ciContext = CIContext.init(options: nil)
        
        let bitMapImage = ciContext.createCGImage(QRImage, from: extentRect)!
        
        bitMapContext.interpolationQuality = CGInterpolationQuality.none
        
        bitMapContext.scaleBy(x: scale, y: scale)
        
        bitMapContext.draw(bitMapImage, in: extentRect)
        
        let scaleImage : CGImage = bitMapContext.makeImage()!
        
        return UIImage.init(cgImage: scaleImage)
    }
    
    //MARK: add Icon
    private func AppendIconWithHighImage(HighImage : UIImage,Icon : UIImage)->UIImage{
        
        let imageSize = HighImage.size
        
        //开启图片上下文
        UIGraphicsBeginImageContext(imageSize)
        
        HighImage.draw(in: CGRect.init(x: 0, y: 0, width: imageSize.width, height: imageSize.height))
        
        let iconX = (imageSize.width - IconSize) / 2
        
        let iconY = (imageSize.height - IconSize) / 2
        
        Icon.draw(in: CGRect.init(x: iconX, y: iconY, width: IconSize, height: IconSize))
        
        let appendImage = UIGraphicsGetImageFromCurrentImageContext()!
        
        UIGraphicsEndImageContext()
        
        return appendImage
    }
}
