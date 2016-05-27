//
//  LeSocketLibrary.h
//  LeSocketLibrary
//
//  Created by caic on 16/5/17.
//  Copyright © 2016年 caic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LeSocketManager.h"

#define LeSocketSDK    [LeSocketLibrary sharedInstace]

@interface LeSocketLibrary : NSObject
{
    LeSocketManager *mSocketManager;
}

+ (instancetype) sharedInstace;

- (LeSocketManager *)createSocketWithServerAddr:(NSString *)serverAddr
                                     serverPort:(int)serverPort
                                  dataRecvBlock:(LSDataRecvBlock)dataRecvBlock
                         connStatusChangedBlock:(LSConnStatusChangedBlock)connStatusChangedBlock
                             sendDataErrorBlock:(LSSendDataErrorBlock)sendDataErrBlock;

- (void)sendData:(int)nPDUType
        dataBody:(Byte *)lpData
        dataSize:(unsigned int)uDataSize;

@end
