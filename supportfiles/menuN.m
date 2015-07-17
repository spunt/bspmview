function choice = menuN(mtitle, options, Opt)
%% MENUN An alternative to Matlab's menu function with added functionality
%   
% Syntax:
%  choice = MENUN(mtitle, options)
%  choice = MENUN(mtitle, options, Opt)
%
% Input:
%  mtitle   - [string]  - Menu window title 
%  options  - [various] - Multifunctional: 
%     (b) [cellstr]: Buttons are created with labels as in the cell array.   
%     ex. options = {'option1', 'option2', ... },
%     OR: options = 'b|option1|option2|...', results in:
%           |--mtitle---------|
%           |  [  option1  ]  |
%           |  [  option2  ]  |
%           |  [    ...    ]  |
%           |-----------------|
%     (r) [string && options(1:2) == 'r|' ]: 
%           Radiobuttons for single selection, separate options with |:      
%           Start an option string part with ¤ to have it default toggled on.    
%     ex. options = 'r|option1|¤option2|...', results in:
%           |--mtitle--------|
%           |  O  option1    |
%           |  x  option2    |
%           |  O     ...     |
%           |  [    OK    ]  |
%           |----------------|
%     (p) [string && options(1:2) == 'p|' ]: 
%           Popupmenu for single selection, separate options with |:      
%           Start an option string part with ¤ to set it default toggled on.    
%     ex. options = 'p|option1|option2|...', results in:
%           |--mtitle--------|
%           |  | optionX |v| |        
%           |  [    OK     ] |
%           |----------------|
%     (x) [string && options(1:2) == 'x|' ]: 
%           Checkboxes with mutliselection, separate options with |:      
%           Start an option string part with ¤ to set it default toggled on.    
%     ex. options = 'x|option1|¤option2|...', results in:
%           |--mtitle--------|
%           | | | options    |
%           | |x| options    |
%           | | |    ...     |
%           | [    OK     ]  |
%           |----------------|
%     (l) [string]: Listbox with mutliselection, separate options with |.    
%           Start an option string part with ¤ to set it default toggled on.    
%     ex. options = 'option1|option2|...', results in: 
%           |--mtitle----------|
%           |  |  option1  |   |
%           |  |  option2  |   |
%           |  |    ...    |   |
%           |  [    OK     ]   |
%           |------------------|
%     (s) [double, length == 2]: Slider is created from initial to final value.
%      or [double, length == 3]: Same slider but with third value as default
%     ex. options = [0,7,3.5], results in: 
%           |--mtitle--------------|
%           | |<|====[]====|>| 3.5 |
%           | [        OK        ] |
%           |----------------------|
%     (t) [string && options(1:2) == 't|' ]:
%           Input text box, returns string inputed into text box. 
%     ex. options = 't|my text|the second line', results in: 
%           |--mtitle--------------|
%           | | my text          | |
%           | | the second line  | |
%           | [        OK        ] |
%           |----------------------|
%     (*) [cell-Nx2]: Multiple "choice groups" in the same menu:
%           Each cell element should have any of the syntaxes as above. 
%           A gui menu window is then created with all of these selections of 
%           choices. The second column of the cell should contain a subtitle for
%           the corresponding choice group. If the second input is empty no 
%           subtitle is printed. The pushbutton type menu group (b) is changed
%           to a popupmenu selection (p) instead of pushbuttons. Example:
%     ex. options = {'p|option1|option2|...','subititle1';...
%                    'options2 part1|options2 part2','subtitle2';...
%                    [0,7,3.5],'subtitle3'}, results in: 
%           |--mtitle---------------|
%           |  subtitle1            |
%           |  | options1     |v|   |        % Popupmenu (instead of buttons)
%           |  subtitle2            |
%           |  | options2 part1 |   |        % Listbox
%           |  | options2 part2 |   |
%           |  subtitle3            |
%           |  |<|===[]===|>| 3.5   |        % Slider
%           |  [       OK       ]   |
%           |-----------------------|
%  Opt    - [struct]  - Structure containing options for font name, size etc.
%
% Output:
%  choice - [double OR cell IF multiple options] - selected option(s)
%     (a) If multiple selection groups are used as by input of type (5) choice 
%         is a cell array equal with length == number of rows in options.
%     (b) If an selection type allows multiselection the choice array
%         contains all selected options, (array instead of scalar).
%     (c) If any option group has no values selected its value is -1.
%  
% Example of usage with input of type (*):
%  choice = menuN('menuN',...
%        {  [1,2,1.75], 'Loss Parameter:';   ...
%           'r|optA1|op2|¤defasdfasdfa','Operating Model:';...
%           'p|a|b|¤c','Select a, b or c:';...
%           'x|Use1|¤Use2|¤Use3','Use methods:';...
%           't|first test|all is ok','Comment:'});
%  If OK is selected directly we are returned the following choice:
%   choice = 
%        [    1.7500]
%        [         3]
%        [         3]
%        [2x1 double] % == [2;3];
%  Note, calling menuN without any input invokes the above call to menuN.
%
% See also menu, inputdlg, uicontrol

