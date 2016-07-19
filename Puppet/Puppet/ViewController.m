#import "ViewController.h"

#import "AvalancheAnalytics.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
  [super viewDidLoad];
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
}

- (IBAction)onButtonTapped:(id)sender {
  
  [AVAAnalytics sendEventLog:@"finally"];
}

@end
