function window = raisedCosineWindow(nSubcarriers,...
    cyclicPrefixLen, windowLen)

    window = hanning(2*windowLen + 1);
    window = [window(1:windowLen);
        ones(nSubcarriers + cyclicPrefixLen, 1);
        window((end-windowLen+1):end)];
end