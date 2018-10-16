//
//  desFile.h
//  foryao
//
//  Created by soyea on 16/6/24.
//  Copyright © 2016年 lyf. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DesFile : NSObject
+(NSString *)ToHex:(long long int)tmpid;
+ (NSString *)stringFromHexString:(NSString *)hexString;
+ (NSString *)encryptWithText:(NSString *)sText;//加密
+ (NSString *)decryptWithText:(NSString *)sText;//解密
@end