%   Created by: Johan Winges
%   $Revision: 1.0$  $Date: 2013-10-20 00:00:00$
%   $Revision: 1.1$  $Date: 2014-10-21 11:00:00$
%     -Fixed R2014b slider update, additional help comments


%% Set up default Opt struct:
defOpt = struct();
defOpt.defaultOptionSymbol    = '*'; % ¤ in original
defOpt.fontName               = 'Arial';
defOpt.subtitleFontSize       = 13;
defOpt.subtitleFontWeight     = 'Bold';
defOpt.pushbuttonFontSize     = 12;
defOpt.popupmenuFontSize      = 11;
defOpt.radiobuttonFontSize    = 12;
defOpt.checkboxFontSize       = 12;
defOpt.listboxFontSize        = 11;
defOpt.checkboxFontSize       = 12;
defOpt.sliderFontSize         = 11;
defOpt.sliderStepsFraction    = [0.01, 0.10];
defOpt.okButtonLabel          = 'OK';
defOpt.cancelButtonLabel      = 'Cancel'; 
defOpt.pixelHeigthUIcontrol   = 20;
defOpt.pixelPaddingHeigth     = [8,   5]; % [bottom/top, between uicontrols]
defOpt.pixelPaddingWidth      = [6,   4]; % [bottom/top, between uicontrols]
defOpt.InsteadOfPushUse       = 'p';      % p = popupmenu, r = radiobuttons

% Check for opt input:
if nargin == 0
   % Showcase of possible options:
   mtitle   = 'menuN';
   options  = {  [1,2,1.75], 'Loss Parameter:';   ...
          'r|optA1|op2|*defasdfasdfa','Operating Model:';...
          'p|a|b|*c','Select a, b or c:';...
          'x|Use1|*Use2|*Use3','Use methods:';...
          't|first test|all is ok','Comment:'};
   Opt      = defOpt;
elseif nargin == 3
   if isstruct(Opt)
      Opt = setdefaultsstruct(Opt,defOpt);
   else
      error('menuN:input:Third input is not a structure.')
   end
elseif nargin == 2
   Opt      = defOpt;
else
   error('menuN:input:Insufficent inputs, menuN need mtitle and options.')
end

% Set up a large amount of padding options []:
extentWidthUniversal          = 200;   % It is increased/decreased when necessary
extentWidthUniversalMin       = 195;   % Minimum allowed width of uicontrols

extentWidthSliderMin          = 100;
extentHeigthTextInPadding     = 0;
extentHeigthTextPadding       = 2;
extentWidthTextInPadding      = 40;

extentHeigthPushbuttonPadding    = 4;
extentHeigthPushbuttonInPadding  = 2;
extentWidthPushbuttonInPadding   = 10;

extentWidthPopupmenuInPadding = 12;
extentHeightPopupmenuPadding  = 0;

extentHeigthCheckboxInPadding = 2;
extentHeigthCheckboxPadding   = 1;
extentWidthCheckboxInPadding  = 20;

extentHeigthRadiobuttonInPadding = 2;
extentHeigthRadiobuttonPadding   = 1;
extentWidthRadiobuttonInPadding  = 20;

extentWidthGroupPadding       = 15;
extentHeightTitlePadding      = -Opt.pixelPaddingHeigth(2);

thewindowstyle = 'normal'; % 'modal'

%% Create a figure
% We do not worry about its size and position yet:
% hFig           = figure('Name',mtitle,'WindowStyle','modal','NumberTitle','off');
hFig           = figure('Name',mtitle,'Toolbar','none','Menubar','none','NumberTitle','off', 'WindowStyle', thewindowstyle);

% Set initial necessary width that all uicontrols must be [pixels]:
tmpMinimumSize                = [extentWidthUniversalMin, 15];

% Assume that a OK button is necessary:
flagMakeOkButton              = true;

%% Check what type of options input we have
if iscellstr(options) && isvector(options) && ...
      isempty(strfind(options{1},'|'))                      % Input type (b)
   % Fake the input to look like type (*):
   options                    = {options};
   % Create empty subtitles (it is not printed if empty):
   subtitles                  = {''};
   % Check Okbutton is unnecessary:
   flagMakeOkButton        = false;
elseif iscell(options) && size(options,2) == 2              % Input type (*)   
   % Make all (eventual) pusbutton group become popup
   Opt.usePopupInsteadOfPush  = true;
   % Collect titles:
   subtitles                  = options(:,2);
   % Create single array of options:
   options                    = options(:,1);
else                                                        % Rest Input types
   % Fake the input to look like type (5):
   options                    = {options};
   % Create empty title (it is not printed if empty):
   subtitles                  = {''};                              
end

% Check number of options groups:
numOptionsGroups  = length(options);

% Print uicointrol components start from the bottom of the list:
tmpCurrentPosition  = [Opt.pixelPaddingWidth(1),  Opt.pixelPaddingHeigth(1)];

