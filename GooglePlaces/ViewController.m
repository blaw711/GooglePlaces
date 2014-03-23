//
//  ViewController.m
//  GooglePlaces
//
//  Created by Bob Law on 3/21/14.
//  Copyright (c) 2014 Bob Law. All rights reserved.
//

#import "ViewController.h"
#import "UIImageView+AFNetworking.h"

@interface ViewController (){
    CLLocationManager *locationManager;
    CLLocationCoordinate2D currentCentre;
    int currenDist;
    BOOL firstLaunch;
}

@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedControl;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSArray *locationsArray;
@end

#define kGOOGLE_API_KEY @"AIzaSyBEVI_Wrs8WO2GL8pcWdcnPWU4nvMZ7PMM"
#define kBgQueue dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)



@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    firstLaunch = YES;
    
	// Do any additional setup after loading the view, typically from a nib.
    self.mapView.delegate = self;
    
    // Ensure that you can view your own location in the map view.
    [self.mapView setShowsUserLocation:YES];
    
    //Instantiate a location object.
    locationManager = [[CLLocationManager alloc] init];
    
    //Make this controller the delegate for the location manager.
    [locationManager setDelegate:self];
    
    //Set some parameters for the location object.
    [locationManager setDistanceFilter:kCLDistanceFilterNone];
    [locationManager setDesiredAccuracy:kCLLocationAccuracyBest];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
}
- (IBAction)recenterButtonPressed:(id)sender {
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(locationManager.location.coordinate,1000,1000);

    [self.mapView setRegion:region animated:YES];
}

- (IBAction)barButtonItemPressed:(id)sender {
    UIBarButtonItem *button = (UIBarButtonItem *)sender;
    NSString *place = [button.title lowercaseString];
    
    [self queryGooglePlaces:place];
}

- (IBAction)segmentedControl:(id)sender {
    
    if (self.segmentedControl.selectedSegmentIndex ==0) {
        self.tableView.alpha = 0;
        self.mapView.alpha = 1;
    } else{
        self.tableView.alpha = 1;
        self.mapView.alpha = 0;
    }
    
}
-(void) queryGooglePlaces: (NSString *) googleType {
    // Build the url string to send to Google. NOTE: The kGOOGLE_API_KEY is a constant that should contain your own API key that you obtain from Google. See this link for more info:
    // https://developers.google.com/maps/documentation/places/#Authentication
    NSString *url;
    if ([googleType isEqualToString:@"all"]) {
        
        url = [NSString stringWithFormat:@"https://maps.googleapis.com/maps/api/place/search/json?location=%f,%f&radius=%@&sensor=true&key=%@", currentCentre.latitude, currentCentre.longitude, [NSString stringWithFormat:@"%i", currenDist], kGOOGLE_API_KEY];
    } else{
        
        url = [NSString stringWithFormat:@"https://maps.googleapis.com/maps/api/place/search/json?location=%f,%f&radius=%@&types=%@&sensor=true&key=%@", currentCentre.latitude, currentCentre.longitude, [NSString stringWithFormat:@"%i", currenDist], googleType, kGOOGLE_API_KEY];
    }
    
    //Formulate the string as a URL object.
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
    NSArray* places = [json objectForKey:@"results"];
    
    self.locationsArray = places;
    [self.tableView reloadData];
    [self.tableView reloadInputViews];
    
    //Write out the data to the console.
    [self addPlacesToMapView:places];
}

