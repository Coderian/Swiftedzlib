//
//  ZLib.swift
//  Swiftedzlib
//
//  Created by 佐々木 均 on 2016/02/10.
//  Copyright © 2016年 S-Parts. All rights reserved.
//

import Foundation

// ref http://zlib.net
// ref https://oku.edu.mie-u.ac.jp/~okumura/compression/zlib.html
// ref zlib.h
public struct ZLib {
    public enum ZError: ErrorType {
        case ErrNo(message: String)         // Z_ERRNO
        case StreamError(message: String)   // Z_STREAM_ERROR
        case DataError(message: String)     // Z_DATA_ERROR
        case MemoryError(message: String)   // Z_MEM_ERROR
        case BufferError(message: String)   // Z_BUF_ERROR
        case VersionError(message: String)  // Z_VERSION_ERROR
        case UnknownError(returnCode: CInt)
    }
    
    public enum CompressionLevel: CInt {
        case NoCompression = 0      //Z_NO_COMPRESSION
        case BestSpeed = 1          //Z_BEST_SPEED
        case BestCompression = 9    //Z_BEST_COMPRESSION
        case Default = -1           //Z_DEFAULT_COMPRESSION
    }
    
    public enum CompressionStrategy: CInt {
        case Filtered = 1
        case HuffmanOnly = 2
        case RLE = 3
        case Fixed = 4
        case Default = 0
    }
    
    public enum PossibleValues: CInt {
        case Binary = 0
        case TextOrASCII = 1
        case Unknown = 2
    }
    
    public enum FlushVariation: CInt {
        case NoFlush = 0
        case PartialFlush = 1
        case SyncFlush = 2
        case FullFlush = 3
        case Finish = 4
        case Block = 5
        case Trees = 6
    }
    
    private var _sizeOfOriginalBuffer:Int = 0
    
    public static var version:String? {
        return String.fromCString(zlibVersion())
    }
    public static var compileFlags:UInt {
        return zlibCompileFlags()
    }

    /// adler32( adler: uLong, buf: UnsafePointer<Bytef>, len: uInt)
    public static func toAdler32(adler:UInt , buffer: Array<UInt8> ) -> CUnsignedLong {
        return adler32(adler, buffer, CUnsignedInt(buffer.count))
    }

    /// crc32( crc: uLong, buf: UnsafePointer<bytef>, len: uInt )
    public static func toCrc32(crc:UInt, buffer:Array<UInt8> ) -> CUnsignedLong {
        return crc32(crc, buffer, CUnsignedInt(buffer.count) )
    }
    
    /// compress(dest: UnsafeMutablePointer<Bytef>, destLen: UnsafeMutablePointer<uLongf>, source: UnsafePointer<Bytef>, sourceLen: uLong )
    public mutating func toCompress(source: Array<UInt8>) throws -> Array<UInt8> {
        _sizeOfOriginalBuffer = source.count
        return try self.dynamicType.toCompress(source)
    }
    
    /// compress2( dest: UnsafeMutablePointer<Bytef>, destLen: UnsafeMutablePointer<uLongf>, source: UnsafePointer<Bytef>, sourceLen: uLong, level: Int32 )
    public mutating func toCompress(source: Array<UInt8>, level: CompressionLevel) throws -> Array<UInt8> {
        _sizeOfOriginalBuffer = source.count
        return try self.dynamicType.toCompress(source, level: level)
    }
    
    /// compress(dest: UnsafeMutablePointer<Bytef>, destLen: UnsafeMutablePointer<uLongf>, source: UnsafePointer<Bytef>, sourceLen: uLong )
    public static func toCompress(source: Array<UInt8>) throws -> Array<UInt8> {
        let sizeOfCompressBuffer = compressBound(CUnsignedLong(source.count))
        var dest = Array<Bytef>(count:Int(sizeOfCompressBuffer), repeatedValue: 0)
        var destlen:CUnsignedLong = CUnsignedLong(dest.count)
        let ret = compress(&dest, &destlen, source, CUnsignedLong(source.count))
        switch(ret){
        case Z_OK:
            //            let retValue = dest.prefix(Int(destlen)).map({UInt8($0)})
            let retValue = Array(dest.prefix(Int(destlen)))
            return retValue
        case Z_MEM_ERROR:
            throw ZError.MemoryError(message: "not enough memory")
        case Z_BUF_ERROR:
            throw ZError.BufferError(message: "not enough room in the output buffer")
        default:
            throw ZError.UnknownError(returnCode: ret)
        }
    }
    
