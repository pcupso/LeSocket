//
//  LeByteStream.m
//  LeSocketLibrary
//
//  Created by caic on 16/5/18.
//  Copyright © 2016年 caic. All rights reserved.
//

#import "LeByteStream.h"

@implementation LeByteStream

- (instancetype)initWithBuff:(Byte *)lpData isNetOrder:(BOOL)bIsNetOrder
{
    if (self == [super init])
    {
        m_pBuf = lpData;
        m_bNetOrder = bIsNetOrder;
        m_bManaged = NO;
        m_nMaxSize = 0;
        m_nCurPos = 0;
    }
    return self;
}

- (instancetype)initWithSize:(unsigned int)nBufSize isNetOrder:(BOOL)bIsNetOrder
{
    if (self == [super init])
    {
        m_pBuf = (Byte *)malloc(nBufSize);
        m_bNetOrder = bIsNetOrder;
        m_bManaged = YES;
        m_nMaxSize = nBufSize;
        m_nCurPos = 0;
    }
    return self;
}

-(void)setCurPos:(unsigned int)curPos{
    m_nCurPos = curPos;
}

-(unsigned int)curPos{
    return m_nCurPos;
}

-(void)Skip:(unsigned int)nSkip
{
    m_nCurPos += nSkip;
}

-(Byte *)GetDataBuf
{
    return m_pBuf;
}

-(void)readBytes:(Byte *)pData dataSize:(unsigned int)nDataSize
{
    if (!pData || nDataSize == 0) return;
    
    memcpy(pData, m_pBuf + m_nCurPos, nDataSize);
    m_nCurPos += nDataSize;
}

-(void)writeBytes:(Byte *)pData dataSize:(unsigned int)nDataSize
{
    if (!pData || nDataSize == 0) return;
    
    memcpy(m_pBuf + m_nCurPos, pData, nDataSize);
    m_nCurPos += nDataSize;
}


- (NSString *)readString
{
    char * pStr = (char *)(m_pBuf + m_nCurPos);
    m_nCurPos += ((unsigned int)strlen(pStr) + 1);
    
    NSString *retStr = [NSString stringWithCString:pStr encoding:NSUTF8StringEncoding];
    return retStr;
}

- (void)writeString:(NSString *)string
{
    if (0 == [string length]) return;
    
    NSData *bytes = [string dataUsingEncoding:NSUTF8StringEncoding];
    strncpy((char *)m_pBuf + m_nCurPos, (char *)[bytes bytes], strlen([bytes bytes]));
    
    *(m_pBuf + m_nCurPos) = '\0';
    m_nCurPos++;
    
}

- (void)readStr:(char *)str
{
    char * pStrLocal = (char *)(m_pBuf + m_nCurPos);
    m_nCurPos += ((unsigned int)strlen(pStrLocal) + 1);
    
    strncpy(str, pStrLocal, strlen(pStrLocal));
}

- (void)writeStr:(const char *)str
{
    if (str != nil)
    {
        strncpy((char *)m_pBuf + m_nCurPos, str, strlen(str));
        m_nCurPos += (unsigned int)strlen(str);
    }
    
    *(m_pBuf + m_nCurPos) = '\0';
    m_nCurPos ++;
}


- (void)inputUnsignedchar:(unsigned char)ch
{
    m_pBuf[m_nCurPos++] = ch;
}

- (void)inputChar:(char)ch
{
    m_pBuf[m_nCurPos++] = (unsigned char)ch;
}

- (void)inputUnsignedshort:(unsigned short)s
{
    unsigned short sLocal = s;
    if (m_bNetOrder) {
        sLocal = htons((unsigned short)s);
    }
    [self writeBytes:(Byte *)&sLocal dataSize:sizeof(unsigned short)];
}

- (void)inputShort:(short)s
{
    short sLocal = (short)s;
    if (m_bNetOrder) {
        sLocal = htons((short)s);
    }
    [self writeBytes:(Byte *)&sLocal dataSize:sizeof(short)];
}

- (void)inputUnsignedint:(unsigned int)i
{
    unsigned int iLocal = (unsigned int)i;
    if (m_bNetOrder){
        iLocal = htonl((unsigned int)i);
    }
    [self writeBytes:(Byte *)&iLocal dataSize:sizeof(unsigned int)];
}

- (void)inputInt:(int)i
{
    int iLocal = i;
    if (m_bNetOrder){
        iLocal = htonl(i);
    }
    [self writeBytes:(Byte *)&iLocal dataSize:sizeof(int)];
}


- (unsigned char)outputUnsignedchar
{
    unsigned char ch = (unsigned char)m_pBuf[m_nCurPos ++];
    return ch;
}

- (char)outputChar
{
    char ch = (char)m_pBuf[m_nCurPos ++];
    return ch;
}

- (unsigned short)outputUnsignedshort
{
    unsigned short s = 0;
    [self readBytes:(Byte *)&s dataSize:sizeof(unsigned short)];
    if (m_bNetOrder){
        return ntohs(s);
    }
    return s;
}

- (short)outputShort
{
    short s = 0;
    [self readBytes:(Byte *)&s dataSize:sizeof(short)];
    if (m_bNetOrder){
        return (short)ntohs(s);
    }
    return (short)s;
}

- (unsigned int)outputUnsignedint
{
    unsigned int i = 0;
    [self readBytes:(Byte *)&i dataSize:sizeof(unsigned int)];
    if (m_bNetOrder){
        unsigned int x = ntohl(i);
        return x;
    }
    return i;
}

- (int)outputInt
{
    int i = 0;
    [self readBytes:(Byte *)&i dataSize:sizeof(int)];
    if (m_bNetOrder){
        return (int)ntohl(i);
    }
    return (int)i;
}





@end
