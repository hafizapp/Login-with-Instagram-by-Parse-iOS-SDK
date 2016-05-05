//
//  PFUser+Instagram.h
//  InstagramLogin
//
//  Created by Hafizur Rahman on 5/5/16.
//  Copyright © 2016 My Company. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Parse/Parse.h>


#define kInstagramAPIEndpoint @"https://api.instagram.com"
//MARK: Instagram JSON Data Keys
#define kUserName       @"username"
#define kUserId         @"id"
#define kPhotoUrlString @"profile_picture"
#define kName           @"full_name"
#define kAccessTokenKey @"access_token"


//MARK: PARSE CLASS & KEYS
#define PF_TOKEN_STORAGE_CLASS  @"TokenStorage"
#define PF_TOKEN_INSTAGRAM_ID         @"instagramId"
#define PF_TOKEN_INSTAGRAM_USERNAME   @"username"
#define PF_TOKEN_INSTAGRAM_TOKEN      @"accessToken"
#define PF_TOKEN_USER_TEMP_PASSWORD   @"secureCode"
#define PF_TOKEN_USER                 @"user"

//====================================================//

#define PF_USER_CLASS           @"_User"
#define PF_USER_NAME                  @"name"
#define PF_USER_PHOTO_URL             @"profilePhotoUrl"


typedef void (^PFInstagramUserResultBlock)(PFUser *_Nullable user, BOOL isNew, NSError *_Nullable error);


@interface PFInstagramUtils : NSObject

//@property (nonatomic, readonly) NSDictionary *userAuthenticatedData;

+ ( PFInstagramUtils* _Nonnull )shareDelegate;

- (BOOL)application:( UIApplication * _Nullable )application
            openURL:( NSURL * _Nullable )url
  sourceApplication:( NSString * _Nullable )sourceApplication
         annotation:(id _Nullable)annotation;

- (void)loginInstagramWithClientId:(NSString* _Nonnull)clientId withDirectURI:(NSString* _Nonnull)uriURI block:(nullable PFInstagramUserResultBlock)block;

@end
