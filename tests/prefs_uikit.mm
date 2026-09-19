// Simulator-only harness: compile the production controller, not a mock table.
#import <UIKit/UIKit.h>
#import "../PrefsController.m"
#include <cstdlib>

static void Require(BOOL ok, NSString *message) {
    if (!ok) @throw [NSException exceptionWithName:@"PrefsTestFailure" reason:message userInfo:nil];
}
static void Pump(void) {
    NSDate *end = [NSDate dateWithTimeIntervalSinceNow:0.8];
    while ([end timeIntervalSinceNow] > 0)
        [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.02]];
}
// Suppress informational alerts only. Navigation and sharing use real UIKit.
@interface KSTestController : KSRootListController
@property(nonatomic, copy) NSString *lastMessage;
@end
@implementation KSTestController
- (void)showMessage:(NSString *)message { self.lastMessage = message; }
@end
static void Five(KSRootListController *controller) {
    [controller.tableView layoutIfNeeded];
    Require([controller.tableView numberOfSections] == 1, @"one section");
    Require([controller.tableView numberOfRowsInSection:0] == 5, @"five visible data-source rows");
    NSArray *labels = @[@"Enabled（实验性图片换肤）", @"生成示例", @"预览", @"导出兼容报告", @"清除"];
    for (NSInteger row = 0; row < 5; row++) {
        UITableViewCell *cell = [controller tableView:controller.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:0]];
        Require([cell.textLabel.text isEqual:labels[row]], @"row label/order");
        Require(row == 0 ? [cell.accessoryView isKindOfClass:UISwitch.class] : cell.accessoryView == nil, @"switch only in row zero");
    }
}
static void Select(KSRootListController *controller, NSInteger row) {
    [controller tableView:controller.tableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:0]];
    Pump(); Five(controller);
}
static void Toggle(KSRootListController *controller, BOOL enabled) {
    UITableViewCell *cell = [controller tableView:controller.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    UISwitch *toggle = (UISwitch *)cell.accessoryView;
    toggle.on = enabled;
    [toggle sendActionsForControlEvents:UIControlEventValueChanged];
    Require([KSRead(@"Enabled") isEqual:@(enabled)], @"toggle persisted");
    Five(controller);
}
@interface KSTestApp : UIResponder <UIApplicationDelegate>
@property(nonatomic, strong) UIWindow *window;
@end
@implementation KSTestApp
- (BOOL)application:(UIApplication *)app didFinishLaunchingWithOptions:(NSDictionary *)options {
    (void)app; (void)options;
    self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    KSTestController *controller = [KSTestController new];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:controller];
    self.window.rootViewController = nav;
    [self.window makeKeyAndVisible];
    dispatch_async(dispatch_get_main_queue(), ^{
        // Only the disposable simulator app's preference domain is touched.
        NSArray *keys = @[@"Enabled", @"NormalImageData", @"FunctionImageData", @"ProbeEnabled"];
        NSMutableDictionary *backup = [NSMutableDictionary dictionary];
        for (NSString *key in keys) backup[key] = KSRead(key) ?: NSNull.null;
        BOOL passed = NO;
        NSString *detail = @"";
        @try {
            for (NSString *key in keys) KSWrite(key, nil);
            CFPreferencesAppSynchronize(KSDomain);
            Pump(); Five(controller);
            Require(![controller enabledValue], @"absent Enabled defaults false");
            KSWrite(@"Enabled", @"YES"); CFPreferencesAppSynchronize(KSDomain);
            Require(![controller enabledValue], @"malformed Enabled fails closed");
            Toggle(controller, NO);
            Select(controller, 1);
            Require(KSSavedImage(@"NormalImageData") && KSSavedImage(@"FunctionImageData"), @"generated valid PNGs");
            Require(![controller enabledValue], @"generation does not enable");
            NSData *normal = KSRead(@"NormalImageData"), *function = KSRead(@"FunctionImageData");
            Toggle(controller, YES); Toggle(controller, NO); Toggle(controller, YES);
            Require([KSRead(@"NormalImageData") isEqual:normal] && [KSRead(@"FunctionImageData") isEqual:function], @"toggle preserves images");
            NSArray *instances = @[[KSRootListController new], [[KSRootListController alloc] initWithStyle:UITableViewStyleGrouped], [[KSRootListController alloc] initWithNibName:nil bundle:nil]];
            for (KSRootListController *other in instances) { [other loadViewIfNeeded]; Five(other); Require([other enabledValue], @"reinit preserves Enabled"); }
            Require([KSRead(@"NormalImageData") isEqual:normal] && [KSRead(@"FunctionImageData") isEqual:function], @"reinit preserves images");
            for (NSInteger cycle = 0; cycle < 3; cycle++) {
                Select(controller, 2);
                Require(nav.topViewController != controller, @"preview pushed");
                [nav popViewControllerAnimated:NO]; Pump(); Five(controller);
                Select(controller, 3);
                Require([controller.presentedViewController isKindOfClass:UIActivityViewController.class], @"real share presented");
                [controller dismissViewControllerAnimated:NO completion:nil]; Pump();
                Require(controller.presentedViewController == nil, @"share dismissed"); Five(controller);
            }
            Select(controller, 4);
            Require(!KSRead(@"NormalImageData") && !KSRead(@"FunctionImageData"), @"clear removed images");
            Require([KSRead(@"Enabled") isEqual:@NO] && [KSRead(@"ProbeEnabled") isEqual:@NO], @"clear disabled flags");
            Select(controller, 2); Require(nav.topViewController == controller, @"empty preview stays on list");
            passed = YES;
        } @catch (NSException *error) { detail = error.reason; }
        @finally {
            for (NSString *key in keys) KSWrite(key, backup[key] == NSNull.null ? nil : backup[key]);
            CFPreferencesAppSynchronize(KSDomain);
        }
        NSString *result = [NSString stringWithFormat:@"%@: UIKit production controller %@\n", passed ? @"PASS" : @"FAIL", detail];
        NSString *path = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/result.txt"];
        [result writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:nil];
        NSLog(@"%@", result);
        exit(passed ? 0 : 1);
    });
    return YES;
}
@end
int main(int argc, char **argv) {
    @autoreleasepool { return UIApplicationMain(argc, argv, nil, NSStringFromClass(KSTestApp.class)); }
}
