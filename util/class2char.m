function y = class2char(obj)
    % CLASS2CHAR
    %
    % Description:
    %   Returns class name as char
    %
    % Syntax:
    %   y = class2char(obj)
    %
    % See also:
    %   CLASS2DISPLAY
    %
    % History:
    %   09Nov2021 - SSP 
    %   05Jun2022 - SSP - Capitalization
    % ---------------------------------------------------------------------
    
    mc = metaclass(obj);
    y = class2display(mc.Name, true);
    y = y{:};
    y(isstrprop(y, 'wspace')) = [];
