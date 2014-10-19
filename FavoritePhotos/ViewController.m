//
//  ViewController.m
//  FavoritePhotos
//
//  Created by Eduardo Alvarado Díaz on 10/16/14.
//  Copyright (c) 2014 Organization. All rights reserved.
//

#import "ViewController.h"
#import "CollectionViewImageCell.h"
#import <CoreLocation/CoreLocation.h>
#import "ImageDetailViewController.h"

@interface ViewController () <UIWebViewDelegate, CLLocationManagerDelegate, UICollectionViewDataSource, UICollectionViewDelegate>
@property CLLocationManager *myLocationManager;
@property CLPlacemark *currentLocation;
@property (strong, nonatomic) IBOutlet UIWebView *webView;
@property (strong, nonatomic) IBOutlet UICollectionView *imageCollectionView;
@property NSDictionary *instaProperties;
@property NSArray *instaResultData;
@property NSDictionary *selectedItem;

@end

@implementation ViewController

- (void)viewDidLoad{
    [super viewDidLoad];

    if (self.instaProperties == nil) {
        self.instaProperties = [[NSDictionary alloc]init];
    }
    self.selectedItem = [[NSDictionary alloc]init];

    self.myLocationManager = [[CLLocationManager alloc] init];
    [self.myLocationManager requestWhenInUseAuthorization];
    self.myLocationManager.delegate = self;

    [self.myLocationManager startUpdatingLocation];
    [self load];
}

-(NSURL *)documentsDicrectory{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *files = [fileManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
    return files.firstObject;
}

-(void)load{
    NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"insta" ofType:@"plist"];
    self.instaProperties = [NSDictionary dictionaryWithContentsOfFile:plistPath];

    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *token = [userDefaults objectForKey:@"KACCESS_TOKEN"];
    NSLog(@"KACCESS_TOKEN: %@",token);

    if (token == nil) {
        self.webView.hidden = NO;
        self.imageCollectionView.hidden = YES;
        [self loadURL];
    }
}

-(void)save:(NSString *)token{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:token forKey:@"KACCESS_TOKEN"];
    [userDefaults synchronize];
}

-(void)loadURL{
    NSString *stringURL = [NSString stringWithFormat:@"%@?client_id=%@&redirect_uri=%@&scope=likes&response_type=token",
                           [self.instaProperties objectForKey:@"KAUTHURL"],
                           [self.instaProperties objectForKey:@"KCLIENTID"],
                           [self.instaProperties objectForKey:@"KREDIRECTURI"]];
    NSURL *url = [NSURL URLWithString:stringURL];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [self.webView loadRequest:request];
}

-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType{
    NSString* urlString = [[request URL] absoluteString];
    NSArray *UrlParts = [urlString componentsSeparatedByString:[NSString stringWithFormat:@"%@#", [self.instaProperties objectForKey:@"KREDIRECTURI"]]];
    NSInteger x = [UrlParts count];
    if (x > 1) {
        urlString = [UrlParts objectAtIndex:1];
        NSRange accessToken = [urlString rangeOfString: @"access_token="];
        if (accessToken.location != NSNotFound) {
            NSString* strAccessToken = [urlString substringFromIndex: NSMaxRange(accessToken)];
            [self save:strAccessToken];
        }
        return NO;
    }
    return YES;
}


-(void)loadRequestForMediaPopular {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *token = [userDefaults objectForKey:@"KACCESS_TOKEN"];
    NSString *url = [self.instaProperties objectForKey:@"KAPIURL"];

    NSString *stringURL = [NSString stringWithFormat:@"%@media/popular?access_token=%@",url,token];
    NSLog(@"stringURL: %@",stringURL);
    NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:stringURL]];
    self.instaResultData = [((NSDictionary *)[NSJSONSerialization JSONObjectWithData:data options:0 error:nil]) objectForKey:@"data"];
    //NSLog(@"Response: %@",self.instaResultData);
}

-(void)loadRequestForSearch{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *token = [userDefaults objectForKey:@"KACCESS_TOKEN"];
    NSString *url = [self.instaProperties objectForKey:@"KAPIURL"];
    double lat = self.currentLocation.location.coordinate.latitude;
    double lng = self.currentLocation.location.coordinate.longitude;

    NSString *stringURL = [NSString stringWithFormat:@"%@media/search?lat=%f&lng=%f&access_token=%@",url,lat,lng,token];
    NSLog(@"stringURL: %@",stringURL);
    NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:stringURL]];
    self.instaResultData = [((NSDictionary *)[NSJSONSerialization JSONObjectWithData:data options:0 error:nil]) objectForKey:@"data"];

    //NSLog(@"Response: %@",self.instaResultData);
}

-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations{
    for (CLLocation *location in locations) {
        if(location.verticalAccuracy < 1000 && location.horizontalAccuracy < 1000){
            [self reverseGeocode:location];
            [self.myLocationManager stopUpdatingLocation];
            break;
        }
    }
}

-(void)reverseGeocode:(CLLocation *)location{
    CLGeocoder *geocoder = [CLGeocoder new];
    [geocoder reverseGeocodeLocation:location completionHandler:^(NSArray *placemarks, NSError *error) {
        self.currentLocation = placemarks.firstObject;
        NSString *address = [NSString stringWithFormat:@"%@, %@ at %@",
                             self.currentLocation.subThoroughfare,
                             self.currentLocation.thoroughfare,
                             self.currentLocation.locality];
        NSLog(@"Found you: %@",address);

        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        NSString *token = [userDefaults objectForKey:@"KACCESS_TOKEN"];
        NSLog(@"KACCESS_TOKEN: %@",token);
        if (token != nil) {
            [self loadRequestForSearch];
            [self.imageCollectionView reloadData];
        }
    }];
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    //return self.instaResultData.count;
    return 10;
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    CollectionViewImageCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];

    NSString *stringURL = [[(NSDictionary *)[(NSDictionary *)[self.instaResultData objectAtIndex:indexPath.row]objectForKey:@"images"] objectForKey:@"thumbnail"] objectForKey:@"url"];

    cell.imageView.image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:stringURL]]];
    return cell;
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    self.selectedItem = [self.instaResultData objectAtIndex:indexPath.item];
    [self performSegueWithIdentifier: @"imageDetail" sender: self];
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    ImageDetailViewController *destination = [segue destinationViewController];

    destination.instaProperties = self.instaProperties;
    destination.id = [self.selectedItem objectForKey:@"id"];
    NSString *stringURL = [[(NSDictionary *)[(NSDictionary *)self.selectedItem objectForKey:@"images"] objectForKey:@"standard_resolution"] objectForKey:@"url"];
    NSLog(@"url image standard: %@",stringURL);
    destination.user_has_liked = [[self.selectedItem objectForKey:@"user_has_liked"] description];
    NSLog(@"user has liked: %@",destination.user_has_liked);

    destination.stringURL = stringURL;
}

@end
