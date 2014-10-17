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
@property NSString *stringURL;
@end
