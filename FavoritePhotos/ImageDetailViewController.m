//
//  ImageDetailViewController.m
//  FavoritePhotos
//
//  Created by Eduardo Alvarado Díaz on 10/17/14.
//  Copyright (c) 2014 Organization. All rights reserved.
//

#import "ImageDetailViewController.h"

@interface ImageDetailViewController () <UIAlertViewDelegate>

@end

@implementation ImageDetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.imageView.image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:self.stringURL]]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (IBAction)imageTapped:(UITapGestureRecognizer *)sender {
    UIAlertView *alertView = [[UIAlertView alloc] init];
    alertView.delegate = self;
    [alertView addButtonWithTitle:@"No"];
    [alertView addButtonWithTitle:@"Yes!"];
    if ([self.user_has_liked isEqualToString:@"0"]) {
        alertView.title = @"Add to favorites?";

    }else{
        alertView.title = @"Remove from favorites?";
    }

    [alertView show];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex{
    if (buttonIndex == 1){
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        NSString *token = [userDefaults objectForKey:@"KACCESS_TOKEN"];

        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
        NSString *post = [NSString stringWithFormat:@"access_token=%@",token];
        NSData *postData = [post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
        NSString *postLength = [NSString stringWithFormat:@"%lu", (unsigned long)[postData length]];

        NSString *url = [self.instaProperties objectForKey:@"KAPIURL"];
        NSString *stringURL = [NSString stringWithFormat:@"%@media/%@/likes",url,self.id];

        if ([self.user_has_liked isEqualToString:@"0"]) {
            NSLog(@"Mark favorite");
            [request setHTTPMethod:@"POST"];
        }else{
            NSLog(@"Remove favorite");
            [request setHTTPMethod:@"DELETE"];
            stringURL = [NSString stringWithFormat:@"%@media/%@/likes?access_token=%@",url,self.id,token];
        }

        [request setURL:[NSURL URLWithString:stringURL]];
        [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
        [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
        [request setHTTPBody:postData];

        [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
            NSError *jsonError = nil;
            NSArray *responseJSON;
            responseJSON = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
            NSLog(@"%@",responseJSON);
            self.user_has_liked = @"1";

            if (connectionError != nil) {
                NSLog(@"Connection error: %@", connectionError);
            }
            if (jsonError != nil) {
                NSLog(@"JSON error: %@", jsonError);
            }
        }];
    }
}

@end
