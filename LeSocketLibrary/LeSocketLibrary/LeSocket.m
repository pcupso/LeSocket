//
//  LeSocket.m
//  LeSocketLibrary
//
//  Created by caic on 16/5/17.
//  Copyright © 2016年 caic. All rights reserved.
//

#import "LeSocket.h"
#import "LeSocketParseObject.h"
#import "LeByteStream.h"
#import <sys/socket.h>
#import <netinet/in.h>
#import <arpa/inet.h>

#define MAXDATASIZE_TCPBODYDATA (1024 * 32)
#define NEED_IPV6  (defined(__IPHONE_OS_VERSION_MIN_REQUIRED) && __IPHONE_OS_VERSION_MIN_REQUIRED >= 90000) || (defined(__MAC_OS_X_VERSION_MIN_REQUIRED) &&  __MAC_OS_X_VERSION_MIN_REQUIRED >- 101100)

@implementation LeSocket

- (instancetype)initWithTCPServerAddr:(NSString *)serverAddr
                           serverPort:(unsigned short)serverPort
{
    if (self == [super init]) {
        mIsServer = YES;
        mServerAddr = serverAddr;
        mServerPort = serverPort;
        m_nCountArrayMySocketAbout = MAXCONNECTION_TCPSERVERCANACCEPT;
        
        [self initialize];
    }
    return self;
}

- (instancetype)initWithTCPClientAddr:(NSString *)localAddr
                            localPort:(unsigned short)localPort
                           serverAddr:(NSString *)serverAddr
                           serverPort:(unsigned short)serverPort
{
    if (self = [super init]) {
        m_MaxFD = -1;
        if (m_MaxFD < STDIN_FILENO) {
            m_MaxFD = STDIN_FILENO;
        }
        
        mIsServer = NO;
        mLocalAddr = (localAddr ? @"127.0.0.1" : localAddr);
        mLocalPort = localPort;
        mServerAddr = serverAddr;
        mServerPort = serverPort;
        m_nCountArrayMySocketAbout = 1;
        
        [self initialize];
    }
    return self;
}

- (void)initialize
{
    mSocket = -1;
    
    mStop = NO;
    mThreadRecv = nil;
    mThreadCall = nil;
    self.mCallback = nil;
    self.mDataCallback = nil;
    
    m_bConnectToServerOK = NO;
    m_ThreadConnectToServer = nil;
    m_lpArrayMySocketAbout = nil;
    m_LockFD = [[NSCondition alloc] init];
    m_LockSendData = [[NSCondition alloc] init];
    FD_ZERO(&m_SocketFDSet);
    
    m_uTCPHeaderSize = 0;
    m_uTCPHeaderSizeMin = 0;
    m_uMaxTCPBodySize = 0;
    
    _curStatus = 0;
}


- (int)createNewSocket
{
    mStop = NO;
    
#if NEED_IPV6
    
    struct sockaddr_in6 address;
    bzero(&address, sizeof(address));
    address.sin6_len = sizeof(address);
    address.sin6_port = htons(mLocalPort);
    address.sin6_family = AF_INET6;
    
    const char *lpszLocalAddr = NULL;
    if (mLocalAddr) {
        lpszLocalAddr = [mLocalAddr cStringUsingEncoding:NSUTF8StringEncoding];
    }
    if (lpszLocalAddr == NULL || strcmp(lpszLocalAddr, "")==0) {
        memcpy(address.sin6_addr.s6_addr, &lpszLocalAddr, sizeof(lpszLocalAddr));
    } else {
        static const uint8_t myaddr[16] = { 0xff, 0x02, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01 };
        memcpy(address.sin6_addr.s6_addr, myaddr, sizeof(myaddr));
    }
    
#else
    struct sockaddr_in address;
    bzero(&address, sizeof(address));
    address.sin_len = sizeof(address);
    address.sin_port = htons(mLocalPort);
    address.sin_family = AF_INET;
    
    const char *lpszLocalAddr = NULL;
    if (mLocalAddr) {
        lpszLocalAddr = [mLocalAddr cStringUsingEncoding:NSUTF8StringEncoding];
    }
    if (lpszLocalAddr == NULL || strcmp(lpszLocalAddr, "")==0) {
        address.sin_addr.s_addr = inet_addr(lpszLocalAddr);
    } else {
        address.sin_addr.s_addr = INADDR_ANY;
    }
#endif
    
    int nRet = bind(mSocket, (struct sockaddr*)&address, sizeof(address));
    
    if (nRet == -1) {
        close(mSocket);
        mSocket = -1;
    }
    
    _curStatus = -1;
    
    return 0;
}


