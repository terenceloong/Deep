function kml_output(obj)
% Êä³ökmlÎÄ¼þ

if obj.GPSflag==1
    kmlwriteline('~temp\trajGPS.kml', obj.storage.satnavGPS(:,1),obj.storage.satnavGPS(:,2), ...
                 'Color',[65,180,250]/255, 'Width',2);
end

if obj.BDSflag==1
    kmlwriteline('~temp\trajBDS.kml', obj.storage.satnavBDS(:,1),obj.storage.satnavBDS(:,2), ...
                 'Color',[255,65,65]/255, 'Width',2);
end

kmlwriteline('~temp\trajMulti.kml', obj.storage.satnav(:,1),obj.storage.satnav(:,2), ...
             'Color','g', 'Width',2);

end