function word = bitsFlip(word, D30)
% 根据导航电文校验规则,当上一个字的最后一个比特是1时,下一个字的数据位要翻转

if D30=='1'
    for k=1:24
        if word(k)=='1'
            word(k) = '0';
        else
            word(k) = '1';
        end
    end
end

end