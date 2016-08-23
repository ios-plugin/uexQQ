//
//
//  EUExQQApi.m
//  EUExQQApi
//
//  Created by liguofu on 14/11/20.
//  Copyright (c) 2014年 AppCan.can. All rights reserved.
//

#import "EUExQQ.h"
#import "EUtility.h"


#import <TencentOpenAPI/TencentOAuth.h>
#import <TencentOpenAPI/QQApiInterface.h>
#import <TencentOpenAPI/TencentMessageObject.h>
@interface EUExQQ()<TencentSessionDelegate,UIAlertViewDelegate,QQApiInterfaceDelegate>
@property (nonatomic, retain) TencentOAuth *tencentOAuth;
@property (nonatomic, retain) NSDictionary *cbShareDic;
@property (nonatomic, retain) NSString *cbShareStr;
@property (nonatomic, retain) QQApiObject *qqApiObj;
@property (nonatomic, retain) NSString *cbQQLoginStr;
@property (nonatomic, assign) QQSendType sendType;
@property(nonatomic,strong)ACJSFunctionRef*funcLogin;
@property(nonatomic,strong)ACJSFunctionRef*funcLogout;
@property(nonatomic,strong)ACJSFunctionRef*funcGetInfo;
@property(nonatomic,strong)ACJSFunctionRef*funcShare;
@property(nonatomic,strong)ACJSFunctionRef*funcInstalled;
@end

static EUExQQ *callbackTarget = nil;


@implementation EUExQQ

#define SAFE_REMOVE(x) if(x){[x removeFromSuperview];self.x = nil;}
#define IS_NSString(x) ([x isKindOfClass:[NSString class]] && x.length>0)
#define IS_NSMutableArray(x) ([x isKindOfClass:[NSMutableArray class]] && [x count]>0)
#define IS_NSArray(x) ([x isKindOfClass:[NSArray class]] && [x count]>0)
#define IS_NSMutableDictionary(x) ([x isKindOfClass:[NSMutableDictionary class]])
#define IS_NSDictionary(x) ([x isKindOfClass:[NSDictionary class]])
#define STRTOURL(x) [NSURL URLWithString:x]
#define alertViewAboutQQorQzone 9999999

#pragma mark -
#pragma mark - method

