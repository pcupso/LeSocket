//
//  LeSocketParseObject.h
//  LeSocketLibrary
//
//  Created by caic on 16/5/18.
//  Copyright © 2016年 caic. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, ProtocalSocketType) {
    kProtocalSocketTypeNull = 0,
    kProtocalSocketTypeTCP,
    kProtocalSocketTypeUDP,
};

typedef NS_ENUM(NSInteger, SocketCloseReason) {
    kSocketCloseReasonNormal = 0,
    kSocketCloseReasonReadError,
};


@protocol LeSocketSendComponentDelegate <NSObject>

- (int)sendData:(Byte *)lpData dataSize:(unsigned int)uDataSize
  remoteNetAddr:(unsigned long)uRemoteNetAddr remoteNetPort:(unsigned short)uRemoteNetPort extInfo:(int)nExtInfoIndex;

@end


@protocol LeSocketCallbackDelegate <NSObject>

- (void)onCreateSocketResult:(int)nResult sendComponent:(id<LeSocketSendComponentDelegate>)pSendComponent;
- (void)onCertainSocketClose:(int)nReason index:(int)nIndex;

@end


@protocol LeSocketDataCallbackDelegate <NSObject>

- (void)onDataRecv:(Byte *)lpData dataSize:(unsigned int)uDataSize netAddrRemote:(unsigned long)uRemoteNetAddr netPortRemote:(unsigned short)uRemoteNetPort extInfo:(int)nExtInfoIndex;

@end


@protocol LeSocketTCPHeaderParseCallbackDelegate <NSObject>

- (int)ParseTCPHeader:(Byte *)lpDataTCPHeader
    dataSizeTCPHeader:(unsigned int)uDataSizeTCPHeader
      dataSizeTCPBody:(unsigned int *)uDataSizeTCPBodySize
     dataSizeNeedMore:(unsigned int *)uDataSizeNeedMore;

@end



