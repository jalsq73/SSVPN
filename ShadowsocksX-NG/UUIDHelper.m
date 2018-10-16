//
//  UUID.m
//  DouBan
//
//  Created by 乐游先锋 on 16/5/24.
//  Copyright © 2016年 JYC. All rights reserved.
//

#import "UUIDHelper.h"

#import "KeyChainStore.h"


CFUUIDRef uuidRef;

@implementation UUIDHelper

+(NSString *)getUUID
{
    NSString * strUUID = (NSString *)[KeyChainStore load:@"com.company.app.psd"];
    //首次执行该方法时，uuid为空
    NSLog(@"uuid:%@",strUUID);
//    if ([strUUID isEqualToString:@""] || !strUUID)
//    {
//
//        strUUID = [[NSUserDefaults standardUserDefaults] valueForKey:@"uuID"];
//        //将该uuid保存到keychain
//        [KeyChainStore save:KEY_USERNAME_PASSWORD data:strUUID];
//    }
    return strUUID;
}


+(NSString *)getToken{
    
    NSString *token = (NSString *)[KeyChainStore load:@"com.company.app.token"];
    //首次执行该方法时，token为空
    NSLog(@"token:%@",token);
//    if ([token isEqualToString:@""] || !token)
//    {
//        token = [[NSUserDefaults standardUserDefaults] valueForKey:@"token"];
//        //将该token保存到keychain
//        [KeyChainStore save:KEY_USERNAME_TOKEN data:token];
//    }
    return token;
}

- (void)dealloc
{
    uuidRef = nil;
}
@end
