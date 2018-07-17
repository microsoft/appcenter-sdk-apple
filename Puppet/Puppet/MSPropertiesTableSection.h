#import <UIKit/UIKit.h>

@interface MSPropertiesTableSection : NSObject <UITableViewDelegate>

- (instancetype)initWithTableSection:(NSInteger)tableSection tableView:(UITableView *)tableView;

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath;

- (void)tableView:(UITableView *)tableView
    commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
     forRowAtIndexPath:(nonnull NSIndexPath *)indexPath;

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section;

- (BOOL)hasSectionId:(NSInteger)sectionId;

- (BOOL)isPropertyRowAtIndexPath:(NSIndexPath *)indexPath;

- (BOOL)isInsertRowAtIndexPath:(NSIndexPath *)indexPath;

- (NSInteger)cellRowForTextField:(UITextField *)textField;

- (NSInteger)propertyCellOffset;

@end
