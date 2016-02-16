classdef FindWordWorker < handle
    
    
    methods
        function  this = FindWordWorker()
            
        end
    end
    
    
    methods(Static)
        function dataCell = FindWord(modelName,searchWord,settingLookInside)
            dataCellBlockDialog = FindWordWorker.SearchBlockDialog(modelName,settingLookInside,searchWord);
            dataCellBlockName = FindWordWorker.SearchName(modelName,settingLookInside,searchWord,'block','BlockName');
            dataCellLineName = FindWordWorker.SearchName(modelName,settingLookInside,searchWord,'line','LineName');
            dataCell = [dataCellBlockDialog;dataCellBlockName;dataCellLineName];
        end
        function [modifiedWord,catchError] = ReplaceWord(currentData,searchWord,replaceWord)
            catchError = 0;
            modifiedWord = strrep(currentData{DataStruct.STRING}, searchWord, replaceWord);
            try
                set_param(currentData{DataStruct.HANDLE},currentData{DataStruct.PARAM},modifiedWord);
            catch ME
                catchError = 1;
                msgbox({'Replace Error: ',ME.message},'Word Replace Error','error');
            end
        end
    end
    
    methods(Access = private,Static)
        function dataCell = SearchBlockDialog(modelName,settingLookInside,searchWord)
            % init local parameter
            foundHandleHold = nan;
            foundTypeHold = [];
            skipNumber = 0;
            % Serach Block
            if(settingLookInside.Mask == 1)
                handle = find_system(modelName,'RegExp','on','FindAll','on','LookUnderMasks','all','BlockDialogParams',searchWord);
            else
                handle = find_system(modelName,'RegExp','on','FindAll','on','BlockDialogParams',searchWord);
            end
            %
            dataCell = cell(length(handle),DataStruct.MAX_NUMBER);
            for i=1:length(handle)
                % Search each block handle
                cellRowNumber = i - skipNumber;
                dataCell{cellRowNumber,DataStruct.TYPE} = 'BlockParams';
                dataCell{cellRowNumber,DataStruct.HANDLE} = handle(i);
                if(foundHandleHold ~= handle(i))
                    foundTypeHold = [];
                end
                dataCell{cellRowNumber,DataStruct.PATH} = getfullname(handle(i));
                if(~isempty(get_param(handle(i),'DialogParameters')))
                    blockParamName = fieldnames(get_param(handle(i),'DialogParameters'));
                else
                    blockParamName = [];
                end
                for j=1:length(blockParamName)
                    % Search in DialogParameters
                    if(~any(any(strcmp(blockParamName{j},foundTypeHold))))
                        dialogString = get_param(handle(i),blockParamName{j});
                        if(isnumeric(dialogString))
                            dialogString = num2str(dialogString);
                        end
                        if(isstruct(dialogString))
                            dialogString = '';
                        end
                        if(~isempty(regexp(dialogString,searchWord, 'once')))
                            dataCell{cellRowNumber,DataStruct.PARAM} = blockParamName{j};
                            dataCell{cellRowNumber,DataStruct.STRING} = dialogString;
                            foundTypeHold = [foundTypeHold;blockParamName(j)];
                            foundHandleHold = handle(i);
                            break;
                        end
                    end
                    if(j==length(blockParamName))
                        warning(['Cannnot find search word. Block Name = ',getfullname(handle(i))]);
                        skipNumber = skipNumber+1;
                    end
                end
            end
            dataCell = dataCell(1:(length(handle)-skipNumber),:);
        end
        function dataCell = SearchName(modelName,settingLookInside,searchWord,type,typeString)
            handle = find_system(modelName,'RegExp','on','FindAll', 'on', 'type', type,'Name',searchWord);
            dataCell = cell(length(handle),DataStruct.MAX_NUMBER);
            for i=1:length(handle)
                dataCell{i,DataStruct.TYPE} = typeString;
                dataCell{i,DataStruct.HANDLE} = handle(i);
                dataCell{i,DataStruct.PATH} = getfullname(handle(i));
                dataCell{i,DataStruct.PARAM} = 'Name';
                dataCell{i,DataStruct.STRING} = get_param(handle(i),'Name');
            end
        end
    end
    
    
end