- (void)login:(NSMutableArray *)inArguments {
    
    if (inArguments != nil ) {
        ACJSFunctionRef *func = JSFunctionArg(inArguments.lastObject);
        self.funcLogin = func;
        NSArray* permissions = [NSArray arrayWithObjects:
                                kOPEN_PERMISSION_GET_USER_INFO,
                                kOPEN_PERMISSION_GET_SIMPLE_USER_INFO,
                                kOPEN_PERMISSION_ADD_ALBUM,
                                kOPEN_PERMISSION_ADD_IDOL,
                                kOPEN_PERMISSION_ADD_ONE_BLOG,
                                kOPEN_PERMISSION_ADD_PIC_T,
                                kOPEN_PERMISSION_ADD_SHARE,
                                kOPEN_PERMISSION_ADD_TOPIC,
                                kOPEN_PERMISSION_CHECK_PAGE_FANS,
                                kOPEN_PERMISSION_DEL_IDOL,
                                kOPEN_PERMISSION_DEL_T,
                                kOPEN_PERMISSION_GET_FANSLIST,
                                kOPEN_PERMISSION_GET_IDOLLIST,
                                kOPEN_PERMISSION_GET_INFO,
                                kOPEN_PERMISSION_GET_OTHER_INFO,
                                kOPEN_PERMISSION_GET_REPOST_LIST,
                                kOPEN_PERMISSION_LIST_ALBUM,
                                kOPEN_PERMISSION_UPLOAD_PIC,
                                kOPEN_PERMISSION_GET_VIP_INFO,
                                kOPEN_PERMISSION_GET_VIP_RICH_INFO,
                                kOPEN_PERMISSION_GET_INTIMATE_FRIENDS_WEIBO,
                                kOPEN_PERMISSION_MATCH_NICK_TIPS_WEIBO,
                                nil];
        
        // NSArray *permissions = [NSArray arrayWithObjects:@"all", nil];
        NSString *appid = [inArguments objectAtIndex:0];
        if (!_tencentOAuth) {
            
            _tencentOAuth = [[TencentOAuth alloc] initWithAppId:appid andDelegate:self];
        }
        [_tencentOAuth authorize:permissions];
        callbackTarget = self;
    }
}
-(void)logout:(NSMutableArray *)inArguments{
    ACJSFunctionRef *func = JSFunctionArg(inArguments.lastObject);
    self.funcLogout = func;
    [self.tencentOAuth logout:self];
    callbackTarget = self;
}
-(void)getUserInfo:(NSMutableArray *)inArguments{
    ACJSFunctionRef *func = JSFunctionArg(inArguments.lastObject);
    self.funcGetInfo = func;
    [_tencentOAuth getUserInfo];
}
-(NSNumber*)isQQInstalled:(NSMutableArray *)inArguments{

    BOOL isInstalled = [QQApiInterface isQQInstalled];
    if (isInstalled){
        //[self jsSuccessWithName:@"uexQQ.cbIsQQInstalled" opId:0 dataType:UEX_CALLBACK_DATATYPE_INT intData:UEX_CSUCCESS];
        [self.webViewEngine callbackWithFunctionKeyPath:@"uexQQ.cbIsQQInstalled" arguments:ACArgsPack(@0,@2,@0)];
        
    }else{
       // [self jsSuccessWithName:@"uexQQ.cbIsQQInstalled" opId:0 dataType:UEX_CALLBACK_DATATYPE_INT intData:UEX_CFAILED];
        [self.webViewEngine callbackWithFunctionKeyPath:@"uexQQ.cbIsQQInstalled" arguments:ACArgsPack(@0,@2,@1)];
        
    }
    return @(isInstalled);
}

/**
 * 分享图文到QQ
 */
-(void)shareWebImgTextToQQ:(NSMutableArray *)inArguments {
     ACJSFunctionRef *func = JSFunctionArg(inArguments.lastObject);
    self.funcShare = func;
    _sendType = QQNewsWeb;
    if (IS_NSMutableArray(inArguments)) {
        NSString *appId = [inArguments objectAtIndex:0];
        
        if (_tencentOAuth == nil) {
            
            _tencentOAuth = [[TencentOAuth alloc] initWithAppId:appId andDelegate:self];
            
        }
        NSString *json = [inArguments objectAtIndex:1];

        NSString *appName = nil;
        int  cflag ;
        NSMutableDictionary *dict = [[[NSMutableDictionary alloc] init] autorelease];
        dict = [json ac_JSONValue];
        NSString *title = ([dict objectForKey:@"title"]&&[dict[@"title"] length]>0)?dict[@"title"]:@" ";
        NSString *description = [dict objectForKey:@"summary"]&&[dict[@"summary"] length]>0?dict[@"summary"]:@"";
        NSString *utf8String = [dict objectForKey:@"targetUrl"]&&[dict[@"targetUrl"] length]>0?dict[@"targetUrl"]:@"";
        appName = [dict objectForKey:@"appName"];
        cflag = [[dict objectForKey:@"cflag"] intValue];
        if ([dict objectForKey:@"imageUrl"]) {
            NSString *imagePath = [dict objectForKey:@"imageUrl"];
            imagePath = [self absPath:imagePath];
            QQApiNewsObject *newsObj = Nil;
            if ([imagePath hasPrefix:@"http://"]) {
                newsObj = [QQApiNewsObject objectWithURL:STRTOURL(utf8String) title:title description:description previewImageURL:STRTOURL(imagePath)];
            }
            else{
                UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
                NSData *fristData = UIImageJPEGRepresentation(image, 0.5);
                newsObj = [QQApiNewsObject
                           objectWithURL:STRTOURL(utf8String)
                           title:title
                           description:description
                           previewImageData:fristData];
            }
            self.qqApiObj = newsObj;
            SendMessageToQQReq *req = [SendMessageToQQReq reqWithContent:newsObj];
            QQApiSendResultCode sent = [QQApiInterface sendReq:req];
            [self handleSendResult:sent];
            callbackTarget = self;
            /*
            if(cflag == 1){
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"请选择分享的平台" message:@"请选择你要分享内容的平台" delegate:self cancelButtonTitle:@"QZone" otherButtonTitles:@"QQ", nil];
                alertView.tag = alertViewAboutQQorQzone;
                [alertView show];
                [alertView release];
            }
            else if(cflag ==2){
                SendMessageToQQReq *req = [SendMessageToQQReq reqWithContent:newsObj];
                QQApiSendResultCode sent = [QQApiInterface sendReq:req];
                [self handleSendResult:sent];
            }
            else{
                SendMessageToQQReq *req = [SendMessageToQQReq reqWithContent:newsObj];
                QQApiSendResultCode sent = [QQApiInterface SendReqToQZone:req];
                [self handleSendResult:sent];
            }
             */
            
        }
    }
}
/**
 * 分享本地图片到QQ
 */
