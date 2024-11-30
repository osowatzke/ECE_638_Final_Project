classdef simModel < keyValueInitializer
    properties
        baseFigNum = 1;
    end
    properties(SetAccess=protected)
        figNum = [];
    end
    methods(Access=protected)
        function resetFigNum(self)
            self.figNum = self.baseFigNum;
        end
        function f = createFigure(self)
            f = figure(self.figNum);
            clf(f);
            self.figNum = self.figNum + 1;
        end
    end
end