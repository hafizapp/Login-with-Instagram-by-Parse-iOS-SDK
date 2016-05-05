# Login-with-Instagram-by-Parse-iOS-SDK
instagram login with parse iOS SDK

import "PFInstagramUtils.h" on your view controller then add this following code to your instagram login button action.


[[PFInstagramUtils shareDelegate] loginInstagramWithClientId:@"b5e3187a599345f6a288cccac09879da" withDirectURI:@"wicky://" block:^(PFUser * _Nullable user, BOOL isNew, NSError * _Nullable error) {

    if (!error) {
        if (isNew) {
            NSLog(@"User newly created by instagram");
        }
        else{
            NSLog(@"User just logged in by instagram");
        }

        [self.instagramButton setTitle:[NSString stringWithFormat:@"Logged In as %@", [user objectForKey:PF_USER_NAME]] forState:UIControlStateNormal];
    }

    else{
        NSLog(@"%@", error.localizedDescription);
        [[[UIAlertView alloc]initWithTitle:error.localizedDescription message:nil delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
    }
}];
