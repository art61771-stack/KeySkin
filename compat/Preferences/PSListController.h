#import "PSViewController.h"
// Minimal declarations following the real Theos superclass and protected ivar.
// Not used by the entry; no private table storage is duplicated in production.
@interface PSListController : PSViewController {
    NSMutableArray *_specifiers;
}
// Signatures verified: github.com/theos/headers Preferences/PSListController.h
- (NSMutableArray *)loadSpecifiersFromPlistName:(NSString *)name target:(PSListController *)target;
- (NSMutableArray *)loadSpecifiersFromPlistName:(NSString *)name target:(PSListController *)target bundle:(NSBundle *)bundle;
@property(nonatomic, retain) NSMutableArray *specifiers;
- (void)reloadSpecifiers;
@end
