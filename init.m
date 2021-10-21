% 创建必要的文件夹 

if ~exist('~temp','dir')
    mkdir('~temp')
end

if ~exist('~temp\almanac','dir')
    mkdir('~temp\almanac')
end

if ~exist('~temp\data','dir')
    mkdir('~temp\data')
end

if ~exist('~temp\ephemeris','dir')
    mkdir('~temp\ephemeris')
end

if ~exist('~temp\kml','dir')
    mkdir('~temp\kml')
end

if ~exist('~temp\result','dir')
    mkdir('~temp\result')
end

if ~exist('~temp\spirent','dir')
    mkdir('~temp\spirent')
end

if ~exist('~temp\traj','dir')
    mkdir('~temp\traj')
end