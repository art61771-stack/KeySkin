#import <UIKit/UIKit.h>
#import <CoreFoundation/CoreFoundation.h>
#import <ImageIO/ImageIO.h>
#import <objc/runtime.h>
#import "KSKeyImage.h"

static CFStringRef const KSDomain = CFSTR("com.zuotian.keyskin");
static NSUInteger const KSMaxPNGBytes = 512 * 1024;
static id KSRead(NSString *key) {
    CFPreferencesAppSynchronize(KSDomain);
    return CFBridgingRelease(CFPreferencesCopyAppValue((__bridge CFStringRef)key, KSDomain));
}
static void KSWrite(NSString *key, id value) {
    CFPreferencesSetAppValue((__bridge CFStringRef)key, (__bridge CFPropertyListRef)value, KSDomain);
}
static NSData *KSExample(BOOL functionKey) {
    UIGraphicsImageRendererFormat *format = [UIGraphicsImageRendererFormat defaultFormat];
    format.scale = 2;
    format.opaque = YES;
    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:CGSizeMake(96, 96) format:format];
    return [renderer PNGDataWithActions:^(UIGraphicsImageRendererContext *context) {
        UIColor *color = functionKey ? [UIColor colorWithRed:.14 green:.18 blue:.24 alpha:1] : [UIColor colorWithRed:.04 green:.32 blue:.42 alpha:1];
        [color setFill];
        [context fillRect:CGRectMake(0, 0, 96, 96)];
        [[UIColor colorWithWhite:1 alpha:.18] setFill];
        [[UIBezierPath bezierPathWithOvalInRect:CGRectMake(18, 18, 60, 60)] fill];
    }];
}
// Never decode unbounded externally modified preference data.
static UIImage *KSSavedImage(NSString *key) {
    id value = KSRead(key);
    if (![value isKindOfClass:NSData.class] || ![value length] || [value length] > KSMaxPNGBytes) return nil;
    CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)value, NULL);
    if (!source) return nil;
    NSString *type = (__bridge NSString *)CGImageSourceGetType(source);
    NSDictionary *properties = CFBridgingRelease(CGImageSourceCopyPropertiesAtIndex(source, 0, NULL));
    BOOL valid = [type isEqualToString:@"public.png"] && CGImageSourceGetCount(source) == 1 &&
        [properties[(__bridge NSString *)kCGImagePropertyPixelWidth] integerValue] == 192 &&
        [properties[(__bridge NSString *)kCGImagePropertyPixelHeight] integerValue] == 192;
    CFRelease(source);
    return valid ? [UIImage imageWithData:value scale:2] : nil;
}
typedef NS_ENUM(NSInteger, KSSettingsRow) {
    KSSettingsRowEnabled = 0,
    KSSettingsRowInstall,
    KSSettingsRowPreview,
    KSSettingsRowExport,
    KSSettingsRowClear,
    KSSettingsRowCount
};

// Production content is independent of the private Preferences table machinery.
@interface KSSettingsTableController : UITableViewController
@end

#ifndef KS_CONTENT_UIKIT_TEST
#import <Preferences/PSViewController.h>
// Theos PSViewController inherits UIViewController and owns the complete
// Preferences entry contract (specifier/parent/root setters and initializers).
// Do not redeclare its storage or intercept unknown selectors.
@interface KSRootListController : PSViewController
@end
@implementation KSRootListController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"KeySkin 0.1.5";
    self.view.backgroundColor = UIColor.systemGroupedBackgroundColor;
    KSSettingsTableController *content = [KSSettingsTableController new];
    [self addChildViewController:content];
    content.view.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:content.view];
    UILayoutGuide *safe = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [content.view.topAnchor constraintEqualToAnchor:safe.topAnchor],
        [content.view.bottomAnchor constraintEqualToAnchor:safe.bottomAnchor],
        [content.view.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor],
        [content.view.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor]
    ]];
    [content didMoveToParentViewController:self];
}
@end
#endif

