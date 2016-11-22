function [phandle, pidx] = pgrid(nrow, ncol, varargin)
% PGRID Create a grid of of UIPANELs
%
%  USAGE: [phandle, pidx] = pgrid(nrow, ncol, varargin)
%
%  OUTPUT
%   hpanel: array of handles to uipanels comprising the grid
%   hidx:   [row,col] indices for the returned uipanel handles
% ________________________________________________________________________________________
%  INPUTS
%   nrow:   number of rows in grid
%   ncol:   number of cols in grid
% ________________________________________________________________________________________
%  VARARGIN
% | NAME            | DEFAULT       | DESCRIPTION
% |-----------------|---------------|-----------------------------------------------------
% | parent          | gcf           | parent object for grid
% | relwidth        | ones(1, ncol) | relative width of columns (arbitrary units)
% | relheight       | ones(1, nrow) | relative height of rows (arbitrary units)
% | marginsep       | 0.0100        | size of margin surrounding grid (normalized units)
% | panelsep        | 0.0100        | size of space between panels (normalized units)
% | backgroundcolor | [.08 .09 .09] | uipanel background color
% | foregroundcolor | [.97 .97 .97] | uipanel foreground color
% | bordertype      | 'none'        | etchedin, etchedout, beveledin, beveledout, line
% | borderwidth     | 1             | uipanel border width in pixels
% ________________________________________________________________________________________
%

% ----------------------------- Copyright (C) 2015 Bob Spunt -----------------------------
%	Created:  2015-08-23
%	Email:     spunt@caltech.edu
% ________________________________________________________________________________________

% | Defaults for VARARGIN
def = { ...
'parent',              []                                   ,...
'relwidth',            []                                   ,...
'relheight',		   []                                   ,...
'marginsep',          .01                                   ,...
'panelsep',           .01                                   ,...
'backgroundcolor',    [20/255 23/255 24/255]                ,...
'foregroundcolor',    [248/255 248/255 248/255]             ,...
'bordertype',         'none'                                ,...
'borderwidth',         1                                     ...
};

% | Update values for VARARGIN where necessary
vals = setargs(def, varargin);

% | Check arguments
if nargin < 2, mfile_showhelp; return; end
if isempty(parent), parent          = gcf; end
if isempty(relwidth), relwidth      = ones(1, ncol); end
if isempty(relheight), relheight    = ones(1, nrow); end
if length(relwidth)~=ncol, printmsg('Length of RELWIDTH must equal NCOL. Try again!'); phandle = []; pidx = []; return; end
if length(relheight)~=nrow, printmsg('Length of RELHEIGHT must equal NROW. Try again!'); phandle = []; pidx = []; return; end

% | Get normalized positions for each panel
pos         = getpositions(relwidth, relheight, marginsep, panelsep);
pidx        = pos(:,1:2);
hpos        = pos(:,3:end);

% | pgrid loop
npanel      = size(hpos, 1);
% phandle     = gobjects(npanel, 1);
phandle     = zeros(npanel, 1); 
for i = 1:npanel

    phandle(i)  =  uipanel( ...
                  'Parent'   ,     parent                                 ,...
                   'Units'   ,     'normalized'                           ,...
                     'Tag'   ,     sprintf('[%d] x [%d]', pidx(i,:))        ,...
                   'Title'   ,     ''                                     ,...
           'TitlePosition'   ,     'centertop'                            ,...
                'Position'   ,     hpos(i,:)                              ,...
         'BackgroundColor'   ,     backgroundcolor                        ,...
         'ForegroundColor'   ,     foregroundcolor                        ,...
              'BorderType'   ,     bordertype                             ,...
             'BorderWidth'   ,     borderwidth                            ,...
                'UserData'   ,     num2cell(pidx(i,:))                              ,...
                 'Visible'   ,     'off'                                   ...
                            );
end

% | Make Visible
for i = 1:npanel, set(phandle(i), 'visible', 'on'); drawnow; end

end
% ========================================================================================
%
% ------------------------------------- SUBFUNCTIONS -------------------------------------
%
% ========================================================================================
function pos = getpositions(relwidth, relheight, marginsep, uicontrolsep, top2bottomidx)
if nargin<2, relheight = [6 7]; end
if nargin<3, marginsep = .025; end
if nargin<4, uicontrolsep = .01; end
if nargin<5, top2bottomidx = 1; end
if size(relheight,1) > 1, relheight = relheight'; end
if size(relwidth, 1) > 1, relwidth = relwidth'; end
ncol        = length(relwidth);
nrow        = length(relheight);
if top2bottomidx, relheight = relheight(end:-1:1); end

% width
rowwidth    = 1-(marginsep*2)-(uicontrolsep*(ncol-1));
uiwidths    = (relwidth/sum(relwidth))*rowwidth;
allsep      = [marginsep repmat(uicontrolsep, 1, ncol-1)];
uilefts     = ([0 cumsum(uiwidths(1:end-1))]) + cumsum(allsep);

% height
colheight   = 1-(marginsep*2)-(uicontrolsep*(nrow-1));
uiheights   = (relheight/sum(relheight))*colheight;
allsep      = [marginsep repmat(uicontrolsep, 1, nrow-1)];
uibottoms   = ([0 cumsum(uiheights(1:end-1))]) + cumsum(allsep);
if top2bottomidx, uiheights = uiheights(end:-1:1); end
if top2bottomidx, uibottoms = uibottoms(end:-1:1); end

% combine
pos = zeros(ncol*nrow, 6);
pos(:,1) = reshape(repmat(nrow:-1:1, ncol, 1), size(pos,1), 1);
pos(:,2) = reshape(repmat(1:ncol, 1, nrow), size(pos,1), 1);
pos(:,3) = uilefts(pos(:,2));
pos(:,4) = uibottoms(pos(:,1));
pos(:,5) = uiwidths(pos(:,2));
pos(:,6) = uiheights(pos(:,1));
pos      = sortrows(pos, 1);
end
function mfile_showhelp(varargin)
% MFILE_SHOWHELP
ST = dbstack('-completenames');
if isempty(ST), fprintf('\nYou must call this within a function\n\n'); return; end
eval(sprintf('help %s', ST(2).file));
end
function argstruct = setargs(defaults, optargs)
% SETARGS Name/value parsing and assignment of varargin with default values
if nargin < 1, mfile_showhelp; return; end
if nargin < 2, optargs = []; end
defaults = reshape(defaults, 2, length(defaults)/2)';
if ~isempty(optargs)
    if mod(length(optargs), 2)
        error('Optional inputs must be entered as Name, Value pairs, e.g., myfunction(''name'', value)');
    end
    arg = reshape(optargs, 2, length(optargs)/2)';
    for i = 1:size(arg,1)
       idx = strncmpi(defaults(:,1), arg{i,1}, length(arg{i,1}));
       if sum(idx) > 1
           error(['Input "%s" matches multiple valid inputs:' repmat('  %s', 1, sum(idx))], arg{i,1}, defaults{idx, 1});
       elseif ~any(idx)
           error('Input "%s" does not match a valid input.', arg{i,1});
       else
           defaults{idx,2} = arg{i,2};
       end
    end
end
for i = 1:size(defaults,1), assignin('caller', defaults{i,1}, defaults{i,2}); end
if nargout>0, argstruct = cell2struct(defaults(:,2), defaults(:,1)); end
end
