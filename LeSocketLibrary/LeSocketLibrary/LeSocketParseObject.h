//
//  LeSocketParseObject.h
//  LeSocketLibrary
//
//  Created by caic on 16/5/18.
//  Copyright © 2016年 caic. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LeSocketCreateSocketParseObject : NSObject

@property (nonatomic, assign) int nResultVal;

@end



@interface LeSocketCertainSocketCloseParseObject : NSObject

@property (nonatomic, assign) int nResultVal;
@property (nonatomic, assign) int nRemoteIndex;

@end


@interface LeSocketDataRecvParseObject : NSObject
{
    Byte *mData;
    unsigned int mDataSize;
}

@property (nonatomic, assign) unsigned long mRemoteAddr;
@property (nonatomic, assign) unsigned short mRemotePort;
@property (nonatomic, assign) int mExtInfoIndex;

- (instancetype)initWithParaData:(Byte *)lpData dataSize:(unsigned int)uDataSize;

- (Byte *)getDataVal;
- (unsigned int)getDataSizeVal;




@end



