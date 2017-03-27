#import "MSDeviceInfoViewController.h"
#import "MSDeviceTracker.h"
#import "MSDevice.h"
#import "MSSerializableObject.h"

@interface MSDeviceInfoViewController ()

@property(nonatomic,strong) NSArray *keys;
@property(nonatomic, strong) NSDictionary *desc;
@property(nonatomic,strong) NSDictionary *data;

@end

@implementation MSDeviceInfoViewController

#pragma mark - View Controller

- (void)viewDidLoad {
  [super viewDidLoad];
  
  self.data = [[[MSDeviceTracker sharedInstance] device] performSelector:@selector(serializeToDictionary)];
  self.desc = @{
                @"sdk_name": @"Name of the SDK. Consists of the name of the SDK and the platform",
                @"sdk_version": @"Version of the SDK in semver format",
                @"model": @"Device model",
                @"oem_name": @"Device manufacturer",
                @"os_name": @"OS name",
                @"os_version": @"OS version",
                @"os_build": @"OS build code",
                @"os_api_level": @"API level when applicable like in Android",
                @"locale": @"Language code",
                @"time_zone_offset": @"The offset in minutes from UTC for the device time zone",
                @"screen_size": @"Screen size of the device in pixels",
                @"app_version": @"Application version name",
                @"carrier_name": @"Carrier name (for mobile devices)",
                @"carrier_country": @"Carrier country code (for mobile devices)",
                @"app_build": @"The app's build number",
                @"app_namespace": @"The bundle/package identifier, or namespace"
                };
  self.keys = [self.data allKeys];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
    return YES;
  } else {
    return toInterfaceOrientation != UIInterfaceOrientationPortraitUpsideDown;
  }
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return self.keys.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  static NSString *CellIdentifier = @"entry";
  
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
  if (cell == nil) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
  }
  
  NSString *key = [self.keys objectAtIndex:indexPath.row];
  NSString *desc = [self.desc objectForKey:key];
  NSObject *value = [self.data objectForKey:key];
  
  cell.textLabel.text = desc;
  cell.detailTextLabel.text = [NSString stringWithFormat:@"%@", value];
  
  return cell;
}

@end
