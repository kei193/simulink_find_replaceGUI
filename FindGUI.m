classdef(Sealed) FindGUI < handle
%%% FindGUI Class - GUI for Find and Replace in Simulink Model
%
% Start the GUI with FindGUI.start()
%
% or run the FindAndReplaceInModel.m script
    properties(Constant)
        guiPosition = [120 100 650 500];
        centerLine = 430;
        topMargin = 14;
        bottomMargin = 14;
        leftMargin = 10;
        panelWidth = 200;
        panelButtonWidth = 180;
    end
    
    properties(SetAccess = private)
        modelName;
        modelHandle = [];
        searchPlace = '';
        handlesGUI;
        findWorker;  % class instance
        currentCheckLine = 0;
        currentMaxLine = 0;
        dataCell;
        stateActiveHilite = 1;
    end
    
    %% singleton
    methods (Access = private)
        function this = FindGUI()
            
        end
    end
    methods (Static)
        function this = start()
            persistent localObj
            if isempty(localObj) || ~isvalid(localObj)
                localObj = FindGUI();
                localObj.handlesGUI = localObj.SetupLayout();
                localObj.findWorker = FindWordWorker();
            end
            localObj.modelName = bdroot;
            localObj.handlesGUI.editSearchPlace.String = localObj.modelName;
            localObj.InitializeState();
            localObj.VisibleOn(localObj.handlesGUI.fig);
            this = localObj;
        end
    end
    %% Callback function
    methods(Access = private)
        function ButtonFind_push(this,hObject,callbackdata)
            % Check and set model handle
            if(isempty(this.handlesGUI.editSearchPlace.String))
                catchError = 1;
                this.modelName = '';
                this.modelHandle = [];
                msgbox('Please set Search Place.','Search Place Error','error');
                return;
            end
            try
                this.modelName = bdroot(this.handlesGUI.editSearchPlace.String);
            catch ME
                catchError = 1;
                this.modelName = '';
                this.modelHandle = [];
                msgbox({'Search Place Error: ',ME.message},'Search Place Error','error');
                return;
            end
            this.searchPlace = this.handlesGUI.editSearchPlace.String;
            this.modelHandle = get_param(this.modelName,'handle');
            
            % Hilite off before Search
            try
                if(this.currentCheckLine > 0 && size(this.dataCell,1) > 0)
                    this.HiliteOff(this.dataCell{this.currentCheckLine,DataStruct.HANDLE});
                end
            catch
                % Nothing to do
            end
            
            % Find Start
            this.currentCheckLine = 0;
            this.currentMaxLine = 0;
            settingLookInside  = struct('Mask',this.handlesGUI.checkMask.Value);
            this.dataCell = this.findWorker.FindWord(this.searchPlace,this.handlesGUI.editSearchWord.String,...
                settingLookInside);
            if(size(this.dataCell,1) > 0)
                this.ResetTableSearch();
            else
                % no data
                msgbox(['''',this.handlesGUI.editSearchWord.String,''' not found.'],'Error','error');
                this.ChangeStateSomeButton('off');
                this.ClearTable(this.handlesGUI.tableSearch);
            end
        end
        
        function ButtonPrevious_push(this,hObject,callbackdata)
            if(isempty(this.dataCell))
                return;
            end
            previousCheckLine = this.currentCheckLine;
            this.currentCheckLine = this.currentCheckLine -1;
            if(this.currentCheckLine < 1)
                this.currentCheckLine = this.currentMaxLine;
            end
            if(previousCheckLine ~= 0)
                this.SetPointOffTable(previousCheckLine);
                this.HiliteOff(this.dataCell{previousCheckLine,DataStruct.HANDLE},this.stateActiveHilite);
            end
            this.SetPointOnTable(this.currentCheckLine);
            this.HiliteOn(this.dataCell{this.currentCheckLine,DataStruct.HANDLE},this.stateActiveHilite);
        end
        
        function ButtonNext_push(this,hObject,callbackdata)
            if(isempty(this.dataCell))
                return;
            end
            previousCheckLine = this.currentCheckLine;
            this.currentCheckLine = this.currentCheckLine + 1;
            if(this.currentCheckLine > this.currentMaxLine)
                this.currentCheckLine = 1;
            end
            if(previousCheckLine ~= 0)
                this.SetPointOffTable(previousCheckLine);
                this.HiliteOff(this.dataCell{previousCheckLine,DataStruct.HANDLE},this.stateActiveHilite);
            end
            this.SetPointOnTable(this.currentCheckLine);
            this.HiliteOn(this.dataCell{this.currentCheckLine,DataStruct.HANDLE},this.stateActiveHilite);
        end
        
        function ButtonReplace_push(this,hObject,callbackdata)
            this.stateActiveHilite = 1;
            currentData = this.dataCell(this.currentCheckLine,:);
            [modifiedWord,catchError] = this.findWorker.ReplaceWord(currentData,this.handlesGUI.editSearchWord.String,this.handlesGUI.editReplaceWord.String);
            if(~catchError)
                this.SetStringTable(this.currentCheckLine,modifiedWord);
                this.ButtonNext_push([],[]);
            end
        end
        
        function ButtonReplaceAll_push(this,hObject,callbackdata)
            this.stateActiveHilite = 0;
            startLine = this.currentCheckLine;
            this.HiliteOff(this.dataCell{this.currentCheckLine,DataStruct.HANDLE},1);
            while(1)
                currentData = this.dataCell(this.currentCheckLine,:);
                [modifiedWord,catchError] = this.findWorker.ReplaceWord(currentData,this.handlesGUI.editSearchWord.String,this.handlesGUI.editReplaceWord.String);
                if(catchError)
                    break;
                end
                this.SetStringTable(this.currentCheckLine,modifiedWord);
                this.ButtonNext_push([],[]);
                if(this.currentCheckLine == startLine)
                    msgbox('All items replaced.','Finished');
                    break;
                end
            end
            this.stateActiveHilite = 1;
            this.HiliteOn(this.dataCell{this.currentCheckLine,DataStruct.HANDLE},1);
        end
        function editSearchPlace_edit(this,hObject,callbackdata)
            this.InitializeState();
        end
        
        function fig_Close(this,hObject,callbackdata)
            try
                previousCheckLine = this.currentCheckLine;
                if(previousCheckLine ~= 0)
                    this.HiliteOff(this.dataCell{previousCheckLine,DataStruct.HANDLE})
                end
            catch
                delete(gcf);
            end
            delete(gcf);
            delete(this);
        end
    end
    
    methods(Access = private)
        %% Layout
        function [handlesGUI] = SetupLayout(this)
            handlesGUI.fig = figure('Visible','off',...
                'Resize','off',...
                'Units','points',...
                'Position',this.guiPosition,...
                'Tag','fig',...
                'ToolBar','none',...
                'MenuBar','none',...
                'Name','SearchGUI',...
                'NumberTitle','off',...
                'CloseRequestFcn',@this.fig_Close);
            
            handlesGUI.tableSearch = uitable('Parent',handlesGUI.fig,...
                'Units','points',...
                'FontName','Arial',...
                'FontSize',10,...
                'Position',[this.leftMargin,this.bottomMargin,this.centerLine-10-this.leftMargin,this.guiPosition(4)-this.topMargin-this.bottomMargin],...
                'Tag','tableSearch',...
                'Enable','inactive');
            %%
            handlesGUI.panelSearchPlace = uipanel('Parent',handlesGUI.fig,...
                'Units','points',...
                'Position',[this.centerLine,this.guiPosition(4)-this.topMargin-50,this.panelWidth,50],...
                'BorderType','none',...
                'Tag','panelSearchPlace');
            
            handlesGUI.editSearchPlace = uicontrol('Style','edit','Parent',handlesGUI.panelSearchPlace,...
                'Units','points',...
                'Position',[5,5,handlesGUI.panelSearchPlace.Position(3)-10,20],...
                'HorizontalAlignment','left',...
                'FontName','Arial',...
                'FontSize',12,...
                'Callback',@this.editSearchPlace_edit,...
                'Tag','editSearchPlace');
            
            handlesGUI.textSearchPlace = uicontrol('Style','text','Parent',handlesGUI.panelSearchPlace,...
                'Units','points',...
                'Position',[5, handlesGUI.editSearchPlace.Position(4)+ handlesGUI.editSearchPlace.Position(2)+3,...
                handlesGUI.panelSearchPlace.Position(3)-10,15],...
                'HorizontalAlignment','left',...
                'FontName','Arial',...
                'FontSize',12,...
                'String','Search Place:',...
                'Tag','textSearchPlace');
            % panelSearchWord Setting
            handlesGUI.panelSearchWord = uipanel('Parent',handlesGUI.fig,...
                'Units','points',...
                'Position',[this.centerLine,handlesGUI.panelSearchPlace.Position(2)-10-100,this.panelWidth,100],...
                'Tag','panelSearchWord');
            
            handlesGUI.editReplaceWord = uicontrol('Style','edit','Parent',handlesGUI.panelSearchWord,...
                'Units','points',...
                'Position',[5,5,handlesGUI.panelSearchWord.Position(3)-10,20],...
                'HorizontalAlignment','left',...
                'FontName','Arial',...
                'FontSize',12,...
                'Tag','editReplaceWord');
            
            handlesGUI.textReplaceWord = uicontrol('Style','text','Parent',handlesGUI.panelSearchWord,...
                'Units','points',...
                'Position',[5,handlesGUI.editReplaceWord.Position(4)+handlesGUI.editReplaceWord.Position(2)+3,...
                handlesGUI.panelSearchWord.Position(3)-10,15],...
                'HorizontalAlignment','left',...
                'FontName','Arial',...
                'FontSize',12,...
                'String','Replace Word:',...
                'Tag','textReplaceWord');
            
            handlesGUI.editSearchWord = uicontrol('Style','edit','Parent',handlesGUI.panelSearchWord,...
                'Units','points',...
                'Position',[5,handlesGUI.textReplaceWord.Position(4)+handlesGUI.textReplaceWord.Position(2)+10,...
                handlesGUI.panelSearchWord.Position(3)-10,20],...
                'HorizontalAlignment','left',...
                'FontName','Arial',...
                'FontSize',12,...
                'Tag','editSearchWord');
            
            handlesGUI.textSearchWord = uicontrol('Style','text','Parent',handlesGUI.panelSearchWord,...
                'Units','points',...
                'Position',[5, handlesGUI.editSearchWord.Position(4)+ handlesGUI.editSearchWord.Position(2)+3,...
                handlesGUI.panelSearchWord.Position(3)-10,15],...
                'HorizontalAlignment','left',...
                'FontName','Arial',...
                'FontSize',12,...
                'String','Search Word:',...
                'Tag','textSearchWord');
            
            % panel lookInside Setting
            handlesGUI.panelLookInside = uipanel('Parent',handlesGUI.fig,...
                'Units','points',...
                'FontSize',11,...
                'Title','Look Inside',...
                'Position',[this.centerLine+5,handlesGUI.panelSearchWord.Position(2)-15-50,this.panelButtonWidth,50],...
                'Tag','panelLookInside'); % 'BorderType','none',...
            
            handlesGUI.checkMask = uicontrol('Parent',handlesGUI.panelLookInside,...
                'Style','checkbox',...
                'Units','points',...
                'Position',[10,5,130,30],...
                'HorizontalAlignment','center',...
                'FontName','Arial',...
                'FontSize',13,...
                'Value',0,...
                'String','Masked System',...
                'Tag','checkMask');
            
            % panelSearchButton Setting
            handlesGUI.panelSearchButton = uipanel('Parent',handlesGUI.fig,...
                'Units','points',...
                'Position',[this.centerLine+5,handlesGUI.panelLookInside.Position(2)-15-160,this.panelButtonWidth,160],...
                'Tag','panelSearchButton'); % 'BorderType','none',...
            
            handlesGUI.buttonReplaceAll = uicontrol('Parent',handlesGUI.panelSearchButton,...
                'Units','points',...
                'Position',this.CalcCenterXPosition(0,5,130,30,this.panelButtonWidth),...
                'HorizontalAlignment','center',...
                'FontName','Arial',...
                'FontSize',13,...
                'String','Replace All',...
                'Tag','buttonReplaceAll',...
                'Callback',@this.ButtonReplaceAll_push);
            
            handlesGUI.buttonNext = uicontrol('Parent',handlesGUI.panelSearchButton,...
                'Units','points',...
                'Position',this.CalcRightXPosition(0,handlesGUI.buttonReplaceAll.Position(2)+handlesGUI.buttonReplaceAll.Position(4)+10,...
                60,30,this.panelButtonWidth/2-5),...
                'HorizontalAlignment','center',...
                'FontName','Arial',...
                'FontSize',13,...
                'String','Next',...
                'Tag','buttonNext',...
                'Callback',@this.ButtonNext_push);
            
            handlesGUI.buttonPrevious = uicontrol('Parent',handlesGUI.panelSearchButton,...
                'Units','points',...
                'Position',this.CalcRightXPosition(0,handlesGUI.buttonNext.Position(2)+handlesGUI.buttonNext.Position(4)+10,...
                60,30,this.panelButtonWidth/2-5),...
                'HorizontalAlignment','center',...
                'FontName','Arial',...
                'FontSize',13,...
                'String','Previous',...
                'Tag','buttonnPrevious',...
                'Callback',@this.ButtonPrevious_push);
            
            handlesGUI.buttonReplace = uicontrol('Parent',handlesGUI.panelSearchButton,...
                'Units','points',...
                'Position',[this.panelButtonWidth/2+5,handlesGUI.buttonReplaceAll.Position(2)+handlesGUI.buttonReplaceAll.Position(4)+10,...
                60,70],...
                'HorizontalAlignment','center',...
                'FontName','Arial',...
                'FontSize',13,...
                'String','Replace',...
                'Tag','buttonReplace',...
                'Callback',@this.ButtonReplace_push);
            
            handlesGUI.buttonFind = uicontrol('Parent',handlesGUI.panelSearchButton,...
                'Units','points',...
                'Position',this.CalcCenterXPosition(0,handlesGUI.buttonPrevious.Position(2)+handlesGUI.buttonPrevious.Position(4)+10,...
                130,30,this.panelButtonWidth),...
                'HorizontalAlignment','center',...
                'FontName','Arial',...
                'FontSize',13,...
                'String','Find',...
                'Tag','buttonFind',...
                'Callback',@this.ButtonFind_push);
        end
        %% private function
        function InitializeState(this)
            this.modelHandle = [];
            this.searchPlace = '';
            % Hilite off before clear table
            try
                if(this.currentCheckLine > 0 && size(this.dataCell,1) > 0)
                    this.HiliteOff(this.dataCell{this.currentCheckLine,DataStruct.HANDLE});
                end
            catch
                % Nothing to do
            end
            %
            this.ChangeStateSomeButton('off');
            this.currentCheckLine = 0;
            this.currentMaxLine = 0;
            this.ClearTable(this.handlesGUI.tableSearch);
        end
        function ResetTableSearch(this)
            this.handlesGUI.tableSearch.RowName = [];
            this.currentMaxLine = size(this.dataCell,1);
            this.handlesGUI.tableSearch.Data = [cell(this.currentMaxLine,1),this.dataCell(:,[DataStruct.TYPE,DataStruct.PATH,DataStruct.PARAM,DataStruct.STRING])];
            this.handlesGUI.tableSearch.ColumnName = {'','Type','Path','Param','String'};
            %
            this.handlesGUI.tableSearch.Units = 'pixels';
            pixelPosition = this.handlesGUI.tableSearch.Position;
            this.handlesGUI.tableSearch.Units = 'points';
            pointsPosition = this.handlesGUI.tableSearch.Position;
            ratioPointsToPixel = pixelPosition(3)/pointsPosition(3);
            %
            columnPointsWidth =  [18,70,120,80,0];
            columnPixelWidth =  columnPointsWidth * ratioPointsToPixel;
            columnPixelWidth(length(columnPixelWidth)) = pixelPosition(3)-sum(columnPixelWidth);
            columnPixelWidth = round(columnPixelWidth);
            this.handlesGUI.tableSearch.ColumnWidth = {columnPixelWidth(1) columnPixelWidth(2) columnPixelWidth(3) columnPixelWidth(4) columnPixelWidth(5)};
            %
            this.ButtonNext_push([],[]);
            this.ChangeStateSomeButton('on');
        end
        
        
        function ChangeStateSomeButton(this,state)
            this.handlesGUI.buttonReplaceAll.Enable = state;
            this.handlesGUI.buttonReplace.Enable = state;
            this.handlesGUI.buttonPrevious.Enable = state;
            this.handlesGUI.buttonNext.Enable = state;
        end
        
        function SetPointOnTable(this,lineNumber)
            this.handlesGUI.tableSearch.Data{lineNumber,1} = ' X';
        end
        
        function SetPointOffTable(this,lineNumber)
            this.handlesGUI.tableSearch.Data{lineNumber,1} = '';
        end
        
        function SetStringTable(this,lineNumber,string)
            this.handlesGUI.tableSearch.Data{lineNumber,5} = string;
        end
        function ClearTable(this,tableHandle)
            tableHandle.ColumnName = {};
            tableHandle.Data = {};
            this.dataCell = [];
        end
    end
    %% static function
    methods(Static)
        function position = CalcCenterXPosition(x,y,width,height,maxWidth)
            position = [0 0 0 0];
            center = maxWidth/2+x;
            position(1) = center-width/2;
            position(3) = width;
            position(2) = y;
            position(4) = height;
        end
        function position = CalcRightXPosition(x,y,width,height,maxWidth)
            position = [0 0 0 0];
            position(1) = maxWidth-width+x;
            position(3) = width;
            position(2) = y;
            position(4) = height;
        end
        
        function VisibleOn(handleName)
            handleName.Visible = 'on';
        end
        
        function HiliteOff(blockHandle,varargin)
            if(isempty(varargin))
                hilite_system(blockHandle,'none');
                return;
            end
            if(varargin{1} == 1)
                hilite_system(blockHandle,'none');
            end
        end
        function HiliteOn(blockHandle,varargin)
            if(isempty(varargin))
                hilite_system(blockHandle);
                return;
            end
            if(varargin{1} == 1)
                hilite_system(blockHandle);
            end
        end
        
    end
    
end

