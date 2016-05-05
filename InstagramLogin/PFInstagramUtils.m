//
//  PFUser+Instagram.m
//  InstagramLogin
//
//  Created by Hafizur Rahman on 5/5/16.
//  Copyright © 2016 My Company. All rights reserved.
//

#import "PFInstagramUtils.h"
#import <SafariServices/SafariServices.h>

@interface PFInstagramUtils()

@property (nonatomic, strong) SFSafariViewController *safariVC;
@property (nonatomic, strong) PFInstagramUserResultBlock completionBlock;


@end

@implementation PFInstagramUtils


+ (PFInstagramUtils*)shareDelegate{

    static PFInstagramUtils *instagramDelegate = nil;
    
    if (!instagramDelegate) {
        instagramDelegate = [[PFInstagramUtils alloc]init];
    }
    return instagramDelegate;
}

- (BOOL)application:( UIApplication * _Nullable )application
            openURL:( NSURL * _Nullable )url
  sourceApplication:( NSString * _Nullable )sourceApplication
         annotation:(id _Nullable)annotation{

    if (self.safariVC) {
        [self.safariVC dismissViewControllerAnimated:YES completion:nil];
    }
    
    NSString *queryString = [url absoluteString];
    
    queryString = [queryString stringByRemovingPercentEncoding];
    
    queryString = [[queryString componentsSeparatedByString:@"#"] lastObject];
    
    if (queryString.length > 0) {
        
        NSArray *queryArray = [queryString componentsSeparatedByString:@"&"];
        
        NSMutableDictionary *dict = [[NSMutableDictionary alloc]initWithCapacity:queryArray.count];
        
        for (NSString *string in queryArray) {
            
            NSArray *keyValue = [string componentsSeparatedByString:@"="];
            
            if (keyValue.count) {
                [dict setObject:[keyValue lastObject] forKey:[keyValue firstObject]];
            }
        }
        
        if (dict.count > 0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self instagramUserDetailsWithAccessToken:[dict objectForKey:kAccessTokenKey]];
            });
            return YES;
        }
    }
    
    return NO;
}

- (void)loginInstagramWithClientId:(NSString* _Nonnull)clientId withDirectURI:(NSString* _Nonnull)uriURI block:(nullable PFInstagramUserResultBlock)block{

    self.completionBlock = block;
    
    NSString *urlString = [NSString stringWithFormat:@"%@/oauth/authorize/?client_id=%@&redirect_uri=%@&response_type=token", kInstagramAPIEndpoint, clientId,uriURI];
    
    self.safariVC = [[SFSafariViewController alloc] initWithURL:[NSURL URLWithString:urlString]];
    
    [[self applicationTopViewController] presentViewController:self.safariVC animated:YES completion:^{
        
    }];
}


- (void)instagramUserDetailsWithAccessToken:(NSString*)accessToken{
    
    if (accessToken) {
    
        NSString *urlString = [NSString stringWithFormat:@"%@/v1/users/self/?%@=%@", kInstagramAPIEndpoint, kAccessTokenKey, accessToken];
        
        [NSURLConnection sendAsynchronousRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:urlString]] queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse * _Nullable response, NSData * _Nullable data, NSError * _Nullable connectionError) {
            
            if (!connectionError) {
                
                NSDictionary *josnData = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                
                NSMutableDictionary *userData = [[NSMutableDictionary alloc]init];
                
                [userData setObject:accessToken forKey:kAccessTokenKey];
                if (josnData.count) {
                    
                    NSDictionary *data = [josnData objectForKey:@"data"];
                    [userData setObject:data forKey:PF_TOKEN_USER];
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self registerUserToParseServerWithUserDataDict:userData];
                    });
                }
            }
        }];
    }
}


