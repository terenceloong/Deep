valid_prefix = 'B210-'; %文件名有效前缀
[file, path] = uigetfile('*.dat', '选择GNSS数据文件'); %文件选择对话框
if ~ischar(file) || ~contains(valid_prefix, strtok(file,'_'))
    error('File error!')
end
filename = [path, file]; %数据文件完整路径,path最后带\

fs = 4e6;
acqConf.freqMax = 5e3;
acqConf.threshold = 1.4;
acqResult = BDS.B1C.acquisition(filename, fs, 0*fs, acqConf);