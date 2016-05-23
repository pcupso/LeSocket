//
//  LeSocketParseObject.m
//  LeSocketLibrary
//
//  Created by caic on 16/5/18.
//  Copyright © 2016年 caic. All rights reserved.
//

#import "LeSocketParseObject.h"

@implementation LeSocketCreateSocketParseObject

@end



@implementation LeSocketCertainSocketCloseParseObject

@end



@implementation LeSocketDataRecvParseObject

- (instancetype)initWithParaData:(Byte *)lpData dataSize:(unsigned int)uDataSize
{
    if (self = [super init])
    {
        if (lpData != nil)
        {
            mData = (Byte *)malloc(uDataSize);
            memcpy(mData, lpData, uDataSize);
            mDataSize = uDataSize;
        }
    }
    return self;
}

- (void)dealloc
{
    if (!mData) {
        free(mData);
        mData = nil;
    }
}

- (Byte *)getDataVal
{
    return mData;
}

- (unsigned int)getDataSizeVal
{
    return mDataSize;
}

@end