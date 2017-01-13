//
//  MXRegularExpression.swift
//  MXRegularExpression
//
//  Created by mx on 2017/1/12.
//  Copyright © 2017年 mengx. All rights reserved.
//

import Foundation

class MXRegularExpression {
    
    static let share : MXRegularExpression = MXRegularExpression()
    
    private init(){
        
    }
    
    //MARK: 查找串中是否存在规定模式的串
    func isExist(pattern regular : String,destination dest : String,encoding : String.Encoding = .utf8)->Bool {
            
        let results = self.getFormulaResults(pattern: regular, destination: dest)
            
        if results.count > 0 {
            return true
        }
        
        return false
    }
    
    //是否为电话号码
    func isPhoneNumber(destination dest : String)->Bool {
        //数字1开头，数字结尾
        return self.isExist(pattern: "^1[3|4|5|7|8][0-9]\\d{8}$", destination: dest)
    }
    //是否为QQ
    func isQQ(destination dest : String)->Bool {
        //全是数字。5-11位
        return self.isExist(pattern: "^[1-9]\\d{4,10}$", destination: dest)
    }
    //是否为邮箱号
    func isEmail(destination dest : String)->Bool {
        //没完成
        return self.isExist(pattern: "[0-9a-zA-Z]*@[163a-zA-z_]+.com", destination: dest)
    }
    //是否为文件URL
    func isFileUrl(destination dest : String)->Bool {
        
        return self.isExist(pattern
            : "file://([\\w-]+\\.)+[\\w-]+(/[\\w-./?%&=]*)?$", destination: dest)
    }
    //是否为网络URL
    func isHTTPUrl(destination dest : String)->Bool {
        
        return self.isExist(pattern: "https?://([\\w-]+\\.)+[\\w-]+(/[\\w-./?%&=]*)?$", destination: dest)
    }
    //获取指定格式的子串的位置
    private func getFormulaResults(pattern regular : String,destination dest : String,encoding : String.Encoding = .utf8)->[NSTextCheckingResult]{
        do{
            let expression = try NSRegularExpression.init(pattern: regular
                , options: NSRegularExpression.Options.caseInsensitive)
            
            let results = expression.matches(in: dest, options: NSRegularExpression.MatchingOptions.init(rawValue: 0), range: NSRange.init(location: 0, length: dest.characters.count))
            
            return results
        }catch{
            print("出现错误")
            return [NSTextCheckingResult]()
        }

    }
    func getFormulaStringRange(pattern regular : String,destination dest : String)->[NSRange]?{
        if self.isExist(pattern: regular, destination: dest) {
            //操作
            var ranges = [NSRange]()
            
            let results = self.getFormulaResults(pattern: regular, destination: dest)
            
            for result in results {
                ranges.append(result.range)
            }
            
            return ranges
        }
        return nil
    }
    
    //MARK: 匹配规定格式内容，并返回
    func getFormulaString(pattern regular : String,destination dest : String)->[String]?{
        if self.isExist(pattern: regular, destination: dest) {
            //操作
            var subStrings = [String]()
            
            let results = self.getFormulaResults(pattern: regular, destination: dest)
            
            for result in results {
                //abcde
                let start = result.range.location
                
                let end = result.range.length + start
                
                subStrings.append(dest[start..<end])
            }
            
            return subStrings
        }
        return nil
    }
    
    //MARK: 删除指定格式的内容,如果没有，就返回原串
    func deleteFormulaString(pattern regular : String,destination dest : String)->String{
        if self.isExist(pattern: regular, destination: dest) {
            //操作
            let results = self.getFormulaResults(pattern: regular, destination: dest)
            
            var modifyString : String = dest
            
            var length = 0
            
            for result in results {
                
                let start = modifyString.index(modifyString.startIndex, offsetBy: result.range.location - length)
                
                let end = modifyString.index(modifyString.startIndex, offsetBy: result.range.location - length + result.range.length)
                
                let range = start..<end
                
                modifyString.removeSubrange(range)
                
                length += result.range.length
            }
            return modifyString
        }
        return dest
    }
    
    //MARK:替换指定格式的内容
    func replaceFormulaString(pattern regular : String,destination dest : String,with : String)->String{
        if self.isExist(pattern: regular, destination: dest) {
            //操作
            //操作
            let results = self.getFormulaResults(pattern: regular, destination: dest)
            
            var modifyString : String = dest
            
            var deleteLength = 0
            
            let replaceLength = with.characters.count
            
            var finallyLength = 0
            
            for result in results {
                
                let start = modifyString.index(modifyString.startIndex, offsetBy: result.range.location + finallyLength)
                
                let end = modifyString.index(modifyString.startIndex, offsetBy: result.range.location + finallyLength + result.range.length)
                
                let range = start..<end
             
                modifyString.replaceSubrange(range, with: with)
                
                deleteLength = result.range.length
                
                finallyLength += replaceLength - deleteLength
            }

            return modifyString
        }
        return dest
    }
    
}

extension String {
    subscript (range: CountableRange<Int>) -> String {
        get {
            let startIndex = self.index(self.startIndex, offsetBy: range.lowerBound)
            let endIndex = self.index(self.startIndex, offsetBy: range.upperBound)
            return self[startIndex..<endIndex]
        }
        
        set {
            //newValue就是String
            
        }
    }
    
    subscript (range : CountableClosedRange<Int>) -> String {
        get {
            let startIndex = self.index(self.startIndex, offsetBy: range.lowerBound)
            let endIndex = self.index(self.startIndex, offsetBy: range.upperBound)
            return self[startIndex..<endIndex]
        }
        
        set {
            
        }
    }
}
