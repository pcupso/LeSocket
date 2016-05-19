//
//  LeSocketBaseObject.m
//  LeSocketLibrary
//
//  Created by caic on 16/5/18.
//  Copyright © 2016年 caic. All rights reserved.
//

#import "LeSocketBaseObject.h"

@implementation LeSocketBaseObject

- (int)sendData:(Byte *)lpData
       dataSize:(unsigned int)uDataSize
  remoteNetAddr:(unsigned long)uRemoteNetAddr
  remoteNetPort:(unsigned short)uRemoteNetPort
        extInfo:(int)nExtInfoIndex
{
    return 0;
}

- (BOOL)shouldThreadStop
{
    return mStop;
}


- (void)callback_onCreateSocketResult:(id)paraVal
{
    if (paraVal && [paraVal isKindOfClass:[LeSocketCreateSocketParseObject class]])
    {
        LeSocketCreateSocketParseObject *object = (LeSocketCreateSocketParseObject *)paraVal;
        
        if ([_mCallback respondsToSelector:@selector(onCreateSocketResult:sendComponent:)])
        {
            [_mCallback onCreateSocketResult:[object nResultVal] sendComponent:self];
        }
    }
    
}

- (void)callback_onCertainSocketClosed:(id)paraVal
{
    if (paraVal && [paraVal isKindOfClass:[LeSocketCertainSocketCloseParseObject class]])
    {
        LeSocketCertainSocketCloseParseObject *object = (LeSocketCertainSocketCloseParseObject *)paraVal;
        
        if ([_mCallback respondsToSelector:@selector(onCertainSocketClose:index:)])
        {
            [_mCallback onCertainSocketClose:object.nResultVal index:object.nRemoteIndex];
        }
    }
}

- (void)callback_onDataRecv:(id)paraVal
{
    if (paraVal && [paraVal isKindOfClass:[LeSocketDataRecvParseObject class]])
    {
        LeSocketDataRecvParseObject *object = (LeSocketDataRecvParseObject *)paraVal;
        
        if ([_mCallback respondsToSelector:@selector(onDataRecv:dataSize:netAddrRemote:netPortRemote:extInfo:)])
        {
            [_mDataCallback onDataRecv:[object getDataVal]
                              dataSize:[object getDataSizeVal]
                         netAddrRemote:[object mRemoteAddr]
                         netPortRemote:[object mRemotePort]
                               extInfo:[object mExtInfoIndex]];
        }
    }
}





@end
