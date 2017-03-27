#import "MSDeviceInfoViewController.h"
#import "MSDeviceTracker.h"
#import "MSDevice.h"
#import "MSSerializableObject.h"

@interface MSDeviceInfoViewController ()

@property(nonatomic,strong) NSArray *keys;
@property(nonatomic,strong) NSDictionary *data;
@property(nonatomic,strong) NSDictionary *desc;

@end

@implementation MSDeviceInfoViewController

#pragma mark - View Controller

- (void)viewDidLoad {
  [super viewDidLoad];
  self.title = @"Device Info";
  
  //NSMutableDictionary *device = [[[MSDeviceTracker sharedInstance] device] performSelector:@selector(serializeToDictionary)];
  
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
  return 0;//self.booksArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  static NSString *CellIdentifier = @"entry";
  
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
  if (cell == nil) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
  }
  
  //cell.textLabel.text = crash.title;
  //cell.detailTextLabel.text =
  
  return cell;
}

@end
