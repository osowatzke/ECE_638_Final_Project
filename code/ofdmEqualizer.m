classdef ofdmEqualizer < keyValueInitializer
    properties
        interpMethod    = OFDM_DEFAULT.INTERP_METHOD;
        smoothingFilter = OFDM_DEFAULT.SMOOTHING_FILTER;
        useIdealChanEst = OFDM_DEFAULT.USE_IDEAL_CHAN_EST;
        eqAlgorithm     = OFDM_DEFAULT.EQ_ALGORITHM;
        SNR_dB          = [];
        txPilots        = [];
        fadedSymbols    = [];
        txSymbols       = [];
        pilotIndices    = [];
        dataIndices     = [];
    end
    methods
        function eqSymbols = run(dataSymbols, rxPilots)            
            H = self.chanEst(rxPilots);    
            eqWeights = computeEqWeights(H);
            eqSymbols = dataSymbols.*eqWeights;
        end
    end
    methods (Access=protected)

        function eqWeights = computeEqWeights(self, H)
            if strcmpi(self.eqAlgorithm,'mmse')
                eqWeights = conj(H)./(abs(H).^2 + 10^(-self.SNR_dB/10));
            elseif strcmpi(self.eqAlgorithm,'zf')
                eqWeights = 1./H;
            else
                error('Unsupported EQ Algorithm. Please select from {''mmse'',''zf''}')
            end
        end

        function H = chanEst(self, rxPilots)
            if self.useIdealChanEst
                H = self.idealChanEst(self);
            else
                H = self.pilotChanEst(self, rxPilots);
            end
        end

        function H = pilotChanEst(self, rxPilots)
            H = zeros(length(self.dataIndices), size(rxPilots,2));
            Hp = rxPilots./self.txPilots;
            for i = 1:size(H,2)
                H(:,i) = interp1(self.pilotIndices, Hp(:,i),...
                    self.dataIndices, self.interpMethod, 'extrap');
            end
            H = self.smoothingFilter(H);
        end

        function H = idealChanEst(self)
            H = self.fadedSymbols./self.txSymbols;
        end
    end
end