%% Print OK button
if flagMakeOkButton
   tmpPosition   = [tmpCurrentPosition, tmpMinimumSize];
   hOK            = uicontrol( ...
      'Style',       'Pushbutton',...
      'String',      Opt.okButtonLabel,...
      'FontName',    Opt.fontName, ...
      'FontSize',    Opt.pushbuttonFontSize, ...
      'Position',    tmpPosition, ...
      'Callback',    {@closeMenuFigure,hFig,'OK'});

   % Check actual necessary size:
   tmpExtent = get(hOK,'extent');
   extentWidthUniversal   = max(extentWidthUniversal, ...
      tmpExtent(3)+extentWidthPushbuttonInPadding);
   tmpNewSize  = [extentWidthUniversal, ...
      tmpExtent(4) + extentHeigthPushbuttonInPadding];
   % Update size of uicontrol:
   set(hOK,'Position',[tmpCurrentPosition,tmpNewSize]);   
   % Update current position Y coordinate:
   tmpCurrentPosition(2) = tmpCurrentPosition(2) + tmpNewSize(2) + ...
      extentHeigthPushbuttonPadding + Opt.pixelPaddingHeigth(2);
end

%% Print Options depending on input type:
% Start at the last options group:
hOptions       = cell(numOptionsGroups,1);
hSubtitle      = cell(numOptionsGroups,1);
for idxOptions = numOptionsGroups:-1:1   
   % Get current options:
   tmpOptions = options{idxOptions};
   
   % Get current position:
   tmpPosition   = [tmpCurrentPosition, tmpMinimumSize];
   
   %% Print for Options of Input type (b)
   if iscellstr(tmpOptions)                                    
      if numOptionsGroups > 1  % popupmenu || radiobuttons
         % Rework tmpOptions to a popupmenustring:
         tmpSeparators     = repmat({'|'},1,length(tmpOptions));
         tmpSeparators{1}  = sprintf('%s|',Opt.InsteadOfPushUse);
         tmpOptions        = cat(1,tmpSeparators,tmpOptions);
         tmpOptions        = cat(2,tmpOptions{:});
      else
         % Create pushbuttons:
         numObjects        = length(tmpOptions);
         hObjects          = cell(numObjects,1);
         
         % Start at the last button:
         for idxObjects     = numObjects:-1:1
            
            % Create uicontrol:
            hObjects{idxObjects} = uicontrol( ...
               'Style',       'pushbutton',...
               'String',      ['A' tmpOptions{idxObjects}],... % A trick.
               'FontName',    Opt.fontName, ...
               'FontSize',    Opt.pushbuttonFontSize, ...
               'Position',    tmpPosition, ...
               'Callback',    {@closeMenuFigure,hFig,idxObjects});
      
            % Check actual necessary size:
            tmpExtent = get(hObjects{idxObjects},'extent');
            extentWidthUniversal   = max(extentWidthUniversal, ...
               tmpExtent(3)+extentWidthPushbuttonInPadding);
            tmpNewSize  = [extentWidthUniversal, ...
               tmpExtent(4) + extentHeigthPushbuttonInPadding];
            % Update size of uicontrol:
            set(hObjects{idxObjects},'Position',[tmpCurrentPosition,tmpNewSize]);   
            % Update current position Y coordinate:
            tmpCurrentPosition(2) = tmpCurrentPosition(2) + tmpNewSize(2) + ...
               Opt.pixelPaddingHeigth(2);
            
            % Correct button label: (A trick to get all buttons heights same). 
            set(hObjects{idxObjects},'String',tmpOptions{idxObjects});      
         end
         
         % Save handles:
         hOptions{idxOptions} = hObjects;
      end
   end   
   %% Print for Options of Input type (x)
   if ischar(tmpOptions) && strcmp(tmpOptions(1:2),'x|')       
      % Remove marker from charachter line:
      tmpOptions     = tmpOptions(3:end);
      tmpPipeIdx     = strfind(tmpOptions,'|');
      tmpMarkedIdx   = strfind(tmpOptions,Opt.defaultOptionSymbol);
      tmpOptions(tmpMarkedIdx)   = [];
      % Split string into cellstr array at |:
      numObjects     = length(tmpPipeIdx)+1;
      tmpPipeIdxExt  = [0,strfind(tmpOptions,'|'),length(tmpOptions)+1];
      tmpLables      = arrayfun(@(idxObjects) tmpOptions(...
         tmpPipeIdxExt(idxObjects)+1:tmpPipeIdxExt(idxObjects+1)-1),...
         1:numObjects,'un',0);      
      
      % Check if we have a defualt selection on:
      if ~isempty(tmpMarkedIdx)
         tmpValue = arrayfun(@(markIdx) emptyIsZero(...
            find(markIdx >= tmpPipeIdx,1,'last')),tmpMarkedIdx) + 1;  
      else
         tmpValue = 0;
      end
      
      % Create uipanel:
      hPanel               = uipanel( ...
         'Units',       'pixels', ...
         'Position',    tmpPosition);
      
      % Create radiobuttons:
      hObjects             = cell(numObjects,1);

      tmpCurrentPositionChild = [Opt.pixelPaddingWidth(2),Opt.pixelPaddingHeigth(2)];
      tmpPositionChild     = [tmpCurrentPositionChild,tmpMinimumSize];
      tmpExtentHeightTotal = Opt.pixelPaddingHeigth(2);
      tmpExtentWidthMaxChild = 0; 
      
      % Start at the last button:
      for idxObjects     = numObjects:-1:1
         
         % Create uicontrol:
         hObjects{idxObjects} = uicontrol( ...
            'Style',       'checkbox',...
            'Parent',      hPanel, ...
            'String',      ['A' tmpLables{idxObjects}],...
            'FontName',    Opt.fontName, ...
            'FontSize',    Opt.checkboxFontSize, ...
            'Position',    tmpPositionChild,...
            'Userdata',    idxObjects);
         % Check actual necessary size:
         tmpExtent = get(hObjects{idxObjects},'extent');
         tmpExtentWidthMaxChild   = max(tmpExtentWidthMaxChild, ...
            tmpExtent(3)+extentWidthCheckboxInPadding);
         tmpNewSize  = [tmpExtentWidthMaxChild, ...
            tmpExtent(4) + extentHeigthCheckboxInPadding];
         % Update size of uicontrol:
         set(hObjects{idxObjects},'Position',[tmpCurrentPositionChild,tmpNewSize]);   
         % Update current position Y coordinate:
         tmpCurrentPositionChild(2) = tmpCurrentPositionChild(2) + tmpNewSize(2) + ...
            extentHeigthCheckboxPadding + Opt.pixelPaddingHeigth(2);
         tmpExtentHeightTotal = tmpExtentHeightTotal + tmpNewSize(2) + ...
            extentHeigthCheckboxPadding + Opt.pixelPaddingHeigth(2);
         % Correct button label: (A trick to get all buttons heights same). 
         set(hObjects{idxObjects},'String',tmpLables{idxObjects});     
         
         % Set as marked if default:
         if ismember(idxObjects,tmpValue)
            set(hObjects{idxObjects},'Value',1);
         end
         
      end
            
      % Update size of hPanel:
      extentWidthUniversal   = max(extentWidthUniversal, ...
         tmpExtentWidthMaxChild+extentWidthGroupPadding+Opt.pixelPaddingWidth(2));
      set(hPanel,'Position',[tmpCurrentPosition, ...
         extentWidthUniversal,tmpExtentHeightTotal])      
      % Update current position Y coordinate:
      tmpCurrentPosition(2) = tmpCurrentPosition(2) + tmpExtentHeightTotal + ...
         + Opt.pixelPaddingHeigth(2);
            
      % Save handle to group:
      hOptions{idxOptions} = hPanel;
      
   %% Print for Options of Input type (r)
   elseif ischar(tmpOptions) && strcmp(tmpOptions(1:2),'r|')   
      % Remove marker from charachter line:
      tmpOptions     = tmpOptions(3:end);
      tmpPipeIdx     = strfind(tmpOptions,'|');
      tmpMarkedIdx   = strfind(tmpOptions,Opt.defaultOptionSymbol);
      tmpOptions(tmpMarkedIdx)   = [];
      % Split string into cellstr array at |:
      numObjects     = length(tmpPipeIdx)+1;
      tmpPipeIdxExt  = [0,strfind(tmpOptions,'|'),length(tmpOptions)+1];
      tmpLables      = arrayfun(@(idxObjects) tmpOptions(...
         tmpPipeIdxExt(idxObjects)+1:tmpPipeIdxExt(idxObjects+1)-1),...
         1:numObjects,'un',0);
      
      % Create uibuttongroup:
      hGroup               = uibuttongroup( ...
         'Units',       'pixels', ...
         'Position',    tmpPosition);
      
      % Create radiobuttons:
      hObjects             = cell(numObjects,1);

      tmpCurrentPositionChild = [Opt.pixelPaddingWidth(2),Opt.pixelPaddingHeigth(2)];
      tmpPositionChild     = [tmpCurrentPositionChild,tmpMinimumSize];
      tmpExtentHeightTotal = Opt.pixelPaddingHeigth(2);
      tmpExtentWidthMaxChild = 0; 
      
      % Start at the last button:
      for idxObjects     = numObjects:-1:1
         
         % Create uicontrol:
         hObjects{idxObjects} = uicontrol( ...
            'Style',       'radiobutton',...
            'Parent',      hGroup, ...
            'String',      ['A' tmpLables{idxObjects}],...
            'FontName',    Opt.fontName, ...
            'FontSize',    Opt.radiobuttonFontSize, ...
            'Position',    tmpPositionChild,...
            'Userdata',    idxObjects);
         % Check actual necessary size:
         tmpExtent = get(hObjects{idxObjects},'extent');
         tmpExtentWidthMaxChild   = max(tmpExtentWidthMaxChild, ...
            tmpExtent(3)+extentWidthRadiobuttonInPadding);
         tmpNewSize  = [tmpExtentWidthMaxChild, ...
            tmpExtent(4) + extentHeigthRadiobuttonInPadding];
         % Update size of uicontrol:
         set(hObjects{idxObjects},'Position',[tmpCurrentPositionChild,tmpNewSize]);   
         % Update current position Y coordinate:
         tmpCurrentPositionChild(2) = tmpCurrentPositionChild(2) + tmpNewSize(2) + ...
            extentHeigthRadiobuttonPadding + Opt.pixelPaddingHeigth(2);
         tmpExtentHeightTotal = tmpExtentHeightTotal + tmpNewSize(2) + ...
            extentHeigthRadiobuttonPadding + Opt.pixelPaddingHeigth(2);
         % Correct button label: (A trick to get all buttons heights same). 
         set(hObjects{idxObjects},'String',tmpLables{idxObjects});     
         
      end
            
      % Update size of hGroup:
      extentWidthUniversal   = max(extentWidthUniversal, ...
         tmpExtentWidthMaxChild+extentWidthGroupPadding+Opt.pixelPaddingWidth(2));
      set(hGroup,'Position',[tmpCurrentPosition, ...
         extentWidthUniversal,tmpExtentHeightTotal])      
      % Update current position Y coordinate:
      tmpCurrentPosition(2) = tmpCurrentPosition(2) + tmpExtentHeightTotal + ...
         + Opt.pixelPaddingHeigth(2);
      
      % Check if we have a defualt selection on:
      if ~isempty(tmpMarkedIdx)
         tmpValue = arrayfun(@(markIdx) emptyIsZero(...
            find(markIdx >= tmpPipeIdx,1,'last')),tmpMarkedIdx) + 1;  
         if length(tmpValue) > 1
            warning('menuN:popupmenu',...
               'Only one selected element is valid as default.');
            tmpValue = tmpValue(1);
         end
         set(hGroup,'SelectedObject',hObjects{tmpValue})
      else
         set(hGroup,'SelectedObject',[])
      end
      
      % Save handle to group:
      hOptions{idxOptions} = hGroup;
      
   %% Print for Options of Input type (p)
   elseif ischar(tmpOptions) && strcmp(tmpOptions(1:2),'p|')   
      % Remove marker from charachter line:
      tmpOptions     = tmpOptions(3:end);
      tmpPipeIdx     = strfind(tmpOptions,'|');
      tmpMarkedIdx   = strfind(tmpOptions,Opt.defaultOptionSymbol);
      tmpOptions(tmpMarkedIdx)   = [];
      
      % Create uicontrol:
      hOptions{idxOptions} = uicontrol( ...
         'Style',       'popupmenu',...
         'String',      tmpOptions,...
         'FontName',    Opt.fontName, ...
         'FontSize',    Opt.popupmenuFontSize, ...
         'Position',    tmpPosition);
      
      % Check if we have a defualt selection on:
      if ~isempty(tmpMarkedIdx)
         tmpValue = arrayfun(@(markIdx) emptyIsZero(...
            find(markIdx >= tmpPipeIdx,1,'last')),tmpMarkedIdx) + 1;  
         if length(tmpValue) > 1
            warning('menuN:popupmenu',...
               'Only one selected element is valid as default.');
            tmpValue = tmpValue(1);
         end
         set(hOptions{idxOptions},'Value',tmpValue)
      end
      
      % Check actual necessary size:
      tmpExtent = get(hOptions{idxOptions},'extent');
      extentWidthUniversal   = max(extentWidthUniversal, ...
         tmpExtent(3)+extentWidthPopupmenuInPadding);
      tmpNewSize  = [extentWidthUniversal, tmpExtent(4)];
      % Update size of uicontrol:
      set(hOptions{idxOptions},'Position',[tmpCurrentPosition,tmpNewSize]);   
      % Update current position Y coordinate:
      tmpCurrentPosition(2) = tmpCurrentPosition(2) + tmpNewSize(2) + ...
         extentHeightPopupmenuPadding + Opt.pixelPaddingHeigth(2);
   %% Print for Options of Input type (t)
   elseif ischar(tmpOptions) && strcmp(tmpOptions(1:2),'t|')   
      % Remove marker from charachter line:
      tmpOptions     = tmpOptions(3:end);
      tmpPipeIdx     = strfind(tmpOptions,'|');
      tmpMarkedIdx   = strfind(tmpOptions,Opt.defaultOptionSymbol);
      tmpOptions(tmpMarkedIdx)   = [];
      % Convert any | charachters left to newline characters if any. Also ensure
      % that the edit box is multiline if this is the case.
      if ~isempty(tmpPipeIdx)
         tmpOptions = strrep(tmpOptions,'|',sprintf('\n'));
         tmpMax = 2;
      else
         tmpMax = 1;
      end
      tmpMin = 0;
      
      % Create uicontrol:
      hOptions{idxOptions} = uicontrol( ...
         'Style',       'edit',...
         'Max',         tmpMax, ...
         'Min',         tmpMin, ...
         'String',      tmpOptions,...
         'FontName',    Opt.fontName, ...
         'FontSize',    Opt.popupmenuFontSize, ...
         'Position',    tmpPosition, ...
         'HorizontalAlignment', 'left');
            
      % Check actual necessary size:
      tmpExtent = get(hOptions{idxOptions},'extent');
      extentWidthUniversal   = max(extentWidthUniversal, ...
         tmpExtent(3)+extentWidthPopupmenuInPadding);
      tmpNewSize  = [extentWidthUniversal, tmpExtent(4)];
      % Update size of uicontrol:
      set(hOptions{idxOptions},'Position',[tmpCurrentPosition,tmpNewSize]);   
      % Update current position Y coordinate:
      tmpCurrentPosition(2) = tmpCurrentPosition(2) + tmpNewSize(2) + ...
         extentHeightPopupmenuPadding + Opt.pixelPaddingHeigth(2);      
   %% Print for Options of Input type (l)
   elseif ischar(tmpOptions)                                   
      % Remove marker from charachter line:
      tmpPipeIdx     = strfind(tmpOptions,'|');
      tmpMarkedIdx   = strfind(tmpOptions,Opt.defaultOptionSymbol);
      tmpOptions(tmpMarkedIdx)   = [];
      
      % Create uicontrol:
      hOptions{idxOptions} = uicontrol( ...
         'Style',       'listbox',...
         'Min',         0,...
         'Max',         2,...
         'String',      tmpOptions,...
         'FontName',    Opt.fontName, ...
         'FontSize',    Opt.listboxFontSize, ...
         'Position',    tmpPosition);
      
      % Check if we have a defualt selection on:
      if ~isempty(tmpMarkedIdx)
         tmpValue = arrayfun(@(markIdx) emptyIsZero(...
            find(markIdx >= tmpPipeIdx,1,'last')),tmpMarkedIdx) + 1;  
         set(hOptions{idxOptions},'Value',tmpValue)
      end
      
      % Check actual necessary size:
      tmpExtent = get(hOptions{idxOptions},'extent');
      extentWidthUniversal   = max(extentWidthUniversal, ...
         tmpExtent(3)+extentWidthPopupmenuInPadding);
      tmpNewSize  = [extentWidthUniversal, tmpExtent(4)];
      % Update size of uicontrol:
      set(hOptions{idxOptions},'Position',[tmpCurrentPosition,tmpNewSize]);   
      % Update current position Y coordinate:
      tmpCurrentPosition(2) = tmpCurrentPosition(2) + tmpNewSize(2) + ...
         extentHeightPopupmenuPadding + Opt.pixelPaddingHeigth(2);
      
   %% Print for Options of Input type (s)
   elseif isnumeric(tmpOptions)    
       
       
