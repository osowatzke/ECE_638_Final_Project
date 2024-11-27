classdef OFDM_DEFAULT
    properties(Constant)
        MOD_TYPE           = 'qam';
        MOD_ORDER          = 4;
        NSUBCARRIERS       = 64;
        NDATA_CARRIERS     = 48;
        PILOT_CARRIERS     = [-21, -7, 7, 21];
        USE_DC_SUBCARRIER  = false;
        CYCLIC_PREFIX_LEN  = 16;
        WINDOW_LEN         = 4;
        USE_IDEAL_CHAN_EST = true;
        EQ_ALGORITHM       = 'mmse';
        INTERP_METHOD      = 'linear';
        SMOOTHING_FILTER   = @(x)filter(ones(1,16), 1, x);
    end
end