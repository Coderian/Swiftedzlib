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
        case StreamEnd
        case NeedDictionary
        case ErrNo
        case StreamError
        case DataError
        case MemoryError
        case BufferError
        case VersionError
        case UnknownError
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
    
    public static var version:String? {
        return String.fromCString(zlibVersion())
    }
    var buffer = Array<UInt8>(count:Int(BUFSIZ), repeatedValue:  0)
    var sizeOfCompressBuffer:CUnsignedLong = 0
    var sizeOfOriginalBuffer:Int = 0

    /// adler32( adler: uLong, buf: UnsafePointer<Bytef>, len: uInt)
    public static func toAdler32(adler:CUnsignedLong , buffer: Array<UInt8> ) -> CUnsignedLong {
        return adler32(adler, buffer, CUnsignedInt(buffer.count))
    }

    /// crc32( crc: uLong, buf: UnsafePointer<bytef>, len: uInt )
    public static func toCrc32(crc:CUnsignedLong, buffer:Array<UInt8> ) -> CUnsignedLong {
        return crc32(crc, buffer, CUnsignedInt(buffer.count) )
    }
    
    /// compress(dest: UnsafeMutablePointer<Bytef>, destLen: UnsafeMutablePointer<uLongf>, source: UnsafePointer<Bytef>, sourceLen: uLong )
    public mutating func toCompress(source: Array<UInt8>) throws -> Array<UInt8> {
        sizeOfOriginalBuffer = source.count
        sizeOfCompressBuffer = compressBound(CUnsignedLong(source.count))
        var dest = Array<Bytef>(count:Int(sizeOfCompressBuffer), repeatedValue: 0)
        var destlen:CUnsignedLong = CUnsignedLong(dest.count)
        let ret = compress(&dest, &destlen, source, CUnsignedLong(source.count))
        switch(ret){
        case Z_OK:
            let retValue = dest.prefix(Int(destlen)).map({UInt8($0)})
            return retValue
        case Z_MEM_ERROR:
            throw ZError.MemoryError
        case Z_BUF_ERROR:
            throw ZError.BufferError
        default:
            throw ZError.UnknownError
        }
    }
    
    /// compress2( dest: UnsafeMutablePointer<Bytef>, destLen: UnsafeMutablePointer<uLongf>, source: UnsafePointer<Bytef>, sourceLen: uLong, level: Int32 )
    public mutating func toCompress(source: Array<UInt8>, level: CompressionLevel) throws -> Array<UInt8> {
        sizeOfOriginalBuffer = source.count
        sizeOfCompressBuffer = compressBound(CUnsignedLong(source.count))
        var dest = Array<Bytef>(count:Int(sizeOfCompressBuffer), repeatedValue: 0)
        var destlen:CUnsignedLong = CUnsignedLong(dest.count)
        let ret = compress2(&dest, &destlen, source, CUnsignedLong(source.count), level.rawValue)
        switch(ret){
        case Z_OK:
            return dest
        case Z_MEM_ERROR:
            throw ZError.MemoryError
        case Z_BUF_ERROR:
            throw ZError.BufferError
        default:
            throw ZError.UnknownError
        }
    }
    
    /// uncompress(dest: UnsafeMutablePointer<Bytef>, destLen: UnsafeMutablePointer<uLongf>, source: UnsafePointer<Bytef>, sourceLen: uLong)
    public func toUncompress( source: Array<UInt8>) throws -> Array<UInt8> {
        var dest = Array<Bytef>(count:Int(sizeOfOriginalBuffer), repeatedValue: 0)
        var destlen:CUnsignedLong = CUnsignedLong(dest.count)
        let ret = uncompress(&dest, &destlen, source, CUnsignedLong(source.count))
        switch(ret){
        case Z_OK:
            return dest
        case Z_MEM_ERROR:
            throw ZError.MemoryError
        case Z_BUF_ERROR:
            throw ZError.BufferError
        default:
            throw ZError.UnknownError
        }
    }
    
    public static func toUncompress( source: Array<UInt8>, sizeOfOriginalBuffer:Int ) throws -> Array<UInt8> {
        var dest = Array<Bytef>(count:Int(sizeOfOriginalBuffer), repeatedValue: 0)
        var destlen:CUnsignedLong = CUnsignedLong(dest.count)
        let ret = uncompress(&dest, &destlen, source, CUnsignedLong(source.count))
        switch(ret){
        case Z_OK:
            return dest
        case Z_MEM_ERROR:
            throw ZError.MemoryError
        case Z_BUF_ERROR:
            throw ZError.BufferError
        default:
            throw ZError.UnknownError
        }
    }
    
    /// dompressBound( sourceLen: uLong )
    func doCompressBound(){}

    
    ///
    public class Inflate {
        var stream: z_stream
        var inBuffer = Array<UInt8>(count:Int(BUFSIZ),repeatedValue:0)
        var outBuffer = Array<UInt8>(count:Int(BUFSIZ), repeatedValue: 0)
        
        /// initilize
        ///
        /// zlib.h
        ///
        ///     inflateInit2_( strm: z_streamp, windowBits: Int32, version: UnsafePointer<Int8>, stream_size: Int32 )
        init(windowBits:CInt){
            stream = z_stream(next_in: nil, avail_in: 0, total_in: 0, next_out: nil, avail_out: 0, total_out: 0, msg: nil, state: nil, zalloc: nil, zfree: nil, opaque: nil, data_type: 0, adler: 0, reserved: 0)
            let ret = inflateInit2_(&stream, windowBits, ZLIB_VERSION, CInt(sizeof(z_stream)))
            if ret != Z_OK {
                // TODO:
            }
        }
        /// initilize
        ///  inflateInit_( strm: z_streamp, version: UnsafePointer<Int8>, stream_size: Int32 )
        init(){
            stream = z_stream(next_in: nil, avail_in: 0, total_in: 0, next_out: nil, avail_out: 0, total_out: 0, msg: nil, state: nil, zalloc: nil, zfree: nil, opaque: nil, data_type: 0, adler: 0, reserved: 0)
            inflateInit_(&stream, ZLIB_VERSION, CInt(sizeof(z_stream)))
        }
        ///
        /// inflateEnd( strm: z_streamp )
        deinit{
            inflateEnd(&stream)
        }
        
        func doInflate(sourceFileName:String, destFileName:String){
            
        }

        /// inflate( strm: z_streamp, flush: Int32 )
        private func doInflate(flush:FlushVariation = .NoFlush){
            inflate(&stream, flush.rawValue)
        }

        /// inflateCopy( dest: z_streamp, source: z_streamp )
        func duplicate() -> Inflate {
            let dest:Inflate = Inflate()
            inflateEnd(&dest.stream)
            inflateCopy(&dest.stream, &self.stream)
            return dest
        }

        /// inflateGetHeader( strm: z_streamp, head: gz_headerp )
        func getHeader() -> gz_header {
            var header = gz_header()
            inflateGetHeader(&stream, &header)
            return header
        }

        /// inflateMark( strm: z_streamp )
        func mark() -> CLong{
            return inflateMark(&stream)
        }

        /// inflatePrime( strm: z_streamp, bits: Int32, value: Int32 )
        func prime(bits:CInt, value:PossibleValues){
            inflatePrime(&stream, bits, value.rawValue)
        }

        /// inflateReset( strm: z_streamp )
        func reset(){
            inflateReset(&stream)
        }

        /// inflateReset2( strm: z_streamp, windowBits: Int32 )
        func reset(windowBits:CInt){
            inflateReset2(&stream, windowBits)
        }

        /// inflateSetDictionary( strm: z_streamp, dictionary: UnsafePointer<Bytef>, dictLength: uInt )
        func setDictionary(){
        }

        /// inflateSync( strm: z_streamp )
        func sync(){
            inflateSync(&stream)
        }


        /// inflateBackInit_( strm: z_streamp, windowBits: Int32, window: UnsafeMutalbePointer<UInt8>, version: UnsafePointer<Int8>, stream_size: Int32 )
        func backInit(){}
        
        /// inflateBackEnd( strm: z_streamp )
        func backEnd(){}
        
        /// inflateBack( strm: z_streamp, `in`: in_func!, in_desc: UnsafeMutablePointer<Void>, out: out_func!, out_desc: UnsafeMutablePointer<Void>)
        func back(){}
    }
    
    public class Deflate {
        var stream : z_stream
        var inBuffer = Array<UInt8>(count:Int(BUFSIZ),repeatedValue:0)
        var outBuffer = Array<UInt8>(count:Int(BUFSIZ), repeatedValue: 0)
        
        /// deflateInit_( strm: z_streamp, level: Int32, version: UnsafePointer<Int8>, stream_size: Int32 )
        init(level:CompressionLevel = .Default){
            stream = z_stream(next_in: nil, avail_in: 0, total_in: 0, next_out: nil, avail_out: 0, total_out: 0, msg: nil, state: nil, zalloc: nil, zfree: nil, opaque: nil, data_type: 0, adler: 0, reserved: 0)
            deflateInit_(&stream, level.rawValue, ZLIB_VERSION, CInt(sizeof(z_stream)))
        }

        /// defalteInit2_( strm: z_stramp, level: Int32, method: Int32, windowBits: Int32, memLevel: Int32, strategy: Int32, version: UnsafePointer<Int8>, stream_size: Int32 )
        init(level:CInt, method:CInt, windowBits:CInt, memLevel:CInt, strategy:CInt){
            stream = z_stream(next_in: nil, avail_in: 0, total_in: 0, next_out: nil, avail_out: 0, total_out: 0, msg: nil, state: nil, zalloc: nil, zfree: nil, opaque: nil, data_type: 0, adler: 0, reserved: 0)
            deflateInit2_(&stream, level, method, windowBits, memLevel, strategy, ZLIB_VERSION, CInt(sizeof(z_stream)))
        }
        /// deflateEnd( strm: z_streamp )
        deinit{
            deflateEnd(&stream)
        }

        /// deflate( strm: z_streamp, flush: Int32 )
        private func doDeflate( flush: FlushVariation = .NoFlush) -> CInt {
            return deflate(&stream, flush.rawValue)
        }
        
        /// deflateBOund( strm: z_streamp, sourceLen: uLong )
        func Bound(){
        
        }

        /// deflateCopy( dest: z_stramp, source: z_streamp )
        func duplicate() -> Deflate {
            let dest:Deflate = Deflate()
            deflateEnd(&dest.stream)
            deflateCopy(&dest.stream, &self.stream)
            return dest
        }

        /// defalteParams( strm: z_steramp, level: Int32, strategy: Int32 )
        func params(level:CompressionLevel, strategy: CompressionStrategy){
            deflateParams(&stream, level.rawValue, strategy.rawValue)
        }

        /// deflatePrime( strm: z_streamp, bits: Int32, value: Int32 )
        func prime(bits:CInt, value:PossibleValues){
            deflatePrime(&stream, bits, value.rawValue)
        }

        /// deflateReset( strm: z_streamp )
        func reset(){
            deflateReset(&stream)
        }

        /// deflateSetDictionary( strm: z_streamp, dictionary: UnsafePointer<Bytef>, dictLength: uInt )
        func setDictionary(){
        
        }

        /// deflateSetHeader( strm: z_streamp, head: gz_headerp )
        func setHeader(){
        
        }

        /// deflateTune( strm: z_stramp, good_length: Int32, max_lazy: Int32, nice_length: Int32, max_chain: Int32 )
        func tune(){
        
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