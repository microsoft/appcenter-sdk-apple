#import "MSCustomPropertiesViewController.h"
#import "AppCenter.h"
#import "MSAppCenterPrivate.h"

@interface MSCustomPropertiesViewController ()

@end

@implementation MSCustomPropertiesViewController

#pragma mark - view controller

- (void)viewDidLoad {
  [super viewDidLoad];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  [tableView deselectRowAtIndexPath:indexPath animated:YES];

  switch ([indexPath section]) {

  // Actions
  case 0: {
    switch (indexPath.row) {
      
      // Set String
      case 0: {
        MSCustomProperties *customProperties = [MSCustomProperties new];
        [customProperties setString:@"test" forKey:@"test"];
        [MSAppCenter setCustomProperties:customProperties];
        break;
      }
        
      // Set Number
      case 1: {
        MSCustomProperties *customProperties = [MSCustomProperties new];
        [customProperties setNumber:@42 forKey:@"test"];
        [MSAppCenter setCustomProperties:customProperties];
        break;
      }
        
      // Set Boolean
      case 2: {
        MSCustomProperties *customProperties = [MSCustomProperties new];
        [customProperties setBool:NO forKey:@"test"];
        [MSAppCenter setCustomProperties:customProperties];
        break;
      }
        
      // Set Date
      case 3: {
        MSCustomProperties *customProperties = [MSCustomProperties new];
        [customProperties setDate:[NSDate date] forKey:@"test"];
        [MSAppCenter setCustomProperties:customProperties];
        break;
      }
        
      // Set Multiple
      case 4: {
        MSCustomProperties *customProperties = [MSCustomProperties new];
        [customProperties setString:@"test" forKey:@"t1"];
        [customProperties setDate:[NSDate date] forKey:@"t2"];
        [customProperties setNumber:@42 forKey:@"t3"];
        [customProperties setBool:NO forKey:@"t4"];
        [MSAppCenter setCustomProperties:customProperties];
        break;
      }
        
      // Clear
      case 5: {
        MSCustomProperties *customProperties = [MSCustomProperties new];
        [customProperties clearPropertyForKey:@"test"];
        [MSAppCenter setCustomProperties:customProperties];
        break;
      }
        
      default:
        break;

    }

    default:
      break;
    }
  }
}

@end
