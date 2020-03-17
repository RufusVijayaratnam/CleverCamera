clc;
syms  u v x y z h;
phi = (2 / 15) * pi;
theta = (1/6) * pi;
tau = 0;
tx = 2000;
ty = 0;
tz = 510;
fx = 1.1086317008784154e+03;
fy = 1.0612325424113169e+03;
x0 = 7.3917766770204355e+02;
y0 = 5.7223494062937539e+02; 
h = 350;



k = [fx, 0, x0; 0, fy, y0; 0, 0, 1];
                  
rx = [1, 0, 0; 0, cos(theta), -sin(theta); 0, sin(theta), cos(theta)];
ry = [cos(phi), 0, sin(phi); 0, 1, 0; -sin(phi), 0, cos(phi)];
rz = [cos(tau), -sin(tau), 0; sin(tau), cos(tau), 0; 0, 0, 1];

r  = rz * ry * rx;

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



left = (c * transpose(d) - d * transpose(c)) * plucker;

right = (transpose(plucker) * d) * c - (transpose(plucker) * c) * d;


