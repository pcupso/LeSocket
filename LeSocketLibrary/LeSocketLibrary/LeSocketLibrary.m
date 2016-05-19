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

- (LeSocket *)createSocket
{
    return [[LeSocket alloc] init];
}



@end