    /// compress2( dest: UnsafeMutablePointer<Bytef>, destLen: UnsafeMutablePointer<uLongf>, source: UnsafePointer<Bytef>, sourceLen: uLong, level: Int32 )
    public static func toCompress(source: Array<UInt8>, level: CompressionLevel) throws -> Array<UInt8> {
        let sizeOfCompressBuffer = compressBound(CUnsignedLong(source.count))
        var dest = Array<Bytef>(count:Int(sizeOfCompressBuffer), repeatedValue: 0)
        var destlen:CUnsignedLong = CUnsignedLong(dest.count)
        let ret = compress2(&dest, &destlen, source, CUnsignedLong(source.count), level.rawValue)
        switch(ret){
        case Z_OK:
//            let retValue = dest.prefix(Int(destlen)).map({UInt8($0)})
            let retValue = Array(dest.prefix(Int(destlen)))
            return retValue
        case Z_MEM_ERROR:
            throw ZError.MemoryError(message: "not enough memory")
        case Z_BUF_ERROR:
            throw ZError.BufferError(message: "not enough room in the output buffer")
        case Z_STREAM_END:
            throw ZError.StreamError(message: "the level parameter is invalid")
        default:
            throw ZError.UnknownError(returnCode: ret)
        }
    }
    
    /// uncompress(dest: UnsafeMutablePointer<Bytef>, destLen: UnsafeMutablePointer<uLongf>, source: UnsafePointer<Bytef>, sourceLen: uLong)
    public func toUncompress( source: Array<UInt8>) throws -> Array<UInt8> {
        return try self.dynamicType.toUncompress(source, sizeOfOriginalBuffer: _sizeOfOriginalBuffer)
    }
    
    public static func toUncompress( source: Array<UInt8>, sizeOfOriginalBuffer:Int ) throws -> Array<UInt8> {
        var dest = Array<Bytef>(count:Int(sizeOfOriginalBuffer), repeatedValue: 0)
        var destlen:CUnsignedLong = CUnsignedLong(dest.count)
        let ret = uncompress(&dest, &destlen, source, CUnsignedLong(source.count))
        switch(ret){
        case Z_OK:
            return dest
        case Z_MEM_ERROR:
            throw ZError.MemoryError(message: "not enough memory")
        case Z_BUF_ERROR:
            throw ZError.BufferError(message: "not enough room in the output buffer")
        case Z_DATA_ERROR:
            throw ZError.DataError(message: "the input data was corrupted or incomplete")
        default:
            throw ZError.UnknownError(returnCode: ret)
        }
    }
    
    ///
    public class Inflate {
        private var _stream: z_stream
        private var _inBuffer:Array<CUnsignedChar>
        private var _outBuffer:Array<CUnsignedChar>
        
