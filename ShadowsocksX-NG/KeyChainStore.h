//
//  KeyChainStore.h
//  DouBan
//
//  Created by 乐游先锋 on 16/5/24.
//  Copyright © 2016年 JYC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KeyChainStore : NSObject


+ (void)save:(NSString *)service data:(id)data;

+ (id)load:(NSString *)service;

+ (void)deleteKeyData:(NSString *)service;

@end
