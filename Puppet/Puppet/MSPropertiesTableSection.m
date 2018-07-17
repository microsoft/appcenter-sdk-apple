#import "MSPropertiesTableSection.h"
#import "MSAnalyticsPropertyTableViewCell.h"

@interface MSPropertiesTableSection ()
@property(nonatomic) short propertyCounter;
@property(nonatomic) NSInteger tableSection;
@property(nonatomic) UITableView *tableView;
@end

@implementation MSPropertiesTableSection

- (instancetype)initWithTableSection:(NSInteger)tableSection tableView:(UITableView *)tableView {
  if ((self = [self init])) {
    _tableView = tableView;
    _tableSection = tableSection;
  }
  return self;
}

- (void)propertyKeyChanged:(UITextField *)sender {
  [self ThrowExceptionOnAbstractMethodCalled];
}

- (void)propertyValueChanged:(UITextField *)sender {
  [self ThrowExceptionOnAbstractMethodCalled];
}

#pragma UITableViewDelegate

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView
           editingStyleForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
  if ([self isInsertRowAtIndexPath:indexPath]) {
    return UITableViewCellEditingStyleInsert;
  } else if ([self isPropertyRowAtIndexPath:indexPath]) {
    return UITableViewCellEditingStyleDelete;
  }
  return UITableViewCellEditingStyleNone;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return [self propertyCount] + [self propertyCellOffset];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
  UITableViewCell *cell;
  if ([self isInsertRowAtIndexPath:indexPath]) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    cell.textLabel.text = @"Add Property";
    return cell;
  }
  MSAnalyticsPropertyTableViewCell *propertyCell =
      [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([MSAnalyticsPropertyTableViewCell class])
                                     owner:self
                                   options:nil] firstObject];

  // Set cell text.
  NSString *propertyKey = [self propertyKeyAtRow:indexPath.row];
  NSString *propertyValue = [self propertyValueForKey:propertyKey];
  propertyCell.keyField.text = propertyKey;
  propertyCell.valueField.text = propertyValue;

  // Set cell to respond to being edited.
  [propertyCell.keyField addTarget:self
                            action:@selector(propertyKeyChanged:)
                  forControlEvents:UIControlEventEditingChanged];
  [propertyCell.valueField addTarget:self
                              action:@selector(propertyValueChanged:)
                    forControlEvents:UIControlEventEditingChanged];
  return propertyCell;
}

- (void)tableView:(UITableView *)tableView
    commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
     forRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
  if (editingStyle == UITableViewCellEditingStyleDelete) {
    [self removePropertyAtRow:indexPath.row];
    [tableView deleteRowsAtIndexPaths:@[ indexPath ] withRowAnimation:UITableViewRowAnimationAutomatic];
  } else if (editingStyle == UITableViewCellEditingStyleInsert) {
    NSString *propertyKey, *propertyValue;
    [self setNewDefaultKey:&propertyKey andValue:&propertyValue];
    [self addPropertyString:propertyValue forKey:propertyKey];
    [tableView insertRowsAtIndexPaths:@[ [NSIndexPath indexPathForRow:indexPath.row + 1 inSection:indexPath.section] ]
                     withRowAnimation:UITableViewRowAnimationAutomatic];
  }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
  return [self isPropertyRowAtIndexPath:indexPath] || [self isInsertRowAtIndexPath:indexPath];
}

#pragma Helper methods

- (void)setNewDefaultKey:(NSString **)key andValue:(NSString **)value {
  *key = [NSString stringWithFormat:@"key%d", self.propertyCounter];
  *value = [NSString stringWithFormat:@"value%d", self.propertyCounter];
  self.propertyCounter++;
}

- (BOOL)hasSectionId:(NSInteger)sectionId {
  return sectionId == self.tableSection;
}

- (BOOL)isInsertRowAtIndexPath:(NSIndexPath *)indexPath {
  return indexPath.row == [self numberOfCustomHeaderCells];
}

- (BOOL)isPropertyRowAtIndexPath:(NSIndexPath *)indexPath {
  return indexPath.row > [self numberOfCustomHeaderCells];
}

- (NSInteger)numberOfCustomHeaderCells {
  return 0;
}

- (NSInteger)propertyCellOffset {
  return [self numberOfCustomHeaderCells] + 1;
}

- (NSInteger)propertyCount {
  [self ThrowExceptionOnAbstractMethodCalled];
  return 0;
}

- (void)removePropertyAtRow:(NSInteger)row {
  [self ThrowExceptionOnAbstractMethodCalled];
}

- (void)addPropertyString:(NSString *)property forKey:(NSString *)key {
  [self ThrowExceptionOnAbstractMethodCalled];
}

- (NSString *)propertyKeyAtRow:(NSInteger)row {
  [self ThrowExceptionOnAbstractMethodCalled];
  return nil;
}

- (NSString *)propertyValueForKey:(NSString *)key {
  [self ThrowExceptionOnAbstractMethodCalled];
  return nil;
}

- (NSInteger)cellRowForTextField:(UITextField *)textField {
  MSAnalyticsPropertyTableViewCell *cell = (MSAnalyticsPropertyTableViewCell *)textField.superview.superview;
  NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
  return indexPath.row;
}

- (void)ThrowExceptionOnAbstractMethodCalled {
  @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                 reason:@"Attempting to call an abstract method from MSProperiesTableSection class."
                               userInfo:nil];
}

@end
