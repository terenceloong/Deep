f = figure;
c = uicontrol(f);
c.Style = 'slider';
c.Position = [15,15,120,15];
c.Max = 80;
c.Min = 0;
c.SliderStep = [2,8]/80;
c.Callback = @showValue;

function showValue(src, event)
    disp(src.Value)
end