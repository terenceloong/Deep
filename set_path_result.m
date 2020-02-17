% 打开文件夹选择对话框,选择运行结果存储的文件夹
% 每次打开工程时运行,将路径写入.\temp\path_result.txt
% 如需修改,再次运行此脚本
% 将此脚本设置快捷键

while 1
    selpath = uigetdir('.', '选择结果存储路径');
    if selpath~=0 %如果未选路径,无限循环
        break
    end
end

fileID = fopen('.\temp\path_result.txt', 'w');
fprintf(fileID, '%s', selpath);
fclose(fileID);

clearvars ans fileID selpath