        /// initilize
        ///  inflateInit_( strm: z_streamp, version: UnsafePointer<Int8>, stream_size: Int32 )
        init(buffersize: Int = 1024) throws {
            _inBuffer = Array<CUnsignedChar>(count:Int(buffersize),repeatedValue:0)
            _outBuffer = Array<CUnsignedChar>(count:Int(buffersize),repeatedValue:0)
            
            _stream = z_stream(next_in: nil, avail_in: 0, total_in: 0, next_out: nil, avail_out: 0, total_out: 0, msg: nil, state: nil, zalloc: nil, zfree: nil, opaque: nil, data_type: 0, adler: 0, reserved: 0)
            let ret = inflateInit_(&_stream, ZLIB_VERSION, CInt(sizeof(z_stream)))
            switch ret {
            case Z_OK:
                break
            case Z_MEM_ERROR:
                throw ZError.MemoryError(message: String.fromCString(_stream.msg)!)
            case Z_VERSION_ERROR:
                throw ZError.VersionError(message: String.fromCString(_stream.msg)!)
            case Z_STREAM_ERROR:
                throw ZError.StreamError(message: String.fromCString(_stream.msg)!)
            default:
                throw ZError.UnknownError(returnCode: ret)
            }
        }
        /// initilize
        ///
        /// zlib.h
        ///
        ///     inflateInit2_( strm: z_streamp, windowBits: Int32, version: UnsafePointer<Int8>, stream_size: Int32 )
        init(windowBits:Int32, buffersize: Int = 1024 ) throws {
            _inBuffer = Array<CUnsignedChar>(count:Int(buffersize),repeatedValue:0)
            _outBuffer = Array<CUnsignedChar>(count:Int(buffersize),repeatedValue:0)
            
            _stream = z_stream(next_in: nil, avail_in: 0, total_in: 0, next_out: nil, avail_out: 0, total_out: 0, msg: nil, state: nil, zalloc: nil, zfree: nil, opaque: nil, data_type: 0, adler: 0, reserved: 0)
            let ret = inflateInit2_(&_stream, windowBits, ZLIB_VERSION, CInt(sizeof(z_stream)))
            switch ret {
            case Z_OK:
                break
            case Z_MEM_ERROR:
                throw ZError.MemoryError(message: String.fromCString(_stream.msg)!)
            case Z_VERSION_ERROR:
                throw ZError.VersionError(message: String.fromCString(_stream.msg)!)
            case Z_STREAM_ERROR:
                throw ZError.StreamError(message: String.fromCString(_stream.msg)!)
            default:
                throw ZError.UnknownError(returnCode: ret)
            }
        }
        ///
        /// inflateEnd( strm: z_streamp )
        deinit{
            inflateEnd(&_stream)
        }
        
        func doInflate(src:Array<UInt8>, writer: (buffer:Array<UInt8>) -> Bool) throws {
            _stream.next_out = UnsafeMutablePointer<CUnsignedChar>(_outBuffer)
            _stream.avail_out = CUnsignedInt(_outBuffer.count)
            _stream.avail_in = 0
            var remining = src.count
            for index in 0.stride(to: src.count, by: _inBuffer.count){
                // TODO: inBuffer[] < src[] の場合が必要
                if src.count < index + _inBuffer.count {
                    _inBuffer[0...src.count-1] = src[index...index+src.count-1]
                    _stream.avail_in = CUnsignedInt(src.count)
                }
                else {
                    _inBuffer[0..._inBuffer.count-1] = src[index...index+_inBuffer.count-1]
                    _stream.avail_in = CUnsignedInt(_inBuffer.count)
                    remining -= _inBuffer.count
                }
                _stream.next_in = UnsafeMutablePointer<CUnsignedChar>(_inBuffer)
                repeat {
                    let ret = try _inflate()
                    if ret == Z_STREAM_END {
                        break;
                    }

                    if _stream.avail_out == 0 {
                        if writer(buffer: _outBuffer) == false {
                            return
                        }
                        _stream.next_out = UnsafeMutablePointer<CUnsignedChar>(_outBuffer)
                        _stream.avail_out = CUnsignedInt(_outBuffer.count)
                    }
                }while (_stream.avail_in != 0)
            }
            // TODO: サイズが合わない
            let count:Int = _outBuffer.count - Int(_stream.avail_out)
            if count != 0 {
                if writer(buffer: _outBuffer) == false {
                    return
                }
            }
            
        }
        
        func Finished(writer: (buffer:Array<UInt8>) -> Bool) throws {
            // TODO:
        }
        
        
        // ref http://oku.edu.mie-u.ac.jp/~okumura/compression/comptest.c
        func doInflate(src: Array<UInt8> ) throws -> Array<UInt8> {
            var value = Array<UInt8>()
            _stream.next_out = UnsafeMutablePointer<CUnsignedChar>(_outBuffer)
            _stream.avail_out = CUnsignedInt(_outBuffer.count)
            _stream.avail_in = 0
            for index in 0.stride(to: src.count, by: _inBuffer.count){
                // TODO: inBuffer[] < src[] の場合が必要
                if src.count < index + _inBuffer.count {
                    _inBuffer[0...src.count-1] = src[index...index+src.count-1]
                    _stream.avail_in = CUnsignedInt(src.count)
                }
                else {
                    _inBuffer[0..._inBuffer.count-1] = src[index...index+_inBuffer.count-1]
                    _stream.avail_in = CUnsignedInt(_inBuffer.count)
                }
                _stream.next_in = UnsafeMutablePointer<CUnsignedChar>(_inBuffer)
                repeat {
                    let ret = try _inflate()
                    if ret == Z_STREAM_END {
                        break;
                    }

                    if _stream.avail_out == 0 {
                        value.appendContentsOf(_outBuffer)
                        _stream.next_out = UnsafeMutablePointer<CUnsignedChar>(_outBuffer)
                        _stream.avail_out = CUnsignedInt(_outBuffer.count)
                    }
                }while (_stream.avail_in != 0)
            }
            // TODO: サイズが合わない
            let count:Int = _outBuffer.count - Int(_stream.avail_out)
            if count != 0 {
                value.appendContentsOf(_outBuffer[0...count])
            }
            return value
            
        }
        
