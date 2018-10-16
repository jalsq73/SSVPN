//
//  JInPayController.m
//   VPN
//
//  Created by Tommy on 2017/7/26.
//  Copyright © 2017年 cacac. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>
#import "JInPayController.h"
//#import "SVProgressHUD.h"
//#import "desFile.h"

static JInPayController* sharedInstance = nil;

@interface JInPayController ()<SKPaymentTransactionObserver,SKProductsRequestDelegate>
@property (nonatomic,strong) NSArray * productsArray;
@property (nonatomic,strong) NSString * country;

@end

@implementation JInPayController

int _id;

- (NSString *) panduan
{
    NSString *lang;
    if([[self currentLanguage] compare:@"zh-Hans" options:NSCaseInsensitiveSearch]==NSOrderedSame || [[self currentLanguage] compare:@"zh-Hant" options:NSCaseInsensitiveSearch]==NSOrderedSame || [[self currentLanguage] rangeOfString:@"zh-Hans"].location == !NSNotFound || [[self currentLanguage] rangeOfString:@"zh-Hant"].location == !NSNotFound)
    {
        lang = @"zh";
        return @"chinese";
    }
    else{
        lang = @"en";
        return @"English";
    }
}

-(NSString*)currentLanguage
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSArray *languages = [defaults objectForKey:@"AppleLanguages"];
    NSString *currentLang = [languages objectAtIndex:0];
    
    NSLog(@"%@",currentLang);
    
    return currentLang;
}


+(instancetype) sharedInstanceMethod
{
    static dispatch_once_t onceToken ;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[super allocWithZone:NULL] init] ;
    }) ;
    
    return sharedInstance ;
}



-(void)initInPay
{
    _arrayData = [NSMutableArray arrayWithCapacity:0];

    if ([[self panduan]isEqualToString:@"chinese"])
    {
        _country = @"1";
    }else
    {
        _country = @"0";
    }
    
//    NSString * listProduct = [NSString stringWithFormat:@"%@/usertest/ios.asmx/VpnProListCountryType?apikey=lygames_0953&type=%@&Country=%@",GONGYOUURL,TYPESTRING,_country];
//    AFHTTPRequestOperationManager * manager = [AFHTTPRequestOperationManager manager];
//    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
//    [manager GET:listProduct parameters:nil success:^(AFHTTPRequestOperation * _Nonnull operation, id  _Nonnull responseObject) {
//        NSArray * array = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingMutableContainers error:nil];
//        [_arrayData addObjectsFromArray:array];
//        _isActivate = true;
//    } failure:^(AFHTTPRequestOperation * _Nullable operation, NSError * _Nonnull error) {
//
//    }];
//
    [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}


-(void)buy:(NSInteger)itemId
{

    if(!_isActivate){
        return;
    }
//    if(_isPaying){
//        return;
//    }
    _id = (int)itemId;
    NSString * string = _arrayData[itemId][@"productID"];
    
    NSSet * LySet = [NSSet setWithObject:string];
    SKProductsRequest * projectRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:LySet];
    projectRequest.delegate = self;
    [projectRequest start];
    _isPaying = true;
//    [SVProgressHUD showWithStatus:NSLocalizedString(@"product10", nil)];
}

#pragma mark  ---------------------  SKProductsRequestDelegate  ---------
- (void) productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
    self.productsArray = response.products;
    
    if (self.productsArray.count < 1) {
//        [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"product2", nil)];
        return;
    }
    //4.2 拿商品转换类型 (根据商品是什么样的,商家给用户小票,让用户拿着小票去排队付款)
    SKPayment * payment = [SKPayment paymentWithProduct:response.products[0]];
    //5 .  排队,等付款
    [[SKPaymentQueue defaultQueue] addPayment:payment];
}

-(void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray<SKPaymentTransaction *> *)transactions{
    //遍历所有交易,得出没有交易的状态
    //    [SVProgressHUD dismiss];
    for (SKPaymentTransaction * payTran in transactions) {
        if(payTran.transactionState == SKPaymentTransactionStatePurchased){
            [self completeTransaction:payTran];
        }
        if(payTran.transactionState == SKPaymentTransactionStateRestored){
            [self completeTransaction:payTran];
        }
        if (payTran.transactionState == SKPaymentTransactionStateFailed) {
            [[SKPaymentQueue defaultQueue] finishTransaction:payTran];
//            [SVProgressHUD dismiss];
//            [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"%@ ：%@",NSLocalizedString(@"product6", nil),payTran.error.localizedDescription]];
        }
    }
}

- (void)completeTransaction:(SKPaymentTransaction *)transaction{
    
    NSURL *recepitURL = [[NSBundle mainBundle] appStoreReceiptURL];
    NSData *receipt = [NSData dataWithContentsOfURL:recepitURL];
    if(!receipt){
    }
//    NSString * uuid = [UUID getUUID];
    NSString * orderNum = transaction.transactionIdentifier;
    NSString * productIdentifier = transaction.payment.productIdentifier;
//    NSString * source = TYPESTRING;
//    _Userdict = [NSKeyedUnarchiver unarchiveObjectWithFile:USERALLDATA];

//    NSString * des = [NSString stringWithFormat:@"{\"name\":\"%@\",\"OrderNum\":\"%@\",\"PackageName\":\"%@\",\"source\":\"%@\"}",_Userdict[@"UserName"],orderNum,productIdentifier,source];
    NSString * string = [NSString stringWithFormat:@"{\"receipt\":\"%@\",\"desSring\":\"%@\"}",[receipt base64EncodedStringWithOptions:0],@""];
    
    //向自己的服务器验证购买凭证
//    NSString * str1 = [NSString stringWithFormat:@"%@/usertest/ios.asmx/NJmLQYUserPayNew",GONGYOUURL];
//    NSDictionary * dict = @{@"apikey":@"lygames_0953",@"json":string};
//    AFHTTPRequestOperationManager * manager = [AFHTTPRequestOperationManager manager];
//    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
//    [manager POST:str1 parameters:dict success:^(AFHTTPRequestOperation * _Nonnull operation, id  _Nonnull responseObject) {
//        _isPaying = false;
//        //交易成功后  通知两个界面的数据进行刷新   自动配置界面  账户中的数据套餐界面
//        NSArray * array = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingMutableContainers error:nil];
//        if ([array[0][@"state"] isEqualToString:@"1"]) {
////            [SVProgressHUD showSuccessWithStatus:NSLocalizedString(@"product8", nil)];
//            //购买成功，提示绑定邮箱
//            if (_bingdingBlock)
//            {
//                _bingdingBlock();
//            }
//            //            NSLog(@"交易成功");
//            [[NSNotificationCenter defaultCenter] postNotificationName:@"refresh1" object:nil];
//            [[NSNotificationCenter defaultCenter] postNotificationName:@"refresh2" object:nil];
//            [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
//        }else if([array[0][@"state"] isEqualToString:@"99"]){
//            [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
//        }
//        else
//        {
////            [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"product6", nil)];
//            //            NSLog(@"交易失败");
//        }
//    } failure:^(AFHTTPRequestOperation * _Nullable operation, NSError * _Nonnull error) {
//
//    }];


}


- (NSString*)dictionaryToJson:(NSDictionary *)dic
{
    NSError *parseError = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:&parseError];
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}


//copy返回单例本身
- (id)copyWithZone:(NSZone *)zone
{
    return [JInPayController sharedInstanceMethod] ;
}

+(id) allocWithZone:(struct _NSZone *)zone
{
    return [JInPayController sharedInstanceMethod] ;
}

@end

