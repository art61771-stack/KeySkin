#import "../KSRuntime.h"
#include <cassert>
#include <cstdio>
@interface KSTest : NSObject
- (void)layoutSubviews;
- (int)badReturn;
- (void)badArgument:(id)value;
@end
@implementation KSTest
- (void)layoutSubviews {}
- (int)badReturn { return 1; }
- (void)badArgument:(id)value { (void)value; }
@end
int main() {
 @autoreleasepool {
  assert(KSValidatedVoidMethod([KSTest class], @selector(layoutSubviews)));
  assert(!KSValidatedVoidMethod([KSTest class], @selector(badReturn)));
  assert(!KSValidatedVoidMethod([KSTest class], @selector(badArgument:)));
  assert(!KSValidatedVoidMethod(Nil, @selector(layoutSubviews)));
  assert(!KSValidatedVoidMethod([NSObject class], @selector(layoutSubviews)));
  assert(KSApprovedClass([KSTest class], [NSObject class], "runtime"));
  assert(!KSApprovedClass([KSTest class], [NSObject class], "/UIKitCore.framework/"));
  assert(!KSApprovedClass([NSObject class], [KSTest class], "Foundation"));
  assert(!KSApprovedClass(Nil, [NSObject class], "Foundation"));
  assert(!KSFunctionGeometry(44,54));
  assert(KSFunctionGeometry(78,54));
  puts("PASS: production ObjC runtime signature/class-image/inheritance guards and geometry heuristic; NOT UIKit hook/device validation");
 }
}
