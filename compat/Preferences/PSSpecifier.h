#import <Foundation/Foundation.h>
// Subset of theos/headers Preferences/PSTableCell.h and PSSpecifier.h.
// Numeric values verified against upstream enum; no private ivar layout used.
typedef NS_ENUM(NSInteger, PSCellType) {
    PSGroupCell = 0, PSSwitchCell = 6, PSButtonCell = 13
};
@interface PSSpecifier : NSObject
+ (instancetype)preferenceSpecifierNamed:(NSString *)name target:(id)target set:(SEL)set get:(SEL)get detail:(Class)detail cell:(PSCellType)cell edit:(Class)edit;
+ (instancetype)groupSpecifierWithName:(NSString *)name;
@property(nonatomic, retain) id target;
@property(nonatomic) SEL buttonAction;
- (id)propertyForKey:(NSString *)key;
- (void)setProperty:(id)value forKey:(NSString *)key;
@end