%        if length(tmpOptions) < 4
%            sliderStepsFraction = Opt.sliderStepsFraction;
%        elseif length(tmpOptions) == 4
%            sliderStepsFraction = [tmpOptions(4) tmpOptions(4)*5];
%            tmpOptions = tmpOptions(1:3);
%        elseif length(tmpOptions) == 5
%            sliderStepsFraction = tmpOptions(4:5);
%            tmpOptions = tmpOptions(1:3); 
%        else
%            error('menuN:input:Unknown format of slider input input.')
%        end
           
      % Check if length is 2:
      if length(tmpOptions) == 2 
         tmpOptions(3) = tmpOptions(1) + 0.5*diff(tmpOptions);
      elseif length(tmpOptions) == 3
         if tmpOptions(3) > tmpOptions(2) || tmpOptions(3) < tmpOptions(1)
            tmpOptions(3) = tmpOptions(1) + 0.5*diff(tmpOptions);
         end
      else
         error('menuN:input:Unknown format of numeric input.')
      end      
      if tmpOptions(1) > tmpOptions(2)
         error('menuN:slider:Start value must be lower the end value.');
      end
      
      % | Check for Slider Step size
      
      % Create uicontrol:
      hSliderGroup         = cell(1,2);
      
      hSliderGroup{1}      = uicontrol( ...
         'Style',       'Text',...
         'FontName',    Opt.fontName, ...
         'FontSize',    Opt.sliderFontSize, ...
         'String',      num2str(tmpOptions(3)),...
         'Position',    tmpPosition);
      % Check actual necessary size:
      tmpExtentText = get( hSliderGroup{1} ,'extent');
      tmpNecessaryHeight = tmpExtentText(4) + extentHeigthTextInPadding;
      
      hSliderGroup{2}      = uicontrol( ...
         'Style',       'Slider',...
         'Min',         tmpOptions(1),...
         'Max',         tmpOptions(2),...
         'Value',       tmpOptions(3),...
         'Position',    tmpPosition,...
         'Userdata',    hSliderGroup{1},...
         'Callback',    {@updateSliderText,hSliderGroup{1}},...
         'SliderStep',  sliderStepsFraction);
      
      % For continous updates when we move the slider we add a listener:
      if exist('addlistener','builtin')
         addlistener(hSliderGroup{2},'Value','PostSet',@updateSliderTextContinuum);
      end
      
      % Update extentWidthUniversal:
      extentWidthUniversal   = max(extentWidthUniversal, ...
         tmpExtentText(3) + extentWidthTextInPadding + extentWidthSliderMin + ...
         Opt.pixelPaddingWidth(2) );
      
      % Update height of our slider group objects:
      tmpPosition(4) = tmpNecessaryHeight;      
      set(hSliderGroup{2},'Position',tmpPosition)
      tmpPosition(3) = tmpExtentText(3) + extentWidthTextInPadding;            
      set(hSliderGroup{1},'Position',tmpPosition)
        
      % Update current position Y coordinate:
      tmpCurrentPosition(2) = tmpCurrentPosition(2) + tmpNecessaryHeight + ...
         extentHeigthTextPadding + Opt.pixelPaddingHeigth(2);
      
      % Save handles:
      hOptions{idxOptions} = hSliderGroup;
   end
   
   %% Print subtitles if any:
   if ~isempty(subtitles{idxOptions})
   
      % Get updated current position:
      tmpPosition   = [tmpCurrentPosition, tmpMinimumSize];
      
      % Create subtitle:
      hSubtitle{idxOptions} = uicontrol( ...
         'Style',       'Text',...
         'FontName',    Opt.fontName, ...
         'FontSize',    Opt.subtitleFontSize, ...
         'FontWeight',  Opt.subtitleFontWeight, ...
         'String',      subtitles{idxOptions},...
         'Position',    tmpPosition,...
         'HorizontalAlignment', 'left');
      
      % Check actual necessary size:
      tmpExtent = get(hSubtitle{idxOptions},'extent');
      extentWidthUniversal   = max(extentWidthUniversal, ...
         tmpExtent(3));
      tmpNewSize  = [extentWidthUniversal, tmpExtent(4) + extentHeigthTextInPadding];
      % Update size of uicontrol:
      set(hSubtitle{idxOptions},'Position',[tmpCurrentPosition(1)+Opt.pixelPaddingWidth(2),...
         tmpCurrentPosition(2),tmpNewSize]);   
      % Update current position Y coordinate:
      tmpCurrentPosition(2) = tmpCurrentPosition(2) + tmpNewSize(2) + ...
         extentHeigthTextPadding + Opt.pixelPaddingHeigth(2);
      
      % Make background "transparent":
      parentColor = get(get(hSubtitle{idxOptions}, 'parent'), 'color');
      set(hSubtitle{idxOptions},'foregroundcolor', [0 0 0], ...
            'backgroundcolor', parentColor);
      
   end
   
