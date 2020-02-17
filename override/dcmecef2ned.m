function dcm = dcmecef2ned(lat, lon)
% ecef系到地理系的坐标变换阵
% lat,lon单位:deg

sinlat = sind(lat);
coslat = cosd(lat);
sinlon = sind(lon);
coslon = cosd(lon);

dcm = [-sinlat*coslon, -sinlat*sinlon,  coslat;
              -sinlon,         coslon,       0;
       -coslat*coslon, -coslat*sinlon, -sinlat];

end