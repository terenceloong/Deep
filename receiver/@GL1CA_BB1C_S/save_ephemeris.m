function save_ephemeris(obj, filename)
% 保存星历

load(filename, 'ephemeris') %加载预存的星历

if obj.GPSflag==1
    ephemeris.GPS_iono = obj.GPS.iono; %保存电离层校正参数
    for k=1:obj.GPS.chN %提取有星历通道的星历
        channel = obj.GPS.channels(k);
        if ~isnan(channel.ephe(1))
            ephemeris.GPS_ephe(channel.PRN,:) = channel.ephe;
        end
    end
end

save(filename, 'ephemeris') %保存到文件中

end