- (int)closeCertainSocket
{
    mStop = YES;
    
    if (m_ThreadConnectToServer != nil) {
        while (![m_ThreadConnectToServer isFinished]) {
            [NSThread sleepForTimeInterval:0.1];
        }
    }
    
    if (mThreadRecv != nil) {
        while (![m_ThreadConnectToServer isFinished]) {
            [NSThread sleepForTimeInterval:0.1];
        }
    }
    
    FD_ZERO(&m_SocketFDSet);
    
    [m_LockFD lock];
    
    if (m_lpArrayMySocketAbout && m_nCountArrayMySocketAbout > 0) {
        for (int i = 0; i < m_nCountArrayMySocketAbout; i++) {
            LPStructExtLeSocketAbout pStructLeSocketAbout = (LPStructExtLeSocketAbout)(m_lpArrayMySocketAbout + i * sizeof(StructExtLeSocketAbout));
            
            if (pStructLeSocketAbout->hSocket != -1) {
                close(pStructLeSocketAbout->hSocket);
                pStructLeSocketAbout->hSocket = -1;
            }
            if (pStructLeSocketAbout->lpRecvDataHeader) {
                free(pStructLeSocketAbout->lpRecvDataHeader);
                pStructLeSocketAbout->lpRecvDataHeader = nil;
            }
            if (pStructLeSocketAbout->lpRecvDataBody) {
                free(pStructLeSocketAbout->lpRecvDataBody);
                pStructLeSocketAbout->lpRecvDataBody = nil;
            }
        }
        
        free(m_lpArrayMySocketAbout);
        m_lpArrayMySocketAbout = nil;
    }
    
    [m_LockFD unlock];
    
    _curStatus = 0;
    
    return 0;
}


- (int)socketBeginToWork
{
    int set = 1;
    setsockopt(mSocket, SOL_SOCKET, SO_NOSIGPIPE, (void*)&set, sizeof(int));
    
    int nSendBufSize = 0;
    int nRecvBufSize = 0;
    
    int nOptLen = sizeof(int);
    getsockopt(mSocket, SOL_SOCKET, SO_RCVBUF, (char*)&nRecvBufSize, (socklen_t *)&nOptLen);
    
    nOptLen = sizeof(int);
    getsockopt(mSocket, SOL_SOCKET, SO_SNDBUF, (char*)&nSendBufSize, (socklen_t *)&nOptLen);
    
    nSendBufSize *= 25;
    nRecvBufSize *= 25;
    
    if (setsockopt(mSocket, SOL_SOCKET, SO_RCVBUF, (char*)&nRecvBufSize, sizeof(int)) == -1)
    {
        close(mSocket);
        mSocket = -1;
        return -10;
    }
    
    if (setsockopt(mSocket, SOL_SOCKET, SO_SNDBUF, (char*)&nSendBufSize, sizeof(int)) == -1) {
        return -20;
    }
    
    if (mIsServer)
    {
        [self setupMySocketAboutArray];
    }
    else
    {
        struct linger l_linger;
        
        memset(&l_linger, 0, sizeof(struct linger));
        l_linger.l_onoff = 1;
        l_linger.l_linger = 0;
        
        if (setsockopt(mSocket, SOL_SOCKET, SO_LINGER, (const char *)&l_linger, sizeof(struct linger)) == -1)
        {
            close(mSocket);
            mSocket = -1;
            return -30;
        }
        
        int nVarFlag = fcntl(mSocket, F_GETFL, 0);
        if (nVarFlag == -1) {
            close(mSocket);;
            mSocket = -1;
            return -40;
        }
        
        fcntl(mSocket, F_SETFL, nVarFlag | O_NONBLOCK);
        
        int nRetVal = [self connectToServer];
        
        if (nRetVal != 0)
        {
            if (nRetVal != 100)
            {
                close(mSocket);
                mSocket = -1;
                return -50;
            }
            
            m_ThreadConnectToServer = [[NSThread alloc] initWithTarget:self selector:@selector(runConnectToServer) object:nil];
            [m_ThreadConnectToServer start];
        }
        else
        {
            m_bConnectToServerOK = YES;
            
            [self setupMySocketAboutArray];
            [self addNewMySocketAbout:mSocket alreadySetAsync:YES];
            
            
            LeSocketCreateSocketParseObject *object = [[LeSocketCreateSocketParseObject alloc] init];
            [object setNResultVal:0];
            
            [self performSelector:@selector(callback_onCreateSocketResult:)
                         onThread:mThreadCall
                       withObject:object
                    waitUntilDone:NO];
        }
    }
    
    mThreadRecv = [[NSThread alloc] initWithTarget:self selector:@selector(runTCPRecv) object:nil];
    [mThreadRecv start];
    
    return 0;
}


