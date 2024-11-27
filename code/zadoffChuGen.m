% Function generates an arbitrary zadoff chu sequence
function x = zadoffChuGen(N)
    n = (0:(N-1)).';
    c = mod(N,2);
    x = exp(-1i*pi*n.*(n+c)/N);
end