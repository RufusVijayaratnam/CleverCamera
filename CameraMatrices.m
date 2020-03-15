clc;
syms fx fy x0 y0 theta phi tau tx ty tz x y z h;

k = [fx, 0, x0; 0, fy, y0; 0, 0, 1];
                  
rx = [1, 0, 0; 0, cos(theta), -sin(theta); 0, sin(theta), cos(theta)];
ry = [cos(phi), 0, sin(phi); 0, 1, 0; -sin(phi), 0, cos(phi)];
rz = [cos(tau), -sin(tau), 0; sin(tau), cos(tau), 0; 0, 0, 1];

r  = ry * rx;

m = k * r;

translation = [tx; ty; tz];
I = eye(3);

p = m * [I translation];

p4 = p(:,4);

c = [(- inv(m)) * p4; 1];

xVecCoord = [x; y; z; 1];

smallX = p * xVecCoord;

d = [inv(m) * smallX; 0];

plucker = [0; 0; 1; -h];










