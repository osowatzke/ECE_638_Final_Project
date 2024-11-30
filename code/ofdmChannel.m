% Class defines an OFDM channel. It can be initialized as 
% ofdmChannel('Name','Value') where 'Name' and 'Value' are
% property names and property values.
% 
% Ex: ofdmChan = ofdmChannel('enRayleighFading',true)
%
% Once class has been instantiated, it can be run as follows:
% 
% rxSignal = ofdmChan.run(txSignal)
%
classdef ofdmChannel < keyValueInitializer

    % Public class properties
    properties
        enRayleighFading = OFDM_DEFAULT.EN_RAYLEIGH_FADING;
        maxDopplerShift  = OFDM_DEFAULT.MAX_DOPPLER_SHIFT;
        sampleRate       = OFDM_DEFAULT.SAMPLE_RATE;
        SNR_dB           = OFDM_DEFAULT.SNR_DB(end);
    end

    % Read-only class properties
    properties(SetAccess=protected)
        fadedSignal;
    end

    % Public class methods
    methods

        % Function generates a received signal from a transmitted signal
        % Fading + noise
        function rxSignal = run(self, txSignal)

            % Create a simple rayleigh fading model
            rayleighChan = comm.RayleighChannel(...
                'PathDelays', 0,...
                'AveragePathGains', 0,...
                'SampleRate', self.sampleRate,...
                'MaximumDopplerShift', self.maxDopplerShift);

            % Apply fading if rayleigh fading is active
            if self.enRayleighFading
                self.fadedSignal = rayleighChan(txSignal);

            % Otherwise pass input signal
            else
                self.fadedSignal = txSignal;
            end

            % Add gaussian noise to faded signal
            rxSignal = awgn(self.fadedSignal, self.SNR_dB, 'measured');
        end
    end
end