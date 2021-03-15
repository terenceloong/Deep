function almanac = read(filename)
% 读GPS YUMA历书文件

% 打开文件
fileID = fopen(filename);
if(fileID == -1)
    almanac = [];
    disp('Can''t open the file!')
    return
end

% 读数据
temp = zeros(32,12);
line = 1; %文件的第几行
while ~feof(fileID)
    tline = fgetl(fileID);
    n = mod(line,15); %每颗卫星的第几行数据,每颗卫星的数据占15行
    if n==2 %第2行为ID号
        [~, remain] = strtok(tline, ':'); %截取:以后的字符,包含:
        C = textscan(remain, '%s %f');
        ID = C{2};
    elseif 3<=n && n<=14 %第3~14行为数据
        [~, remain] = strtok(tline, ':');
        C = textscan(remain, '%s %f');
        temp(ID,n-2) = C{2}; %存数据
    end
    line = line+1;
end

% 关闭文件
fclose(fileID);

% 整理数据
% almanac = [ID, health, week, af0, af1, toe, sqa, e, M0, omega, Omega0, Omega_dot, i];
almanac = zeros(32,13);
almanac(:,1)  = 1:32;        %ID
almanac(:,2)  = temp(:,1);   %health
almanac(:,3)  = temp(:,10);  %af0,s
almanac(:,4)  = temp(:,11);  %af1,s/s
almanac(:,5)  = temp(:,12);  %week
almanac(:,6)  = temp(:,3);   %toe,s
almanac(:,7)  = temp(:,6);   %sqa,sqrt(m)
almanac(:,8)  = temp(:,2);   %e
almanac(:,9)  = temp(:,9);   %M0,rad,平近点角
almanac(:,10) = temp(:,8);   %omega,rad,近地点幅角
almanac(:,11) = temp(:,7);   %Omega0,rad,升交点赤经
almanac(:,12) = temp(:,5);   %Omega_dot,rad/s
almanac(:,13) = temp(:,4);   %i,rad
almanac(almanac(:,7)==0,:) = []; %删除无数据的行

end