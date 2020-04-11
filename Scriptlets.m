classdef Scriptlets < handle
    properties (Access = public, Transient)
        UIFigure matlab.ui.Figure
        % Widget layout
        UIGrid matlab.ui.container.GridLayout
        % Widgets
        WorkspaceDropDown matlab.ui.control.internal.model.WorkspaceDropDown
        ScripletDD matlab.ui.control.DropDown
        Subscription
    end
    properties (Constant, Transient, Hidden)
        TextRowHeight double = 22; % Same as App Designer default
        DropDownWidth double = 150;
        WorkspaceDropDownDefaultValue = 'select variable'
    end
    
    methods (Access = public)
        
        function app = Scriptlets
            app.UIFigure = uifigure('Name','Scriptlets');
            app.UIGrid = uigridlayout(app.UIFigure,[1 4],'ColumnWidth',{'1x','2x','1x','1x'},...
                'RowHeight', num2cell(app.TextRowHeight*ones(1,1)));
            app.WorkspaceDropDown = matlab.ui.control.internal.model.WorkspaceDropDown('Parent',app.UIGrid);
            app.WorkspaceDropDown.FilterVariablesFcn = @(t)app.filterWorkspaceInputs(t);
            app.WorkspaceDropDown.ValueChangedFcn = @app.onUpdate;
            app.ScripletDD = uidropdown('Parent',app.UIGrid','Items',"");
            uibutton('Parent',app.UIGrid,'Text','Insert','ButtonPushedFcn',@app.onInsert);
            uibutton('Parent',app.UIGrid,'Text','Insert and Run','ButtonPushedFcn',@app.onInsertRun);
            app.onUpdate([],[]);
            app.Subscription = message.subscribe( '/liveapps/initializeRequest/*', @app.liveAppInserted );
        end
        
        function delete(app)
            message.unsubscribe( app.Subscription );
        end
        
        function onInsert(app,~,~)            

            richEditorApplication = com.mathworks.mde.liveeditor.LiveEditorApplication.getInstance;
            client = richEditorApplication.getLastActiveLiveEditorClient;
            rtc = client.getRichTextComponent;
            htmlComponent = rtc.getLightWeightBrowser();
            command = 'rtcInstance.actionDataService.executeAction("rtc_move_line_start")';        
            htmlComponent.executeScript( command );
            
            mlxPath = app.ScripletDD.Value;
            % relocate JSON version
            jsonPath = replace( mlxPath, ".mlx", ".json" );
            jsonPath = replace( jsonPath, fullfile( app.getResourceRoot, 'scriptlets' ), ...
                fullfile( app.getResourceRoot, 'json' ) );            
            
            loader = builder.JSONloader;
            loader.OldIDs = {};
            loader.NewIDs = {app.WorkspaceDropDown.Value};
            json = loader.loadFromTemplate( mlxPath,jsonPath );
            
            builder.insertLiveScriptSection(json);                        

            command = 'rtcInstance.actionDataService.executeAction("rtc_navigate_previous_section")';        
            htmlComponent.executeScript( command );

        end
        
        function onInsertRun(app,~,~)
            
            onInsert(app,[],[])
            
            richEditorApplication = com.mathworks.mde.liveeditor.LiveEditorApplication.getInstance;
            client = richEditorApplication.getLastActiveLiveEditorClient;
            rtc = client.getRichTextComponent;
            htmlComponent = rtc.getLightWeightBrowser();
            command = 'rtcInstance.actionDataService.executeAction("rtc_navigate_previous_section")';
            htmlComponent.executeScript( command );
            command = 'rtcInstance.actionDataService.executeAction("rtc_run_section_advance")';
            htmlComponent.executeScript( command );
                        
        end
        
        function onUpdate(app,varargin)
            if isempty(app.WorkspaceDropDown.WorkspaceValue)
                wvClass = 'data';
            else
                wvClass = class(app.WorkspaceDropDown.WorkspaceValue);
            end
            d = recursiveDir(fullfile(app.getResourceRoot,'scriptlets',wvClass),'*.mlx');
            app.ScripletDD.Items = {d.name};            
            app.ScripletDD.ItemsData = string({d.folder})+filesep+string({d.name});
        end
               
        function [code, outputs] = generateScript(app)
            code = '';
            outputs = {};
        end
        function code = generateVisualizationScript(app)
            code = "";
        end
        function summary = generateSummary(app)
            summary = '';
        end
        function state = getState(app)
            state = struct();
        end
        function setState(app, state)
        end
        function reset(app)
        end
        
        function isSupported = filterWorkspaceInputs(app,workspaceInput)
            isSupported = (isa(workspaceInput,'tabular') | isa(workspaceInput,'creditscorecard')) ...
                && ~isempty(workspaceInput);
        end
        
        function folder = getResourceRoot(~)
            p = currentProject;
            folder = fullfile( p.RootFolder, 'resources' );
        end
        
        function liveAppInserted(obj,src)
        for retry = 1:10
            app = matlab.internal.editor.LiveAppManager.getApp(src.editorId,src.appId);
            if ~isempty( app )
                break
            end
            pause(0.5)
        end
        if isa( app, 'BaseFilterReviewerTask' )
            app.WorkspaceDropDown.populateVariables;
            app.WorkspaceDropDown.Value = obj.WorkspaceDropDown.Value;
            doUpdate(app)
        end
        end
        
        
    end
    
end
