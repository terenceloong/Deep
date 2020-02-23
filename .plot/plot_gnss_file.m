function plot_gnss_file
% 观察GNSS文件中的数据

% 选择文件
default_path = fileread('~temp\path_data.txt'); %数据文件所在默认路径
[file, path] = uigetfile([default_path,'\*.dat'], '选择GNSS数据文件'); %文件选择对话框
if file==0 %取消选择,file返回0,path返回0
    disp('Invalid file!');
    return
end
if strcmp(file(1:4),'B210')==0
    error('File error!');
end
data_file = [path, file]; %数据文件完整路径,path最后带\

% 取前一段的数据
fs = 4e6;
n = fs * 0.1; %数据点数
fileID = fopen(data_file, 'r');
data = fread(fileID, [2,n], 'int16'); %两行向量
fclose(fileID);

% 画图
t = (1:n)/fs;
figure
plot(t, data(1,:)) %实部
hold on
plot(t, data(2,:)) %虚部
xlabel('\itt\rm(s)')

end