function [hout,ax_out] = uibutton(varargin)
%uibutton: Create pushbutton with more flexible labeling than uicontrol.
% Usage:
%   uibutton accepts all the same arguments as uicontrol except for the
%   following property changes:
%
%     Property      Values
%     -----------   ------------------------------------------------------
%     Style         'pushbutton', 'togglebutton' or 'text', default =
%                   'pushbutton'.
%     String        Same as for text() including cell array of strings and
%                   TeX or LaTeX interpretation.
%     Interpreter   'tex', 'latex' or 'none', default = default for text()
%     Rotation      text rotation angle, default = 0
%
% Syntax:
%   handle = uibutton('PropertyName',PropertyValue,...)
%   handle = uibutton(parent,'PropertyName',PropertyValue,...)
%   [text_obj,axes_handle] = uibutton('Style','text',...
%       'PropertyName',PropertyValue,...)
%
% uibutton creates a temporary axes and text object containing the text to
% be displayed, captures the axes as an image, deletes the axes and then
% displays the image on the uicontrol.  The handle to the uicontrol is
% returned.  If you pass in a handle to an existing uicontol as the first
% argument then uibutton will use that uicontrol and not create a new one.
%
% If the Style is set to 'text' then the axes object is not deleted and the
% text object handle is returned (as well as the handle to the axes in a
% second output argument).
%
% See also UICONTROL.

% Version: 1.9, 5 November 2010
% Author:  Douglas M. Schwarz
% Email:   dmschwarz=ieee*org, dmschwarz=urgrad*rochester*edu
% Real_email = regexprep(Email,{'=','*'},{'@','.'})


% Detect if first argument is a uicontrol handle.
keep_handle = false;
if nargin > 0
	h = varargin{1};
	if isscalar(h) && ishandle(h) && strcmp(get(h,'Type'),'uicontrol')
		keep_handle = true;
		varargin(1) = [];
	end
end

% Parse arguments looking for 'Interpreter' property.  If found, note its
% value and then remove it from where it was found.
interp_value = get(0,'DefaultTextInterpreter');
rotation_value = get(0,'DefaultTextRotation');
arg = 1;
remove = [];
while arg <= length(varargin)
	v = varargin{arg};
	if isstruct(v)
		fn = fieldnames(v);
		for i = 1:length(fn)
			if strncmpi(fn{i},'interpreter',length(fn{i}))
				interp_value = v.(fn{i});
				v = rmfield(v,fn{i});
			elseif strncmpi(fn{i},'rotation',length(fn{i}))
				rotation_value = v.(fn{i});
				v = rmfield(v,fn{i});
			end
		end
		varargin{arg} = v;
		arg = arg + 1;
	elseif ischar(v)
		if strncmpi(v,'interpreter',length(v))
			interp_value = varargin{arg+1};
			remove = [remove,arg,arg+1]; %#ok<AGROW>
		elseif strncmpi(v,'rotation',length(v))
			rotation_value = varargin{arg+1};
			remove = [remove,arg,arg+1]; %#ok<AGROW>
		end
		arg = arg + 2;
	elseif arg == 1 && isscalar(v) && ishandle(v) && ...
			any(strcmp(get(h,'Type'),{'figure','uipanel'}))
		arg = arg + 1;
	else
		error('Invalid property or uicontrol parent.')
	end
end
varargin(remove) = [];

% Create uicontrol, get its properties then hide it.
if keep_handle
	set(h,varargin{:})
else
	h = uicontrol(varargin{:});
end
s = get(h);
if ~any(strcmp(s.Style,{'pushbutton','togglebutton','text'}))
	delete(h)
	error('''Style'' must be pushbutton, togglebutton or text.')
end
set(h,'Visible','off')

% Create axes.
parent = get(h,'Parent');
ax = axes('Parent',parent,...
	'Units',s.Units,...
	'Position',s.Position,...
	'XTick',[],'YTick',[],...
	'XColor',s.BackgroundColor,...
	'YColor',s.BackgroundColor,...
	'Box','on',...
	'Color',s.BackgroundColor);
% Adjust size of axes for best appearance.
set(ax,'Units','pixels')
pos = round(get(ax,'Position'));
if strcmp(s.Style,'text')
	set(ax,'Position',pos + [0 1 -1 -1])
else
	set(ax,'Position',pos + [4 4 -8 -8])
end
switch s.HorizontalAlignment
	case 'left'
		x = 0.0;
	case 'center'
		x = 0.5;
	case 'right'
		x = 1;
end
% Create text object.
text_obj = text('Parent',ax,...
	'Position',[x,0.5],...
	'String',s.String,...
	'Interpreter',interp_value,...
	'Rotation',rotation_value,...
	'HorizontalAlignment',s.HorizontalAlignment,...
	'VerticalAlignment','middle',...
	'FontName',s.FontName,...
	'FontSize',s.FontSize,...
	'FontAngle',s.FontAngle,...
	'FontWeight',s.FontWeight,...
	'Color',s.ForegroundColor);

% If we are creating something that looks like a text uicontrol then we're
% all done and we return the text object and axes handles rather than a
% uicontrol handle.
if strcmp(s.Style,'text')
	delete(h)
	if nargout
		hout = text_obj;
		ax_out = ax;
	end
	return
end

% Determine parent figure and move it to main screen, if necessary.
% (Necessary because of bug in getframe.)
fig = parent;
while ~strcmp(get(fig,'Type'),'figure')
	fig = get(fig,'Parent');
end
fig_pos = get(fig,'Position');
movegui(fig)

% Capture image of axes and then delete the axes.
frame = getframe(ax);
delete(ax)

% Move figure back to original position.
set(fig,'Position',fig_pos)

% Build RGB image, set background pixels to NaN and put it in 'CData' for
% the uicontrol.
if isempty(frame.colormap)
	rgb = frame.cdata;
else
	rgb = reshape(frame.colormap(frame.cdata,:),[pos([4,3]),3]);
end
size_rgb = size(rgb);
rgb = double(rgb)/255;
back = repmat(permute(s.BackgroundColor,[1 3 2]),size_rgb(1:2));
isback = all(rgb == back,3);
rgb(repmat(isback,[1 1 3])) = NaN;
set(h,'CData',rgb,'String','','Visible',s.Visible)

% Assign output argument if necessary.
if nargout
	hout = h;
end