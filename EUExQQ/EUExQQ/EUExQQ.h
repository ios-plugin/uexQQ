//
//  EUExQQApi.h
//  EUExQQApi
//
//  Created by liguofu on 14/11/20.
//  Copyright (c) 2014年 AppCan.can. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EUExBase.h"
#import <TencentOpenAPI/TencentOAuth.h>
#import "EUExBaseDefine.h"
#import "TencentOpenAPI/QQApiInterface.h"

typedef enum{
    QQNewsWeb = 0,
    QQNewsLocal,
    QQShareText,
    QQShareImg
    
}QQSendType;
@interface EUExQQ : EUExBase <TencentSessionDelegate,UIAlertViewDelegate,QQApiInterfaceDelegate>

@property (nonatomic, retain) TencentOAuth *tencentOAuth;
@property (nonatomic, retain) NSString *cbShareStr;
@property (nonatomic, retain) QQApiObject *qqApiObj;
@property (nonatomic, retain) NSString *cbQQLoginStr;
@property (nonatomic, assign) QQSendType sendType;



@end