- (int)setupMySocketAboutArray
{
    [m_LockFD lock];
    
    m_uMaxTCPBodySize = MAXDATASIZE_TCPBODYDATA;
    m_uTCPHeaderSize = 20;
    m_uTCPHeaderSizeMin = 20;
    
    if (m_lpArrayMySocketAbout != nil) {
        free(m_lpArrayMySocketAbout);
        m_lpArrayMySocketAbout = nil;
    }
    
    m_lpArrayMySocketAbout = (Byte *)malloc(m_nCountArrayMySocketAbout * sizeof(StructExtLeSocketAbout));
    memset(m_lpArrayMySocketAbout, 0, m_nCountArrayMySocketAbout * sizeof(StructExtLeSocketAbout));
    
    for (int i = 0; i < m_nCountArrayMySocketAbout; i++)
    {
        LPStructExtLeSocketAbout pStructMySocketAbout = (LPStructExtLeSocketAbout)(m_lpArrayMySocketAbout + i * sizeof(LPStructExtLeSocketAbout));
        pStructMySocketAbout->nRecordStatus = kRecordStatusIdle;
    }
    
    [m_LockFD unlock];
    
    return 0;
}

- (void)runConnectToServer
{
    BOOL bNotFailed = FALSE;
    for (int i = 0; i < 10; i++)
    {
        if ([self shouldThreadStop])
        {
            bNotFailed = YES;
            break;
        }
        
        struct timeval tv;
        memset(&tv, 0, sizeof(struct timeval));
        tv.tv_sec = 0;
        tv.tv_usec = 500000;
        
        fd_set mySet;
        FD_ZERO(&mySet);
        FD_SET(mSocket, &mySet);
        
        int nRetLocal = select(mSocket + 1, NULL, &mySet, NULL, &tv);
        if (nRetLocal <= 0)
        {
            continue;
        }
        else if (nRetLocal > 0)
        {
            // Socket selected for write
            socklen_t nSocketLen = sizeof(int);
            int nValOpt = 0;
            if (getsockopt(mSocket, SOL_SOCKET, SO_ERROR, (void *)&nValOpt, &nSocketLen) < 0)
            {
                continue;
            }
            
            bNotFailed = TRUE;
            
            m_bConnectToServerOK = TRUE;
            _curStatus = 2;
            
            [self setupMySocketAboutArray];
            [self addNewMySocketAbout:mSocket alreadySetAsync:YES];
            
            LeSocketCreateSocketParseObject *object = [[LeSocketCreateSocketParseObject alloc] init];
            [object setNResultVal:0];
            [self performSelector:@selector(callback_onCreateSocketResult:)
                         onThread:mThreadCall
                       withObject:object
                    waitUntilDone:NO];
        }
    }
    
    if (!bNotFailed)
    {
        close(mSocket);
        mSocket = -1;
        
        LeSocketCreateSocketParseObject *object = [[LeSocketCreateSocketParseObject alloc] init];
        [object setNResultVal:-10];
        [self performSelector:@selector(callback_onCreateSocketResult:)
                     onThread:mThreadCall
                   withObject:object
                waitUntilDone:NO];
        _curStatus = 0;
    }
}

