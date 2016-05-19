//
//  LeSocketBaseObject.h
//  LeSocketLibrary
//
//  Created by caic on 16/5/18.
//  Copyright © 2016年 caic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LeSocketProtocal.h"
#import "LeSocketParseObject.h"

@interface LeSocketBaseObject : NSObject <LeSocketSendComponentDelegate>
{
    BOOL    mIsServer;
    NSString * mServerAddr;
    unsigned short mServerPort;
    NSString * mLocalAddr;
    unsigned short mLocalPort;
    
    int mSocket;
    BOOL mStop;
    
    NSThread * mThreadRecv;
    NSThread * mThreadCall;
    
}

@property (nonatomic, weak) id<LeSocketCallbackDelegate> mCallback;
@property (nonatomic, weak) id<LeSocketDataCallbackDelegate> mDataCallback;
@property (nonatomic, weak) id<LeSocketTCPHeaderParseCallbackDelegate> mTCPHeaderParseCallback;

- (BOOL)shouldThreadStop;

- (void)callback_onCreateSocketResult:(id)paraVal;
- (void)callback_onCertainSocketClosed:(id)paraVal;
- (void)callback_onDataRecv:(id)paraVal;

@end
