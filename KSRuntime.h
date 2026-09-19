#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#include <string.h>
#include <stdlib.h>
// Shared with the actual Objective-C runtime test (not a Python model).
static inline BOOL KSValidatedVoidMethod(Class cls, SEL sel) {
    Method m = cls ? class_getInstanceMethod(cls, sel) : NULL;
    if (!m || method_getNumberOfArguments(m) != 2) return NO;
    const char *expected[] = {"v", "@", ":"};
    for (unsigned i=0; i<3; ++i) {
        char *t = i == 0 ? method_copyReturnType(m) : method_copyArgumentType(m,i-1);
        BOOL good = t && strcmp(t,expected[i]) == 0;
        free(t); if (!good) return NO;
    }
    return YES;
}
static inline BOOL KSApprovedClass(Class cls, Class base, const char *imageFragment) {
    if (!cls || !base) return NO;
    BOOL found = NO;
    for (Class c=cls; c; c=class_getSuperclass(c)) if (c == base) { found=YES; break; }
    const char *image = class_getImageName(cls);
    return found && image && strstr(image,imageFragment);
}
static inline BOOL KSFunctionGeometry(double width, double height) { return width / height >= 1.35; }