- (void)runTCPRecv
{
    struct timeval tv;
    memset(&tv, 0, sizeof(struct timeval));
    tv.tv_sec = 0;
    tv.tv_usec = 100;
    
    unsigned int uDataNeedToGet = 0;
    
    bool bIsHead = NO;
    
    int nIndexValue = -1;
    LPStructExtLeSocketAbout pStructLeSocketAbout = NULL;
    
    int hSocket = -1;
    unsigned int uDataRead = 0;
    int nDataRead = 0;
    int nRet = 0;
    bool bFind = NO;
    
    fd_set readFDs;
    
    bool bOut = NO;
    
    while (![self shouldThreadStop] && !bOut)
    {
        if (!mIsServer && !m_bConnectToServerOK)
        {
            [NSThread sleepForTimeInterval:0.2];
            continue;
        }
        
        FD_ZERO(&readFDs);
        readFDs = m_SocketFDSet;
        //First para of select needed under LINUX, so here set to 0
        nRet = select(m_MaxFD + 1, &readFDs, NULL, NULL, &tv);
        
        if (nRet == 0) {
            continue;
        }
        
        if (nRet < 0) {
            [NSThread sleepForTimeInterval:0.04];
            continue;
        }
        
        bFind = NO;
        for (int i = 0; i < m_nCountArrayMySocketAbout; i++)
        {
            LPStructExtLeSocketAbout pStructLeSocetAboutLocal = (LPStructExtLeSocketAbout)(m_lpArrayMySocketAbout + i * sizeof(LPStructExtLeSocketAbout));
            
            if (pStructLeSocetAboutLocal->nRecordStatus == kRecordStatusBusy &&
                pStructLeSocetAboutLocal->hSocket != -1)
            {
                if (FD_ISSET(pStructLeSocetAboutLocal->hSocket, &readFDs))
                {
                    hSocket = pStructLeSocetAboutLocal->hSocket;
                    nIndexValue = i;
                    pStructLeSocketAbout = pStructLeSocetAboutLocal;
                    bFind = true;
                    
                    break;
                }
            }
        }
        
        if (!bFind) {
            continue;
        }
        
        
        //////
        bIsHead = pStructLeSocketAbout->bIsHead;
        
        if (bIsHead)
        {
            uDataNeedToGet = m_uTCPHeaderSize - pStructLeSocketAbout->uDataSizeRead;
        }
        else
        {
            uDataNeedToGet = pStructLeSocketAbout->uDataSizeTotal - pStructLeSocketAbout->uDataSizeRead;
        }
        
        if (bIsHead)
        {
            nDataRead = (int)recv(hSocket, (char *)(pStructLeSocketAbout->lpRecvDataHeader + pStructLeSocketAbout->uDataSizeRead), (size_t)uDataNeedToGet, 0);
        }
        else
        {
            nDataRead = (int)recv(hSocket, (char *)(pStructLeSocketAbout->lpRecvDataBody + pStructLeSocketAbout->uDataSizeRead), (size_t)uDataNeedToGet, 0);
        }
        
        if (nDataRead <= 0)
        {
            int nCloseFlag = 0;
            if (nDataRead == 0)
            {
                nCloseFlag = kSocketCloseReasonNormal;
            }
            else
            {
                nCloseFlag = kSocketCloseReasonReadError;
            }
            
            LeSocketCertainSocketCloseParseObject *closeObject = [[LeSocketCertainSocketCloseParseObject alloc] init];
            [closeObject setNResultVal:nCloseFlag];
            [closeObject setNRemoteIndex:nIndexValue];
            [self performSelector:@selector(callback_onCertainSocketClosed:)
                         onThread:mThreadRecv
                       withObject:closeObject
                    waitUntilDone:NO];
            
            if (!mIsServer)
            {
                //For Client, uplayer will do action about RemoveCertainMySocketAbout
                break;
            }
            else
            {
                [self removeCertainMySocketAbout:nIndexValue socketVal:hSocket inLockScope:NO];
                continue;
            }
        }
        
        
        uDataRead = (unsigned int)nDataRead;
            
        if (uDataRead == uDataNeedToGet)
        {
            if (bIsHead)
            {
                unsigned int uHeaderSizeNeedMore = 0;
                unsigned int uDataBodyLength = 0;
                
                if (self.mTCPHeaderParseCallback && [self.mTCPHeaderParseCallback respondsToSelector:@selector(ParseTCPHeader:dataSizeTCPHeader:dataSizeTCPBody:dataSizeNeedMore:)])
                {
                    [self.mTCPHeaderParseCallback ParseTCPHeader:pStructLeSocketAbout->lpRecvDataHeader
                                               dataSizeTCPHeader:m_uTCPHeaderSize
                                                 dataSizeTCPBody:&uDataBodyLength
                                                dataSizeNeedMore:&uHeaderSizeNeedMore];
                }
                
                if (uHeaderSizeNeedMore == 0)
                {
                    pStructLeSocketAbout->bIsHead = NO;
                    pStructLeSocketAbout->uDataSizeRead = 0;
                    pStructLeSocketAbout->uDataSizeTotal = uDataBodyLength;
                    
                    m_uTCPHeaderSize = m_uTCPHeaderSizeMin;
                }
                else
                {
                    pStructLeSocketAbout->uDataSizeRead += uDataRead;
                    
                    m_uTCPHeaderSize = m_uTCPHeaderSizeMin + uHeaderSizeNeedMore;
                }
            }
            else
            {
                LeSocketDataRecvParseObject *recvObject = [[LeSocketDataRecvParseObject alloc] initWithParaData:pStructLeSocketAbout->lpRecvDataBody dataSize:pStructLeSocketAbout->uDataSizeTotal];
                [recvObject setMRemoteAddr:0];
                [recvObject setMRemotePort:0];
                [recvObject setMExtInfoIndex:nIndexValue];
                
                [self performSelector:@selector(callback_onDataRecv:)
                             onThread:mThreadCall
                           withObject:recvObject
                        waitUntilDone:NO];
                
                pStructLeSocketAbout->bIsHead = YES;
                pStructLeSocketAbout->uDataSizeRead = 0;
                pStructLeSocketAbout->uDataSizeTotal = m_uTCPHeaderSize;
                
            }
        }
        else
        {
            pStructLeSocketAbout->uDataSizeRead += uDataRead;
        }
    }
}