        /// inflate( strm: z_streamp, flush: Int32 )
        private func _inflate(flush:FlushVariation = .NoFlush) throws -> CInt {
            let ret = inflate(&_stream, flush.rawValue)
            switch ret {
            case Z_OK:
                break
            case Z_STREAM_END:
                break
            case Z_NEED_DICT:
                break
            case Z_MEM_ERROR:
                throw ZError.MemoryError(message: String.fromCString(_stream.msg)!)
            case Z_BUF_ERROR:
                throw ZError.BufferError(message: String.fromCString(_stream.msg)!)
            case Z_DATA_ERROR:
                throw ZError.DataError(message: String.fromCString(_stream.msg)!)
            case Z_VERSION_ERROR:
                throw ZError.VersionError(message: String.fromCString(_stream.msg)!)
            case Z_STREAM_ERROR:
                throw ZError.StreamError(message: String.fromCString(_stream.msg)!)
            default:
                throw ZError.UnknownError(returnCode: ret)
            }
            return ret
        }

        /// inflateCopy( dest: z_streamp, source: z_streamp )
        func duplicate() throws -> Inflate {
            let dest:Inflate = try Inflate()
            inflateEnd(&dest._stream)
            let ret = inflateCopy(&dest._stream, &_stream)
            switch ret {
            case Z_OK:
                break
            case Z_MEM_ERROR:
                throw ZError.MemoryError(message: String.fromCString(_stream.msg)!)
            case Z_STREAM_ERROR:
                throw ZError.StreamError(message: String.fromCString(_stream.msg)!)
            default:
                throw ZError.UnknownError(returnCode: ret)
            }
            
            return dest
        }

        /// inflateGetHeader( strm: z_streamp, head: gz_headerp )
        func getHeader() throws -> gz_header {
            var header = gz_header()
            let ret = inflateGetHeader(&_stream, &header)
            switch ret {
            case Z_OK:
                break
            case Z_BUF_ERROR:
                throw ZError.BufferError(message: String.fromCString(_stream.msg)!)
            case Z_STREAM_ERROR:
                throw ZError.StreamError(message: String.fromCString(_stream.msg)!)
            default:
                throw ZError.UnknownError(returnCode: ret)
            }
            return header
        }

        /// inflateMark( strm: z_streamp )
        func mark() -> Int{
            return inflateMark(&_stream)
        }

        /// inflatePrime( strm: z_streamp, bits: Int32, value: Int32 )
        func prime(bits:Int32, value:PossibleValues) throws {
            let ret = inflatePrime(&_stream, bits, value.rawValue)
            switch ret {
            case Z_OK:
                break
            case Z_BUF_ERROR:
                throw ZError.BufferError(message: String.fromCString(_stream.msg)!)
            case Z_STREAM_ERROR:
                throw ZError.StreamError(message: String.fromCString(_stream.msg)!)
            default:
                throw ZError.UnknownError(returnCode: ret)
            }
        }

        /// inflateReset( strm: z_streamp )
        func reset() throws {
            let ret = inflateReset(&_stream)
            switch ret {
            case Z_OK:
                break
            case Z_STREAM_ERROR:
                throw ZError.StreamError(message: String.fromCString(_stream.msg)!)
            default:
                throw ZError.UnknownError(returnCode: ret)
            }
        }

