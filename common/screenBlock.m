function position = screenBlock(x, y, fx, fy)
% 获取屏幕块的位置
% position:[dx,dy,x,y],单位:像素
% x,y:宽高,像素
% fx,fy:相对左下底角的比例

screenSize = get(0,'ScreenSize'); %获取屏幕尺寸
dx = floor((screenSize(3)-x)*fx);
dy = floor((screenSize(4)-y)*fy);
position = [dx,dy,x,y];

end