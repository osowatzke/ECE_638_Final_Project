classdef ofdmChannel < keyValueInitializer
    properties
        enRayleighFading = OFDM_DEFAULT.EN_RAYLEIGH_FADING;
        maxDopplerShift  = OFDM_DEFAULT.MAX_DOPPLER_SHIFT;
        sampleRate       = OFDM_DEFAULT.SAMPLE_RATE;
        SNR_dB           = OFDM_DEFAULT.SNR_DB(end);
    end
    properties(SetAccess=protected)
        fadedSignal;
    end
    methods
        function rxSignal = run(self, txSignal)

            rayleighChan = comm.RayleighChannel(...
                'PathDelays', 0,...
                'AveragePathGains', 0,...
                'SampleRate', self.sampleRate,...
                'MaximumDopplerShift', self.maxDopplerShift);

            if self.enRayleighFading
                self.fadedSignal = rayleighChan(txSignal);
            else
                self.fadedSignal = txSignal;
            end

            rxSignal = awgn(self.fadedSignal, self.SNR_dB, 'measured');
        end
    end
end