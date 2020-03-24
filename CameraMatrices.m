clear all;
clc;
syms   x y z h u v;
phi = 0;
theta = -1.8985;
tau = 0;
tx = 1000;
ty = -510;
tz = 0;
fx = 3319.68707;
fy = 3337.51214;
x0 = 1476.77578;
y0 = 1921.59370; 
x = 1000 - x0;
y = 0 - y0;
normalizer = 1584;
z = 1500;
h = 0;
u = 0;
v = 0;



k = [fx, 0, x0; 0, fy, y0; 0, 0, 1];
                  
rx = [1, 0, 0; 0, cos(theta), -sin(theta); 0, sin(theta), cos(theta)];
ry = [cos(phi), 0, sin(phi); 0, 1, 0; -sin(phi), 0, cos(phi)];
rz = [cos(tau), -sin(tau), 0; sin(tau), cos(tau), 0; 0, 0, 1];

r  = rx;

m = k * r;

translation = [tx; ty; tz];
I = eye(3);

p = m * [I translation];

p4 = p(:,4);

c = [(- inv(m)) * p4; 1];

xVecCoord = [x; y; z; 1];

smallX = [u; v; 1];

d = [inv(m) * smallX; 0];

plucker = [0; 0; 1; -h];

pixels = (p * xVecCoord) / z;

left = (c * transpose(d) - d * transpose(c)) * plucker;

right = (transpose(plucker) * d) * c - (transpose(plucker) * c) * d;