        /// inflateReset2( strm: z_streamp, windowBits: Int32 )
        func reset(windowBits:Int32) throws {
            let ret = inflateReset2(&_stream, windowBits)
            switch ret {
            case Z_OK:
                break
            case Z_STREAM_ERROR:
                throw ZError.StreamError(message: String.fromCString(_stream.msg)!)
            default:
                throw ZError.UnknownError(returnCode: ret)
            }
        }

        /// inflateSetDictionary( strm: z_streamp, dictionary: UnsafePointer<Bytef>, dictLength: uInt )
        func setDictionary(dictionary: Array<UInt8> ) throws {
            let ret = inflateSetDictionary(&_stream, dictionary, CUnsignedInt(dictionary.count))
            switch ret {
            case Z_OK:
                break
            case Z_STREAM_ERROR:
                throw ZError.StreamError(message: String.fromCString(_stream.msg)!)
            case Z_DATA_ERROR:
                throw ZError.DataError(message: String.fromCString(_stream.msg)!)
            default:
                throw ZError.UnknownError(returnCode: ret)
            }
        }

        /// inflateSync( strm: z_streamp )
        func sync() throws {
            let ret = inflateSync(&_stream)
            switch ret {
            case Z_OK:
                break
            case Z_BUF_ERROR:
                throw ZError.BufferError(message: String.fromCString(_stream.msg)!)
            case Z_STREAM_ERROR:
                throw ZError.StreamError(message: String.fromCString(_stream.msg)!)
            case Z_DATA_ERROR:
                throw ZError.DataError(message: String.fromCString(_stream.msg)!)
            default:
                throw ZError.UnknownError(returnCode: ret)
            }
        }

        /// inflateBackInit_( strm: z_streamp, windowBits: Int32, window: UnsafeMutalbePointer<UInt8>, version: UnsafePointer<Int8>, stream_size: Int32 )
        func backInit(){
            // :TODO
        }
        
        /// inflateBackEnd( strm: z_streamp )
        func backEnd(){
            // :TODO
        }
        
        /// inflateBack( strm: z_streamp, `in`: in_func!, in_desc: UnsafeMutablePointer<Void>, out: out_func!, out_desc: UnsafeMutablePointer<Void>)
        func back(){
            // :TODO
        }
    }
    
    public class Deflate {
        var _stream : z_stream
        var _inBuffer:Array<CUnsignedChar>
        var _outBuffer:Array<CUnsignedChar>
        
        /// deflateInit_( strm: z_streamp, level: Int32, version: UnsafePointer<Int8>, stream_size: Int32 )
        public init(level:CompressionLevel = .Default ,buffersize:Int = 1024 ) throws {
            _inBuffer = Array<CUnsignedChar>(count:Int(buffersize),repeatedValue:0)
            _outBuffer = Array<CUnsignedChar>(count:Int(buffersize),repeatedValue:0)
            
            _stream = z_stream(next_in: nil, avail_in: 0, total_in: 0, next_out: nil, avail_out: 0, total_out: 0, msg: nil, state: nil, zalloc: nil, zfree: nil, opaque: nil, data_type: 0, adler: 0, reserved: 0)
            let ret = deflateInit_(&_stream, level.rawValue, ZLIB_VERSION, CInt(sizeof(z_stream)))
            switch ret {
            case Z_OK:
                break
            case Z_MEM_ERROR:
                throw ZError.MemoryError(message: String.fromCString(_stream.msg)!)
            case Z_VERSION_ERROR:
                throw ZError.VersionError(message: String.fromCString(_stream.msg)!)
            case Z_STREAM_ERROR:
                throw ZError.StreamError(message: String.fromCString(_stream.msg)!)
            default:
                throw ZError.UnknownError(returnCode: ret)
            }
        }