- (void) shareLocalImgToQQ:(NSMutableArray *)inArguments {
    ACJSFunctionRef *func = JSFunctionArg(inArguments.lastObject);
    self.funcShare = func;
    _sendType = QQShareImg;
    
    if (IS_NSMutableArray(inArguments)) {
        
        NSString *appId = [inArguments objectAtIndex:0];
        
        if (_tencentOAuth == nil) {
            
            _tencentOAuth = [[TencentOAuth alloc] initWithAppId:appId andDelegate:self];
            
        }
        NSString *json = [inArguments objectAtIndex:1];
        NSString *imageLocalUrl = nil;
        NSString *appName = nil;
        int  cflag ;
        NSMutableDictionary *dict = [[[NSMutableDictionary alloc] init] autorelease];
        dict = [json ac_JSONValue];
        appName = [dict objectForKey:@"appName"];
        cflag = [[dict objectForKey:@"cflag"] intValue];
        imageLocalUrl = [dict objectForKey:@"imageLocalUrl"];
        imageLocalUrl = [self absPath:imageLocalUrl];
        QQApiImageObject *imgObj = Nil;
        
        if (![imageLocalUrl hasPrefix:@"http"]) {
            
            UIImage *image = [UIImage imageWithContentsOfFile:imageLocalUrl];
            
            NSData *firstData = UIImageJPEGRepresentation(image, 0.5);
            imgObj = [QQApiImageObject objectWithData:firstData previewImageData:firstData title:nil description:nil];
            
        }
        self.qqApiObj = imgObj;
        SendMessageToQQReq *req = [SendMessageToQQReq reqWithContent:imgObj];
        QQApiSendResultCode sent = [QQApiInterface sendReq:req];
        [self handleSendResult:sent];
        callbackTarget = self;
        /*
        
        if(cflag == 1){
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"请选择分享的平台" message:@"请选择你要分享内容的平台" delegate:self cancelButtonTitle:@"QZone" otherButtonTitles:@"QQ", nil];
            alertView.tag = alertViewAboutQQorQzone;
            [alertView show];
            [alertView release];
        }
        else if(cflag ==2){
            SendMessageToQQReq *req = [SendMessageToQQReq reqWithContent:imgObj];
            QQApiSendResultCode sent = [QQApiInterface sendReq:req];
            [self handleSendResult:sent];
        }
        else{
            SendMessageToQQReq *req = [SendMessageToQQReq reqWithContent:imgObj];
            QQApiSendResultCode sent = [QQApiInterface sendReq:req];
            [self handleSendResult:sent];
        }
         */
    }
}
//分享图文到QQ空间

