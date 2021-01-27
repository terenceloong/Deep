function kml_output(obj)
% Êä³ökmlÎÄ¼ş

kmlwriteline('~temp\kml\traj.kml', obj.storage.pos(:,1),obj.storage.pos(:,2), ...
             'Color','r', 'Width',2);

end