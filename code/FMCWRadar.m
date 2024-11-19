classdef FMCWRadar < radar
    properties
        sweepBandwidth = [];
    end
    properties(Access=protected)
        sweepRate;
    end
    methods
        function self = FMCWRadar(varargin)
            self = self@radar(varargin{:});
            if isempty(self.sweepBandwidth)
                self.sweepBandwidth = self.sampleRate;
            end
        end
        function run(self)
            run@radar(self);
            self.generatePlots();
        end
    end
    methods(Access=protected)
        function getParameters(self)
            getParameters@radar(self);
            self.sweepRate = self.sweepBandwidth/self.sampleRate/...
                self.priSamples;
        end
        function getTxWaveform(self)
            n = (0:(self.priSamples-1)).';
            self.txWaveform = exp(1i*pi*self.sweepRate*n.^2);
        end
        function generateRdm(self)

            % Mix signal with transmitted waveform
            % Will result in tone which can be sampled by ADC
            adcData = self.txWaveform.*conj(self.rxData);

            % Fast time FFT
            self.rdm = fft(adcData);
            
            % Slow time FFT
            self.rdm = fft(self.rdm,[],2);
        end
        function generatePlots(self)
            figure(1)
            clf;
            imagesc(db(self.rdm));
            figure(2)
            clf;
            plot(db(self.rdm(:,1)))
        end
    end
end