end

%% Update width of all componenents to be same:
% Update width of all created objects such that all have the width of
% extentWidthUniversal:
for idxOptions = numOptionsGroups:-1:1
   if ~isempty(hSubtitle{idxOptions})
      tmpPosition       = get(hSubtitle{idxOptions},'Position');
      tmpPosition(3)    = extentWidthUniversal;
      set(hSubtitle{idxOptions},'Position',tmpPosition);
   end
   if ~iscell(hOptions{idxOptions})
      tmpPosition       = get(hOptions{idxOptions},'Position');
      tmpPosition(3)    = extentWidthUniversal;
      set(hOptions{idxOptions},'Position',tmpPosition);
   elseif ~flagMakeOkButton
      for idxButton = 1:length(hOptions{idxOptions})
         tmpPosition       = get(hOptions{idxOptions}{idxButton},'Position');
         tmpPosition(3)    = extentWidthUniversal;
         set(hOptions{idxOptions}{idxButton},'Position',tmpPosition);
      end      
   else
      % Update position and size of slider group [need special treatment]:
      tmpPositionText      = get( hOptions{idxOptions}{1} ,'position');
      tmpPositionText(1)   = extentWidthUniversal - tmpPositionText(3) + ...
         Opt.pixelPaddingWidth(1);
      set(hOptions{idxOptions}{1} ,'position', tmpPositionText);
      tmpPositionSlider    = get( hOptions{idxOptions}{2} ,'position');
      tmpPositionSlider(3) = extentWidthUniversal - tmpPositionText(3) - ...
          Opt.pixelPaddingWidth(2);
      set(hOptions{idxOptions}{2} ,'position',tmpPositionSlider);
   end
