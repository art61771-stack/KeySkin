#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import <dlfcn.h>
#import <atomic>
#include <cstring>
// Private rendering ABI/ownership has NOT been established on iOS 16.6.
// Never invoke or replace the two render selectors based on guesswork.
static IMP KSOriginal;
static std::atomic<unsigned> KSLayouts{0};
static bool KSEnabled(void) {
    CFStringRef domain = CFSTR("com.zuotian.keyskin");
    CFPreferencesAppSynchronize(domain);
    return CFPreferencesGetAppBooleanValue(CFSTR("Enabled"), domain, NULL) &&
           CFPreferencesGetAppBooleanValue(CFSTR("ProbeEnabled"), domain, NULL);
}
static bool KSType(Method method, unsigned index, const char *expected) {
    char *type = index == 99 ? method_copyReturnType(method) : method_copyArgumentType(method, index);
    bool ok = type && strcmp(type, expected) == 0;
    free(type); return ok;
}
static void KSLayout(id self, SEL cmd) {
    ((void (*)(id, SEL))KSOriginal)(self, cmd);
    // Counter only, no key objects, text, screenshots, or input callbacks.
    if (KSLayouts.load(std::memory_order_relaxed) < 1000)
        KSLayouts.fetch_add(1, std::memory_order_relaxed);
}
static void KSDescribe(const char *className, const char *selectorName) {
    Class cls = objc_getClass(className);
    Method m = cls ? class_getInstanceMethod(cls, sel_registerName(selectorName)) : NULL;
    // Type encodings only: this is not proof of semantics or ownership.
    NSLog(@"[KeySkin] metadata %s %s: %s; render hook NOT installed", className,
          selectorName, m ? method_getTypeEncoding(m) : "absent");
}
__attribute__((constructor)) static void KSInit(void) {
    @autoreleasepool {
        if (!KSEnabled()) return; // No hooks or diagnostics by default.
        KSDescribe("UIKBRenderer", "renderBackgroundTraits:");
        KSDescribe("UIKBRenderFactory", "_traitsForKey:onKeyplane:");
        Class cls = objc_getClass("UIKeyboardLayoutStar");
        if (!cls || ![cls isSubclassOfClass:[UIView class]]) return;
        SEL sel = @selector(layoutSubviews);
        Method m = class_getInstanceMethod(cls, sel);
        if (!m || method_getNumberOfArguments(m) != 2 ||
            !KSType(m, 99, "v") || !KSType(m, 0, "@") || !KSType(m, 1, ":")) return;
        const char *image = class_getImageName(cls);
        if (!image || !strstr(image, "/UIKitCore.framework/")) return;
        using Hook = void (*)(Class, SEL, IMP, IMP *);
        Hook hook = (Hook)dlsym(RTLD_DEFAULT, "MSHookMessageEx");
        if (!hook) { NSLog(@"[KeySkin] Substrate hook API absent; no hook installed"); return; }
        hook(cls, sel, (IMP)KSLayout, &KSOriginal);
        NSLog(@"[KeySkin] opt-in layout probe installed; background replacement DISABLED");
    }
}
