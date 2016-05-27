//
//  LeSocketManager.h
//  LeSocketLibrary
//
//  Created by caic on 16/5/26.
//  Copyright © 2016年 caic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LeSocket.h"
#import "LeByteStream.h"

typedef void (^LSSendDataErrorBlock)(int nPDU, int nReason);
typedef void (^LSDataRecvBlock)(Byte *lpData, unsigned int uDataSize);
typedef void (^LSConnStatusChangedBlock)(int nStatus);


@interface LeSocketManager : NSObject <LeSocketCallbackDelegate, LeSocketDataCallbackDelegate, LeSocketTCPHeaderParseCallbackDelegate>


//- (instancetype)createServerWithAddr:(NSString *)serverAddr
//                          serverPort:(unsigned short)serverPort
//                       dataRecvBlock:(LSDataRecvBlock)dataRecvBlock
//              connStatusChangedBlock:(LSConnStatusChangedBlock)connStatusChangedBlock
//                  sendDataErrorBlock:(LSSendDataErrorBlock)sendDataErrBlock;


- (instancetype)createClientWithAddr:(NSString *)serverAddr
                          serverPort:(unsigned short)serverPort
                       dataRecvBlock:(LSDataRecvBlock)dataRecvBlock
              connStatusChangedBlock:(LSConnStatusChangedBlock)connStatusChangedBlock
                  sendDataErrorBlock:(LSSendDataErrorBlock)sendDataErrBlock;


- (void)sendData:(int)nPDUType
       dataBody:(Byte *)lpData
       dataSize:(unsigned int)uDataSize;

@end