        /// defalteInit2_( strm: z_stramp, level: Int32, method: Int32, windowBits: Int32, memLevel: Int32, strategy: Int32, version: UnsafePointer<Int8>, stream_size: Int32 )
        public init(level:CompressionLevel, method:CInt, windowBits:CInt, memLevel:CInt, strategy:CompressionStrategy, buffersize:Int = 1024 ) throws {
            _inBuffer = Array<CUnsignedChar>(count:Int(buffersize),repeatedValue:0)
            _outBuffer = Array<CUnsignedChar>(count:Int(buffersize),repeatedValue:0)
            
            _stream = z_stream(next_in: nil, avail_in: 0, total_in: 0, next_out: nil, avail_out: 0, total_out: 0, msg: nil, state: nil, zalloc: nil, zfree: nil, opaque: nil, data_type: 0, adler: 0, reserved: 0)
            let ret = deflateInit2_(&_stream, level.rawValue, method, windowBits, memLevel, strategy.rawValue, ZLIB_VERSION, CInt(sizeof(z_stream)))
            switch ret {
            case Z_OK:
                break
            case Z_MEM_ERROR:
                throw ZError.MemoryError(message: String.fromCString(_stream.msg)!)
            case Z_VERSION_ERROR:
                throw ZError.VersionError(message: String.fromCString(_stream.msg)!)
            case Z_STREAM_ERROR:
                throw ZError.StreamError(message: String.fromCString(_stream.msg)!)
            default:
                throw ZError.UnknownError(returnCode: ret)
            }
        }
        /// deflateEnd( strm: z_streamp )
        deinit{
            deflateEnd(&_stream)
        }
        
        public func doDeflate(src:Array<UInt8>, writer: (buffer:Array<UInt8>) -> Bool) throws {
            // TODO:
            _stream.next_out = UnsafeMutablePointer<CUnsignedChar>(_outBuffer)
            _stream.avail_out = CUnsignedInt(_outBuffer.count)
            _stream.avail_in = 0

            var status = Z_OK
            var flush:FlushVariation = .NoFlush
            var remaining = src.count
            for index in 0.stride(to: src.count, by: _inBuffer.count){
                repeat {
                    if _stream.avail_in == 0 {
                        // TODO: inBuffer[] < src[] の場合が必要
                        _inBuffer[0..._inBuffer.count-1] = src[index...index+_inBuffer.count-1]
                        remaining -= _inBuffer.count
                        _stream.next_in = UnsafeMutablePointer<CUnsignedChar>(_inBuffer)
                        _stream.avail_in = CUnsignedInt(_inBuffer.count)
                        if _stream.avail_in < CUnsignedInt(_inBuffer.count) {
                            flush = .Finish
                        }
                    }
                    
                    status = try _deflate(flush)
                    if _stream.avail_out == 0 {
                        if writer(buffer: _outBuffer) == false {
                            break;
                        }
                    }
                } while status == Z_STREAM_END
            }

        }
        
        public func Finished(writer: (buffer:Array<UInt8>) -> Bool) throws -> Bool{
            try _deflate(.Finish)
            let count:Int = _outBuffer.count - Int(_stream.avail_out)
            if count != 0 {
                let buf = Array(_outBuffer[0...count])
                return writer(buffer: buf)
            }
            return true
        }
        
