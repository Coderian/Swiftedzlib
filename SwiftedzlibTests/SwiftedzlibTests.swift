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
        let uncDefault = try? ZLib.toUncompress(cDefault!, sizeOfOriginalBuffer: source.count)
        XCTAssertEqual(source, uncDefault!, "値が復元されない")
        print("original size=\(source.count) compress size=\(cDefault?.count) = \((Double(cDefault!.count)/Double(source.count)) * 100)%")
        
        let cBestSpeed = try? ZLib.toCompress(source, level: .BestSpeed)
        XCTAssertNotNil(cBestSpeed)
        let uncBS = try? ZLib.toUncompress(cBestSpeed!, sizeOfOriginalBuffer: source.count)
        XCTAssertEqual(source, uncBS!, "値が復元されない")
        print("BestSpeed original size=\(source.count) compress size=\(cBestSpeed?.count) = \((Double(cBestSpeed!.count)/Double(source.count)) * 100)%")
        
        let cBestCompression = try? ZLib.toCompress(source, level: .BestCompression)
        XCTAssertNotNil(cBestCompression)
        print("BestCompression original size=\(source.count) compress size=\(cBestCompression?.count) = \((Double(cBestCompression!.count)/Double(source.count)) * 100)%")
        let uncBC = try? ZLib.toUncompress(cBestCompression!, sizeOfOriginalBuffer: source.count)
        XCTAssertEqual(source, uncBC!, "値が復元されない")
        
        // buffer error
        let uncBufferErrored:Array<UInt8>?
        do {
            uncBufferErrored = try ZLib.toUncompress(cBestCompression!, sizeOfOriginalBuffer: source.count/2)
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
    
    func testDeflate() {
        let deflate = try? ZLib.Deflate()
        XCTAssertNotNil(deflate)
    }
    
    func testInflate() {
        let inflate = try? ZLib.Inflate()
        XCTAssertNotNil(inflate)
        
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock {
            // Put the code you want to measure the time of here.
        }
    }
    
}
