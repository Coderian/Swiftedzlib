//
//  ByteStream.swift
//  Swiftedzlib
//
//  Created by 佐々木 均 on 2016/02/12.
//  Copyright © 2016年 S-Parts. All rights reserved.
//

import Foundation

// 例えばこんな実装できるのか？
//
// compressfile << compress << source
//  compresser.in(source)
//  compresser.out(compressfile)
//   compresser.in(source).out(compressfile)
// compressfile >> decompress >> data
//  decompresser.in(compressfile)
//  decompresser.out(data)
//   decompresser.in(compressfile).out(data)
// XCTAssertEqual(source,data)

protocol ByteStream {
    func inlet(data:Array<UInt8>) -> Self
    func outlet(inout data:Array<UInt8>) -> Self
}

infix operator <<< { associativity left precedence 140 }
func <<< (left:ByteStream, right:ByteStream) -> ByteStream {
    var data:Array<UInt8> = Array<UInt8>()
    right.outlet(&data)
    return left.inlet(data)
}
infix operator >>> { associativity left precedence 140 }
func >>> (left:ByteStream, right:ByteStream) -> ByteStream {
    var data:Array<UInt8> = Array<UInt8>()
    left.outlet(&data)
    return right.inlet(data)
}

struct StringStream : ByteStream {
    func inlet(data:Array<UInt8>) -> StringStream {
        return self
    }
    func outlet(inout data:Array<UInt8>) -> StringStream {
        return self
    }
}

struct FileStream : ByteStream {
    func inlet(data:Array<UInt8>) -> FileStream {
        return self
    }
    func outlet(inout data:Array<UInt8>) -> FileStream {
        return self
    }
}

struct Compresser: ByteStream {
    func inlet(data:Array<UInt8>) -> Compresser {
        return self
    }
    func outlet(inout data:Array<UInt8>) -> Compresser {
        return self
    }
}

struct DeCompresser: ByteStream {
    func inlet(data:Array<UInt8>) -> DeCompresser {
        return self
    }
    func outlet(inout data:Array<UInt8>) -> DeCompresser {
        return self
    }
}

func example (){
    let file = FileStream()
    let source = StringStream()
    let data = StringStream()
    let compresser = Compresser()
    let decompresser = DeCompresser()
    file <<< compresser <<< source
    data <<< decompresser <<< file
    file >>> decompresser >>> data

}

protocol Reader {
    func readline() -> String
    func read() -> UInt8
    func readBlock() -> Array<UInt8>
    func readBlock(size:Int) -> Array<UInt8>
}

protocol Writer {
    func writeLine(buffer:String)
    func write(byte:UInt8)
    func writeBlock(bytes:Array<UInt8>)
}

class FileReader {
    private var _fd: UnsafeMutablePointer<FILE> = nil
    init(){

    }
    deinit{
        if _fd != nil {
            fclose(_fd)
        }
    }
    func open(filename:String) {
        _fd = fopen(filename, "rb")
    }
}

class FileWriter {
    private var _fd: UnsafeMutablePointer<FILE> = nil
    init(){

    }
    deinit{
        if _fd != nil {
            fclose(_fd)
        }
    }
    func open(filename:String) {
        _fd = fopen(filename, "rb")
    }
}

class CFile {
    private var _fd: UnsafeMutablePointer<FILE> = nil
    init(){

    }
    deinit{
        if _fd != nil {
            fclose(_fd)
        }
    }
    func open(filename:String,mode:String) {
        _fd = fopen(filename, mode)
    }
}