        // ref http://oku.edu.mie-u.ac.jp/~okumura/compression/comptest.c
        public func doDeflate(src: Array<UInt8> ) throws -> Array<UInt8> {
            var value = Array<UInt8>()
            _stream.next_out = UnsafeMutablePointer<CUnsignedChar>(_outBuffer)
            _stream.avail_out = CUnsignedInt(_outBuffer.count)
            _stream.avail_in = 0
            let sizeBuffer = _inBuffer.count
            var flush:FlushVariation = .NoFlush
            var status:CInt = Z_OK
            
            for index in 0.stride(to: src.count, by: sizeBuffer) {
                if _stream.avail_in == 0 {
                    // TODO: inBuffer[] < src[] の場合が必要
                    _inBuffer[0...sizeBuffer-1] = src[index...index+sizeBuffer-1]
                    _stream.next_in = UnsafeMutablePointer<CUnsignedChar>(_inBuffer)
                    _stream.avail_in = CUnsignedInt(sizeBuffer)
                    if _stream.avail_in < CUnsignedInt(sizeBuffer) {
                        flush = .Finish
                    }
                }
                status = try _deflate(flush)
                if status == Z_STREAM_END {
                    break
                }
                    
                if _stream.avail_out == 0 {
                    value.appendContentsOf(_outBuffer)
                    _stream.next_out = UnsafeMutablePointer<CUnsignedChar>(_outBuffer)
                    _stream.avail_out = CUnsignedInt(_outBuffer.count)
                }
            }
            if _stream.avail_in == 0 {
                // TODO: inBuffer[] < src[] の場合が必要
                _stream.next_in = UnsafeMutablePointer<CUnsignedChar>(_inBuffer)
                _stream.avail_in = 0
                if _stream.avail_in < CUnsignedInt(sizeBuffer) {
                    flush = .Finish
                    status = try _deflate(flush)
                }
            }

            
/*
            for index in 0.stride(to: src.count, by: sizeBuffer){
                // TODO: inBuffer[] < src[] の場合が必要
                if _stream.avail_in == 0 {
                    _inBuffer[0...sizeBuffer-1] = src[index...index+sizeBuffer-1]
                    _stream.next_in = UnsafeMutablePointer<CUnsignedChar>(_inBuffer)
                    _stream.avail_in = CUnsignedInt(sizeBuffer)
                    if _stream.avail_in < CUnsignedInt(sizeBuffer) {
                        flush = .Finish
                    }
                }
                let ret = try _deflate(flush)
                if ret == Z_STREAM_END {
                    break;
                }

                if _stream.avail_out == 0 {
                    value.appendContentsOf(_outBuffer)
                    _stream.next_out = UnsafeMutablePointer<CUnsignedChar>(_outBuffer)
                    _stream.avail_out = CUnsignedInt(_outBuffer.count)
                }
            }
*/
            let count:Int = _outBuffer.count - Int(_stream.avail_out)
            if count != 0 {
                value.appendContentsOf(_outBuffer[0...count])
            }
            return value
        }
        
        /// deflate( strm: z_streamp, flush: Int32 )
        private func _deflate( flush: FlushVariation = .NoFlush) throws -> CInt {
            let ret = deflate(&_stream, flush.rawValue)
            switch ret {
            case Z_OK:
                break
            case Z_STREAM_END:
                break
            case Z_NEED_DICT:
                break
            case Z_MEM_ERROR:
                throw ZError.MemoryError(message: String.fromCString(_stream.msg)!)
            case Z_BUF_ERROR:
                throw ZError.BufferError(message: String.fromCString(_stream.msg)!)
            case Z_DATA_ERROR:
                throw ZError.DataError(message: String.fromCString(_stream.msg)!)
            case Z_VERSION_ERROR:
                throw ZError.VersionError(message: String.fromCString(_stream.msg)!)
            case Z_STREAM_ERROR:
                throw ZError.StreamError(message: String.fromCString(_stream.msg)!)
            default:
                throw ZError.UnknownError(returnCode: ret)
            }
            return ret
            
        }
        
        /// deflateBound( strm: z_streamp, sourceLen: uLong )
        func Bound() -> UInt{
//            return deflateBound(&stream, <#T##sourceLen: uLong##uLong#>)
            return 0
        }

        /// deflateCopy( dest: z_stramp, source: z_streamp )
        func duplicate() throws -> Deflate {
            let dest:Deflate = try Deflate()
            deflateEnd(&dest._stream)
            deflateCopy(&dest._stream, &_stream)
            return dest
        }

        /// defalteParams( strm: z_steramp, level: Int32, strategy: Int32 )
        func params(level:CompressionLevel, strategy: CompressionStrategy) throws{
            let ret = deflateParams(&_stream, level.rawValue, strategy.rawValue)
            switch ret {
            case Z_OK:
                break
            case Z_BUF_ERROR:
                throw ZError.BufferError(message: String.fromCString(_stream.msg)!)
            case Z_STREAM_ERROR:
                throw ZError.StreamError(message: String.fromCString(_stream.msg)!)
            default:
                throw ZError.UnknownError(returnCode: ret)
            }
        }

        /// deflatePrime( strm: z_streamp, bits: Int32, value: Int32 )
        func prime(bits:Int32, value:PossibleValues) throws {
            let ret = deflatePrime(&_stream, bits, value.rawValue)
            switch ret {
            case Z_OK:
                break
            case Z_BUF_ERROR:
                throw ZError.BufferError(message: String.fromCString(_stream.msg)!)
            case Z_STREAM_ERROR:
                throw ZError.StreamError(message: String.fromCString(_stream.msg)!)
            default:
                throw ZError.UnknownError(returnCode: ret)
            }
        }