- (int)connectToServer
{
#if NEED_IPV6
    struct sockaddr_in6 remoteAddr;
    memset(&remoteAddr, 0, sizeof(struct sockaddr_in6));
    remoteAddr.sin6_family = AF_INET6;
    remoteAddr.sin6_port = htons(mServerPort);
    const char * lpszRemoteAddr = [mServerAddr cStringUsingEncoding:NSUTF8StringEncoding];
    memcpy(remoteAddr.sin6_addr.s6_addr, &lpszRemoteAddr, sizeof(lpszRemoteAddr));
#else
    struct sockaddr_in remoteAddr;
    memset(&remoteAddr, 0, sizeof(struct sockaddr_in));
    remoteAddr.sin_family = AF_INET;
    remoteAddr.sin_port = htons(mServerPort);
    remoteAddr.sin_addr.s_addr = inet_addr([mServerAddr cStringUsingEncoding : NSUTF8StringEncoding]);
#endif
    
    int nRet = connect(mSocket, (struct sockaddr *)&remoteAddr, sizeof(remoteAddr));
    
    if (nRet != 0)
    {
        if (errno == EINPROGRESS)
        {
            return 100;
        }
    }
    
    return nRet;
}

#pragma mark - SENDDATA
- (int)sendData:(Byte *)lpData
       dataSize:(unsigned int)uDataSize
  remoteNetAddr:(unsigned long)uRemoteNetAddr
  remoteNetPort:(unsigned short)uRemoteNetPort
        extInfo:(int)nExtInfoIndex
{
    if (nExtInfoIndex < 0) return -100;
    
    if (mIsServer)
    {
        if (nExtInfoIndex >= m_nCountArrayMySocketAbout)
        {
            return -101;
        }
    }
    else
    {
        if (nExtInfoIndex != 0)
        {
            return -102;
        }
    }
    
    LPStructExtLeSocketAbout pStructLeSocketAbout = (LPStructExtLeSocketAbout)(m_lpArrayMySocketAbout + nExtInfoIndex * sizeof(StructExtLeSocketAbout));
    
    if (pStructLeSocketAbout->nRecordStatus == kRecordStatusIdle)
    {
        return -103;
    }
    
    unsigned int uTotalSend = 0;
    unsigned int uDataSizeSend = uDataSize;
    
    [m_LockSendData lock];
    
    while ((uTotalSend <    uDataSize) && uDataSizeSend > 0)
    {
        int nRet = (int)send(pStructLeSocketAbout->hSocket, (char *)(lpData + uTotalSend), (size_t)uDataSizeSend, 0);
        
        if (nRet == -1)
        {
            if (errno == EWOULDBLOCK)
            {
                [NSThread sleepForTimeInterval:0.01];
                continue;
            }
            
            [m_LockSendData unlock];
            return -110;
        }
        
        uTotalSend += (unsigned int)nRet;
        uDataSizeSend -= (unsigned int)nRet;
    }
    
    [m_LockSendData unlock];
    return 0;
}


