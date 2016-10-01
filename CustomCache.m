classdef CustomCache
    properties
        folder
    end
    methods
        
        % Constructor
        function obj = CustomCache(folder)
            obj.folder = GetFullPath(folder);
        end
        
        % Call
        function varargout = subsref(obj,s)
            
            if s(1).type=='.'
                if strcmp(s(1).subs, 'folder')
                    varargout = {obj.folder};
                    return
                else
                    error('Reference to non-existent field.');
                end
            end
            
            if strcmp(s(1).type, '{}')
                error(['Cell contents reference from a non-cell array ',...
                    'object.']);
            end
            
            if length(s)~=1
                error('Invalid field or cell access.');
            end
            
            if nargout==0
                CachePureFunction(obj.folder, s(1).subs{:});
                varargout{1} = ans;
            else
                [varargout{1:nargout}] =...
                    CachePureFunction(obj.folder, s(1).subs{:});
            end
                    
        end
        
    end
end
  