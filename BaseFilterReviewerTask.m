classdef BaseFilterReviewerTask < handle & matlab.mixin.internal.Scalar
    % embedded app for filtering and reviewing
    
    %   Copyright 2019 The MathWorks, Inc.
    
    properties (Access = public, Transient)
        UIFigure matlab.ui.Figure
    end
    
    properties (Access = public, Transient, Hidden)
        % Widget layout
        UIGrid matlab.ui.container.GridLayout
        % Widgets
        WorkspaceDropDown matlab.ui.control.internal.model.WorkspaceDropDown
        CommentBox matlab.ui.control.TextArea
        WebButton matlab.ui.control.Button        
    end
    
    properties (Constant, Transient, Hidden)
        TextRowHeight double = 22; % Same as App Designer default
        DropDownWidth double = 150;
        WorkspaceDropDownDefaultValue = 'select variable'
    end

    properties
        State struct = struct 
    end    
    
    methods (Access = public, Hidden)
        
        function createDelimiterRow(app,textLabel,row)
        % Black bold text delimiting rows of parameter groups
        L = uilabel(app.UIGrid,'Text',textLabel,'FontSize',15,...
            'FontWeight','bold','FontColor',[0.24 0.24 0.24]);
        L.Layout.Column = [1 6];
        L.Layout.Row = row;
        end        
        
        function openInBrowser(app,~,~)
        [errorCode,remoteUrl] = system('git config --get remote.origin.url');
        if errorCode ~= 0
            uialert( app.UIFigure, 'No remote Git repository named origin', 'Error' )
            return
        end
        assert( remoteUrl(end) == newline );
        remoteUrl(end) = []; % remove newline
        remoteUrl = replace( remoteUrl, ".git", "" );       
        match = regexp(app.CommentBox.Value,'^#(\d*)','tokens');
        if ~isempty(match{1})
            issueNumber = match{1}{1}{1};
            remoteUrl = remoteUrl + "/issues/" + issueNumber;
        end
        web(remoteUrl)
        end

    end
    
    methods (Abstract, Access = public, Hidden)
        isSupported = filterWorkspaceInputs(app,workspaceInput)        
    end
    
end