end
if flagMakeOkButton
   tmpPosition = get(hOK,'Position');
   tmpPosition(3) = extentWidthUniversal;

   % | CANCEL BUTTON
okPos = tmpPosition; 
okPos(3) = (okPos(3)/2) - (okPos(1)/2);
cancelPos = okPos;
cancelPos(1) = sum(cancelPos([1 3])) + (okPos(1));  
set(hOK,'Position',okPos);
    hCancel            = uicontrol( ...
    'Style',       'Pushbutton',...
    'String',      Opt.cancelButtonLabel,...
    'FontName',    Opt.fontName, ...
    'FontSize',    Opt.pushbuttonFontSize, ...
    'Position',    cancelPos, ...
    'Callback',    {@closeMenuFigure,hFig,'cancel'});
end

%% Change size of figure, place it at the center of the screen:
screenSize           = get(0,'ScreenSize');
figureSize           = [extentWidthUniversal + 2*Opt.pixelPaddingWidth(1),...
   tmpCurrentPosition(2) + Opt.pixelPaddingHeigth(1) + extentHeightTitlePadding];
figurePosition       = 0.5*screenSize([3,4]) - 0.5*figureSize;
set(hFig,'Position',[figurePosition,figureSize]);

% Start to wait until a button is pressed or that the window is closed:
drawnow
%% Wait until user have selected their choice:
uiwait(hFig)

