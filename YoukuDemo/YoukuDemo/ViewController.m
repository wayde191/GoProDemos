//
//  ViewController.m
//  YoukuDemo
//
//  Created by Wei Wayde Sun on 7/28/15.
//  Copyright (c) 2015 iHakula. All rights reserved.
//

#import "ViewController.h"
#import "ASIHTTPRequest.h"
#import "ASIHTTPRequestDelegate.h"
#import "AFAppDotNetAPIClient.h"

@interface ViewController () {
    NSString *_codeStr;
    NSDictionary *_tokenDic;
}

@property (weak, nonatomic) IBOutlet UIWebView *webview;
@property (weak, nonatomic) IBOutlet UITextView *textView;
@end


#define OAUTH_URL @"https://openapi.youku.com/v2/oauth2/authorize?client_id=136e7467d834f358&response_type=code&redirect_uri=http%3A%2F%2Fwww.ihakula.com%2Fapi%2Findex.php%2FYouku&state=Wayde"

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.textView.text = @"";
    [self.webview loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:OAUTH_URL]]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)outputLogtoScreen: (NSString *)text {
    NSString *outputStr = [NSString stringWithFormat:@"%@\n\r%@", self.textView.text, text];
    self.textView.text = outputStr;
}

#pragma mark - Webview Delegate
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    NSLog(@"%@", request.URL);
    NSLog(@"%@", request.URL.host);
    if ([@"www.ihakula.com" isEqualToString:request.URL.host]) {
        _codeStr = request.URL.absoluteString;
        [self performSelector:@selector(refreshOAuth2) withObject:nil afterDelay:2.0];
    }
    
    return YES;
}

#pragma mark - Private Methods
- (NSString *)foundStringWithRegex:(NSString *)userRegex {
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:userRegex options:NSRegularExpressionCaseInsensitive error:nil];
    
    NSArray *matchs = [regex matchesInString:_codeStr options:0 range:NSMakeRange(0, [_codeStr length])];
    NSTextCheckingResult *match = matchs[0];
    NSRange m1 = [match rangeAtIndex:1];
    NSString *foundStr = [_codeStr substringWithRange:m1];
    
    return foundStr;
}

//http://www.ihakula.com/api/index.php/Youku?code=8651b00cb152fcb8547496577cc69de6&state=xyz&response_type=login

- (NSDictionary *)getResponseDic {
    return @{
             @"code": [self foundStringWithRegex:@"code=(\\w*)"],
             @"state": [self foundStringWithRegex:@"state=(\\w*)"],
             @"responseType": [self foundStringWithRegex:@"response_type=(\\w*)"]
             };
}

- (void)refreshOAuth2 {
    NSDictionary *responseDic = [self getResponseDic];
    NSLog(@"--%@", responseDic);
    
    NSDictionary *para = @{
                           @"client_id": @"136e7467d834f358",
                           @"client_secret": @"de27721affb03c81a889f2a4f0b2ee10",
                           @"grant_type": @"authorization_code",
                           @"code": responseDic[@"code"],
                           @"redirect_uri": @"http://www.ihakula.com/api/index.php/Youku"
                           };
    [[AFAppDotNetAPIClient sharedClient] POST:@"oauth2/token" parameters:para success:^(NSURLSessionDataTask * __unused task, id JSON) {
        _tokenDic = JSON;
        NSLog(@"%@", _tokenDic);
        [self uploadVideo];
        
    } failure:^(NSURLSessionDataTask *__unused task, NSError *error) {
        NSLog(@"error .......");
    }];
}

- (void)uploadVideo {
    NSDictionary *params = @{@"access_token" : _tokenDic[@"access_token"]};
//    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"phoenix" ofType:@"m4v"];
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"tw" ofType:@"mov"];

    NSDictionary *info = @{
                           @"title" : @"凤凰",
                           @"file_name": filePath,
                           @"tags": @"testing"
                           };
    
    [[YoukuUploader sharedInstance] upload:params uploadInfo:info uploadDelegate:self dispatchQueue:nil];
}

#pragma mark - YoukuUploaderDelegate

- (void) onStart {
    NSLog(@"start......");
    [self outputLogtoScreen:@"start......"];
}

- (void) onProgressUpdate:(int)progress {
    NSLog(@"Uploading...%d", progress);
    [self outputLogtoScreen:[NSString stringWithFormat:@"Uploading...%d", progress]];
}

- (void) onSuccess:(NSString*)vid {
    NSLog(@"Success.");
    [self outputLogtoScreen:@"Success."];
}

- (void) onFailure:(NSDictionary*)response {
    NSLog(@"Failure: %@", response);
    [self outputLogtoScreen:[NSString stringWithFormat:@"Failure: %@", response]];
}

@end

