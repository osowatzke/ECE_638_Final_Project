% Class defines an OFDM equalizer. It can be initialized as 
% ofdmTransmitter('Name','Value') where 'Name' and 'Value' are
% property names and property values.
% 
% Ex: ofdmEq = ofdmEqualizer('interpMethod','linear')
%
% Once class has been instantiated, it can be run as follows:
% 
% eqSymbols = ofdmEq.run(symbols, pilots)
%
classdef ofdmEqualizer < keyValueInitializer

    % Public class properties
    properties
        interpMethod    = OFDM_DEFAULT.INTERP_METHOD;
        smoothingFilter = OFDM_DEFAULT.SMOOTHING_FILTER;
        useIdealChanEst = OFDM_DEFAULT.USE_IDEAL_CHAN_EST;
        eqAlgorithm     = OFDM_DEFAULT.EQ_ALGORITHM;
        SNR_dB          = OFDM_DEFAULT.SNR_DB(end);
        txPilots        = [];
        fadedSymbols    = [];
        txSymbols       = [];
        pilotIndices    = [];
        dataIndices     = [];
    end

    % Public class methods
    methods

        % Function equalizes the receive symbols
        function eqSymbols = run(self, dataSymbols, rxPilots)

            % Estimate the channel's frequency response
            H = self.chanEst(rxPilots);

            % Compute EQ weights with either 'MMSE' or 'ZF' algorithm
            eqWeights = self.computeEqWeights(H);

            % Equalize channel
            eqSymbols = dataSymbols.*eqWeights;
        end
    end

    % Protected class methods
    methods (Access=protected)

        % Function computes equalizer weights from channel's
        % frequency response
        function eqWeights = computeEqWeights(self, H)

            % Allow the user to select between MMSE weights or ZF
            % weights
            if strcmpi(self.eqAlgorithm,'mmse')
                eqWeights = conj(H)./(abs(H).^2 + 10^(-self.SNR_dB/10));
            elseif strcmpi(self.eqAlgorithm,'zf')
                eqWeights = 1./H;
            else
                error('Unsupported EQ Algorithm. Please select from {''mmse'',''zf''}')
            end
        end

        % Function estimates the channel's frequency response
        function H = chanEst(self, rxPilots)

            % Allow user to select from an ideal channel estimate or
            % an pilot channel estimate. The ideal channel estimate
            % is the perfect channel estimate and can't be physically
            % implemented
            if self.useIdealChanEst
                H = self.idealChanEst();
            else
                H = self.pilotChanEst(rxPilots);
            end
        end

        % Function estimates the channel's frequency response
        % using the pilots
        function H = pilotChanEst(self, rxPilots)

            % Allocate empty array for channel frequency response
            H = zeros(length(self.dataIndices), size(rxPilots,2));

            % Measure the frequency response of the pilots
            Hp = rxPilots./self.txPilots;

            % Interpolate frequency response of pilots to obtain
            % the frequency response at the data carriers
            for i = 1:size(H,2)
                H(:,i) = interp1(self.pilotIndices, Hp(:,i),...
                    self.dataIndices, self.interpMethod, 'extrap');
            end

            % Run a smoothing filter on the received data
            % This is typically done with a Kalman filter
            H = self.smoothingFilter(H);
        end

        % Function performs an ideal channel estimate using the
        % faded symbolds
        function H = idealChanEst(self)
            H = self.fadedSymbols./self.txSymbols;
        end
    end
end