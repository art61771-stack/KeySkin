#import <UIKit/UIKit.h>
#import <ImageIO/ImageIO.h>
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>
#import <dlfcn.h>
#import "KSRuntime.h"
#include <cmath>

// Experimental per-key rendering. No input callbacks or private rendering ABI.
static IMP KSOriginal;
static Class KSKeyClass;
static UIImage *KSNormalImage;
static UIImage *KSFunctionImage;
static char KSBackgroundKey;
static const NSInteger KSBackgroundTag = 0x4B530012;

static UIImage *KSReadImage(CFStringRef key) {
    CFPropertyListRef value = CFPreferencesCopyAppValue(key, CFSTR("com.zuotian.keyskin"));
    if (!value) return nil;
    UIImage *result = nil;
    if (CFGetTypeID(value) == CFDataGetTypeID() &&
        CFDataGetLength((CFDataRef)value) > 0 &&
        CFDataGetLength((CFDataRef)value) <= 512 * 1024) {
        CGImageSourceRef source = CGImageSourceCreateWithData((CFDataRef)value, NULL);
        if (source && CGImageSourceGetCount(source) == 1) {
            NSDictionary *props = CFBridgingRelease(CGImageSourceCopyPropertiesAtIndex(source, 0, NULL));
            id w = props[(__bridge NSString *)kCGImagePropertyPixelWidth];
            id h = props[(__bridge NSString *)kCGImagePropertyPixelHeight];
            if ([w isKindOfClass:[NSNumber class]] && [h isKindOfClass:[NSNumber class]] &&
                [w doubleValue] > 0 && [h doubleValue] > 0 &&
                [w doubleValue] <= 512 && [h doubleValue] <= 512) {
                CGImageRef image = CGImageSourceCreateImageAtIndex(source, 0, NULL);
                if (image) { result = [UIImage imageWithCGImage:image]; CGImageRelease(image); }
            }
        }
        if (source) CFRelease(source);
    }
    CFRelease(value);
    return result;
}

static void KSRemoveBackground(UIView *view) {
    UIImageView *background = objc_getAssociatedObject(view, &KSBackgroundKey);
    // Never search/remove an unrelated UIKit view by its tag.
    if (background) {
        [background removeFromSuperview];
        objc_setAssociatedObject(view, &KSBackgroundKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

static void KSLayout(id object, SEL command) {
    ((void (*)(id, SEL))KSOriginal)(object, command); // Always preserve UIKit layout first.
    if (![NSThread isMainThread]) return;
    UIView *view = (UIView *)object;
    // This is the key itself, not its keyboard container. Unknown subclasses fail closed.
    if (object_getClass(view) != KSKeyClass) { KSRemoveBackground(view); return; }
    CGRect b = view.bounds;
    if (!std::isfinite(b.origin.x) || !std::isfinite(b.origin.y) ||
        !std::isfinite(b.size.width) || !std::isfinite(b.size.height) ||
        b.size.width < 8 || b.size.height < 8 ||
        b.size.width > 240 || b.size.height > 100) {
        KSRemoveBackground(view); return;
    }
    // Geometry is a documented heuristic, NOT key identity/text inspection.
    UIImage *image = KSFunctionGeometry(b.size.width, b.size.height) ? KSFunctionImage : KSNormalImage;
    if (!image) { KSRemoveBackground(view); return; } // No fabricated fallback artwork.
    UIImageView *background = objc_getAssociatedObject(view, &KSBackgroundKey);
    // Confirm no nested key view is present; never paint a key container.
    for (UIView *child in view.subviews) {
        if ([child isKindOfClass:KSKeyClass]) { KSRemoveBackground(view); return; }
    }
    if (!background) {
        background = [[UIImageView alloc] initWithFrame:b];
        background.tag = KSBackgroundTag;
        background.userInteractionEnabled = NO;
        background.isAccessibilityElement = NO;
        background.accessibilityElementsHidden = YES;
        background.contentMode = UIViewContentModeScaleAspectFill;
        background.clipsToBounds = YES;
        objc_setAssociatedObject(view, &KSBackgroundKey, background, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    background.image = image;
    background.frame = b;
    // Only our own image layer is masked, entirely inside this key's bounds.
    background.layer.cornerRadius = MIN(6.0, MIN(b.size.width, b.size.height) / 4.0);
    background.layer.masksToBounds = YES;
    // Index zero is below every existing text/icon subview. Never change their contents.
    if (background.superview != view) [view insertSubview:background atIndex:0];
    else [view sendSubviewToBack:background];
    [CATransaction commit];
}

__attribute__((constructor)) static void KSInit(void) {
    @autoreleasepool {
        CFStringRef domain = CFSTR("com.zuotian.keyskin");
        CFPreferencesAppSynchronize(domain);
        CFPropertyListRef enabled = CFPreferencesCopyAppValue(CFSTR("Enabled"), domain);
        BOOL allowed = enabled && CFGetTypeID(enabled) == CFBooleanGetTypeID() &&
                       CFBooleanGetValue((CFBooleanRef)enabled);
        if (enabled) CFRelease(enabled);
        if (!allowed) return; // Missing/malformed/false: no hook installed.
        Class cls = objc_getClass("UIKBKeyView");
        SEL sel = @selector(layoutSubviews);
        if (!KSApprovedClass(cls, [UIView class], "/UIKitCore.framework/") ||
            !KSValidatedVoidMethod(cls, sel)) return;
        KSNormalImage = KSReadImage(CFSTR("NormalImageData"));
        KSFunctionImage = KSReadImage(CFSTR("FunctionImageData"));
        if (!KSNormalImage && !KSFunctionImage) return;
        using Hook = void (*)(Class, SEL, IMP, IMP *);
        Hook hook = (Hook)dlsym(RTLD_DEFAULT, "MSHookMessageEx");
        if (!hook) return;
        KSKeyClass = cls;
        hook(cls, sel, (IMP)KSLayout, &KSOriginal);
    }
}
