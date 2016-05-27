//
//  LeByteStream.h
//  LeSocketLibrary
//
//  Created by caic on 16/5/18.
//  Copyright © 2016年 caic. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LeByteStream : NSObject
{
    Byte * m_pBuf;
    unsigned int m_nCurPos;
    unsigned int m_nMaxSize;
    BOOL m_bNetOrder;
    BOOL m_bManaged;
}

@property (nonatomic, assign) unsigned int curPos;


- (instancetype)initWithBuff:(Byte *)lpData isNetOrder:(BOOL)bIsNetOrder;
- (instancetype)initWithSize:(unsigned int)nBufSize isNetOrder:(BOOL)bIsNetOrder;

-(void)readBytes:(Byte *)pData dataSize:(unsigned int)nDataSize;
-(void)writeBytes:(Byte *)pData dataSize:(unsigned int)nDataSize;


-(void)Skip:(unsigned int)nSkip;
-(Byte *)GetDataBuf;


- (NSString *)readString;
- (void)writeString:(NSString *)string;

- (void)readStr:(char *)str;
- (void)writeStr:(const char *)str;


- (void)inputUnsignedchar:(unsigned char)ch;
- (void)inputChar:(char)ch;
- (void)inputUnsignedshort:(unsigned short)s;
- (void)inputShort:(short)s;
- (void)inputUnsignedint:(unsigned int)i;
- (void)inputInt:(int)i;


- (unsigned char)outputUnsignedchar;
- (char)outputChar;
- (unsigned short)outputUnsignedshort;
- (short)outputShort;
- (unsigned int)outputUnsignedint;
- (int)outputInt;



@end
