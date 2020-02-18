% 测试为figure上的曲线加右键菜单

figure
ps = polarscatter(1,1, 220);
c = uicontextmenu;
ps.UIContextMenu = c;
m1 = uimenu(c, 'Text','dashed', 'MenuSelectedFcn',@fun);
m1.UserData.a = 3;

function fun(app, event)
    figure
    plot([1,2],[1,2])
end