/**
 * 分享网络新闻消息到QZone
 */
-(void)shareImgTextToQZone:(NSMutableArray *)inArguments {
    ACJSFunctionRef *func = JSFunctionArg(inArguments.lastObject);
    self.funcShare = func;
    _sendType = QQNewsWeb;
    if (inArguments.count > 0) {
        
        NSString *appId = [inArguments objectAtIndex:0];
        NSString *json = [inArguments objectAtIndex:1];
        
        NSString *title = nil;
        NSString *description = nil;
        NSString *utf8String = nil;
        NSMutableDictionary *dict = [[[NSMutableDictionary alloc] init] autorelease];
        dict = [json ac_JSONValue];
        title = [dict objectForKey:@"title"];
        description = [dict objectForKey:@"summary"];
        utf8String = [dict objectForKey:@"targetUrl"];
        if (_tencentOAuth == nil) {
            
            _tencentOAuth = [[TencentOAuth alloc] initWithAppId:appId andDelegate:self];
        }
        QQApiNewsObject *newsObj = Nil;
        NSMutableArray *previewImageUrlArr = [dict objectForKey:@"imageUrl"];
        NSString *previewImageUrl = nil;
        if (previewImageUrlArr.count >=1) {
            //iOS的QQSDK不支持多张照片(但Android支持),默认为第一张
            previewImageUrl = [previewImageUrlArr objectAtIndex:0];
        }
        //如果是网络图片
        if ([previewImageUrl hasPrefix:@"http://"]) {
            newsObj = [QQApiNewsObject
                       objectWithURL:STRTOURL(utf8String)
                       title:title
                       description:description
                       previewImageURL:STRTOURL(previewImageUrl)];
        }else{
            previewImageUrl = [self absPath:previewImageUrl];
            UIImage *image = [UIImage imageWithContentsOfFile:previewImageUrl];
            
            if (image) {
                NSData *fristData = UIImageJPEGRepresentation(image, 0.5);
                newsObj = [QQApiNewsObject
                           objectWithURL:STRTOURL(utf8String)
                           title:title
                           description:description
                           previewImageData:fristData];
            }
        }
        self.qqApiObj = newsObj;
        SendMessageToQQReq *req = [SendMessageToQQReq reqWithContent:newsObj];
        QQApiSendResultCode sent = [QQApiInterface SendReqToQZone:req];
        [self handleSendResult:sent];
        callbackTarget = self;
        
    }
}

