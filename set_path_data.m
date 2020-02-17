% 打开文件夹选择对话框,选择数据所在的文件夹
% 每次打开工程时运行,将路径写入.\temp\path_data.txt
% 如需修改,再次运行此脚本
% 将此脚本设置快捷键

while 1
    selpath = uigetdir('.', '选择数据文件路径');
    if selpath~=0 %如果未选路径,无限循环
        break
    end
end

fileID = fopen('.\temp\path_data.txt', 'w');
fprintf(fileID, '%s', selpath);
fclose(fileID);

clearvars ans fileID selpath