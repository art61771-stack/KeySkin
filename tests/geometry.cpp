#include "../KSGeometry.h"
#include <cassert>
#include <fstream>
#include <limits>
#include <iostream>
int main(int argc,char**argv) {
 ks::Rect s,d;
 assert(ks::crop({10,10,40,60},{0,0,100,100},100,100,s,d));
 assert(std::abs(s.w-66.6666667)<1e-5 && s.h==100);
 assert(ks::crop({-10,0,40,60},{0,0,100,100},100,100,s,d)&&d.x==0&&d.w==30);
 assert(!ks::crop({0,0,0,10},{0,0,100,100},10,10,s,d));
 assert(!ks::crop({200,0,10,10},{0,0,100,100},10,10,s,d));
 assert(!ks::crop({0,0,10,10},{0,0,100,100},NAN,10,s,d));
 assert(!ks::crop({INFINITY,0,10,10},{0,0,100,100},10,10,s,d));
 assert(!ks::crop({0,0,10,10},{0,0,100,100},0,10,s,d));
 assert(!ks::roundedContains({0,0,40,60},8,0,0));
 assert(ks::roundedContains({0,0,40,60},8,20,30));
 const int W=240,H=90; unsigned char pixels[H][W][3]={};
 for(int i=0;i<4;i++) {
  ks::Rect key={double(8+i*58),10,double(i==3?50:42),65};
  assert(ks::crop(key,{0,0,W,H},64,64,s,d));
  for(int y=0;y<H;y++) for(int x=0;x<W;x++) if(ks::roundedContains(key,9,x+.5,y+.5)) {
   double u=s.x+(x+.5-d.x)/d.w*s.w, v=s.y+(y+.5-d.y)/d.h*s.h;
   if(u<0||u>=64||v<0||v>=64) continue;
   pixels[y][x][0]=(unsigned char)(u*4);
   pixels[y][x][1]=(unsigned char)(v*4);
   pixels[y][x][2]=(unsigned char)(80+i*40);
  }
 }
 assert(pixels[0][0][0]==0 && pixels[40][55][0]==0);
 std::ofstream f(argc>1?argv[1]:"offscreen.ppm",std::ios::binary);
 f<<"P6\n"<<W<<" "<<H<<"\n255\n";
 f.write(reinterpret_cast<char*>(pixels),sizeof pixels); assert(f.good());
 std::cout<<"PASS: crop bounds, invalid geometry, aspect fill, rounded mask, independent key raster\n";
}
