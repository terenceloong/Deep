function c = cross(a, b)

c1 = a(2)*b(3) - a(3)*b(2);
c2 = a(3)*b(1) - a(1)*b(3);
c3 = a(1)*b(2) - a(2)*b(1);

c = [c1, c2, c3];

end