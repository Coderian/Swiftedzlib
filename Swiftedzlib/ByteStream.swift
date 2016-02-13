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
    mutating func inlet(indata:Array<UInt8>) -> Self
    func outlet(inout outdata:Array<UInt8>) -> Self
}

infix operator <<< { associativity right precedence 140 }
func <<< (var left:ByteStream, right:ByteStream) -> ByteStream {
    var data:Array<UInt8> = Array<UInt8>()
    right.outlet(&data)
    return left.inlet(data)
}
infix operator >>> { associativity left precedence 140 }
func >>> (left:ByteStream, var right:ByteStream) -> ByteStream {
    var data:Array<UInt8> = Array<UInt8>()
    left.outlet(&data)
    return right.inlet(data)
}

struct StringStream : ByteStream {
    var text:String
    init(){
        text = String()
    }
    init(text:String){
        self.text = text
    }
    mutating func inlet(indata:Array<UInt8>) -> StringStream {
        debugPrint("StringStream inlet \(indata)")
        self.text = String(indata)
        return self
    }
    func outlet(inout outdata:Array<UInt8>) -> StringStream {
        outdata = Array(self.text.utf8)
        debugPrint("StringStream outlet \(outdata)")
        return self
    }
}

struct FileStream : ByteStream {
    func inlet(indata:Array<UInt8>) -> FileStream {
        debugPrint("FileStream inlet \(indata)")
        return self
    }
    func outlet(inout outdata:Array<UInt8>) -> FileStream {
        debugPrint("FileStream outlet \(outdata)")
        return self
    }
}

struct Compresser: ByteStream {
    var compressedData:Array<UInt8>
    init(){
        compressedData = Array<UInt8>()
    }
    mutating func inlet(indata:Array<UInt8>) -> Compresser {
        debugPrint("Compresser inlet \(indata)")
        // TODO: Compress
        self.compressedData = indata
        return self
    }
    func outlet(inout outdata:Array<UInt8>) -> Compresser {
        outdata = self.compressedData
        debugPrint("Compresser outlet \(outdata)")
        return self
    }
}

struct DeCompresser: ByteStream {
    var decompressedData:Array<UInt8>
    init(){
        decompressedData = Array<UInt8>()
    }
    mutating func inlet(indata:Array<UInt8>) -> DeCompresser {
        debugPrint("DeCompresser inlet \(indata)")
        // TODO: Decompress
        self.decompressedData = indata
        return self
    }
    func outlet(inout outdata:Array<UInt8>) -> DeCompresser {
        outdata = self.decompressedData
        debugPrint("DeCompresser outlet \(outdata)")
        return self
    }
}

func example (){
    let file = FileStream()
    let source = StringStream(text: "source")
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