-(void)shareAudioToQQ:(NSMutableArray *)inArguments  {
    ACJSFunctionRef *func = JSFunctionArg(inArguments.lastObject);
    self.funcShare = func;
    if (inArguments.count > 0) {
        
        NSString *appid = [inArguments objectAtIndex:0];
        NSString *json = [inArguments objectAtIndex:1];
        NSMutableDictionary *dict = [[[NSMutableDictionary alloc]init] autorelease];
        dict = [json ac_JSONValue];
        
        if (_tencentOAuth == nil) {
            
            _tencentOAuth = [[TencentOAuth alloc] initWithAppId:appid andDelegate:self];
        }
        
        NSString *utf8String = nil;
        NSString *title = nil;
        NSString *descriotion =nil;
        NSString *previewImageUrl = nil;
        NSString *flashURL = nil;
        int cflag;
        utf8String = [dict objectForKey:@"targetUrl"];
        title = [dict objectForKey:@"title"];
        descriotion = [dict objectForKey:@"description"];
        previewImageUrl = [dict objectForKey:@"imageUrl"];
        flashURL = [dict objectForKey:@"audio_url"];
        cflag = [[dict objectForKey:@"cflag"] intValue];
        
        QQApiAudioObject *audioObj =
        [QQApiAudioObject objectWithURL:[NSURL URLWithString:utf8String]
                                  title:title
                            description:descriotion
                        previewImageURL:[NSURL URLWithString:previewImageUrl]];
        
        [audioObj setFlashURL:[NSURL URLWithString:flashURL]];
        
        self.qqApiObj = audioObj;
        SendMessageToQQReq *req = [SendMessageToQQReq reqWithContent:audioObj];
        QQApiSendResultCode sent = [QQApiInterface sendReq:req];
        [self handleSendResult:sent];
        callbackTarget = self;
        /*
        if(cflag == 1){
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"请选择分享的平台" message:@"请选择你要分享内容的平台" delegate:self cancelButtonTitle:@"QZone" otherButtonTitles:@"QQ", nil];
            alertView.tag = alertViewAboutQQorQzone;
            [alertView show];
            [alertView release];
        }
        else if(cflag ==2){
            SendMessageToQQReq *req = [SendMessageToQQReq reqWithContent:audioObj];
            QQApiSendResultCode sent = [QQApiInterface sendReq:req];
            [self handleSendResult:sent];
        }
        else{
            SendMessageToQQReq *req = [SendMessageToQQReq reqWithContent:audioObj];
            QQApiSendResultCode sent = [QQApiInterface SendReqToQZone:req];
            [self handleSendResult:sent];
        }
         */
    }
}
- (void)handleSendResult:(QQApiSendResultCode)sendResult
{
    switch (sendResult)
    {
        case EQQAPIAPPNOTREGISTED:
        {
            UIAlertView *msgbox = [[UIAlertView alloc] initWithTitle:@"Error" message:@"App未注册" delegate:nil cancelButtonTitle:@"取消" otherButtonTitles:nil];
            [msgbox show];
            [msgbox release];
            break;
        }
        case EQQAPIMESSAGECONTENTINVALID:
        case EQQAPIMESSAGECONTENTNULL:
        case EQQAPIMESSAGETYPEINVALID:
        {
            UIAlertView *msgbox = [[UIAlertView alloc] initWithTitle:@"Error" message:@"发送参数错误" delegate:nil cancelButtonTitle:@"取消" otherButtonTitles:nil];
            [msgbox show];
            [msgbox release];
            break;
        }
        case EQQAPIQQNOTINSTALLED:
        {
            UIAlertView *msgbox = [[UIAlertView alloc] initWithTitle:@"Error" message:@"未安装手Q" delegate:nil cancelButtonTitle:@"取消" otherButtonTitles:nil];
            [msgbox show];
            [msgbox release];
            break;
        }
        case EQQAPIQQNOTSUPPORTAPI:
        {
            UIAlertView *msgbox = [[UIAlertView alloc] initWithTitle:@"Error" message:@"API接口不支持" delegate:nil cancelButtonTitle:@"取消" otherButtonTitles:nil];
            [msgbox show];
            [msgbox release];
            break;
        }
        case EQQAPISENDFAILD:
        {
            UIAlertView *msgbox = [[UIAlertView alloc] initWithTitle:@"Error" message:@"发送失败" delegate:nil cancelButtonTitle:@"取消" otherButtonTitles:nil];
            [msgbox show];
            [msgbox release];
            break;
        }
        case EQQAPIQZONENOTSUPPORTTEXT:
        {
            UIAlertView *msgbox = [[UIAlertView alloc] initWithTitle:@"Error" message:@"空间分享不支持纯文本分享，请使用图文分享" delegate:nil cancelButtonTitle:@"取消" otherButtonTitles:nil];
            [msgbox show];
            [msgbox release];
            break;
        }
        case EQQAPIQZONENOTSUPPORTIMAGE:
        {
            UIAlertView *msgbox = [[UIAlertView alloc] initWithTitle:@"Error" message:@"空间分享不支持纯图片分享，请使用图文分享" delegate:nil cancelButtonTitle:@"取消" otherButtonTitles:nil];
            [msgbox show];
            [msgbox release];
            break;
        }
        default:
        {
            break;
        }
    }
}
#pragma mark - QQApiInterfaceDelegate