@implementation KSSettingsTableController
- (instancetype)init {
    return [self initWithStyle:UITableViewStyleInsetGrouped];
}
- (instancetype)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) self.title = @"KeySkin 0.1.5";
    return self;
}
- (instancetype)initWithNibName:(NSString *)name bundle:(NSBundle *)bundle {
    // No nib or plist is needed, regardless of the loader's entry path.
    (void)name; (void)bundle;
    self = [super initWithNibName:nil bundle:nil];
    if (self) self.title = @"KeySkin 0.1.5";
    return self;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"KeySkin 0.1.5";
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView reloadData];
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    (void)tableView;
    return 1;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    (void)tableView;
    return section == 0 ? KSSettingsRowCount : 0;
}
- (BOOL)enabledValue {
    id value = KSRead(@"Enabled");
    return value && CFGetTypeID((__bridge CFTypeRef)value) == CFBooleanGetTypeID() ? [value boolValue] : NO;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"KSSetting"];
    if (!cell) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"KSSetting"];
    cell.accessoryView = nil;
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    cell.textLabel.textColor = self.view.tintColor;
    switch (indexPath.row) {
        case KSSettingsRowEnabled: {
            cell.textLabel.text = @"Enabled（实验性图片换肤）";
            cell.textLabel.textColor = UIColor.labelColor;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            UISwitch *toggle = [[UISwitch alloc] init];
            toggle.on = [self enabledValue];
            toggle.accessibilityIdentifier = @"KeySkin.Enabled";
            [toggle addTarget:self action:@selector(enabledChanged:) forControlEvents:UIControlEventValueChanged];
            cell.accessoryView = toggle;
            break;
        }
        case KSSettingsRowInstall: cell.textLabel.text = @"生成示例"; break;
        case KSSettingsRowPreview: cell.textLabel.text = @"预览"; break;
        case KSSettingsRowExport: cell.textLabel.text = @"导出兼容报告"; break;
        case KSSettingsRowClear: cell.textLabel.text = @"清除"; break;
        default: cell.textLabel.text = @""; break;
    }
    return cell;
}
- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    (void)tableView; (void)section;
    return @"默认关闭。示例不会自动启用换肤；更改后需重启目标宿主。兼容报告仅反映设置进程，不代表键盘宿主验证。";
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section != 0) return;
    switch (indexPath.row) {
        case KSSettingsRowInstall: [self installBuiltin:nil]; break;
        case KSSettingsRowPreview: [self previewBuiltin:nil]; break;
        case KSSettingsRowExport: [self exportCompatibility:nil]; break;
        case KSSettingsRowClear: [self clearSkin:nil]; break;
        default: break;
    }
}
- (void)showMessage:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"KeySkin" message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"好" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}
- (void)enabledChanged:(UISwitch *)sender {
    if (![sender isKindOfClass:UISwitch.class]) return;
    BOOL requested = sender.isOn;
    KSWrite(@"Enabled", @(requested));
    BOOL saved = CFPreferencesAppSynchronize(KSDomain);
    saved = saved && ([self enabledValue] == requested);
    [self.tableView reloadData];
    if (!saved) [self showMessage:@"保存失败。请检查偏好目录权限；未确认配置已持久化。"];
}
- (void)installBuiltin:(id)sender {
    (void)sender;
    NSData *normal = KSExample(NO), *function = KSExample(YES);
    if (!normal.length || !function.length || normal.length > KSMaxPNGBytes || function.length > KSMaxPNGBytes) {
        [self showMessage:@"示例生成失败，配置未更改。"];
        return;
    }
    KSWrite(@"NormalImageData", normal);
    KSWrite(@"FunctionImageData", function);
    BOOL saved = CFPreferencesAppSynchronize(KSDomain);
    saved = saved && [KSRead(@"NormalImageData") isEqual:normal] && [KSRead(@"FunctionImageData") isEqual:function];
    [self showMessage:saved ? @"两张本地合成 PNG 已保存，可点击预览。未自动开启换肤；开启实验开关并重启宿主后才尝试逐键显示。" : @"示例保存或回读校验失败；请清除后重试。"];
}
- (void)previewBuiltin:(id)sender {
    (void)sender;
    UIImage *normal = KSSavedImage(@"NormalImageData"), *function = KSSavedImage(@"FunctionImageData");
    if (!normal || !function) {
        [self showMessage:@"尚无完整示例，或缓存无效。请先生成合成示例。"];
        return;
    }
    UIViewController *preview = [UIViewController new];
    preview.title = @"合成示例（非键盘效果）";
    preview.view.backgroundColor = UIColor.systemBackgroundColor;
    UIStackView *stack = [[UIStackView alloc] init];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.alignment = UIStackViewAlignmentCenter;
    stack.spacing = 16;
    NSArray *images = @[normal, function];
    NSArray *titles = @[@"普通键示例", @"功能键示例"];
    for (NSUInteger index = 0; index < images.count; index++) {
        UILabel *label = [UILabel new];
        label.text = titles[index];
        [stack addArrangedSubview:label];
        // Synthetic single-key geometry only; never claims to be a system key contour.
        UIImage *input = images[index];
        CGImageRef clipped = KSCreateKeyImage(input.CGImage, CGSizeMake(index ? 78 : 44, 54), 7, 2);
        if (!clipped) { [self showMessage:@"单键离屏裁剪失败；未修改系统键盘。"]; return; }
        UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageWithCGImage:clipped scale:2 orientation:UIImageOrientationUp]];
        CGImageRelease(clipped);
        [stack addArrangedSubview:imageView];
    }
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    [preview.view addSubview:stack];
    [NSLayoutConstraint activateConstraints:@[
        [stack.centerXAnchor constraintEqualToAnchor:preview.view.safeAreaLayoutGuide.centerXAnchor],
        [stack.centerYAnchor constraintEqualToAnchor:preview.view.safeAreaLayoutGuide.centerYAnchor]
    ]];
    [self.navigationController pushViewController:preview animated:YES];
}
- (void)exportCompatibility:(id)sender {
    (void)sender;
    NSMutableDictionary *classes = [NSMutableDictionary dictionary];
    for (NSString *name in @[@"UIKBKeyplaneView", @"UIKBKeyView", @"UIKBRenderer", @"UIKBRenderFactory"]) {
        Class cls = NSClassFromString(name);
        const char *image = cls ? class_getImageName(cls) : NULL;
        classes[name] = @{@"presentInSettingsProcess": @(cls != Nil),
                          @"image": image ? @(image) : @"absent"};
    }
    UIImage *sample = KSSavedImage(@"NormalImageData");
    CGImageRef result = sample ? KSCreateKeyImage(sample.CGImage, CGSizeMake(44,54),7,2) : NULL;
    NSDictionary *report = @{@"version": @"0.1.5", @"os": UIDevice.currentDevice.systemVersion,
        @"scope": @"Settings process only; not keyboard host validation",
        @"configuredEnabled": KSRead(@"Enabled") ?: @NO, @"targetABIProven": @NO,
        @"reason": @"Experimental UIKBKeyView images; Settings cannot verify host hooks or appearance",
        @"syntheticOffscreenImageCreated": @(result != NULL), @"classes": classes};
    if (result) CGImageRelease(result);
    NSData *data = [NSJSONSerialization dataWithJSONObject:report options:NSJSONWritingPrettyPrinted error:nil];
    NSString *text = data ? [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] : nil;
    if (!text) { [self showMessage:@"报告生成失败。"]; return; }
    UIActivityViewController *share = [[UIActivityViewController alloc] initWithActivityItems:@[text] applicationActivities:nil];
    share.popoverPresentationController.sourceView = self.view;
    share.popoverPresentationController.sourceRect = CGRectMake(CGRectGetMidX(self.view.bounds),CGRectGetMidY(self.view.bounds),1,1);
    [self presentViewController:share animated:YES completion:nil];
}
- (void)clearSkin:(id)sender {
    (void)sender;
    KSWrite(@"NormalImageData", nil);
    KSWrite(@"FunctionImageData", nil);
    KSWrite(@"Enabled", @NO);
    KSWrite(@"ProbeEnabled", @NO);
    BOOL saved = CFPreferencesAppSynchronize(KSDomain);
    [self.tableView reloadData];
    [self showMessage:saved ? @"已清除示例并关闭图片实验开关（同时重置旧 ProbeEnabled）。请手动重启目标宿主，已运行进程不会动态卸钩。" : @"清除或保存失败，未确认配置已持久化。请检查权限后重试。"];
}
@end
