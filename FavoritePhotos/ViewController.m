//
//  ViewController.m
//  FavoritePhotos
//
//  Created by Eduardo Alvarado Díaz on 10/16/14.
//  Copyright (c) 2014 Organization. All rights reserved.
//

#import "ViewController.h"
#import <CoreLocation/CoreLocation.h>

@interface ViewController () <UIWebViewDelegate, CLLocationManagerDelegate>
@property CLLocationManager *myLocationManager;
@property CLPlacemark *currentLocation;
@property (strong, nonatomic) IBOutlet UIWebView *webView;
@property NSDictionary *instaProperties;

@end

@implementation ViewController

- (void)viewDidLoad{
    [super viewDidLoad];

    if (self.instaProperties == nil) {
        self.instaProperties = [[NSDictionary alloc]init];
    }
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
        [self loadURL];
    }else{
        //[self loadRequestForMediaPopular];
        //[self loadRequestForSearch];
    }
}

-(void)save:(NSString *)token{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
//    NSURL *pList = [[self documentsDicrectory] URLByAppendingPathComponent:@"insta.plist"];
//    [self.instaProperties writeToURL:pList atomically:YES];

    [userDefaults setObject:token forKey:@"KACCESS_TOKEN"];
    [userDefaults synchronize];
}

-(void)loadURL{
    NSString *stringURL = [NSString stringWithFormat:@"%@?client_id=%@&redirect_uri=%@&response_type=token",[self.instaProperties objectForKey:@"KAUTHURL"],[self.instaProperties objectForKey:@"KCLIENTID"],[self.instaProperties objectForKey:@"KREDIRECTURI"]];
NSLog(@"fullURL: %@",stringURL);
    NSURL *url = [NSURL URLWithString:stringURL];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [self.webView loadRequest:request];
}

-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType{
    NSString* urlString = [[request URL] absoluteString];
NSLog(@"URL STRING: %@ ",urlString);
    NSArray *UrlParts = [urlString componentsSeparatedByString:[NSString stringWithFormat:@"%@#", [self.instaProperties objectForKey:@"KREDIRECTURI"]]];
    NSInteger x = [UrlParts count];
    if (x > 1) {
        urlString = [UrlParts objectAtIndex:1];
        NSRange accessToken = [urlString rangeOfString: @"access_token="];
        if (accessToken.location != NSNotFound) {
            NSString* strAccessToken = [urlString substringFromIndex: NSMaxRange(accessToken)];
NSLog(@"AccessToken = %@ ",strAccessToken);
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
    NSDictionary *dictResponse = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
NSLog(@"Response: %@",dictResponse);
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
    NSDictionary *dictResponse = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
NSLog(@"Response: %@",dictResponse);
}

-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations{
    for (CLLocation *location in locations) {
        if(location.verticalAccuracy < 1000 && location.horizontalAccuracy < 1000){
            [self reverseGeocode:location];
            //NSLog(@"location: %@",location);
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
        [self loadRequestForSearch];
    }];
}

@end