- (void)registerUserToParseServerWithUserDataDict:(NSDictionary*)params{
    
    NSNumber *userIdNumber = [NSNumber numberWithInteger:[[[params objectForKey:PF_TOKEN_USER] objectForKey:kUserId]integerValue]];
    
    NSString *accessTokenNew = [params objectForKey:kAccessTokenKey];
    
    PFQuery *query = [PFQuery queryWithClassName:PF_TOKEN_STORAGE_CLASS];
    [query whereKey:PF_TOKEN_INSTAGRAM_ID equalTo:userIdNumber];
    [query findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        
        if (objects.count == 0) { // if new user
            
            [self signUpUser:params];
        }
        else{   // if already registered user 
            
            PFObject *tokenData = [objects firstObject];
            NSString *accessToken = [tokenData objectForKey:PF_TOKEN_INSTAGRAM_TOKEN];
            
            if (![accessToken isEqualToString:accessTokenNew]) {
                
                tokenData[PF_TOKEN_INSTAGRAM_TOKEN] = accessTokenNew;
                
                [tokenData saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                    
                    if (error) {
                        
                        NSLog(@"error to save token: %@", error.localizedDescription);
                    }
                    else{
                        
                        PFUser *currentUser = [tokenData objectForKey:PF_TOKEN_USER];
                        NSLog(@"currentUser: %@", currentUser);
                        
                        NSString *password = [tokenData objectForKey:PF_TOKEN_USER_TEMP_PASSWORD];
                        
                        
                        [PFUser logInWithUsernameInBackground:currentUser.username password:password block:^(PFUser * _Nullable user, NSError * _Nullable error) {
                            
                            if (!error) {
                                
                                self.completionBlock(user, false, nil);
                            }
                            else{
                                self.completionBlock(nil, false, error);
                            }
                        }];
                    }
                }];
            }
            else{
                self.completionBlock([PFUser currentUser], false, nil);
            }
        }
    }];
}


- (void)signUpUser:(NSDictionary*)params{
    
    PFUser *user = [PFUser user];
    
    NSData *usernameData = [[self randomStringWithLength:24] dataUsingEncoding:NSUTF8StringEncoding];
    NSString *userName = [usernameData base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
    
    NSData *passwordData = [[self randomStringWithLength:24] dataUsingEncoding:NSUTF8StringEncoding];
    NSString *password = [passwordData base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
    
    user.username = userName;
    user.password = password;
    [user setObject:[[params objectForKey:PF_TOKEN_USER] objectForKey:kName] forKey:PF_USER_NAME];
    [user setObject:[[params objectForKey:PF_TOKEN_USER] objectForKey:kPhotoUrlString] forKey:PF_USER_PHOTO_URL];
    
    [user signUpInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
        
        if (succeeded) {
            
            PFObject *tokenStorage = [PFObject objectWithClassName:PF_TOKEN_STORAGE_CLASS];
            tokenStorage[PF_TOKEN_INSTAGRAM_ID] = [NSNumber numberWithInteger:[[[params objectForKey:PF_TOKEN_USER] objectForKey:PF_TOKEN_INSTAGRAM_ID]integerValue]];
            tokenStorage[PF_TOKEN_INSTAGRAM_USERNAME] = [[params objectForKey:PF_TOKEN_USER] objectForKey:kUserName];
            tokenStorage[PF_TOKEN_USER] = user;
            tokenStorage[PF_TOKEN_INSTAGRAM_TOKEN] = [params objectForKey:kAccessTokenKey];
            tokenStorage[PF_TOKEN_USER_TEMP_PASSWORD] = password;
            
            PFACL *acl = [PFACL ACLWithUser:user];
            acl.publicReadAccess = true;
            acl.publicWriteAccess = false;
            tokenStorage.ACL = acl;
            
            [tokenStorage saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                
                if (error) {
                    NSLog(@"error: %@", error.localizedDescription);
                }
                else{
                    self.completionBlock(user, true, nil);
                }
            }];
        }
        else{
            self.completionBlock(nil, true, error);

        }
    }];
}


-(NSString *) randomStringWithLength: (int) len {
    
    NSString *letters = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ123456789";
    NSMutableString *randomString = [NSMutableString stringWithCapacity: len];
    
    for (int i=0; i<len; i++) {
        [randomString appendFormat: @"%C", [letters characterAtIndex: arc4random_uniform((u_int32_t)[letters length])]];
    }
    
    return randomString;
}

- (UIViewController *)applicationTopViewController {
    UIViewController *viewController = [UIApplication sharedApplication].keyWindow.rootViewController;
    while (viewController.presentedViewController) {
        viewController = viewController.presentedViewController;
    }
    return viewController;
}


@end
