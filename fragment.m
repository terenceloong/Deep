%% 常用程序片段

%% 添加路径

% addpath(genpath('xxx')) %包含子文件夹
addpath('common')
addpath('override')
addpath('receiver')

%% 移除路径

% rmpath(genpath('xxx')) %包含子文件夹
rmpath('common')
rmpath('override')
rmpath('receiver')

%% 历书相关
%  下载GPS历书并读取
filename = GPS.almanac.download('~temp\almanac', UTC2GPS([2020,2,23,15,0,0],8));
almanac = GPS.almanac.read(filename);

%% 星历相关
%  下载GPS星历并读取
filename = GPS.ephemeris.download('~temp\ephemeris', '2020-02-22');
ephe = RINEX.read_N2(filename);
%%
%  下载BDS星历并读取
filename = BDS.ephemeris.download('~temp\ephemeris', '2020-02-22');
ephe = RINEX.read_B303(filename);

%% 星座图
%  显示GPS星座图
c = [2020,2,23,11,50,0];
p = [42.27452, 123.85232, 105];
ax = GPS.constellation('~temp\almanac', c, 8, p);
%%
%   显示BDS星座图
c = [2020,2,23,11,50,0];
p = [42.27452, 123.85232, 105];
ax = BDS.constellation('~temp\ephemeris', c, 8, p);
%%
%  同时显示GPS,BDS星座图
c = [2020,2,23,11,50,0];
p = [42.27452, 123.85232, 105];
ax = GPS.constellation('~temp\almanac', c, 8, p);
ax = BDS.constellation('~temp\ephemeris', c, 8, p, ax);
%%
%   显示未来一段时间GPS卫星轨迹
c = [2020,2,23,11,50,0];
p = [42.27452, 123.85232, 105];
GPS.visibility('~temp\almanac', c, 8, p, 1);

%% kml输出
%    纬度经度写入kml文件
kmlwriteline('~temp\traj.kml', nCoV.storage.pos(:,1),nCoV.storage.pos(:,2), 'Color','r', 'Width',2);

%% 电离层
%   计算一天中的电离层校正值
date = '2019-08-26';
p = [45.730952, 126.624970, 212];
GPS.iono_24h('~temp\ephemeris', date, p, 8, 10);