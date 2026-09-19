#include "../KSKeyImage.h"
#include <cassert>
#include <cstdio>
#include <limits>
int main() {
 auto cs=CGColorSpaceCreateDeviceRGB();
 auto ctx=CGBitmapContextCreate(nullptr,192,192,8,192*4,cs,kCGImageAlphaPremultipliedLast);
 CGColorSpaceRelease(cs); assert(ctx);
 CGContextSetRGBFillColor(ctx,0.1,0.6,0.8,1); CGContextFillRect(ctx,CGRectMake(0,0,192,192));
 auto image=CGBitmapContextCreateImage(ctx); CGContextRelease(ctx); assert(image);
 for (double width : {44.,78.}) {
  auto out=KSCreateKeyImage(image,CGSizeMake(width,54),7,2); assert(out);
  assert(CGImageGetWidth(out)==width*2 && CGImageGetHeight(out)==108);
  auto data=CGDataProviderCopyData(CGImageGetDataProvider(out));
  auto bytes=CFDataGetBytePtr(data); auto row=CGImageGetBytesPerRow(out);
  assert(bytes[3]==0); // corner outside rounded path is transparent
  assert(bytes[54*row+(size_t)width*4+3]==255); // center opaque
  CFRelease(data); CGImageRelease(out);
 }
 assert(!KSCreateKeyImage(nullptr,CGSizeMake(44,54),7,2));
 assert(!KSCreateKeyImage(image,CGSizeMake(0,54),7,2));
 assert(!KSCreateKeyImage(image,CGSizeMake(513,54),7,2));
 assert(!KSCreateKeyImage(image,CGSizeMake(44,54),-1,2));
 assert(!KSCreateKeyImage(image,CGSizeMake(44,54),7,5));
 assert(!KSCreateKeyImage(image,CGSizeMake(std::numeric_limits<double>::quiet_NaN(),54),7,2));
 CGImageRelease(image);
 puts("PASS: production KSCreateKeyImage; normal/function synthetic sizes, alpha corners/center, invalid fallback; NOT keyboard host validation");
}
