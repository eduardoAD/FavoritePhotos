//
//  ImageDetailViewController.m
//  FavoritePhotos
//
//  Created by Eduardo Alvarado Díaz on 10/17/14.
//  Copyright (c) 2014 Organization. All rights reserved.
//

#import "ImageDetailViewController.h"

@interface ImageDetailViewController ()

@end

@implementation ImageDetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.imageView.image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:self.stringURL]]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}



@end
