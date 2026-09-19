#import <UIKit/UIKit.h>
// Minimal compile-time declarations, not an implementation. Runtime dependency: Preferences.
@interface PSListController : UIViewController
- (NSArray *)loadSpecifiersFromPlistName:(NSString *)name target:(id)target;
- (void)reloadSpecifiers;
@end
