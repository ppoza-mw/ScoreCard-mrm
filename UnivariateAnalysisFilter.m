classdef UnivariateAnalysisFilter < BaseFilterReviewerTask
    % UnivariateAnalysisFilter embedded app for removing variables from a
    % table based on univariate analysis
    
    %   Copyright 2019 The MathWorks, Inc.
    
    properties (Access = public, Transient, Hidden)
        VariableDD matlab.ui.control.DropDown
        ExcludeCB matlab.ui.control.CheckBox
        SummaryCB matlab.ui.control.CheckBox
        HistogramCB matlab.ui.control.CheckBox
    end
    
    methods (Access = public)
        
        function app = UnivariateAnalysisFilter
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
            app.UIFigure = uifigure('Name','Univariate Analysis Filter');
            % The entire app uses a uigridlayout
            app.UIGrid = uigridlayout(app.UIFigure,[6 6],'ColumnWidth',{'1x','1x','1x','1x','2x','1x'},...
                'RowHeight', num2cell(app.TextRowHeight*ones(1,6)));
            createWidgets(app);
            setInputDataAndWidgetsToDefault(app);
        end
        
        function createWidgets(app)
            createDelimiterRow(app,'Select Input Table and Variable',1);
            createInputDataRow(app);
            createDelimiterRow(app,'Review Analysis',3);
            createCommentRow(app)
            createDelimiterRow(app,'Analysis Options',5);
            createAnalysisOptionRow(app)
        end
        
        function createInputDataRow(app)
            uilabel(app.UIGrid,'Text','Input Table');
            app.WorkspaceDropDown = matlab.ui.control.internal.model.WorkspaceDropDown('Parent',app.UIGrid);
            app.WorkspaceDropDown.FilterVariablesFcn = @(t)app.filterWorkspaceInputs(t);
            app.WorkspaceDropDown.ValueChangedFcn = @app.doUpdate;
            uilabel(app.UIGrid,'Text','Select Variable');
            app.VariableDD = uidropdown('Parent',app.UIGrid,'ValueChangedFcn',@app.doUpdate);
        end
        
        function excludeVariable(app,src,evt)
            if ~isfield( app.State, app.VariableDD.Value )
                app.State.(app.VariableDD.Value).Comment = "";
            end
            app.State.(app.VariableDD.Value).Exclude = src.Value;
            doUpdate(app)
        end
        
        function createCommentRow(app)
            app.ExcludeCB = matlab.ui.control.CheckBox('Parent',app.UIGrid,...
                'Text','Exclude Variable?','ValueChangedFcn',@app.excludeVariable);
            app.CommentBox = matlab.ui.control.TextArea('Parent',app.UIGrid...
                ,'ValueChangedFcn',@app.updateComment);
            app.CommentBox.Layout.Column = [2 5];
            app.WebButton = matlab.ui.control.Button('Parent',app.UIGrid,...
                'Text','Open in Browser','ButtonPushedFcn',@app.openInBrowser);
        end
        
        function createAnalysisOptionRow(app)
            app.SummaryCB = matlab.ui.control.CheckBox('Parent',app.UIGrid,...
                'Text','Summary','Enable','on', 'Value', 1);
            app.HistogramCB = matlab.ui.control.CheckBox('Parent',app.UIGrid,...
                'Text','Histogram','Enable','on', 'Value', 1);
        end
        
        function updateComment(app,src,evt)
            if ~isfield( app.State, app.VariableDD.Value )
                app.State.(app.VariableDD.Value).Exclude = false;
            end
            app.State.(app.VariableDD.Value).Comment = src.Value;
            doUpdate(app)
        end
        
        function isSupported = filterWorkspaceInputs(app,workspaceInput)
            isSupported = isa(workspaceInput,'tabular') && ~isempty(workspaceInput);
        end
        
        function setInputDataAndWidgetsToDefault(app)
            app.WorkspaceDropDown.Value = app.WorkspaceDropDownDefaultValue;
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
                app.VariableDD.Items = app.WorkspaceDropDown.WorkspaceValue.Properties.VariableNames;
                app.VariableDD.Enable = 'on';
                app.ExcludeCB.Value = isfield( app.State, app.VariableDD.Value ) && ...
                    app.State.(app.VariableDD.Value).Exclude;
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
            code = "filteredData = " + app.WorkspaceDropDown.Value + ";";
            modified = fields( app.State );
            for n = 1:length( modified )
                if app.State.(modified{n}).Exclude
                    code = code + newline + "filteredData(:,'" + modified{n} + "') = [];" ...
                        + "% " + app.State.(modified{n}).Comment;
                end
            end
            outputs = {'filteredData'};
        end
        
        function code = generateVisualizationScript(app)
            code = '';
            if hasInputData(app)
                if app.SummaryCB.Value == 1
                    code = "summary(" + app.WorkspaceDropDown.Value + "(:,'" + app.VariableDD.Value + "'))";
                end
                
                if app.HistogramCB.Value == 1
                    if ~isempty(code)
                        code = code + newline;
                    end
                    code = code + "histogram(" + app.WorkspaceDropDown.Value + "{:,'" + app.VariableDD.Value + "'})";
                end
            end
        end
        
        function summary = generateSummary(app)
            summary = "Filter `" + app.WorkspaceDropDown.Value + "` by univariate analysis";
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