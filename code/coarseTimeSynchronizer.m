classdef coarseTimeSynchronizer < keyValueInitializer
    properties
        numSymbols = 5;
        symbolDuration = 16;       
        figureStart = 1;
    end
    properties(Access=protected)
        autoCorrFilterLen;
        autoCorrFilterCoefs;
        timingMetricFilterLen;
        timingMetricFilterCoefs;
        figureCount;
    end
    methods
        function frameStart = run(self, data)
            self.initialize();
            M = self.getTimingMetric(data);
            self.plotTimingMetric(M,false);
            M = self.filterTimingMetric(M);
            self.plotTimingMetric(M,true);
            [idx, xDiff] = self.findFallingEdges(M);
            frameStart = self.getFrameStart(idx);
            self.plotDiffFiltOut(xDiff,idx);
            self.plotFrameStart(data,frameStart);
        end

        % Function get IIR filter coefficients for a boxcar filter and
        % assigns the to a structure of filter coefficients
        function assignFilterCoefs(self,variableName,filterLen)
            [b, a] = getBoxcarIIRCoefs(filterLen);
            self.(variableName) = struct('a',a,'b',b);
        end

        % Function gets IIR filter coefficients for autocorrelation
        % boxcar filter. Boxcar filter is sum in reference formulas.
        function assignAutoCorrFilterCoefs(self)
            self.assignFilterCoefs('autoCorrFilterCoefs',...
                self.autoCorrFilterLen);
        end

        % Function gets IIR filter coefficients for timing metric
        % boxcar filter. Filter needed to smooth timing metric.
        function assignTimingMetricFilterCoefs(self)
            self.assignFilterCoefs('timingMetricFilterCoefs',...
                self.timingMetricFilterLen);
        end

        % Function assigns dependent class properties
        function initialize(self)

            % Set starting fitler index
            self.figureCount = self.figureStart;

            % Get boxcar filter lengths in units of symbols
            autoCorrFilterLenSym = floor((self.numSymbols-1)/2);
            timingMetricFilterLenSym = self.numSymbols - ...
                autoCorrFilterLenSym - 1;

            % Convert boxcar filter lengths to samples
            self.autoCorrFilterLen = autoCorrFilterLenSym * ...
                self.symbolDuration;
            self.timingMetricFilterLen = timingMetricFilterLenSym * ...
                self.symbolDuration;

            % Get coefficients for boxcar filters
            self.assignAutoCorrFilterCoefs();
            self.assignTimingMetricFilterCoefs();
        end

        % Function correlates two sequences of data
        % Correlation duration is defined by autocorr filter length
        function z = correlate(self,x,y)
            z = x.*conj(y);
            b = self.autoCorrFilterCoefs.b;
            a = self.autoCorrFilterCoefs.a;
            z = filter(b,a,z);
        end

        % Function computes Schmidl & Cox timing metric
        % Note that correlation duration is increased to reduce length of
        % timing metric plateau
        function M = getTimingMetric(self, data)
            dataDly = [zeros(self.symbolDuration,1); ...
                data(1:(end-self.symbolDuration))];
            E = self.correlate(data, data);
            P = self.correlate(data, dataDly);
            M = (P.*conj(P))./E.^2;
        end
        function M = filterTimingMetric(self, M)
            L = self.timingMetricFilterLen;
            a = self.timingMetricFilterCoefs.a;
            b = self.timingMetricFilterCoefs.b;
            M = filter(b,a,M);
            M = M/L;
        end
        function [idx, xDiff] = findFallingEdges(self,x)
            xDiff = filter([1 -1],1,x);
            zeroCrossing = (xDiff(1:(end-1)) >= 0) & (xDiff(2:end) <= 0);
            zeroCrossing = zeroCrossing & (x(1:(end-1)) > 0.5);
            L = self.symbolDuration*self.numSymbols;
            zeroCrossingCount = filter(ones(1,L),1,zeroCrossing);
            zeroCrossing = zeroCrossing & (zeroCrossingCount == 1);
            idx = find(zeroCrossing);
        end
        function frameStart = getFrameStart(self,idx)
            frameStart = idx - 159; %self.boxcarFilterLen + 1;
            %frameStart = frameStart - floor((self.boxcarFilterLen - 1)/2);
        end
        function plotTimingMetric(self,M,addDataTip)
            figure(self.figureCount)
            self.figureCount = self.figureCount + 1;
            clf;
            plt = plot(M,'LineWidth',1.5);
            if addDataTip
                [M,I] = max(M);
                datatip(plt,I,M);
            end
        end
        function plotDiffFiltOut(self,xDiff,idx)
            figure(self.figureCount)
            self.figureCount = self.figureCount + 1;
            clf;
            plot(xDiff,'LineWidth',1.5);
            hold on;
            for i = 1:length(idx)
                line(idx*ones(1,2),ylim,'LineWidth',1.5,'Color','red');
            end
        end
        function plotFrameStart(self,data,frameStart)
            figure(self.figureCount);
            self.figureCount = self.figureCount + 1;
            clf;
            plot(abs(data));
            hold on;
            for i = 1:length(frameStart)
                line(frameStart*ones(1,2),ylim,'LineWidth',1.5,'Color','red');
            end
        end
    end
end