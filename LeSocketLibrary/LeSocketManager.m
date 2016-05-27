//
//  LeSocketManager.m
//  LeSocketLibrary
//
//  Created by caic on 16/5/26.
//  Copyright © 2016年 caic. All rights reserved.
//

#import "LeSocketManager.h"

#define MAXCOUNT_DEALT_INTIMERFUNC  5

@interface LeSocketManager()

@property(nonatomic, strong) NSString *mServerAddr;
@property(nonatomic, assign) unsigned short mServerPort;

@property(nonatomic, strong) NSMutableArray *mSendDataArr;

@property(nonatomic, strong) LSDataRecvBlock mDataRecvBlock;
@property(nonatomic, strong) LSConnStatusChangedBlock mConnStatusChangedBlock;
@property(nonatomic, strong) LSSendDataErrorBlock mSendDataErrorBlock;

@property(nonatomic, strong) NSTimer *mSendDataTimer;
@property(nonatomic, assign) int mIdleTimes;

@property(nonatomic, strong) LeSocket *mSocket;
@property(nonatomic, assign) id<LeSocketSendComponentDelegate> mSendDataComponent;

@end



@implementation LeSocketManager
- (instancetype)init
{
    if (self = [super init])
    {
        _mSendDataArr = [[NSMutableArray alloc] initWithCapacity:1];
        _mSendDataTimer = [NSTimer timerWithTimeInterval:1.0 target:self selector:@selector(sendDataAction:) userInfo:nil repeats:YES];
        
    }
    return self;
}


//- (instancetype)createServerWithAddr:(NSString *)serverAddr
//                          serverPort:(unsigned short)serverPort
//                       dataRecvBlock:(LSDataRecvBlock)dataRecvBlock
//              connStatusChangedBlock:(LSConnStatusChangedBlock)connStatusChangedBlock
//                  sendDataErrorBlock:(LSSendDataErrorBlock)sendDataErrBlock
//{
//    _mServerAddr = @"127.0.0.1";
//    if ([serverAddr length] != 0) {
//        _mServerAddr = serverAddr;
//    }
//    
//    if ([self init])
//    {
//        _mServerPort = serverPort;
//        _mDataRecvBlock = dataRecvBlock;
//        _mConnStatusChangedBlock = connStatusChangedBlock;
//        _mSendDataErrorBlock = sendDataErrBlock;
//        
//        _mSocket = [[LeSocket alloc] initWithTCPServerAddr:_mServerAddr serverPort:_mServerPort];
//        [_mSocket setMCallback:self];
//        [_mSocket setMDataCallback:self];
//        [_mSocket setMTCPHeaderParseCallback:self];
//    }
//    return self;
//}


- (instancetype)createClientWithAddr:(NSString *)serverAddr
                          serverPort:(unsigned short)serverPort
                       dataRecvBlock:(LSDataRecvBlock)dataRecvBlock
              connStatusChangedBlock:(LSConnStatusChangedBlock)connStatusChangedBlock
                  sendDataErrorBlock:(LSSendDataErrorBlock)sendDataErrBlock
{
    if ([serverAddr length] == 0) {
        NSLog(@"服务器地址不能为空");
        return nil;
    }
    
    if ([self init])
    {
        _mServerAddr = serverAddr;
        _mServerPort = serverPort;
        _mDataRecvBlock = dataRecvBlock;
        _mConnStatusChangedBlock = connStatusChangedBlock;
        _mSendDataErrorBlock = sendDataErrBlock;
        
        _mSocket = [[LeSocket alloc] initWithTCPClientAddr:@"127.0.0.1"
                                                 localPort:_mServerPort
                                                serverAddr:_mServerAddr
                                                serverPort:_mServerPort];
        [_mSocket setMCallback:self];
        [_mSocket setMDataCallback:self];
        [_mSocket setMTCPHeaderParseCallback:self];
        
        
    }
    
    return self;
}

#pragma mark - 
- (void)sendDataAction:(NSTimer *)timer
{
    _mIdleTimes = 0;
    
    if (!_mSocket && [_mSocket curStatus] == 0)
    {
        [_mSocket createNewSocket];
        [_mSocket socketBeginToWork];
    }
    
    if (!_mSendDataComponent) return;
    
    int nDealtCount = 0;
    
    for (int i = 0; i < [_mSendDataArr count]; i++)
    {
        if (nDealtCount > MAXCOUNT_DEALT_INTIMERFUNC) return;
        
        LeByteStream *sendDataStream = [_mSendDataArr objectAtIndex:i];
        
        int nRet = [_mSendDataComponent sendData:[sendDataStream GetDataBuf]
                                        dataSize:[sendDataStream curPos]
                                   remoteNetAddr:0
                                   remoteNetPort:0
                                         extInfo:0];
        
        nDealtCount++;
        
        if (nRet != 0) {
            // Error occurred in sending data
            break;
        }
        
        if ([_mSendDataArr count] > 0) {
            [_mSendDataArr removeObjectAtIndex:0];
        }
    }
}

- (void)sendData:(int)nPDUType
       dataBody:(Byte *)lpData
       dataSize:(unsigned int)uDataSize
{
    LeByteStream *byteStream = [[LeByteStream alloc] initWithSize:[self dataSizeToSend:uDataSize] isNetOrder:YES];
    [byteStream inputInt:nPDUType];
    [byteStream writeBytes:lpData dataSize:uDataSize];
    [_mSendDataArr addObject:byteStream];
}


- (unsigned int)dataSizeToSend:(int)uSendDataSize
{
    unsigned int nRetVal = 0;
    
    nRetVal += sizeof(int) * 1  // PDUType
    + uSendDataSize;            // dataSize
    
    return nRetVal;
    
}


#pragma mark - LeSocketCallbackDelegate
- (void)onCreateSocketResult:(int)nResult sendComponent:(id<LeSocketSendComponentDelegate>)pSendComponent
{
    NSLog(@"--- CronCreateSocketResult: reulst=%d", nResult);
    
    if (nResult == 0) {
        _mSendDataComponent = pSendComponent;
        [_mSendDataTimer fire];
    }
}

- (void)onCertainSocketClose:(int)nReason index:(int)nIndex
{
    [_mSocket closeCertainSocket];
    _mSendDataComponent = nil;
}

#pragma mark - LeSocketDataCallbackDelegate
- (void)onDataRecv:(Byte *)lpData dataSize:(unsigned int)uDataSize netAddrRemote:(unsigned long)uRemoteNetAddr netPortRemote:(unsigned short)uRemoteNetPort extInfo:(int)nExtInfoIndex
{
    //LeByteStream *byteSteam = [[LeByteStream alloc] initWithBuff:lpData isNetOrder:YES];
    
    if (_mDataRecvBlock) {
        _mDataRecvBlock(lpData, uDataSize);
    }
}

#pragma mark - LeSocketTCPHeaderParseCallbackDelegate
- (int)ParseTCPHeader:(Byte *)lpDataTCPHeader
    dataSizeTCPHeader:(unsigned int)uDataSizeTCPHeader
      dataSizeTCPBody:(unsigned int *)uDataSizeTCPBodySize
     dataSizeNeedMore:(unsigned int *)uDataSizeNeedMore
{
    LeByteStream *byteStream = [[LeByteStream alloc] initWithBuff:lpDataTCPHeader isNetOrder:YES];
    
    *uDataSizeTCPBodySize = [byteStream outputInt];
    *uDataSizeNeedMore = 0;
    
    return 0;
}




@end