- (void)onReq:(QQBaseReq *)req
{
    switch (req.type)
    {
        case EGETMESSAGEFROMQQREQTYPE:
        {
            break;
        }
        default:
        {
            break;
        }
    }
}

- (void)onResp:(QQBaseResp *)resp
{
    switch (resp.type)
    {
        case ESENDMESSAGETOQQRESPTYPE:
        {
            SendMessageToQQResp* sendResp = (SendMessageToQQResp*)resp;
            if (sendResp.errorDescription) {
                self.cbShareStr = [NSString stringWithFormat:@"{\"errCode\":\"%@\",\"errStr\":\"%@\"}",sendResp.result, sendResp.errorDescription];
                self.cbShareDic = @{@"errCode":@(1),@"errorDescription":sendResp.errorDescription};
            }
            else{
                self.cbShareStr = [NSString stringWithFormat:@"{\"errCode\":\"%@\",\"errStr\":\"\"}",sendResp.result];
                self.cbShareDic = @{@"errCode":@(0),@"errorDescription":@""};
            }
            //延迟回调
            [self performSelector:@selector(cbShare) withObject:self afterDelay:1.0];
            
            break;
        }
        default:
            
            break;
    }
}
- (void)isOnlineResponse:(NSDictionary *)response {
    
}

- (void)cbShare {
    //[self jsSuccessWithName:@"uexQQ.cbShareQQ" opId:0 dataType:UEX_CALLBACK_DATATYPE_JSON strData:self.cbShareStr];
     [self.webViewEngine callbackWithFunctionKeyPath:@"uexQQ.cbShareQQ" arguments:ACArgsPack(@0,@1,self.cbShareStr)];
    [self.funcShare executeWithArguments:ACArgsPack(self.cbShareDic[@"errCode"],self.cbShareDic[@"errorDescription"])];
    self.funcShare = nil;
}

+ (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation{
    [callbackTarget handleOpenURL:url];
    return YES;
}

+ (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url{
    [callbackTarget handleOpenURL:url];
    return YES;
}


- (void)handleOpenURL:(NSURL *)url{
    [QQApiInterface handleOpenURL:url delegate:self];
    BOOL isCan = [TencentOAuth CanHandleOpenURL:url];
    if (isCan) {
        [TencentOAuth HandleOpenURL:url];
    }
}

- (void)parseURL:(NSURL *)url application:(UIApplication *)application {
    /*
    [QQApiInterface handleOpenURL:url delegate:self];
    BOOL isCan = [TencentOAuth CanHandleOpenURL:url];
    if (isCan) {
        [TencentOAuth HandleOpenURL:url];
    }
     */
}

#pragma mark UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == alertViewAboutQQorQzone) {
        SendMessageToQQReq * req = [SendMessageToQQReq reqWithContent:self.qqApiObj];
        QQApiSendResultCode sent = 0;
        if (0 == buttonIndex)
        {
            //分享到QZone
            sent = [QQApiInterface SendReqToQZone:req];
        }
        else
        {
            //分享到QQ
            sent = [QQApiInterface sendReq:req];
        }
        [self handleSendResult:sent];
    }
}
#pragma mark -
#pragma mark - TencentSessionDelegate

- (void)cbLogin:(NSDictionary*)result {
//    if(![result isKindOfClass:[NSString class]]){
//        result=[result ac_JSONFragment];
//    }
    //[self jsSuccessWithName:@"uexQQ.cbLogin" opId:0 dataType:2 strData:result];
    NSNumber *state = result[@"ret"];
    NSDictionary *dic = result[@"data"];
     [self.webViewEngine callbackWithFunctionKeyPath:@"uexQQ.cbLogin" arguments:ACArgsPack(@0,@2,[result ac_JSONFragment])];
    [self.funcLogin executeWithArguments:ACArgsPack(state,dic)];
     self.funcLogin = nil;
}


