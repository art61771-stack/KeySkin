#import <UIKit/UIKit.h>
#include "KSGeometry.h"
// Offline/experimental helper ONLY. Not wired to any private renderer.
// Caller owns the returned CGImage; input is one key's image, never a keyboard capture.
static inline CGImageRef KSCreateKeyImage(CGImageRef image, CGSize size, CGFloat radius, CGFloat scale) {
    if (!image || !std::isfinite(scale) || scale<=0 || scale>4 ||
        !std::isfinite(radius) || radius<0 || size.width>512 || size.height>512) return NULL;
    ks::Rect src,dst;
    if(!ks::crop({0,0,size.width,size.height},{0,0,size.width,size.height},
        CGImageGetWidth(image),CGImageGetHeight(image),src,dst)) return NULL;
    size_t w=(size_t)std::ceil(size.width*scale),h=(size_t)std::ceil(size.height*scale);
    if(!w||!h||w>2048||h>2048) return NULL;
    CGColorSpaceRef cs=CGColorSpaceCreateDeviceRGB();
    CGContextRef ctx=CGBitmapContextCreate(NULL,w,h,8,w*4,cs,kCGImageAlphaPremultipliedLast);
    CGColorSpaceRelease(cs); if(!ctx) return NULL;
    CGImageRef cut=CGImageCreateWithImageInRect(image,CGRectMake(src.x,src.y,src.w,src.h));
    if(!cut) { CGContextRelease(ctx); return NULL; }
    CGContextScaleCTM(ctx,scale,scale);
    CGRect rect=CGRectMake(0,0,size.width,size.height);
    CGFloat r=std::min(radius,std::min(size.width,size.height)/2);
    CGPathRef mask=CGPathCreateWithRoundedRect(rect,r,r,NULL);
    CGContextAddPath(ctx,mask); CGContextClip(ctx); CGPathRelease(mask);
    CGContextDrawImage(ctx,rect,cut); CGImageRelease(cut);
    CGImageRef result=CGBitmapContextCreateImage(ctx); CGContextRelease(ctx);
    return result;
}
