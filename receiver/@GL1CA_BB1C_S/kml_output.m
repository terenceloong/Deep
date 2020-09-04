function kml_output(obj)
% 输出kml文件

%% 正常模式
if obj.state==1
    if obj.GPSflag==1
        kmlwriteline('~temp\trajGPS.kml', obj.storage.satnavGPS(:,1),obj.storage.satnavGPS(:,2), ...
                     'Color','b', 'Width',2);
    end
    if obj.BDSflag==1
        kmlwriteline('~temp\trajBDS.kml', obj.storage.satnavBDS(:,1),obj.storage.satnavBDS(:,2), ...
                     'Color','r', 'Width',2);
    end
    if obj.GPSflag==1 && obj.BDSflag==1
        kmlwriteline('~temp\trajMulti.kml', obj.storage.satnav(:,1),obj.storage.satnav(:,2), ...
                     'Color','g', 'Width',2);
    end
end

%% 深组合模式
if obj.state==3
    kmlwriteline('~temp\traj.kml', obj.storage.pos(:,1),obj.storage.pos(:,2), ...
             'Color','r', 'Width',2);
end

end