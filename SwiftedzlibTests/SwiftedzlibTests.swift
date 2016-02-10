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
        print(source)
        var zlib = ZLib()
        let c = try? zlib.toCompress(source)
        XCTAssertNotNil(c)
        print(c)
        print("original size=\(source.count) compress size=\(c?.count)")
        let d = try? zlib.toUncompress(c!)
        XCTAssertNotNil(d)
        print(d!)
        XCTAssertEqual(source, d!, "値が復元されない")
        // オリジナルのサイズが別途知り得る場合
        let unComp = try? ZLib.toUncompress(c!, sizeOfOriginalBuffer: source.count)
        print(unComp!)
        XCTAssertEqual(source, unComp!, "値が復元されない")
        
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock {
            // Put the code you want to measure the time of here.
        }
    }
    
}
