/*** JoDess.h ***/

#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonCryptor.h>



@interface JoDess : NSObject

+ (NSString *) encode:(NSString *)str key:(NSString *)key;

+ (NSString *) decode:(NSString *)str key:(NSString *)key;


+ (NSString *) encodeBase64WithString:(NSString *)strData;
+ (NSString *) encodeBase64WithData:(NSData *)objData;

+ (NSData *) decodeBase64WithString:(NSString *)strBase64;

+ (NSString *) md5:(NSString *) input ;

@end
