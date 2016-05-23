//
//  LeCommLayerProtocal.h
//  LeSocketLibrary
//
//  Created by caic on 16/5/20.
//  Copyright © 2016年 caic. All rights reserved.
//

#import <Foundation/Foundation.h>

#define LOGICERR_CONNECTFAILED      -10


@protocol LeSocketCommLayerDelegate <NSObject>

@end



@protocol LeSocketCommLayerCallDelegate <NSObject>

- (int)setInitServerAddr:(NSString *)serverAddr
              serverPort:(unsigned short)nServerPort
                delegate:(id<LeSocketCommLayerDelegate>)delegate;

- (int)sendData:(int)nPDUType
       dataBody:(Byte *)lpData
       dataSize:(unsigned int)uDataSize;

@end

