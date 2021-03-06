//
//  SwiftedzlibTests.swift
//  SwiftedzlibTests
//
//  Created by 佐々木 均 on 2016/02/10.
//  Copyright © 2016年 S-Parts. All rights reserved.
//

import XCTest
@testable import Swiftedzlib

class SwiftedzlibTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        let v = ZLib.version
        XCTAssertNotNil(v)
        let flags = ZLib.compileFlags
        XCTAssertNotEqual(flags, 0)
        
        example()
    }
    
    func testCompressionDecompression() {
        let source = ("abcdfghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdfghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
                    + "abcdfghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdfghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ").utf8.map({UInt8($0)})
//        print(source)
        
        // オリジナルサイズを保持する場合
        var zlibDefaultCompression = ZLib()
        let c = try? zlibDefaultCompression.toCompress(source)
        XCTAssertNotNil(c)
//        print(c)
        print("original size=\(source.count) compress size=\(c?.count) = \((Double(c!.count)/Double(source.count)) * 100)%")
        XCTAssertGreaterThan(source.count, c!.count)
        let d = try? zlibDefaultCompression.toUncompress(c!)
        XCTAssertNotNil(d)
//        print(d!)
        XCTAssertEqual(source, d!, "値が復元されない")
        
        var zlibBS = ZLib()
        let cBS = try? zlibBS.toCompress(source, level: .BestSpeed)
        XCTAssertNotNil(cBS)
        print("BestSpeed original size=\(source.count) compress size=\(cBS?.count) = \((Double(cBS!.count)/Double(source.count)) * 100)%")
        XCTAssertGreaterThan(source.count, cBS!.count)
        let dBS = try? zlibBS.toUncompress(cBS!)
        XCTAssertNotNil(dBS)
        XCTAssertEqual(source, dBS!, "値が復元されない")
        
        var zlibBC = ZLib()
        let cBC = try? zlibBC.toCompress(source, level: .BestCompression)
        XCTAssertNotNil(cBC)
        print("BestCompression original size=\(source.count) compress size=\(cBC?.count) = \((Double(cBC!.count)/Double(source.count)) * 100)%")
        XCTAssertGreaterThan(source.count, cBC!.count)
        let dBC = try? zlibBC.toUncompress(cBC!)
        XCTAssertNotNil(dBC)
        XCTAssertEqual(source, dBC!, "値が復元されない")
        
        
        // オリジナルのサイズを別途知り得る場合
        let cDefault = try? ZLib.toCompress(source)
        XCTAssertNotNil(cDefault)
        let uncDefault = try? ZLib.toUncompress(cDefault!.compressData, sizeOfOriginalBuffer: cDefault!.originalSize)
        XCTAssertEqual(source, uncDefault!, "値が復元されない")
        print("original size=\(source.count) compress size=\(cDefault?.compressData.count) = \((Double(cDefault!.compressData.count)/Double((cDefault?.originalSize)!)) * 100)%")
        
        let cBestSpeed = try? ZLib.toCompress(source, level: .BestSpeed)
        XCTAssertNotNil(cBestSpeed)
        let uncBS = try? ZLib.toUncompress(cBestSpeed!.compressData, sizeOfOriginalBuffer: cBestSpeed!.originalSize)
        XCTAssertEqual(source, uncBS!, "値が復元されない")
        print("BestSpeed original size=\(source.count) compress size=\(cBestSpeed?.compressData.count) = \((Double(cBestSpeed!.compressData.count)/Double(cBestSpeed!.originalSize)) * 100)%")
        
        let cBestCompression = try? ZLib.toCompress(source, level: .BestCompression)
        XCTAssertNotNil(cBestCompression)
        print("BestCompression original size=\(source.count) compress size=\(cBestCompression?.compressData.count) = \((Double(cBestCompression!.compressData.count)/Double((cBestCompression?.originalSize)!)) * 100)%")
        let uncBC = try? ZLib.toUncompress(cBestCompression!)
        XCTAssertEqual(source, uncBC!, "値が復元されない")
        
        // buffer error
        let uncBufferErrored:Array<UInt8>?
        do {
            uncBufferErrored = try ZLib.toUncompress(cBestCompression!.compressData, sizeOfOriginalBuffer: cBestCompression!.originalSize/2)
        }
        catch ZLib.ZError.MemoryError {
            print("catch MemoryError")
            uncBufferErrored = nil
        }
        catch ZLib.ZError.BufferError{
            print("catch BufferError")
            uncBufferErrored = nil
        }
        catch{
            print("catch exception")
            uncBufferErrored = nil
        }
        XCTAssertNil(uncBufferErrored)
    }
    
    func testDeflateInflate() {
        // メモリー使用量を少なくするためストレージにつどアクセスする
        let deflate = try? ZLib.Deflate()
        XCTAssertNotNil(deflate)
        let data = Array<UInt8>(count:1024*10, repeatedValue: 90)
        var compressdata = Array<UInt8>()
        for index in 0.stride(to: data.count, by: data.count/10){
            let chunk = Array(data[index...index+1024-1])
            try! deflate?.doDeflate(chunk, writer: { compressdata.appendContentsOf($0); return true })
        }
        try! deflate?.Finished( { compressdata.appendContentsOf($0); return true })
        XCTAssert(compressdata.count < data.count,"圧縮されていない")
        
        var uncompressdata = Array<UInt8>()
        let inflate = try? ZLib.Inflate()
        XCTAssertNotNil(inflate)
        
        do {
            try inflate?.doInflate(compressdata, writer: { uncompressdata.appendContentsOf($0); return true })
        }
        catch ZLib.ZError.DataError(let msg) {
            print(msg)
        }
        catch {
            print("catch")
        }
        XCTAssertEqual(data,uncompressdata,"値が復元されない")
        print("original size=\(data.count) compress size=\(compressdata.count) = \((Double(compressdata.count)/Double(data.count)) * 100)%")
    }
    
    func testGzFile(){
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock {
            // Put the code you want to measure the time of here.
        }
    }
    
}
