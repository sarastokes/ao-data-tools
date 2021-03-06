classdef (Abstract) Entity < handle 
% ENTITY
%
% Constructor:
%   obj = aod.core.Entity()
%
% Properties:
%   Parent                      aod.core.Entity
%   description                 string
%   notes                       cell
%   allowableParentTypes        cellstr
%
% Dependent properties:
%   label                       string
%   shortName                   string
%
% Methods:
%   addParameter(obj, name, value)
%   value = getParameter(obj, name)
%   addNote(obj, txt)
%   clearNotes(obj)
%
% Protected methods:
%   addParent(obj, parent)
%   x = getShortName(obj)
%   x = getLabel(obj)
%
% Private methods:
%   tf = isValidParent(obj, parent)
% -------------------------------------------------------------------------

    properties (SetAccess = private)
        Parent                      %aod.core.Entity 
        description                 string = string.empty() 
        notes                       string = string.empty()
    end

    
    properties (Hidden, SetAccess = protected)
        allowableParentTypes        cell    = cell.empty();
    end

    properties (Dependent = true)
        label
    end

    properties (Hidden, Dependent)
        shortName
    end

    methods
        function obj = Entity()
        end

        function value = get.label(obj)
            value = obj.getLabel();
        end

        function value = get.shortName(obj)
            value = obj.getShortName();
        end

        function h = ancestor(obj, className)
            % ANCESTOR
            %
            % Description:
            %   Recursively search 'Parent' property for className & return
            %
            % Syntax:
            %   h = obj.ancestor(className)
            % -------------------------------------------------------------
            h = obj;
            while ~isSubclass(h, className)
                h = h.Parent;
                if isempty(h)
                    %warning('Ancestor of class %s not found!', className);
                    break
                end
            end
        end
    end

    methods 
        function setDescription(obj, txt, overwrite)
            % SETDESCRIPTION
            %
            % Syntax:
            %   setDescription(obj, txt, overwrite)
            %
            % Inputs:
            %   txt         string
            %       Description
            % Optional inputs:
            %   overwrite   logical (default = false)
            %       Whether to overwrite existing description 
            % -------------------------------------------------------------
            if nargin < 3
                overwrite = false;
            end

            if ~isempty(obj.description) && ~overwrite 
                warning('Set overwrite=true to change existing description');
                return
            end
            obj.description = txt;
        end
        
        function addNote(obj, txt)
            % ADDNOTE
            % 
            % Syntax:
            %   obj.addNote(txt)
            % -------------------------------------------------------------
            if ~isempty(obj.notes)
                obj.notes = obj.notes + '; ';
            end
            obj.notes = obj.notes + txt;
        end

        function clearNotes(obj)
            % CLEARNOTES
            %
            % Syntax:
            %   obj.clearNotes()
            % -------------------------------------------------------------
            obj.notes = string.empty();
        end
    end

    % Methods likely to be overwritten by subclasses
    methods (Access = protected)
        function value = getLabel(obj)  
            % GETVALUE
            %      
            % Syntax:
            %   value = obj.getLabel()
            % -------------------------------------------------------------
            value = ao.util.class2char(obj);
        end

        function shortName = getShortName(obj)
            % GETSHORTNAME
            % 
            % Syntax:
            %   shortName = obj.getShortName()
            % -------------------------------------------------------------
            shortName = obj.getLabel();
        end
    end

    methods (Access = protected)
        function setParent(obj, parent)
            % SETPARENT
            %   
            % Syntax:
            %   obj.setParent(parent)
            % -------------------------------------------------------------
            if isempty(parent)
                return
            end
            
            if obj.isValidParent(parent)
                obj.Parent = parent;
            else
                error('%s is not a valid parent', class(parent));
            end
        end
    end

    methods (Access = private)
        function tf = isValidParent(obj, parent)
            % ISVALIDPARENT
            %
            % Description:
            %   Determine if parent is in or subclass of allowable parents
            %
            % Syntax:
            %   tf = isValidParent(parent)
            % -------------------------------------------------------------
            tf = false;
            if isempty(obj.allowableParentTypes)
                tf = true;
                return;
            end

            for i = 1:numel(obj.allowableParentTypes)
                if ~tf
                    if isa(parent, obj.allowableParentTypes{i}) ...
                            || ismember(obj.allowableParentTypes{i}, superclasses(class(parent)))
                        tf = true;
                    else
                        tf = false;
                    end
                end
            end
        end
    end

    methods (Static)
        function tf = isEntity(x)
            tf = isSubclass(x, 'aod.core.Entity');
        end
    end
end 