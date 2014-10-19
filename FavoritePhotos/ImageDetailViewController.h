//
//  ImageDetailViewController.h
//  FavoritePhotos
//
//  Created by Eduardo Alvarado Díaz on 10/17/14.
//  Copyright (c) 2014 Organization. All rights reserved.
//

#import "ViewController.h"

@interface ImageDetailViewController : ViewController
@property (strong, nonatomic) IBOutlet UIImageView *imageView;
@property NSDictionary *instaProperties;
@property NSString *stringURL;
@property NSString *id;
@property NSString *user_has_liked;

@end