-(void)cbLoginWithResult:(BOOL)isSuccess{
    NSNumber *ret=@1;
    if(isSuccess){
        ret=@0;
    }
    NSMutableDictionary *data=[NSMutableDictionary dictionary];
    [data setValue:_tencentOAuth.openId forKey:@"openid"];
    [data setValue:_tencentOAuth.accessToken forKey:@"access_token"];
    NSMutableDictionary *resultDict=[NSMutableDictionary dictionary];
    [resultDict setValue:ret forKey:@"ret"];
    [resultDict setValue:data forKey:@"data"];
    [self cbLogin:[resultDict copy]];
}
- (void)tencentDidLogin {
    /*
    if (_tencentOAuth.accessToken && 0 != [_tencentOAuth.accessToken length]) {
        self.cbQQLoginStr = [NSString stringWithFormat:@"{\"ret\":0,\"openid\":\"%@\",\"access_token\":\"%@\"}",_tencentOAuth.openId,_tencentOAuth.accessToken];
        
    } else {
        self.cbQQLoginStr = [NSString stringWithFormat:@"{\"ret\":1,\"openid\":\"%@\",\"access_token\":\"%@\"}",_tencentOAuth.openId,_tencentOAuth.accessToken];
        
    }
     */
    //2015-6-23 回调结构修改by lkl

    if(_tencentOAuth.accessToken && 0 != [_tencentOAuth.accessToken length]){
        [self cbLoginWithResult:YES];
    }else{
        [self cbLoginWithResult:NO];
    }
}




/**
 * 非网络错误导致登录失败
 */
- (void)tencentDidNotLogin:(BOOL)cancelled {
    if (cancelled){
    } else {
    }
    [self cbLoginWithResult:NO];

    
    
}



/**
 * 网络错误导致登录失败
 */
-(void)tencentDidNotNetWork {
    [self cbLoginWithResult:NO];
}

- (void)tencentDidLogout{
    //NSLog(@"---------logout-----------%@",_tencentOAuth);
    _tencentOAuth=nil;
    //[self jsSuccessWithName:@"uexQQ.cbLogout" opId:0 dataType:UEX_CALLBACK_DATATYPE_INT intData:UEX_CSUCCESS];
    [self.webViewEngine callbackWithFunctionKeyPath:@"uexQQ.cbLogout" arguments:ACArgsPack(@0,@2,@0)];
    [self.funcLogout executeWithArguments:ACArgsPack(@0)];
    self.funcLogout = nil;
}
- (void)dealloc {
    
    [self clean];
    [super dealloc];
    
}

- (void)clean {
    
    [_tencentOAuth release];
    _tencentOAuth = nil;
    
    [_qqApiObj release];
    _qqApiObj = nil;
    
    [_cbQQLoginStr release];
    _cbQQLoginStr = nil;
    
    [_cbShareStr release];
    _cbShareStr = nil;
}
- (void)getUserInfoResponse:(APIResponse*) response{
    //NSLog(@"%@",response.jsonResponse);
    if(response.jsonResponse&&!response.errorMsg){
        NSString *userInfo=[response.jsonResponse ac_JSONFragment];
        [self cbGetUserInfo:userInfo];
    }
    else if (response.errorMsg){
        NSString *err=[response.errorMsg ac_JSONFragment];
        [self cbGetUserInfo:err];
    }
}
-(void)cbGetUserInfo:(NSString*)result{
    if(![result isKindOfClass:[NSString class]]){
        result=[result ac_JSONFragment];
    }
    //[self jsSuccessWithName:@"uexQQ.cbGetUserInfo" opId:0 dataType:2 strData:result];
     [self.webViewEngine callbackWithFunctionKeyPath:@"uexQQ.cbGetUserInfo" arguments:ACArgsPack(@0,@2,result)];
    [self.funcGetInfo executeWithArguments:ACArgsPack(result)];
    self.funcGetInfo = nil;
    
}
@end
