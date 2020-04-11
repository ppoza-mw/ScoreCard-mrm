classdef BinningReviewer < BaseFilterReviewerTask
    % BinningReviewer embedded app for reviewing and automatic binning
    
    %   Copyright 2019 The MathWorks, Inc.   
    
    properties (Access = public, Transient, Hidden)   
        VariableDD matlab.ui.control.DropDown
        IncludeCB matlab.ui.control.CheckBox
    end
    
    methods (Access = public)
        
        function app = BinningReviewer
        createComponents(app);
        doUpdate(app);
        end
        
        function delete(app)
        delete(app.UIFigure)
        end
    end
    
    methods (Access = public, Hidden)
        
        function createComponents(app)
        % Create the ui components and lay them out in the figure
        
        % The entire app is one uifigure as wide as about 80 characters
        app.UIFigure = uifigure('Name','Binning Review');
        % The entire app uses a uigridlayout
        app.UIGrid = uigridlayout(app.UIFigure,[6 6],'ColumnWidth',{'1x','1x','1x','1x','2x','1x'},...
            'RowHeight', num2cell(app.TextRowHeight*ones(1,6)));
        createWidgets(app);
        setInputDataAndWidgetsToDefault(app);       
        end
        
        function createWidgets(app)
        createDelimiterRow(app,'Select Input Scorecard and Predictor',1);
        createInputDataRow(app);        
        createDelimiterRow(app,'Review Binning',3);
        createCommentRow(app)
        createDelimiterRow(app,'Analysis Options',5);
        createAnalysisOptionRow(app)
        end        
        
        function createInputDataRow(app)
        uilabel(app.UIGrid,'Text','Input Scorecard');
        app.WorkspaceDropDown = matlab.ui.control.internal.model.WorkspaceDropDown('Parent',app.UIGrid);
        app.WorkspaceDropDown.FilterVariablesFcn = @(t)app.filterWorkspaceInputs(t);
        app.WorkspaceDropDown.ValueChangedFcn = @app.doUpdate;
        uilabel(app.UIGrid,'Text','Select Predictor');
        app.VariableDD = uidropdown('Parent',app.UIGrid,'ValueChangedFcn',@app.doUpdate);
        end
                
        function includePredictor(app,src,~)
        if ~isfield( app.State, app.VariableDD.Value )
            app.State.(app.VariableDD.Value).Comment = "";
        end
        app.State.(app.VariableDD.Value).Include = src.Value;
        doUpdate(app)
        end
        
        function createCommentRow(app)
        app.IncludeCB = matlab.ui.control.CheckBox('Parent',app.UIGrid,...
            'Text','Autobin Predictor?','ValueChangedFcn',@app.includePredictor);        
        app.CommentBox = matlab.ui.control.TextArea('Parent',app.UIGrid...
            ,'ValueChangedFcn',@app.updateComment);
        app.CommentBox.Layout.Column = [2 5];
        app.WebButton = matlab.ui.control.Button('Parent',app.UIGrid,...
            'Text','Open in Browser','ButtonPushedFcn',@app.openInBrowser);
        end

        function createAnalysisOptionRow(app)
        matlab.ui.control.CheckBox('Parent',app.UIGrid,...
            'Text','Binning Information','Enable','off');        
        matlab.ui.control.CheckBox('Parent',app.UIGrid,...
            'Text','Bar Chart','Enable','off');                
        end        
        
        function updateComment(app,src,evt)
        if ~isfield( app.State, app.VariableDD.Value )
            app.State.(app.VariableDD.Value).Include = false;
        end
        app.State.(app.VariableDD.Value).Comment = src.Value;        
        doUpdate(app)
        end
        
        function isSupported = filterWorkspaceInputs(app,workspaceInput)
        isSupported = isa(workspaceInput,'creditscorecard');
        end
        
        function setInputDataAndWidgetsToDefault(app)
        % app.WorkspaceDropDown.Value = 'select';
        setWidgetsToDefault(app)
        end
        
        function setWidgetsToDefault(app)
        set(app.VariableDD,'Enable','off','Items',{'select'})
        end
        
        function doUpdate(app,source,~)        
        if nargin < 2
            source = [];
        else
            % from widget change, make sure variables are still there
            if isempty(app.WorkspaceDropDown.WorkspaceValue)
                app.WorkspaceDropDown.Value = 'select';
            end
            if ~hasInputData(app)
                setWidgetsToDefault(app);
            end
        end
        % Update the entire app
        updateWidgets(app,source);
        end
        
        function hasInput = hasInputData(app)
        hasInput = ~strcmp(app.WorkspaceDropDown.Value,app.WorkspaceDropDownDefaultValue);
        end
               
        function updateWidgets(app,source)
        if isequal(source, app.WorkspaceDropDown)
            % reset the app
            setWidgetsToDefault(app);
        end
        hasInput = hasInputData(app);
        if hasInput
            app.VariableDD.Items = app.WorkspaceDropDown.WorkspaceValue.PredictorVars;
            app.VariableDD.Enable = 'on';            
            app.IncludeCB.Value = isfield( app.State, app.VariableDD.Value ) && ...
                app.State.(app.VariableDD.Value).Include;
            if isfield( app.State, app.VariableDD.Value )
                app.CommentBox.Value = app.State.(app.VariableDD.Value).Comment;
            else
                app.CommentBox.Value = '';
            end
            
        end
        end
               
    end
    
    methods (Access = public) % Methods required for embedding in a Live Script
        
        function reset(app)
        setWidgetsToDefault(app);
        doUpdate(app);
        end
        
        function [code, outputs] = generateScript(app)        
        if ~hasInputData(app)
            code = '';
            outputs = {};
            return
        end
        % Determine which predictor variables have been selected for binning
        predictorVars = string( fields( app.State ) );
        for n = length( predictorVars ):-1:1
            if app.State.(predictorVars{n}).Include
                predictorVars(n) = "'" + predictorVars(n) + "'";
            else
                predictorVars(n) = [];
            end
        end
        if isempty( predictorVars )
            code = "sc_binned = sc; % no variables binned";
        else
            code = "sc_binned = autobinning(" + app.WorkspaceDropDown.Value + ",'PredictorVar',{" + strjoin(predictorVars,',') + "});";
        end
        outputs = {'sc_binned'};
        end
        
        function code = generateVisualizationScript(app)           
            if ~hasInputData(app)
                code = '';
                return               
            end
            code = "bi = bininfo(sc_binned,'" + app.VariableDD.Value + "')";
            code = [code newline 'bar([bi.Good bi.Bad],''stacked'');'];
            code = [code newline 'xticklabels(bi.Bin);'];
        end        
        
        function summary = generateSummary(app)
        summary = "Review binning of `" + app.WorkspaceDropDown.Value + "`";
        end
        
        function state = getState(app)
        state = app.State;
        end
        
        function setState(app,state)
        app.State = state;       
        doUpdate(app);
        end
    end
    
end