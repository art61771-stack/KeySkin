#pragma once
#include <cmath>
#include <algorithm>
namespace ks {
struct Rect { double x,y,w,h; };
inline bool valid(Rect r) {
    return std::isfinite(r.x)&&std::isfinite(r.y)&&std::isfinite(r.w)&&std::isfinite(r.h)&&
           r.w>0&&r.h>0&&std::isfinite(r.x+r.w)&&std::isfinite(r.y+r.h);
}
// Aspect-fill a separate source image into ONE key, intersecting with canvas.
// Output source is in source pixels; dest is in keyboard logical coordinates.
inline bool crop(Rect key, Rect canvas, double iw, double ih, Rect &src, Rect &dst) {
    src=dst={0,0,0,0};
    if(!valid(key)||!valid(canvas)||!std::isfinite(iw)||!std::isfinite(ih)||iw<=0||ih<=0) return false;
    double x=std::max(key.x,canvas.x), y=std::max(key.y,canvas.y);
    double right=std::min(key.x+key.w,canvas.x+canvas.w), bottom=std::min(key.y+key.h,canvas.y+canvas.h);
    if(right<=x||bottom<=y) return false;
    double scale=std::max(key.w/iw,key.h/ih);
    if(!std::isfinite(scale)||scale<=0) return false;
    double sw=key.w/scale, sh=key.h/scale;
    Rect s={(iw-sw)/2+(x-key.x)/scale,(ih-sh)/2+(y-key.y)/scale,(right-x)/scale,(bottom-y)/scale};
    Rect d={x,y,right-x,bottom-y};
    if(!valid(s)||!valid(d)||s.x<0||s.y<0||s.x+s.w>iw+1e-7||s.y+s.h>ih+1e-7) return false;
    src=s; dst=d; return true;
}
inline bool roundedContains(Rect r, double radius, double x, double y) {
    if(!valid(r)||!std::isfinite(radius)||!std::isfinite(x)||!std::isfinite(y)||
       x<r.x||y<r.y||x>=r.x+r.w||y>=r.y+r.h) return false;
    radius=std::max(0.0,std::min(radius,std::min(r.w,r.h)/2));
    double cx=std::clamp(x,r.x+radius,r.x+r.w-radius);
    double cy=std::clamp(y,r.y+radius,r.y+r.h-radius);
    return (x-cx)*(x-cx)+(y-cy)*(y-cy)<=radius*radius;
}
}
