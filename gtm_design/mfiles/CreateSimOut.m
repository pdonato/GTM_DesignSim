function [SimOut] = CreateSimOut(logsout)
% Create structure from logged bus signal that is named SimOut.  All
% signals in SimOut must be the same sample time and rate.  SimOut signal
% must be inside a block on the top level of the diagram named
% "Format_Outputs".  

% $Id: CreateSimOut.m 4852 2013-08-06 22:12:54Z cox $

% Paste the commented code below into the Model StopFcn callback:

% if SimIn.Switches.LogData
%     if exist('logsout','var')
%         clear SimOut
%         SimOut = CreatSimOut(logsout);
%     else
%         Disp('No Log Data Variable')
%     end
% end
% clear logsout

% MATLAB 2016a COMPATIBILTIY ISSUES
% Starting in R2016a, you cannot log data in the ModelDataLogs format. 
% (https://www.mathworks.com/help/simulink/slref/simulink.modeldatalogs.html)
%
% Running GTM examples that record simulation results such as example4.m
% will generate a message: "The signal logging save format setting of
% ModelDataLogs will be ignored and signals marked for logging will be 
% logged in Dataset format. When you save the model, Simulink will 
% reconfigure the model use Dataset format for signal logging.", and
% Simulink will crash in the previous version of this function.
% 
% This version is an update that attempts to produce the same results of the
% original function. All example files run in Matlab 2016a with this 
% function version.

% Eugene Heim, NASA Langley Research Center
% Modified, david.e.cox NASA Langley Research Center
% Modified, pdonato@umich.edu University of Michigan

if(version('-release') ~= '2016a')
    temp = logsout.whos('all');% Get all field names
    index = find(strcmp('Timeseries',{temp(:).simulinkClass}));% Find signals
    for ii = 1:length(index)
         % Remove blockname hierarchy. Cut string before first occurance of SimOut 
        tmpstr=temp(index(ii)).name;
        VariableName = tmpstr([min(strfind(tmpstr,'SimOut')):end]);
        % Grab TimeSeries data, remove singletons and make time vector first dimension, if necessary
        eval(sprintf('data = squeeze(logsout.%s.Data);', temp(index(ii)).name));
        eval(sprintf('timelen = length(logsout.%s.Time);',temp(index(ii)).name))
        if ndims(data) > 2 && timelen>1 % for N-D matrices time is last dim, unless time is singleton.
            eval([VariableName, ' = permute(data,[ndims(data),[1:ndims(data)-1]]);'])
        else
            eval([VariableName,' = data;']);
        end
     end
else
    names = fieldnames(logsout.get(1).Values);
    for i = 1:length(names)
        if(eval(sprintf('isstruct(logsout.get(1).Values.%s);',char(names(i)))))
            eval(sprintf('subnames = fieldnames(logsout.get(1).Values.%s);',char(names(i))));
            eval(sprintf('SimOut.%s = struct;',char(names(i))));                   
            for ii = 1:length(subnames)
                if(eval(sprintf('isstruct(logsout.get(1).Values.%s.%s);',...
                        char(names(i)) ,char(subnames(ii)))))
                    eval(sprintf('subsubnames = fieldnames(logsout.get(1).Values.%s.%s);',...
                                char(names(i)), char(subnames(ii))));
                    eval(sprintf('SimOut.%s.%s = struct;',...
                                char(names(i)), char(subnames(ii))));     
                    for iii = 1:length(subsubnames)
                        SimOut = getData(SimOut, logsout, ...
                                        sprintf('%s.%s.%s',...
                                        char(names(i)), char(subnames(ii)),...
                                        char(subsubnames(iii))));
                    end
                else  
                    SimOut = getData(SimOut, logsout, sprintf('%s.%s',...
                                    char(names(i)), char(subnames(ii))));
                end
            end
        else            
            SimOut = getData(SimOut, logsout, sprintf('%s',char(names(i))));
        end
    end
end

    
function [SimOutf] = getData(SimOuti, logsout, string)

SimOutf = SimOuti;

eval(sprintf('data = squeeze(logsout.get(1).Values.%s.Data);',string));
eval(sprintf('timelen = length(logsout.get(1).Values.%s.Time);',string));                    
                    
if ndims(data) > 2 && timelen>1 % for N-D matrices time is last dim, unless time is singleton.
    eval(sprintf('SimOutf.%s  = permute(data,[ndims(data),[1:ndims(data)-1]]);',...
                string));                       
else
    eval(sprintf('SimOutf.%s  = data;',string));                    
end


    
