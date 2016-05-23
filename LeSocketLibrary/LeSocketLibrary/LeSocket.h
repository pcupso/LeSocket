//
//  LeSocket.h
//  LeSocketLibrary
//
//  Created by caic on 16/5/17.
//  Copyright © 2016年 caic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LeSocketBaseObject.h"



#define MAXCONNECTION_TCPSERVERCANACCEPT    FD_SETSIZE

typedef NS_ENUM(NSInteger, RecordStatus) {
    kRecordStatusIdle = 0,
    kRecordStatusBusy,
};


typedef struct _tagStructExtLeSocketAbout
{
    int nRecordStatus;
    int nRecordIndex;
    int hSocket;
    BOOL bIsHead;
    unsigned int uDataSizeTotal;
    unsigned int uDataSizeRead;
    Byte * lpRecvDataHeader;
    Byte * lpRecvDataBody;
    
}StructExtLeSocketAbout, *LPStructExtLeSocketAbout;



@interface LeSocket : LeSocketBaseObject
{
    BOOL m_bConnectToServerOK;
    NSThread * m_ThreadConnectToServer;
    
    Byte * m_lpArrayMySocketAbout;
    int m_nCountArrayMySocketAbout;
    
    NSCondition * m_LockFD;
    NSCondition * m_LockSendData;
    
    fd_set m_SocketFDSet;
    
    int m_MaxFD;
    
    unsigned int m_uTCPHeaderSize;
    unsigned int m_uTCPHeaderSizeMin;
    unsigned int m_uMaxTCPBodySize;
}

@property (readonly, nonatomic) int curStatus;

- (instancetype)initWithTCPServerAddr:(NSString *)serverAddr
                           serverPort:(unsigned short)serverPort;

- (instancetype)initWithTCPClientAddr:(NSString *)localAddr
                            localPort:(unsigned short)localPort
                           serverAddr:(NSString *)serverAddr
                           serverPort:(unsigned short)serverPort;


- (int)createNewSocket;
- (int)closeCertainSocket;
- (int)socketBeginToWork;


- (int)connectToServer;
- (void)runConnectToServer;
- (void)runTCPRecv;

- (int)setupMySocketAboutArray;
- (int)addNewMySocketAbout:(int)hSocket
           alreadySetAsync:(BOOL)bHaveAlreadySetAsync;
- (int)removeCertainMySocketAbout:(int)nIndexVal
                        socketVal:(int)hSocket
                      inLockScope:(BOOL)bAlreadyInLockScope;



@end





