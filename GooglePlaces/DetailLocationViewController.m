//
//  DetailLocationViewController.m
//  GooglePlaces
//
//  Created by Bob Law on 3/22/14.
//  Copyright (c) 2014 Bob Law. All rights reserved.
//

#import "DetailLocationViewController.h"

@interface DetailLocationViewController ()
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *phoneLabel;
//@property (nonatomic) NSMutableString *address;
@property (weak, nonatomic) IBOutlet UILabel *addressLabel;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;

@end

#define kGOOGLE_API_KEY @"AIzaSyBEVI_Wrs8WO2GL8pcWdcnPWU4nvMZ7PMM"
#define kBgQueue dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)

@implementation DetailLocationViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    
    
//https://maps.googleapis.com/maps/api/place/details/output?key=%@,reference=%@,sensor=true
   // NSLog(@"%@", [self.place objectForKey:@"reference"]);
    
    NSString *url = [NSString stringWithFormat:@"https://maps.googleapis.com/maps/api/place/details/json?reference=%@&sensor=true&key=%@", [self.place objectForKey:@"reference"], kGOOGLE_API_KEY];
    NSURL *googleRequestURL=[NSURL URLWithString:url];
    
    // Retrieve the results of the URL.
    dispatch_async(kBgQueue, ^{
        NSData* data = [NSData dataWithContentsOfURL: googleRequestURL];
        [self performSelectorOnMainThread:@selector(fetchedData:) withObject:data waitUntilDone:YES];
    });
}
-(void)fetchedData:(NSData *)responseData {
    //parse out the json data
    NSError* error;
    NSDictionary* json = [NSJSONSerialization
                          JSONObjectWithData:responseData
                          
                          options:kNilOptions
                          error:&error];
    
    //The results from Google will be an array obtained from the NSDictionary object with the key "results".
    NSDictionary* places = [json objectForKey:@"result"];
    
    //NSDictionary *detail = [places objectAtIndex:0];
    NSString *name = [places objectForKey:@"name"];
    self.nameLabel.text = [NSString stringWithFormat:@"%@", [places objectForKey:@"name"]];

    self.phoneLabel.text = [NSString stringWithFormat:@"%@", [places objectForKey:@"formatted_phone_number"]];
    
    //NSDictionary *geo = [places objectForKey:@"geometry"];
    NSArray *photos = [places objectForKey:@"photos"];
    NSArray *address = [places objectForKey:@"address_components"];
    [self setAddress:address];
    //NSString *formattedAddress = [places objectForKey:@"formatted_address"];
    //NSLog(@"%@", address);
    NSLog(@"%lu", (unsigned long)[address count]);
    NSLog(@"Google Data: %@", places);
    //NSLog(@"%lu", (unsigned long)[places count]);
    //NSLog(@"Google Data: %@", address);
    NSDictionary *geo = [places objectForKey:@"geometry"];
    NSDictionary *location = [geo objectForKey:@"location"];
    CLLocationCoordinate2D pointCoord;
    pointCoord.latitude = [[location objectForKey:@"lat"] doubleValue];
    pointCoord.longitude = [[location objectForKey:@"lng"] doubleValue];
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(pointCoord,1000,1000);
    [self.mapView setRegion:region animated:NO];
    MKPointAnnotation *point = [[MKPointAnnotation alloc] init];
    point.title = name;
    //point.subtitle = address;
    point.coordinate = pointCoord;
    [self.mapView addAnnotation:point];
    
}

-(void) setAddress:(NSArray *) address{

    NSString *streetNumber = [[address objectAtIndex:0] objectForKey:@"long_name"];
    NSString *streetName = [[address objectAtIndex:1] objectForKey:@"long_name"];
    NSString *city = [[address objectAtIndex:2] objectForKey:@"long_name"];
    NSString *state = [[address objectAtIndex:3] objectForKey:@"long_name"];
    NSString *postalCode = [[address objectAtIndex:5] objectForKey:@"long_name"];

    NSString *fullAddress = [NSString stringWithFormat:@"%@ %@\n%@, %@ %@", streetNumber, streetName, city, state, postalCode];
    self.addressLabel.text = fullAddress;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)back:(id)sender {
    [self dismissViewControllerAnimated:YES completion: nil];

}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
