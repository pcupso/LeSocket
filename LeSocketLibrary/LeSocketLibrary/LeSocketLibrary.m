//
//  LeSocketLibrary.m
//  LeSocketLibrary
//
//  Created by caic on 16/5/17.
//  Copyright © 2016年 caic. All rights reserved.
//

#import "LeSocketLibrary.h"

@implementation LeSocketLibrary

+ (instancetype) sharedInstace
{
    static id data = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        data = [[self alloc] init];
    });
    return data;
    
}

- (LeSocketManager *)createSocketWithServerAddr:(NSString *)serverAddr
                                     serverPort:(int)serverPort
                                  dataRecvBlock:(LSDataRecvBlock)dataRecvBlock
                         connStatusChangedBlock:(LSConnStatusChangedBlock)connStatusChangedBlock
                             sendDataErrorBlock:(LSSendDataErrorBlock)sendDataErrBlock
{
    mSocketManager = [[LeSocketManager alloc] createClientWithAddr:serverAddr
                                                        serverPort:serverPort
                                                     dataRecvBlock:dataRecvBlock
                                            connStatusChangedBlock:connStatusChangedBlock sendDataErrorBlock:sendDataErrBlock];
    return mSocketManager;
}


- (void)sendData:(int)nPDUType
        dataBody:(Byte *)lpData
        dataSize:(unsigned int)uDataSize
{
    if (mSocketManager) {
        [mSocketManager sendData:nPDUType dataBody:lpData dataSize:uDataSize];
    }
}


@end
