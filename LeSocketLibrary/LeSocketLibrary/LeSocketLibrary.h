//
//  LeSocketLibrary.h
//  LeSocketLibrary
//
//  Created by caic on 16/5/17.
//  Copyright © 2016年 caic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LeSocket.h"

#define LeSocketSDK    [LeSocketLibrary sharedInstace]

@interface LeSocketLibrary : NSObject

+ (instancetype) sharedInstace;

- (LeSocket *)createSocket;

@end
