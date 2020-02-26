function dt = roundWeek(dt)
% 考虑整周秒数循环,将时间差转成±302400s
% 参见GPS,BDS接口文档星历计算部分

if dt>302400
    dt = dt-604800;
elseif dt<-302400
    dt = dt+604800;
end

end