%% Check if figure handle exists:
if ishandle(hFig)
%% Collect the choice from the figure userdata field or uicontrols:
choice = get(hFig,'userdata');
if strcmp(choice,'OK')
   % Collecte selected choices:
   choice = cell(numOptionsGroups,1);
   for idxOptions = 1:numOptionsGroups
      if ishandle(hOptions{idxOptions})
         % Check for a value field, then that field is the choice:
         tmpStruct = get(hOptions{idxOptions});
         if isfield(tmpStruct,'Style') && strcmp(tmpStruct.Style,'edit')
            choice{idxOptions} = get(hOptions{idxOptions},'String');
         elseif isfield(tmpStruct,'Value')
            choice{idxOptions} = emptyIsMinusOne(...
               get(hOptions{idxOptions},'Value'));
         elseif isfield(tmpStruct,'SelectedObject')
            % We have a buttongroup, instead we search for the selected object:
            tmpSelectedObject = get(hOptions{idxOptions},'SelectedObject');
            if isempty(tmpSelectedObject)
               % No object selected:
               choice{idxOptions} = -1;
            else
               % One object is selected:
               choice{idxOptions} = get(tmpSelectedObject,'userdata');
            end            
         else
            % We have a panel containing checkboxes:
            tmpChilds = get(hOptions{idxOptions},'Children');
            tmpChildValue = logical(arrayfun(@(hObject) get(hObject,'Value'),...
               tmpChilds));
            tmpChildeChoice = arrayfun(@(hObject) get(hObject,'userdata'),...
               tmpChilds);
            % Convert logical true false array to selected indexes:
            choice{idxOptions}       = tmpChildeChoice(tmpChildValue);    
         end
      else
         % We have a cell array of handles in a slider group, second is slider:
         choice{idxOptions} = get(hOptions{idxOptions}{2},'Value');
      end
   end
   % Create choice output as cell array if numOptionsGroups > 1,
   % otherwise just find the selected options:   
   if numOptionsGroups == 1
      choice = choice{1};
   end
