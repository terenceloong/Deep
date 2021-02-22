function angle = attContinuous(angle)
% 将姿态角变连续,角度单位:deg

for k=2:length(angle)
    if angle(k)-angle(k-1)<-300
        angle(k:end) = angle(k:end) + 360;
    elseif angle(k)-angle(k-1)>300
        angle(k:end) = angle(k:end) - 360;
    end
end

end