-(void)addPlacesToMapView:(NSArray *)data{
    for (MKPointAnnotation *point in self.mapView.annotations) {
        if (![point.title isEqualToString:@"Current Location"]) {
            [self.mapView removeAnnotation:point];
        }
    }
    
    for (int i = 0; i < [data count]; i++) {
        
        MKPointAnnotation *point = [[MKPointAnnotation alloc] init];
        NSDictionary *place = [data objectAtIndex:i];
        NSDictionary *geo = [place objectForKey:@"geometry"];
        NSDictionary *location = [geo objectForKey:@"location"];
        NSString *name = [place objectForKey:@"name"];
        NSString *address = [place objectForKey:@"vicinity"];
        CLLocationCoordinate2D pointCoord;
        pointCoord.latitude = [[location objectForKey:@"lat"] doubleValue];
        pointCoord.longitude = [[location objectForKey:@"lng"] doubleValue];
        point.title = name;
        point.subtitle = address;
        point.coordinate = pointCoord;
        [self.mapView addAnnotation:point];
        
    }
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UITableViewDelegate & UITableViewDataSource methods.

- (int)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [self.locationsArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    NSDictionary *place = [self.locationsArray objectAtIndex:indexPath.row];
    NSDictionary *geo = [place objectForKey:@"geometry"];
    NSDictionary *location = [geo objectForKey:@"location"];
    NSString *name = [place objectForKey:@"name"];
    NSString *address = [place objectForKey:@"vicinity"];
    NSString *imageURL = [place objectForKey:@"icon"];
    CLLocationCoordinate2D pointCoord;
    pointCoord.latitude = [[location objectForKey:@"lat"] doubleValue];
    pointCoord.longitude = [[location objectForKey:@"lng"] doubleValue];
    
  //  dispatch_async(kBgQueue, ^{
       // [cell.imageView setImage:[UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:imageURL]]]];
        
  //  });
    NSURL *url = [NSURL URLWithString:imageURL];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    UIImage *placeholderImage = [UIImage imageNamed:@"placeholder"];
    
    __weak UITableViewCell *weakCell = cell;
    
    [cell.imageView setImageWithURLRequest:request
                          placeholderImage:placeholderImage
                                   success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                                       
                                       weakCell.imageView.image = image;
                                       [weakCell setNeedsLayout];
                                       
                                   } failure:nil];
    
   /* [cell.imageView setImage:[UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:imageURL]]]];*/
    
    
    

    cell.textLabel.text = name;
    cell.detailTextLabel.text = address;
    cell.detailTextLabel.textColor = [UIColor lightGrayColor];
    return cell;
}


#pragma mark - MKMapViewDelegate methods.
- (void)mapView:(MKMapView *)mv didAddAnnotationViews:(NSArray *)views {
    //Zoom back to the user location after adding a new set of annotations.
    //Get the center point of the visible map.
    CLLocationCoordinate2D centre = [mv centerCoordinate];
    MKCoordinateRegion region;
    //If this is the first launch of the app, then set the center point of the map to the user's location.
    if (firstLaunch) {
        region = MKCoordinateRegionMakeWithDistance(locationManager.location.coordinate,1000,1000);
        firstLaunch=NO;
    }else {
        //Set the center point to the visible region of the map and change the radius to match the search radius passed to the Google query string.
        region = MKCoordinateRegionMakeWithDistance(centre,currenDist,currenDist);
    }
    //Set the visible region of the map.
    [mv setRegion:region animated:YES];
}
-(void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated {
    //Get the east and west points on the map so you can calculate the distance (zoom level) of the current map view.
    MKMapRect mRect = self.mapView.visibleMapRect;
    MKMapPoint eastMapPoint = MKMapPointMake(MKMapRectGetMinX(mRect), MKMapRectGetMidY(mRect));
    MKMapPoint westMapPoint = MKMapPointMake(MKMapRectGetMaxX(mRect), MKMapRectGetMidY(mRect));
    
    //Set your current distance instance variable.
    currenDist = MKMetersBetweenMapPoints(eastMapPoint, westMapPoint);
    
    //Set your current center point on the map instance variable.
    currentCentre = self.mapView.centerCoordinate;
}
-(MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation {
    // Define your reuse identifier.
    static NSString *identifier = @"MapPoint";
    
    if ([annotation isKindOfClass:[MKPointAnnotation class]]) {
        MKPinAnnotationView *annotationView = (MKPinAnnotationView *) [self.mapView dequeueReusableAnnotationViewWithIdentifier:identifier];
        if (annotationView == nil) {
            annotationView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:identifier];
        } else {
            annotationView.annotation = annotation;
        }
        annotationView.enabled = YES;
        annotationView.canShowCallout = YES;
        annotationView.animatesDrop = YES;
        return annotationView;
    }
    return nil;
}


@end