        /// deflateReset( strm: z_streamp )
        func reset() throws {
            let ret = deflateReset(&_stream)
            switch ret {
            case Z_OK:
                break
            case Z_STREAM_ERROR:
                throw ZError.StreamError(message: String.fromCString(_stream.msg)!)
            default:
                throw ZError.UnknownError(returnCode: ret)
            }
        }

        /// deflateSetDictionary( strm: z_streamp, dictionary: UnsafePointer<Bytef>, dictLength: uInt )
        func setDictionary(dictionary: Array<UInt8>) throws {
            let ret = deflateSetDictionary(&_stream, dictionary, CUnsignedInt(dictionary.count))
            switch ret {
            case Z_OK:
                break
            case Z_STREAM_ERROR:
                throw ZError.StreamError(message: String.fromCString(_stream.msg)!)
            default:
                throw ZError.UnknownError(returnCode: ret)
            }
        }

        /// deflateSetHeader( strm: z_streamp, head: gz_headerp )
        func setHeader(inout header: gz_header) throws {
            let ret = deflateSetHeader(&_stream, &header)
            switch ret {
            case Z_OK:
                break
            case Z_BUF_ERROR:
                throw ZError.BufferError(message: String.fromCString(_stream.msg)!)
            case Z_STREAM_ERROR:
                throw ZError.StreamError(message: String.fromCString(_stream.msg)!)
            default:
                throw ZError.UnknownError(returnCode: ret)
            }
        }

        /// deflateTune( strm: z_stramp, good_length: Int32, max_lazy: Int32, nice_length: Int32, max_chain: Int32 )
        func tune( good_length:Int32, max_lazy:Int32, nice_length:Int32, max_chain:Int32) throws {
            let ret = deflateTune(&_stream, good_length, max_lazy, nice_length, max_chain)
            switch ret {
            case Z_OK:
                break
            case Z_BUF_ERROR:
                throw ZError.BufferError(message: String.fromCString(_stream.msg)!)
            case Z_STREAM_ERROR:
                throw ZError.StreamError(message: String.fromCString(_stream.msg)!)
            default:
                throw ZError.UnknownError(returnCode: ret)
            }
        }
    }
    
    class GzFile {
        var file : gzFile
        init(filename:String, mode:String){
            file = gzopen(filename, mode)
        }

        /// gzclose( file: gzFile )
        deinit{
            gzclose(file)
        }

        /// gzbuffer( file: gzFile, size: UInt32 )
        func buffer(){
        
        }

        /// gzclearerr( file: gzFile )
        func clearerr(){}

        /// gzclose_r( file: gzFile )
        func close_r(){}

        /// gzclose_w( file: gzFile )
        func close_w(){}

        /// gzdirect( file: gzFile )
        func direct(){}

        /// gzdopen( fd: Int32, mode: UnsafePointer<Int8>)
        func dopen(){}

        /// gzeof( file: gzFile )
        func eof(){}

        /// gzerror(file: gzFile, errnum: UnsafeMutablePointer<Int32> )
        func error(){}

        // gzflush(file: gzFile, flush: Int32 )
        func flush(){}

        /// gzgetc(file: gzFile )
        func getc(){}

        /// gzgets( file: gzFile, buf: UnsafeMutablePointer<Int8>, len: Int32 )
        func gets(){}

        /// gzoffset( gzFile )
        func offset(){}

        /// gzputc( file: gzFile, c: Int32 )
        func putc(){}

        /// gzputs( file: gzFile, s: UnsafePointer<Int8> )
        func puts(){}

        /// gzread(file: gzFile, buf: voidp, len: UInt32 )
        func read(){}

        /// gzrewind( file: gzFile )
        func rewind(){}

        /// gzseek(gzFIle, Int, Int32 )
        func seek(){}

        /// gzsetparams( file: gzFile, level: Int32, strategy: Int32 )
        func setParams(){}

        /// gztell( gzFile )
        func tell(){}

        /// gzungetc( c: Int32, file: gzFile )
        func ungetc(){}

        /// gzwrite( file: gzFile, buf: voidpc, len: UInt32 )
        func write(){}
    }
    
}