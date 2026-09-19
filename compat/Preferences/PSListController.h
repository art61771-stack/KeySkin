#import <UIKit/UIKit.h>
// Minimal compile-time declarations, not an implementation. Runtime dependency: Preferences.
@interface PSListController : UIViewController
// Signatures verified: github.com/theos/headers Preferences/PSListController.h
- (NSMutableArray *)loadSpecifiersFromPlistName:(NSString *)name target:(PSListController *)target;
- (NSMutableArray *)loadSpecifiersFromPlistName:(NSString *)name target:(PSListController *)target bundle:(NSBundle *)bundle;
@property(nonatomic, retain) NSMutableArray *specifiers;
- (void)reloadSpecifiers;
@end
