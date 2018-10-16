//
//  JInPayController.h
//   VPN
//
//  Created by Tommy on 2017/7/26.
//  Copyright © 2017年 cacac. All rights reserved.
//
#import <Foundation/Foundation.h>
typedef void(^bingdingBlock)();

#ifndef JInPayController_h
#define JInPayController_h


#endif /* JInPayController_h */
@interface JInPayController : NSObject{
    
}
@property NSMutableArray * arrayData;
@property bool isActivate;
@property bool isPaying;
@property (nonatomic,copy) bingdingBlock bingdingBlock;
@property (nonatomic,strong) NSMutableDictionary * Userdict;

-(void)initInPay;
-(void)buy:(NSInteger)itemId;

+(JInPayController *)sharedInstanceMethod;
@end
