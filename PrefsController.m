#import <UIKit/UIKit.h>
#import <CoreFoundation/CoreFoundation.h>
#import <ImageIO/ImageIO.h>
#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>
#import <objc/runtime.h>
#import "KSKeyImage.h"

static CFStringRef const KSDomain = CFSTR("com.zuotian.keyskin");
static NSUInteger const KSMaxPNGBytes = 512 * 1024;
static BOOL KSBooleanKey(NSString *key) {
    return [key isEqualToString:@"Enabled"] || [key isEqualToString:@"ProbeEnabled"];
}
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
@interface KSRootListController : PSListController
@property(nonatomic, strong) NSArray *ksSpecifiers;
@end
@implementation KSRootListController
- (NSArray *)specifiers {
    if (!self.ksSpecifiers) self.ksSpecifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
    return self.ksSpecifiers;
}
- (void)showMessage:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"KeySkin" message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"好" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}
- (id)readPreferenceValue:(PSSpecifier *)specifier {
    id key = [specifier propertyForKey:@"key"];
    if (![key isKindOfClass:NSString.class] || !KSBooleanKey(key)) return @NO;
    id value = KSRead(key);
    // Only genuine plist booleans are accepted; malformed values fail closed.
    return value && CFGetTypeID((__bridge CFTypeRef)value) == CFBooleanGetTypeID() ? value : @NO;
}
- (void)setPreferenceValue:(id)value specifier:(PSSpecifier *)specifier {
    id key = [specifier propertyForKey:@"key"];
    if (![key isKindOfClass:NSString.class] || !KSBooleanKey(key) || ![value isKindOfClass:NSNumber.class]) return;
    KSWrite(key, @([value boolValue]));
    BOOL saved = CFPreferencesAppSynchronize(KSDomain);
    [self reloadSpecifiers];
    if (!saved) [self showMessage:@"保存失败。请检查偏好目录权限；未确认配置已持久化。"];
}
- (void)installBuiltin:(PSSpecifier *)specifier {
    (void)specifier;
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
- (void)previewBuiltin:(PSSpecifier *)specifier {
    (void)specifier;
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
- (void)exportCompatibility:(PSSpecifier *)specifier {
    (void)specifier;
    NSMutableDictionary *classes = [NSMutableDictionary dictionary];
    for (NSString *name in @[@"UIKBKeyplaneView", @"UIKBKeyView", @"UIKBRenderer", @"UIKBRenderFactory"]) {
        Class cls = NSClassFromString(name);
        const char *image = cls ? class_getImageName(cls) : NULL;
        classes[name] = @{@"presentInSettingsProcess": @(cls != Nil),
                          @"image": image ? @(image) : @"absent"};
    }
    UIImage *sample = KSSavedImage(@"NormalImageData");
    CGImageRef result = sample ? KSCreateKeyImage(sample.CGImage, CGSizeMake(44,54),7,2) : NULL;
    NSDictionary *report = @{@"version": @"0.1.2", @"os": UIDevice.currentDevice.systemVersion,
        @"scope": @"Settings process only; not keyboard host validation",
        @"renderingEnabled": @NO, @"targetABIProven": @NO,
        @"reason": @"iOS 16.6 contour/state/cache/ownership contract unverified; native fallback",
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
- (void)clearSkin:(PSSpecifier *)specifier {
    (void)specifier;
    KSWrite(@"NormalImageData", nil);
    KSWrite(@"FunctionImageData", nil);
    KSWrite(@"Enabled", @NO);
    KSWrite(@"ProbeEnabled", @NO);
    BOOL saved = CFPreferencesAppSynchronize(KSDomain);
    [self reloadSpecifiers];
    [self showMessage:saved ? @"已清除示例并关闭两个探针开关。已运行的宿主仍需手动重启才会移除探针；键盘背景从未被替换。" : @"清除或保存失败，未确认配置已持久化。请检查权限后重试。"];
}
@end
