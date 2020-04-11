classdef ForceIncludePredictor < BaseFilterReviewerTask
    % ForceIncludePredictor embedded app for including a predictor in a
    % scorecard
    
    %   Copyright 2019 The MathWorks, Inc.   
    
    properties (Access = public, Transient, Hidden)   
        VariableDD matlab.ui.control.DropDown
    end
    
    methods (Access = public)
        
        function app = ForceIncludePredictor
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
        app.UIFigure = uifigure('Name','Include Predictor');
        % The entire app uses a uigridlayout
        app.UIGrid = uigridlayout(app.UIFigure,[4 6],'ColumnWidth',{'1x','1x','1x','1x','2x','1x'},...
            'RowHeight', num2cell(app.TextRowHeight*ones(1,4)));
        createWidgets(app);
        setInputDataAndWidgetsToDefault(app);       
        end
        
        function createWidgets(app)
        createDelimiterRow(app,'Select Input Scorecard and Predictor',1);
        createInputDataRow(app);        
        createDelimiterRow(app,'Justification',3);
        createCommentRow(app)
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
        app.CommentBox = matlab.ui.control.TextArea('Parent',app.UIGrid...
            ,'ValueChangedFcn',@app.updateComment);
        app.CommentBox.Layout.Column = [1 5];
        app.WebButton = matlab.ui.control.Button('Parent',app.UIGrid,...
            'Text','Open in Browser','ButtonPushedFcn',@app.openInBrowser);
        end
       
        function updateComment(app,src,evt)
        app.State.Comment = src.Value;        
        doUpdate(app)
        end
        
        function isSupported = filterWorkspaceInputs(app,workspaceInput)
        isSupported = isa(workspaceInput,'creditscorecard');
        end
        
        function setInputDataAndWidgetsToDefault(app)
        setWidgetsToDefault(app)
        end
        
        function setWidgetsToDefault(app)
        set(app.VariableDD,'Enable','off','Items',{app.WorkspaceDropDownDefaultValue})
        end
        
        function doUpdate(app,source,~)        
        if nargin < 2
            source = [];
        else
            % from widget change, make sure variables are still there
            if isempty(app.WorkspaceDropDown.WorkspaceValue)
                app.WorkspaceDropDown.Value = app.WorkspaceDropDownDefaultValue;
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
            if isfield( app.State, 'Comment' )
                app.CommentBox.Value = app.State.Comment;
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
        code = "[sc_fitted,mdl] = fitmodel( " + app.WorkspaceDropDown.Value + " );" + newline ;
        code = code + "mdl = mdl.addTerms( '" + app.VariableDD.Value  + "' )" + newline ;
        code = code + "sc_fitted = setmodel(sc_fitted,mdl.PredictorNames,mdl.Coefficients.Estimate);";
        outputs = {'sc_fitted,mdl'};
        end
        
        function code = generateVisualizationScript(app)           
            code = '';
            return               
        end        
        
        function summary = generateSummary(app)
        summary = "Force include a predictor in `" + app.WorkspaceDropDown.Value + "`";
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