#pragma mark - handle socket
- (int)addNewMySocketAbout:(int)hSocket
           alreadySetAsync:(BOOL)bHaveAlreadySetAsync
{
    FD_SET(hSocket, &m_SocketFDSet);
    if (m_MaxFD < hSocket) {
        m_MaxFD = hSocket;
    }
    
    if (!bHaveAlreadySetAsync)
    {
        int nOpts = fcntl(hSocket, F_GETFL);
        if (nOpts < 0)
        {
            return -5;
        }
        
        nOpts = nOpts | O_NONBLOCK;
        if (fcntl(hSocket, F_SETFL, nOpts) < 0)
        {
            return -10;
        }
    }
    
    [m_LockFD lock];
    int nIndex = -1;
    for (int i = 0; i < m_nCountArrayMySocketAbout; i++)
    {
        LPStructExtLeSocketAbout pStrcutLeSocketAbout = (LPStructExtLeSocketAbout)(m_lpArrayMySocketAbout + i * sizeof(LPStructExtLeSocketAbout));
        if (pStrcutLeSocketAbout->nRecordStatus == kRecordStatusIdle)
        {
            nIndex = i;
            break;
        }
    }
    
    if (nIndex < 0)
    {
        [m_LockFD unlock];
        
        return -15;
    }
    
    LPStructExtLeSocketAbout pStructLeSocketAbout = (LPStructExtLeSocketAbout)(m_lpArrayMySocketAbout + nIndex * sizeof(StructExtLeSocketAbout));
    pStructLeSocketAbout->nRecordStatus = kRecordStatusBusy;
    pStructLeSocketAbout->nRecordIndex = nIndex;
    pStructLeSocketAbout->hSocket = hSocket;
    pStructLeSocketAbout->bIsHead = true;
    pStructLeSocketAbout->uDataSizeTotal = m_uTCPHeaderSize;
    pStructLeSocketAbout->uDataSizeRead = 0;
    
    if (m_uTCPHeaderSize > 0)
    {
        if (pStructLeSocketAbout->lpRecvDataHeader == nil)
        {
            pStructLeSocketAbout->lpRecvDataHeader = (Byte *)malloc(m_uTCPHeaderSize);
        }
        memset(pStructLeSocketAbout->lpRecvDataHeader, 0, m_uTCPHeaderSize);
    }
    
    if (pStructLeSocketAbout->lpRecvDataBody == NULL)
    {
        pStructLeSocketAbout->lpRecvDataBody = (Byte *)malloc(m_uMaxTCPBodySize);
    }
    memset(pStructLeSocketAbout->lpRecvDataBody, 0, m_uMaxTCPBodySize);
    
    [m_LockFD unlock];
    
    return 0;
}

- (int)removeCertainMySocketAbout:(int)nIndexVal
                        socketVal:(int)hSocket
                      inLockScope:(BOOL)bAlreadyInLockScope
{
    int nRet = -1;
    
    if (!bAlreadyInLockScope) {
        [m_LockFD lock];
    }
    
    LPStructExtLeSocketAbout pStructLeSocketAbout = (LPStructExtLeSocketAbout)(m_lpArrayMySocketAbout + nIndexVal * sizeof(LPStructExtLeSocketAbout));
    
    if (pStructLeSocketAbout->nRecordStatus == kRecordStatusBusy &&
        pStructLeSocketAbout->hSocket == hSocket)
    {
        FD_CLR(hSocket, &m_SocketFDSet);
        
        close(hSocket);
        
        pStructLeSocketAbout->nRecordStatus = kRecordStatusIdle;
        pStructLeSocketAbout->nRecordIndex = nIndexVal;
        pStructLeSocketAbout->hSocket = -1;
        pStructLeSocketAbout->bIsHead = YES;
        pStructLeSocketAbout->uDataSizeTotal = 0;
        pStructLeSocketAbout->uDataSizeRead = 0;
        
        if (m_uTCPHeaderSize > 0)
        {
            memset(pStructLeSocketAbout->lpRecvDataHeader, 0, m_uTCPHeaderSize);
        }
        memset(pStructLeSocketAbout->lpRecvDataBody, 0, m_uMaxTCPBodySize);
        
        nRet = 0;
    }
    
    if (!bAlreadyInLockScope) {
        [m_LockFD unlock];
    }
    
    return nRet;
}


@end
