clear all;
clc;

theta = 0;

Rx = [1,          0,           0; 
      0, cos(theta), -sin(theta);
      0, sin(theta), cos(theta)];

tx = -1000;
ty = 1500;
tz = 510;
translation = [tx; ty; tz];

extrinsic = [Rx translation];


fx = 3319.68707;
fy = 3337.51214;
cx = 1476.77578;
cy = 1921.59370;
intrinsic = [fx,   0,  cx; 
              0,  fy,  cy; 
              0,   0,  1];

x = 1000;
y = -1500;
z = 0;
worldCoords = [x; y; z; 1];


scaledPixelCoords = intrinsic * extrinsic * worldCoords;

pixelCoords = scaledPixelCoords / tz;

disp(pixelCoords);