end
%% Close the figure (force it as the CloseRequestFuntion is overriden):
delete(hFig)
else
%% Standard output -1 if window does not exist
choice = 'cancel';
end

%% Utilityfunctions
%% Update Slider text at slider change
function updateSliderText(hSlider,event,hText)
% Update the slider text when the slider bulb is moved:
set(hText,'String',num2str(get(hSlider,'Value')));
function updateSliderTextContinuum(listnerObj,event)
% Update the slider text when the slider bulb is moved:
if isobject(event) % -> [Fixed R2014b has new event object type]
   hSlider  = event.AffectedObject;
   hText    = get(hSlider,'userdata');   
else % Valid for releases prior to R2014b:
   hSlider  = get(event,'AffectedObject');
   hText    = get(hSlider,'userdata');
end
set(hText,'String',num2str(get(hSlider,'Value')));

%% OK button: Close function for menu figure
function closeMenuFigure(hObj,event,hFig,extra)
% Set the correct choice from the parameter extra:
set(hFig,'userdata',extra)
% Resume the menuN script instead of closing the figure 
uiresume(hFig) % -> [Fixed bug if using ctrl+c]:

%% Override default structure fields:
function sout = setdefaultsstruct(s,sdef)
%% SETDEFAULTSSTRUCT sets the default structure values 
%     sout = setdefaultsstruct(s,sdef)
%  Reproduces in s all the structure fields, and their values, that exist in
%  sdef that do not exist in s. 
sout = sdef;
for f = fieldnames(s)'
    sout.(f{1}) = s.(f{1});
end

%% Utility, [] => 0 and [] => -1 functions:
function out = emptyIsZero(in)
if isempty(in)
   out = 0;
else
   out = in;
end
function out = emptyIsMinusOne(in)
if isempty(in)
   out = -1;
else
   out = in;
end