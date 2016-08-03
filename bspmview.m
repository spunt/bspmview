function varargout = bspmview(ol, ul)
% BSPMVIEW Program for viewing fMRI statistical maps
%
%   USAGE: varargout = bspmview(ol*, ul*)       *optional inputs
%
% Requires that Statistical Parametric Mapping (SPM; Wellcome Trust Centre for
% Neuroimaging; www.fil.ion.ucl.ac.uk/spm/) be in your MATLAB search path. In
% addition, it requires a number of supporting utility functions and data
% files that should have been included in the distribution of BSPMVIEW. When
% BSPMVIEW is launched, it will look for these files in a folder called
% "supportfiles" that should be contained in the same folder as this function.
% It has been tested on SPM8/SPM12 operating in MATLAB 2014b running in both
% Windows 8.1 and OS X Yosemite.
%
% ________________________________________________________________________________
% COMMAND LINE USAGE 
% ________________________________________________________________________________
%
% INPUTS
%   ol: filename for statistical image to overlay
%	ul: filename for anatomical image to use as underlay
% 
% EXAMPLES
%   bspmview('spmT_0001.img', 'T1.nii')  % overlay on 'T1.nii'
%   bspmview('spmT_0001.nii.gz')         % overlay on default underlay
%   bspmview                             % open dialogue for selecting overlay
%   S = bspmview;                        % returns struct 'S' w/graphics handles
%
% ________________________________________________________________________________
% ACKNOWLEDGMENTS    
% ________________________________________________________________________________
%
% This software heavily relies on functionality contained within SPM and is in
% many ways an attempt to translate it into a simpler and more user-friendly
% interface. Special thanks goes to Jared Torre for testing an early version
% of the code, and to Guillaume Flandin for help with adding BSPMVIEW to the
% SPM Extensions webpage. In addition, this software was initially inspired by
% and in some cases adapts code from two other statistical image viewers:  
%   - XJVIEW by Xu Cui, Jian Li, & Xiaowei Song (alivelearn.net/xjview8)
%   - FIVE by Aaron P. Schultz (mrtools.mgh.harvard.edu)
%
% Moreover, numerous other open-source MATLAB fMRI analysis tools provided the
% raw material for many of the  functions included in BSPMVIEW, including:
%   - SURFPLOT (mrtools.mgh.harvard.edu/index.php/SurfPlot)
%   - PEAK_NII (nitrc.org/projects/peak_nii)
%   - Anatomy Toolbox (fil.ion.ucl.ac.uk/spm/ext/#Anatomy)
%   - Anatomical Automatic Labeling 2 (AAL2) (http://www.gin.cnrs.fr/AAL2)
%   - Harvard-Oxford Atlas (from FSL) (http://cma.mgh.harvard.edu/fsl_atlas.html)
%
% Finally, several contributions to the MATLAB File Exchange
% (mathworks.com/matlabcentral/fileexchange/) are called by the code. These
% are included in the "supporting files" folder included in the distribution
% of BSPMVIEW. The documentation of the supporting functions contains further
% information about the source and respective copyright holders.
%

% ------ Copyright (C) Bob Spunt, California Institute of Technology ------
%   Email:    bobspunt@gmail.com
%	Created:  2014-09-27
%   GitHub:   https://github.com/spunt/bspmview
%   Version:  20160803
%
%   This program is free software: you can redistribute it and/or modify
%   it under the terms of the GNU General Public License as published by
%   the Free Software Foundation, either version 3 of the License, or (at
%   your option) any later version.
%       This program is distributed in the hope that it will be useful, but
%   WITHOUT ANY WARRANTY; without even the implied warranty of
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
%   General Public License for more details.
%       You should have received a copy of the GNU General Public License
%   along with this program.  If not, see: http://www.gnu.org/licenses/.
% _________________________________________________________________________
global bspmview_version
bspmview_version='20160803';

% | CHECK FOR SPM FOLDER
% | =======================================================================
spmdir = fileparts(which('spm'));
if isempty(spmdir)
    printmsg('SPM is not on your path. This may not work...', 'WARNING');
else
    addpath(fullfile(spmdir,'matlabbatch'));
    addpath(fullfile(spmdir,'config'));
end

% | CHECK FOR SUPPORTFILES, USERPREF, AND SPM FOLDER
% | =======================================================================
mfilepath   = fileparts(mfilename('fullpath'));
supportdir  = fullfile(mfilepath, 'supportfiles');
if ~exist(supportdir, 'dir'), printmsg('The folder "supportfiles" was not found', 'ERROR'); return; end
addpath(supportdir);

% | CHECK INPUTS
% | =======================================================================
if nargin < 1 
    % | CHECK FOR OPEN SPM
    hcon = findobj(0, 'Name', 'SPM contrast manager'); 
    if ~isempty(hcon)
        huserdata = get(hcon, 'UserData');
        selectdir = huserdata.swd;
    else
        selectdir = pwd;
    end
    ol = uigetvol('Select an Image File for Overlay', 0, selectdir);
    if isempty(ol), disp('Must select an overlay!'); return; end
else
    if all([~ischar(ol) ~iscell(ol)]), disp('First argument must be a string or cell array!'); return; end
    if iscell(ol), ol = char(ol); end
    if ~exist(ol, 'file'), disp('Overlay image file cannot be found!'); return; end
end
if nargin < 2
    ul = fullfile(supportdir, 'IIT_MeanT1_2x2x2.nii');
else
    if all([~ischar(ul) ~iscell(ul)]), disp('Second argument must be a string or cell array!'); return; end
    if iscell(ul), ul = char(ul); end
    if ~exist(ul, 'file'), disp('Underlay image file cannot be found!'); return; end
end

% | DEFAULTS
% | =======================================================================
global prevsect st
prevsect       = ul;
st.guipath     = mfilepath;
st.supportpath = supportdir;
st.fonts       = default_fonts; 
st.pos         = default_positions;
preffile       = fullfile(getenv('HOME'), 'bspmview_preferences.mat');
if exist(preffile, 'file')
    st.preferences = load(preffile); 
else
    st.preferences = default_settings; 
end
put_startupmsg;

% | INITIALIZE FIGURE, SPM REGISTRY, & ORTHVIEWS
% | =======================================================================
try
    S = put_figure(ol, ul); shg;
    if nargout, varargout = {S}; end
catch err
    save_error(err);
    rethrow(err)
end

% =========================================================================
% *
% * SUBFUNCTIONS
% *
% =========================================================================

% | GUI DEFAULTS
% =========================================================================
function def    = default_settings
 def  = struct( ...
            'atlasname'     ,   'AnatomyToolbox'      , ...
            'alphacorrect'  ,   .05         , ...
            'separation'    ,   20          , ...
            'numpeaks'      ,   3           , ...
            'alphauncorrect',   .001        , ...
            'clusterextent' ,   5           , ...
            'surfshow'      ,   4           , ...
            'surface'       ,   'Inflated'  , ...
            'shading'       ,   'Sulc'      , ...
            'nverts'        ,   40962       , ...
            'round'         ,   false       , ...
            'neighbor'      ,   0           , ...
            'dilate'        ,   false       , ...
            'shadingmin'    ,   .15         , ...
            'shadingmax'    ,   .70         , ...
            'colorbar'      ,   true          ...
        );
function prefs  = default_preferences(initial)

    if nargin < 1, initial = 0; end
    global st
    deffile         = fullfile(getenv('HOME'), 'bspmview_preferences.mat');
    st.preferences  = catstruct(default_settings, st.preferences);
    def             = st.preferences; 
    if initial, save(deffile, '-struct', 'def'); return; end
    pos = get(st.fig, 'pos'); 
    w   = pos(3)*.65;
    opt             = {'L/R Medial/Lateral' 'L/R Lateral' 'L Medial/Lateral' 'R Medial/Lateral' 'L Lateral' 'R Lateral'};
    optmap          = [4 2 1.9 2.1 -1 1]; 
    opt             = [opt(optmap==def.surfshow) opt(optmap~=def.surfshow)]; 
    optmap          = [optmap(optmap==def.surfshow) optmap(optmap~=def.surfshow)]; 
    surftypeopt     = {'Inflated' 'Pial' 'White' 'PI'}; 
    surftypeopt     = [surftypeopt(strcmpi(surftypeopt, def.surface)) surftypeopt(~strcmpi(surftypeopt, def.surface))]; 
    surftypeshade   = {'Sulc' 'Curv' 'Thk' 'LogCurv' 'Mixed'};
    surftypeshade   = [surftypeshade(strcmpi(surftypeshade, def.shading)) surftypeshade(~strcmpi(surftypeshade, def.shading))]; 
    nvertopt        = [40962 642 2562 10242 163842]; 
    nvertopt        = [nvertopt(nvertopt==def.nverts) nvertopt(nvertopt~=def.nverts)]; 
    atlasopt        = {                                      ...
                        'AAL2'                              ,...
                        'HarvardOxford-maxprob-thr0'        ,...
                        'HarvardOxford-cort-maxprob-thr0'   ,...
                        'HarvardOxford-sub-maxprob-thr0'    ,...
                        'AnatomyToolbox'                     ...
                      }; 
    atlasopt        = [atlasopt(strcmpi(atlasopt, def.atlasname)) atlasopt(~strcmpi(atlasopt, def.atlasname))];          
    [prefs, button] = settingsdlg('title', 'Settings', 'WindowWidth', w, 'ControlWidth', w/2, ...
        'separator'                                 ,       'Thresholding', ...
        {'Default P-Value (Uncorrected)'; 'alphauncorrect'}       ,       def.alphauncorrect, ...
        {'Default Extent'; 'clusterextent'}         ,       def.clusterextent, ...
        {'Voxelwise FWE'; 'alphacorrect'}           ,       def.alphacorrect, ...
        {'Peak Separation'; 'separation'}           ,       def.separation, ...
        {'# Peaks/Cluster'; 'numpeaks'}             ,       def.numpeaks, ...
        'separator'                                 ,       'Anatomical Labeling', ...
        {'Name'; 'atlasname'}                       ,       atlasopt, ...
        'separator'                                 ,       'Surface Rendering', ...
        {'Surfaces to Render'; 'surfshow'}          ,       opt, ...
        {'Surface Type'; 'surface'}                 ,       surftypeopt, ...
        {'Shading Type'; 'shading'}                 ,       surftypeshade, ...
        {'N Vertices'; 'nverts'}                    ,       num2cell(nvertopt), ...
        {'Shading Min'; 'shadingmin'}               ,       def.shadingmin, ...
        {'Shading Max'; 'shadingmax'}               ,       def.shadingmax, ...
        {'Add Color Bar?'; 'colorbar'}              ,       logical(def.colorbar), ...
        {'Dilate Inclusive Mask?'; 'dilate'}        ,       logical(def.dilate), ...
        {'Round Values? (binary images)'; 'round'}  ,       logical(def.round), ...
        {'Nearest Neighbor? (binary/label images)'; 'neighbor'}, logical(def.neighbor)); 
    if strcmpi(button, 'cancel')
        return
    else
        st.preferences = prefs;
    end
    if ~strcmpi(st.preferences.atlasname, def.atlasname)
        setatlas; 
        setregionname; 
    end
    st.preferences.surfshow = optmap(strcmpi(opt, st.preferences.surfshow));
    def = st.preferences;
    save(deffile, '-struct', 'def'); 
function pos    = default_positions 
    screensize      = get(0, 'ScreenSize');
    pos.ss          = screensize(3:4);
    pos.gui         = [pos.ss(1)*.20 25 pos.ss(2)*.55 pos.ss(2)*.50];
    pos.gui(3:4)    = pos.gui(3:4)*1.10; 
    pos.aspratio    = pos.gui(3)/pos.gui(4);
    if pos.gui(3) < 550
        pos.gui(3) = 550; 
        pos.gui(4) = pos.gui(3)*pos.aspratio; 
    end
    if sum(pos.gui([2 4])) > (pos.ss(2)*.95)
        pos.gui(4)  = pos.ss(2)*.90 - 25; 
        pos.gui(3)  = pos.gui(4)/pos.aspratio; 
    end
    guiss           = [pos.gui(3:4) pos.gui(3:4)]; 
    panepos         = getpositions(1, [17 1], .01, .01);
    pos.pane.upper  = panepos(2,3:end); 
    pos.pane.axes   = panepos(1,3:end).*guiss; 
function color  = default_colors(darktag)
    if nargin==0, darktag = 1; end
    if darktag
        color.fg        = [248/255 248/255 248/255];
        color.bg        = [20/255 23/255 24/255] * 2;
        color.border    = [023/255 024/255 020/255]*2;
        color.panel     = [.01 .22 .34];
        color.edit      = [.95 .95 .95];
        color.font      = [0 0 0]; 
    else
        color.fg       = [20/255 23/255 24/255]; 
        color.bg       = [248/255 248/255 248/255] * .95;
        color.edit     = [.95 .95 .95];
        color.border   = 1 - ([023/255 024/255 020/255]*2);
        color.edit      = [.95 .95 .95];
        color.font      = [0 0 0]; 
    end
    color.xhair     = [0.7020    0.8039    0.8902];
    color.blues     = brewermap(40, 'Blues'); 
function fonts  = default_fonts

    % | Font Size
    if regexpi(computer, '^PCWIN')
        PROP = 1/150;
    else
        PROP = 1/110; 
    end
    SS   = get(0, 'screensize');
    sz1  = round(SS(3)*PROP); 
    sz2  = round(sz1*(3/4)); 
    sz3  = round(sz1*(2/3)); 
    sz4  = round(sz1*(3/5)); 
    sz5  = round(sz1*(5/9)); 
    sz6  = round(sz1*(1/2));
    sz   = [sz1 sz2 sz3 sz4 sz5 sz6];
    if sz6 < 10
        sz = [sz1 sz2 sz3 sz4 sz5 sz6];
        sz = ceil(scaledata(sz, [10 sz1]));
    elseif sz1 > 24
        sz = [sz1 sz2 sz3 sz4 sz5 sz6];
        sz = ceil(scaledata(sz, [sz6 24])); 
    end
    fonts.sz1  = sz(1); 
    fonts.sz2  = sz(2); 
    fonts.sz3  = sz(3);
    fonts.sz4  = sz(4);
    fonts.sz5  = sz(5); 
    fonts.sz6  = sz(6);
    
    % | Font Name
    fonts.name = 'Helvetica';   
function prop   = default_properties(varargin)
    global st
    prop.darkbg     = {'backg', st.color.bg, 'foreg', st.color.fg};
    prop.lightbg    = {'backg', st.color.fg, 'foreg', [0 0 0]};
    if ~isempty(varargin), prop.darkbg = [varargin{:} prop.darkbg]; prop.lightbg = [varargin{:} prop.lightbg]; end
    prop.panel      = [prop.darkbg {'bordertype', 'none', 'titlepos', 'centertop', 'fontw', 'bold'}]; 
    prop.edit       = [prop.lightbg {'style', 'edit', 'horiz', 'center'}];
    prop.text       = [prop.darkbg {'style', 'text', 'horiz', 'center'}]; 
    prop.popup      = [prop.lightbg {'style', 'popup'}]; 
    prop.push       = [prop.darkbg {'style', 'push', 'horiz', 'center'}]; 
    prop.radio      = [prop.darkbg {'style', 'radio', 'horiz', 'center'}];
    prop.toggle     = [prop.darkbg {'style', 'toggle'}]; 
    prop.checkbox   = [prop.darkbg {'style', 'check'}]; 
    prop.listbox    = [prop.darkbg {'style', 'list'}]; 
function cmap   = default_colormaps(depth)
    if nargin==0, depth = 64; end
    cmap = [];
    cmap{1,1}   = [];
    cmap{1,2}   = 'signed';
    cmap{2,1}   = hot(depth);
    cmap{2,2}   = 'hot';
    cmap{3,1}   = cold(depth);
    cmap{3,2}   = 'cold';
    cmap{4,1}   = jet(depth);
    cmap{4,2}   = 'jet';
    cmap{5,1}   = [];
    cmap{5,2}   = 'cubehelix';
    cmap{6,1}   = [];
    cmap{6,2}   = 'linspecer';
    cmap{7,1}   = colorGray(depth);
    cmap{7,2}   = 'colorGray';
    anchor = size(cmap,1);
    bmap1 = {'Blues' 'Greens' 'Greys' 'Oranges' 'Purples' 'Reds'};
    for i = 1:length(bmap1)
        tmp = brewermap(50, bmap1{i});
        cmap{anchor+i,1} = cmap_upsample(tmp(11:end,:), depth); 
        cmap{anchor+i,2} = sprintf('%s', bmap1{i});
    end
    tmp1 = brewermap(36, '*Blues'); 
    tmp2 = brewermap(36, 'Reds');
    tmp3 = brewermap(36, 'Greens'); 
    cmap{end+1,1} = [tmp1(1:32,:); tmp2(5:36,:)]; 
    cmap{end,2} = 'Blues-Reds';
    cmap{end+1,1} = [tmp1(1:32,:); tmp3(5:36,:)]; 
    cmap{end,2} = 'Blues-Greens';
    bmap2 = {'Accent' 'Dark2' 'Paired' 'Pastel1' 'Pastel2' 'Set1' 'Set2' 'Set3'};
    bnum2 = [8 8 12 9 8 9 8 12];
    anchor = size(cmap,1); 
    for i = 1:length(bmap2)
        cmap{anchor+i,1} = cmap_upsample(brewermap(bnum2(i), bmap2{i}), depth); 
        cmap{anchor+i,2} = sprintf('%s (%d)', bmap2{i}, bnum2(i));
    end
function urls   = default_urls
urls = {
    'SPM'                               'http://www.fil.ion.ucl.ac.uk/spm/'
    'SPM Listserv'                      'https://www.jiscmail.ac.uk/cgi-bin/webadmin?REPORT&z=4&1=spm&L=spm'
    'SnPM'                              'http://www2.warwick.ac.uk/fac/sci/statistics/staff/academic-research/nichols/software/snpm/'
    'FSL'                               'http://fsl.fmrib.ox.ac.uk/fsl/fslwiki/'
    'AFNI'                              'https://afni.nimh.nih.gov/afni/'
    'Freesurfer'                        'http://www.freesurfer.net/'
    'Caret'                             'http://brainvis.wustl.edu/wiki/index.php/Caret:About'
    'MIALAB'                            'http://mialab.mrn.org/software/'
    'NITRC'                             'https://www.nitrc.org/'
    'Tom Nichols Software'              'http://www2.warwick.ac.uk/fac/sci/statistics/staff/academic-research/nichols/software/'
    'Aaron Schultz Software (MR Tools)' 'http://mrtools.mgh.harvard.edu/index.php/Main_Page'
    'NeuroVault'                        'http://neurovault.org'
    'Human Connectome Project'          'http://www.humanconnectome.org/software/'
};
urls = cell2struct(urls, {'label' 'url'}, 2);
function labs   = default_labels
    labs  = struct( ...
            'atlasname'     ,   'AnatomyToolbox'      , ...
            'alphacorrect'  ,   .05         , ...
            'separation'    ,   20          , ...
            'numpeaks'      ,   3           , ...
            'alphauncorrect',   .001        , ...
            'clusterextent' ,   5           , ...
            'surfshow'      ,   4           , ...
            'surface'       ,   'Inflated'  , ...
            'shading'       ,   'Sulc'      , ...
            'nverts'        ,   40962       , ...
            'round'         ,   false       , ...
            'neighbor'      ,   0           , ...
            'dilate'        ,   false       , ...
            'shadingmin'    ,   .15         , ...
            'shadingmax'    ,   .70         , ...
            'colorbar'      ,   true          ...
        );
function uicell = default_lowerpane
    global st
    prop = default_properties('units', 'norm', 'fontn', 'arial', 'fonts', st.fonts.sz2);
    uicell = { ...
        1, 4, 1, 'Current Location'     , 'uititle'     , prop.text ;   ...
        2, 4, 1, ''                    , 'Location'    , [prop.edit {'Enable', 'Inactive'}] ;   ...
        3, 1, 1, ''                    , 'rowspacer'   , []        ;   ...
        4, 4, 3, 'Value'               , 'uilabel'     , prop.text ;   ...
        4, 4, 5, 'Coordinate'          , 'uilabel'     , prop.text ;   ...
        4, 4, 3, 'ClusterSize'         , 'uilabel'     , prop.text ;   ...
        5, 4, 3, ''                    , 'voxval'      , [prop.edit {'Enable', 'Inactive'}] ;   ...
        5, 4, 5, ''                    , 'xyz'         , [prop.edit {'Callback', @cb_changexyz}] ;   ...
        5, 4, 3, ''                    , 'clustersize' , [prop.edit {'Enable', 'Inactive'}] ;   ...
        6, 2, 1, ''                    , 'rowspacer'   , []        ;   ...
        7, 4, 1, 'Threshold' , 'uititle'     , prop.text ;  ...
        8, 4, 3, 'Extent'              , 'uilabel'     , prop.text ;   ...
        8, 4, 4, 'Thresh'              , 'uilabel'     , prop.text ;   ...
        8, 4, 6, 'P-Value'             , 'uilabel'     , prop.text ;   ...
        9, 4, 3, ''                    , 'Extent'      , [prop.edit {'Callback', @cb_updateoverlay}] ;   ...
        9, 4, 4, ''                    , 'Thresh'      , [prop.edit {'Callback', @cb_updateoverlay}] ;   ...
        9, 4, 6, ''                    , 'P-Value'     , [prop.edit {'Callback', @cb_updateoverlay}] ;   ...
       10, 1, 1, ''                    , 'rowspacer'   , []        ;   ...
       11, 4, 2, 'DF'                  , 'uilabel'     , prop.text ;   ...
       11, 4, 5, 'Type'          , 'uilabel'     , prop.text ;   ...
       12, 4, 2, ''                    , 'DF'          , [prop.edit {'Callback', @cb_updateoverlay}] ;   ...
       12, 4, 5, {'User-specified' 'Voxel FWE' 'Cluster FWE'}                    , 'Correction'  , [prop.popup {'Value', 1, 'Callback', @cb_correct}]     ...
    };
function uicell = default_upperpane

    global st
    prop = default_properties('units', 'norm', 'fontn', 'arial');
        
    uicell = { ...    
    1, 1, 1, ''                    , 'rowspacer'   , []        ;   ...
    2, 5, 4, 'Direction'          , 'uititle'     , prop.text ;   ...
    2, 5, 2, '+'                    , 'direct'  , [prop.radio {'fontunits', 'points', 'pos', [0 0 1 1], 'Callback', @cb_directmenu}] ;  ...
    2, 5, 2, '-'                    , 'direct'  , [prop.radio {'fontunits', 'points', 'pos', [0 0 1 1], 'Callback', @cb_directmenu}] ;  ...
    2, 5, 3, '+/-'                    , 'direct'  , [prop.radio {'fontunits', 'points', 'pos', [0 0 1 1], 'Callback', @cb_directmenu}] ;  ...
    2, 5, .5, ''                    , 'rowspacer'   , []        ;   ...
    2, 5, 4, 'Colormap'           , 'uititle'     , [prop.text {'fontsize', st.fonts.sz3}] ;   ...
    2, 5, 4, st.cmap(:,2)         , 'colormaplist'  , [prop.popup {'Value', 1, 'pos', [0 0 1 .95], 'Callback', @setcolormap, 'fonts', st.fonts.sz3}] ;  ...
    2, 5, 2, ''                     , 'minval'  , [prop.edit {'pos', [0 .10 1 .80], 'Callback', @cb_minval, 'fonts', st.fonts.sz3}] ;  ...
    2, 5, 2, ''                     , 'maxval'  , [prop.edit {'pos', [0 .10 1 .80], 'Callback', @cb_maxval, 'fonts', st.fonts.sz3}] ;  ...
    3, 1, 1, ''                    , 'rowspacer'   , []        ;   ...

    };
    
% | GUI COMPONENTS
% =========================================================================
function S = put_figure(ol, ul)

    default_preferences(1);
    
    % | Check for open GUI, close if one is found
    delete(findobj(0, 'tag', 'bspmview'));
    
    global st
    
    % | Setup new fig
    if isfield(st.preferences, 'fontname'), st.fonts.name   = st.preferences.fontname; end
    if isfield(st.preferences, 'color')
        st.color   = st.preferences.color; 
    else
        st.color   = default_colors;
    end
    S.hFig  = figure(...
            'Name', abridgepath(ol), ...
            'Units', 'pixels', ...
            'Position',st.pos.gui,...
            'Resize','off',...
            'Color',st.color.bg,...
            'ColorMap',gray(64),...
            'NumberTitle','off',...
            'DockControls','off',...
            'MenuBar','none',...
            'Tag', 'bspmview', ...
            'CloseRequestFcn', @cb_closegui, ...
            'DefaultTextColor', st.color.font,...
            'DefaultTextInterpreter','none',...
            'DefaultTextFontName','Arial',...
            'DefaultTextFontSize',st.fonts.sz6,...
            'DefaultAxesColor',st.color.border,...
            'DefaultAxesXColor',st.color.border,...
            'DefaultAxesYColor',st.color.border,...
            'DefaultAxesZColor',st.color.border,...
            'DefaultAxesFontName','Arial',...
            'DefaultPatchFaceColor',st.color.fg,...
            'DefaultPatchEdgeColor',st.color.fg,...
            'DefaultSurfaceEdgeColor',st.color.fg,...
            'DefaultLineColor',st.color.border,...
            'DefaultUicontrolFontName',st.fonts.name,...
            'DefaultUicontrolFontSize',st.fonts.sz3,...
            'DefaultUicontrolInterruptible','on',...
            'Visible','off',...
            'Toolbar','none');
    uicontrol('Parent', S.hFig, 'Units', 'Normal', 'Style', 'Text', ...
    'pos', [0 0 1 .001], 'backg', st.color.blues(8,:));
    uicontrol('Parent', S.hFig, 'Units', 'Normal', 'Style', 'Text', ...
    'pos', [0 .001 .001 1], 'backg', st.color.blues(10,:));
    uicontrol('Parent', S.hFig, 'Units', 'Normal', 'Style', 'Text', ...
    'pos', [.999 .001 .001 .999], 'backg', st.color.blues(10,:));

    % | REGISTRY OBJECT (HREG)
    S.hReg = uipanel('Parent',S.hFig,'Units','Pixels','Position',st.pos.pane.axes,...
            'BorderType', 'none', 'BackgroundColor',st.color.bg);
    set(S.hReg, 'units', 'norm');
    [st.fig, st.figax, st.direct] = deal(S.hFig, S.hReg, '+/-');
    bspm_orthviews('Reset');
    st.cmap     = default_colormaps(64); 
    load_overlay(ol, st.preferences.alphauncorrect, st.preferences.clusterextent);
    bspm_XYZreg('InitReg',S.hReg,st.ol.M,st.ol.DIM,[0;0;0]); % initialize registry object
    st.ho = bspm_orthviews('Image', ul, [.025 .025 .95 .95]);
    bspm_orthviews('Register', S.hReg);
    bspm_orthviews('MaxBB');
    setposition_axes; 
    setxhaircolor;
    put_figmenu; 
    put_upperpane;
    put_lowerpane;
    put_axesxyz; 
    put_axesmenu;
    setthresh(st.ol.C0(3,:), find(strcmpi({'+', '-', '+/-'}, st.direct))); 
    setmaxima;
    setcolormap;
    setfontunits('points'); 
    setunits;
    check4design;
    cb_minmax;
    if nargout, S.handles = gethandles; end
function put_startupmsg
    global st bspmview_version
    [v,r] = spm('Ver','',1);
    st.version.bspmview = bspmview_version; 
    st.version.spm = sprintf('%s_r%s', v, r);
    st.version.matlab = version;
    st.version.computer = computer; 
    [mv, mstr] = version; 
    matlabyear = str2double(regexp(mstr, '\d\d\d\d$', 'match'));
    if matlabyear < 2014
        fprintf(['\nWARNING: This software has only been tested on MATLAB R2014a and later.' ...
                '\nYou are using MATLAB v%s. You may encounter errors.\n\n'], st.version.matlab); 
    end
    if str2double(r) < 6313
        fprintf(['\nWARNING: This software has only been tested with SPM8 (r6313) and SPM12.' ...
                '\nYou are currently using %s (%s). You may encounter errors.\n\n'], v, r); 
    end
    printmsg(sprintf('Started %s', nicetime), sprintf('BSPMVIEW v.%s', bspmview_version));   
function put_upperpane(varargin)

    global st
    cnamepos     = [.01 .15 .98 .85]; 
    prop = default_properties('units', 'norm', 'fontn', 'arial', 'fonts', st.fonts.sz3);
    panelh       = uipanel('parent',st.fig, prop.panel{:}, 'pos', st.pos.pane.upper, 'tag', 'upperpanel');
    uicell = default_upperpane; 
    griddim         = cell2mat(uicell(:,1:3));
    lowpanedim      = unique(griddim(:,1:2), 'rows'); 
    nrow            = size(lowpanedim, 1); 
    
    [phandle, pidx] = pgrid(nrow, 1, ...
        'parent', panelh, ...
        'relheight', lowpanedim(:,2), ...
        'panelsep', 0, ...
        'marginsep', .01, ...
        'backg', st.color.bg, ...
        'foreg', st.color.fg);
    uihandles       = []; 
    for r = 1:nrow
        spec = uicell(griddim(:,1)==r, 3:end);
        ncol = size(spec, 1); 
        if ncol > 1
            chandle = pgrid(1, ncol, ...
                'parent', phandle(r), ...
                'relwidth', cell2mat(spec(:,1)), ...
                'panelsep', .01, ...
                'marginsep', 0, ...
                'backg', st.color.bg, ...
                'foreg', st.color.fg); 
        else
            chandle = phandle(r); 
        end
        uihandles = [uihandles; chandle]; 
    end  
    spaceridx = cellfun('isempty', uicell(:,end));
    uihandles(spaceridx) = []; 
    uicell(spaceridx,:) = []; 
    for i = 1:length(uihandles), ph(i) = uicontrol(uihandles(i), 'string', uicell{i, 4}, uicell{i, 6}{:}, 'pos', [0 0 1 1], 'tag', uicell{i, 5}); drawnow; end
    set(findall(panelh, 'tag', 'uititle'), 'fontsize', st.fonts.sz2, 'fontweight', 'bold');  
    
     % | Check valid directions for contrast display
    allh    = findobj(st.fig, 'Tag', 'direct');
    set(allh, 'FontSize', st.fonts.sz2*1.25); 
    allhstr = get(allh, 'String');
    if any(st.ol.null)
        opt = {'+' '-'}; 
        set(allh(strcmpi(allhstr, '+/-')), 'Value', 0, 'Enable', 'inactive', 'Visible', 'on');
        set(allh(strcmpi(allhstr, opt{st.ol.null})), 'Value', 0, 'Enable', 'inactive',  'Visible', 'on');
        set(allh(strcmpi(allhstr, opt{st.ol.null==0})), 'Value', 1, 'Enable', 'inactive');
    else
        set(allh(strcmpi(allhstr, '+/-')), 'value', 1, 'enable', 'inactive'); 
    end
    set(panelh, 'units', 'norm');
    drawnow;
function put_lowerpane(varargin)

    global st
    
    % | UNITS
    figpos  = get(st.fig, 'pos');
    axpos   = get(st.figax, 'pos');
    figw    = figpos(3);
    axw     = axpos(3); 

    % | PANEL
    [h,subaxpos] = gethandles_axes;
    lowpos = subaxpos(1,:);
    lowpos(1) = subaxpos(3, 1) + .01; 
    lowpos(3) = 1 - lowpos(1);
    prop = default_properties('units', 'norm', 'fontn', 'arial', 'fonts', st.fonts.sz2);
    panelh = uipanel('parent', st.figax, prop.panel{:}, 'pos',lowpos, 'tag', 'lowerpanel');
    uicell = default_lowerpane;
    griddim         = cell2mat(uicell(:,1:3));
    lowpanedim      = unique(griddim(:,1:2), 'rows'); 
    nrow            = size(lowpanedim, 1); 
    [phandle, pidx] = pgrid(nrow, 1, ...
        'parent', panelh, ...
        'relheight', lowpanedim(:,2), ...
        'panelsep', .01, ...
        'marginsep', .025, ...
        'backg', st.color.bg, ...
        'foreg', st.color.fg);
    uihandles       = []; 
    for r = 1:nrow
        spec = uicell(griddim(:,1)==r, 3:end);
        ncol = size(spec, 1); 
        if ncol > 1
            chandle = pgrid(1, ncol, ...
                'parent', phandle(r), ...
                'relwidth', cell2mat(spec(:,1)), ...
                'panelsep', .025, ...
                'marginsep', 0, ...
                'backg', st.color.bg, ...
                'foreg', st.color.fg); 
        else
            chandle = phandle(r); 
        end
        uihandles = [uihandles; chandle]; 
    end 
    spaceridx = cellfun('isempty', uicell(:,end)); 
    uihandles(spaceridx) = []; 
    uicell(spaceridx,:) = []; 
    for i = 1:length(uihandles), ph(i) = uicontrol(uihandles(i), 'string', uicell{i, 4}, uicell{i, 6}{:}, 'pos', [0 0 1 1], 'tag', uicell{i, 5}); drawnow; end
    set(findall(panelh, 'tag', 'uititle'), 'fontsize', st.fonts.sz1, 'fontweight', 'bold');  
    set(findall(panelh, 'Enable', 'Inactive'), 'backg', st.color.fg*.80);
    set(panelh, 'units', 'norm');
    setthreshinfo;
function put_figmenu
    global st
    global bspmview_version
    %% Main Menu
    S.menu1         = uimenu('Parent', st.fig, 'Label', 'bspmVIEW');
    S.version       = uimenu(S.menu1, 'Label', sprintf('v.%s', bspmview_version) , 'Enable', 'off');
    S.checkversion  = uimenu(S.menu1, 'Label', 'Check for Updates', 'Callback', @cb_checkversion);  
    S.appear        = uimenu(S.menu1, 'Label','Appearance', 'Separator', 'on'); 
    S.skin          = uimenu(S.appear, 'Label', 'Skin');
%     if isfield(st.preferences, 'light')
%         S.changeskin(1) = uimenu(S.skin, 'Label', 'Dark', 'Checked', st.preferences.dark, 'Callback', @cb_changeskin);
%         S.changeskin(2) = uimenu(S.skin, 'Label', 'Light', 'Checked', st.preferences.light, 'Separator', 'on', 'Callback',@cb_changeskin);
%     else
    S.changeskin(1) = uimenu(S.skin, 'Label', 'Dark', 'Checked', 'on', 'Callback', @cb_changeskin);
    S.changeskin(2) = uimenu(S.skin, 'Label', 'Light', 'Separator', 'on', 'Callback',@cb_changeskin);
%     end
    S.guisize       = uimenu(S.appear, 'Label','GUI Size'); 
    S.gui(1)        = uimenu(S.guisize, 'Label', 'Increase', 'Accelerator', 'i', 'Callback', @cb_changeguisize);
    S.gui(2)        = uimenu(S.guisize, 'Label', 'Decrease', 'Accelerator', 'd', 'Separator', 'on', 'Callback',@cb_changeguisize);
    S.fontsize      = uimenu(S.appear, 'Label','Font Size'); 
    S.font(1)       = uimenu(S.fontsize, 'Label', 'Increase', 'Accelerator', '=', 'Callback', @cb_changefontsize);
    S.font(2)       = uimenu(S.fontsize, 'Label', 'Decrease', 'Accelerator', '-', 'Callback',@cb_changefontsize);
%     S.fontname      = uimenu(S.appear, 'Label','Font Name', 'Callback', @cb_changefontname);
%     S.setasdef      = uimenu(S.appear, 'Label', 'Set Current as Default', 'Separator', 'on', 'Callback', @cb_setasdefault);

    %% Help Menu
    S.helpme        = uimenu(S.menu1,'Label','Help', 'Separator', 'on');
    S.helpme1       = uimenu(S.helpme,'Label','Online Manual', 'CallBack', {@cb_web, 'http://spunt.github.io/bspmview/'});
    S.helpme2       = uimenu(S.helpme,'Label','Online Issues Forum', 'CallBack', {@cb_web, 'https://github.com/spunt/bspmview/issues'});
    S.helpme3       = uimenu(S.helpme,'Label','Submit Issue or Feature Request', 'CallBack', {@cb_web, 'https://github.com/spunt/bspmview/issues/new'});
    S.debug         = uimenu(S.helpme,'Label','Debug', 'Separator', 'on');     
    S.debug1        = uimenu(S.debug, 'Label','Open GUI M-File', 'Callback', @cb_opencode);
    S.debug2        = uimenu(S.debug, 'Label','Run UIINSPECT', 'Callback', @cb_uiinspect);
    S.exit          = uimenu(S.menu1, 'Label', 'Exit', 'Separator', 'on', 'Callback', {@cb_closegui, st.fig});
    
    %% Make sure resize callbacks are registered one at a time
    set(S.gui, 'BusyAction', 'cancel', 'Interruptible', 'off'); 
    set(S.font, 'BusyAction', 'cancel', 'Interruptible', 'off');
    
    %% Load Menu
    S.load    = uimenu(st.fig,'Label','Load', 'Separator', 'on');
    S.loadol  = uimenu(S.load,'Label','New Overlay', 'Accelerator', 'o', 'CallBack', @cb_loadol);
    S.resetol = uimenu(S.load,'Label','Current Overlay (Reload)', 'CallBack', @cb_resetol);
    S.loadul  = uimenu(S.load,'Label','New Underlay', 'Accelerator', 'u', 'Separator', 'on', 'CallBack', @cb_loadul);
    
    %% Save Menu
    S.save          = uimenu(st.fig,'Label','Save', 'Separator', 'on');
    S.saveintensity = uimenu(S.save,'Label','Save Suprathreshold (Intensity)','CallBack', @cb_saveimg);
    S.savemask      = uimenu(S.save,'Label','Save Suprathreshold (Binary Mask)', 'CallBack', @cb_saveimg);
    S.ctsavemap     = uimenu(S.save,'Label', 'Save Current Cluster (Intensity)', 'callback', @cb_saveclust, 'separator', 'on');
    S.ctsavemask    = uimenu(S.save,'Label', 'Save Current Cluster (Binary Mask)', 'callback', @cb_saveclust);
    S.saveroi       = uimenu(S.save,'Label', 'Save ROI at Current Location', 'CallBack', @cb_saveroi);
    S.savetable     = uimenu(S.save,'Label','Save Results Table', 'Separator', 'on', 'CallBack', @cb_savetable, 'separator', 'on');
    S.savergb       = uimenu(S.save,'Label','Save Screen Capture', 'callback', @cb_savergb);
    
    %% Options Menu
    S.options    = uimenu(st.fig,'Label','Display', 'Separator', 'on');
    S.prefs      = uimenu(S.options, 'Label','Preferences', 'Accelerator', 'P', 'Callback', @cb_preferences); 
    S.report     = uimenu(S.options,'Label','Show Results Table', 'Accelerator', 't', 'Separator', 'on', 'CallBack', @cb_report);
    S.render     = uimenu(S.options,'Label','Show Surface Rendering',  'Accelerator', 'r', 'CallBack', @cb_render);
    S.slice      = uimenu(S.options,'Label','Show Slice Montage', 'Accelerator', 's', 'CallBack', @cb_montage);
    S.smoothmap  = uimenu(S.options,'Label','Apply Smoothing to Overlay', 'Separator', 'on', 'CallBack', @cb_smooth);
    S.smoothmap  = uimenu(S.options,'Label','Apply Mask to Overlay','CallBack', @cb_mask);
    S.xhairtoggle   = uimenu(S.options, 'Label', 'Toggle Crosshairs', 'Accelerator', 'c', 'Tag', 'Crosshairs', 'Checked', 'on', 'CallBack', {@cb_crosshair, 'toggle'}, 'Separator', 'on');
    S.xhaircolor    = uimenu(S.options, 'Label', 'Change Crosshair Color', 'CallBack', {@cb_crosshair, 'color'});
    S.reversemap    = uimenu(S.options,'Label','Reverse Color Map', 'Tag', 'reversemap', 'Checked', 'off', 'CallBack', @cb_reversemap, 'Separator', 'on');

    %% Web Menu
    S.web(1) = uimenu(st.fig,'Label','Web', 'Separator', 'on');
    urls   = default_urls;
    for i = 1:length(urls), S.web(i+1) = uimenu(S.web(1),'Label',urls(i).label, 'Callback', {@cb_web, urls(i).url}); end
    S.web(length(urls)+1) = uimenu(S.web(1),'Label','Search Location in Neurosynth', 'CallBack', @cb_neurosynth);
    
    %% Status 
    S.status = uimenu(st.fig, 'Label', '|    Status: Ready', 'Enable', 'off', 'Tag', 'status');
function put_axesmenu
    [h,axpos]  = gethandles_axes;
    cmenu      = uicontextmenu;
    ctmax      = uimenu(cmenu, 'Label', 'Go to Global Peak', 'callback', @cb_minmax, 'separator', 'off');
    ctlocalmax = uimenu(cmenu, 'Label', 'Go to Nearest Peak', 'callback', @cb_localmax); 
    ctclustmax = uimenu(cmenu, 'Label', 'Go to Cluster Peak', 'callback', @cb_clustminmax);
    ctplot     = uimenu(cmenu, 'Label', 'Plot', 'separator', 'on');
    spaceopt   = {'Cluster' 'Voxel' 'Shape around Voxel'};
    dataopt    = {'Raw' 'Whitened And Filtered'};
    for c = 1:length(spaceopt)
        hs(c) = uimenu(ctplot, 'Label', spaceopt{c});
        for i = 1:length(dataopt)
            uimenu(hs(c), 'Label', dataopt{i}, 'callback', {@cb_clustexplore, spaceopt{c}, dataopt{i}});
        end
    end
    ctsave     = uimenu(cmenu, 'Label', 'Save', 'separator', 'on');
    ctsavemap  = uimenu(ctsave, 'Label', 'Save Current Cluster (Intensity)', 'callback', @cb_saveclust);
    ctsavemask = uimenu(ctsave, 'Label', 'Save Current Cluster (Binary Mask)', 'callback', @cb_saveclust);
    ctsaveroi  = uimenu(ctsave, 'Label', 'Save ROI at Current Location', 'callback', @cb_saveroi);
    ctsavergb  = uimenu(ctsave, 'Label', 'Save Screen Capture', 'callback', @cb_savergb);
    ctns       = uimenu(cmenu, 'Label', 'Search Location in Neurosynth',  'CallBack', @cb_neurosynth, 'separator', 'on');  
    ctxhair    = uimenu(cmenu, 'Label', 'Toggle Crosshairs', 'checked', 'on', 'Accelerator', 'c', 'Tag', 'Crosshairs', 'callback', {@cb_crosshair, 'toggle'}, 'separator', 'on'); 
    for a = 1:3
        set(h.ax(a), 'uicontextmenu', cmenu); 
    end
    drawnow;
function put_axesxyz
    global st
    h = gethandles_axes;
    xyz = round(bspm_XYZreg('GetCoords',st.registry.hReg));
    xyzstr = num2str([-99; xyz]); xyzstr(1,:) = [];
    set(h.ax, 'YAxislocation', 'right'); 
    axidx = [3 2 1]; 
    for a = 1:length(axidx)
        yh = get(h.ax(axidx(a)), 'YLabel'); 
        st.vols{1}.ax{axidx(a)}.xyz = yh; 
        if a==1
            set(yh, 'units', 'norm', 'fontunits', 'norm', 'fontsize', .075, ...
                'pos', [0 1 0], 'horiz', 'left', 'fontname', 'arial', ...
                'color', [1 1 1], 'string', xyzstr(a,:), 'rot', 0, 'tag', 'xyzlabel');
            set(yh, 'fontunits', 'points'); 
            fs = get(yh, 'fontsize');
        else
            set(yh, 'units', 'norm', 'fontsize', fs, ...
                'pos', [0 1 0], 'horiz', 'left', 'fontname', 'arial', ...
                'color', [1 1 1], 'string', xyzstr(a,:), 'rot', 0, 'tag', 'xyzlabel');
        end
    end
    drawnow;
function put_upperpaneinfo(parent)
    global st
    

    data = struct2cell(st.ol.finfo);
    data = data(2:3);  
    
    th = uitable('Parent', parent, ...
        'Data', data, ...
        'Units', 'norm', ...
        'ColumnName', [], ...
        'RowName', [], ...
        'Pos', [0 0 1 1], ...
        'RearrangeableColumns', 'on', ...
        'ColumnWidth', 'auto', ...
        'FontName', 'Fixed-Width', ...
        'FontUnits', 'Points', ...
        'FontSize', st.fonts.sz4);
    
    % | Column Width
    set(th, 'units', 'pix');
    set(parent, 'units', 'pix');
    textent = get(th, 'extent');
    tpos    = get(th, 'Pos'); 
    fpos    = get(parent, 'pos'); 
    ht      = diff([tpos([2 4])]); 
    hw      = diff([fpos([1 3])])*.975;
    tpos(2) = [tpos(4) - textent(4)]; 
    tpos(4) = textent(4); 
    set(th, 'ColumnWidth', {hw}, 'Position', tpos); 
    set(parent, 'units', 'pix'); 
    set(th, 'units', 'norm');
    drawnow;

% | CALLBACKS - THRESHOLDING
% =========================================================================
function cb_updateoverlay(varargin)
    global st
    % | Check for Numeric Input
%     if isempty(varargin) || isnan(str2double(get(varargin{1}, 'string')))
%         setthreshinfo; 
%         return
%     end
    htype       = findobj(st.fig, 'tag', 'Correction');
    htypestr    = get(htype, 'string');
    userstr     = 'User-specified'; 
    T0  = getthresh;
    T   = T0;
    di  = strcmpi({'+' '-' '+/-'}, T.direct);
    if nargin > 0
        tag = get(varargin{1}, 'tag');
        switch tag
            case {'Thresh'}
                if T.df~=Inf, T.pval = bob_t2p(T.thresh, T.df); end
                if find(strcmpi(htypestr, 'Cluster FWE'))==get(htype, 'value')
                    T.extent = cluster_correct(st.ol.fname, T.pval, st.preferences.alphacorrect, max(st.ol.C));
                else
                    set(htype, 'value', find(strcmpi(htypestr, userstr)));
                end
                
            case {'P-Value'}
                if T.df~=Inf, T.thresh = spm_invTcdf(1-T.pval, T.df); end
                if find(strcmpi(htypestr, 'Cluster FWE'))==get(htype, 'value')
                    T.extent = cluster_correct(st.ol.fname, T.pval, st.preferences.alphacorrect, max(st.ol.C));
                else
                    set(htype, 'value', find(strcmpi(htypestr, userstr)));
                end
            case {'DF'}
                if ~any([T.pval T.df]==Inf)
                    T.thresh = spm_invTcdf(1-T.pval, T.df); 
                    T.pval = bob_t2p(T.thresh, T.df);
                end
                if find(strcmpi(htypestr, 'Cluster FWE'))==get(htype, 'value')
                    T.extent = cluster_correct(st.ol.fname, T.pval, st.preferences.alphacorrect, max(st.ol.C));
                else
                    set(htype, 'value', find(strcmpi(htypestr, userstr)));
                end
            case {'Extent'}
                if find(strcmpi(htypestr, 'Cluster FWE'))==get(htype, 'value')
                    set(htype, 'value', find(strcmpi(htypestr, userstr))); 
                end
                if sum(st.ol.C0(di,st.ol.C0(di,:)>=T.extent))==0
                    headsup('No suprathreshold clusters. Setting extent to largest cluster size at current intensity threshold.');      
                    T.extent = max(st.ol.C0(di,:));
                end
        end
    end
    [st.ol.C0, st.ol.C0IDX] = getclustidx(st.ol.Y, T.thresh, T.extent);
    C = st.ol.C0(di,:); 
    if sum(C(C>=T.extent))==0
        setthreshinfo;
%         T0.thresh = st.ol.U; 
%         setthreshinfo(T0);
        headsup('No suprathreshold voxels. Reverting to previous threshold.'); 
        return
    end
    setthresh(C, find(di)); 
    setthreshinfo(T);
    setmaxima;
    drawnow;
function cb_correct(varargin)
    setstatus('Working, please wait...'); 
    global st
    str = get(varargin{1}, 'string');
    methodstr = str{get(varargin{1}, 'value')};
    T0 = getthresh;
    T = T0; 
    di = strcmpi({'+' '-' '+/-'}, T.direct); 
    switch methodstr
        case {'User-specified'}
            cb_resetol; 
            setstatus('Ready'); 
            return;
        case {'Voxel FWE'}
            T.thresh    = voxel_correct(st.ol.fname, st.preferences.alphacorrect);
            T.pval      = bob_t2p(T.thresh, T.df);
        case {'Cluster FWE'}
%             T.extent = cluster_correct(st.ol.fname, T0.pval, st.preferences.alphacorrect, max(st.ol.C));
            T.extent = cluster_correct(st.ol.fname, T0.pval, st.preferences.alphacorrect);
    end
    [st.ol.C0, st.ol.C0IDX] = getclustidx(st.ol.Y, T.thresh, T.extent);
    C = st.ol.C0(di,:); 
    if sum(C(C>=T.extent))==0
        T0.thresh = st.ol.U; 
        setthreshinfo(T0);
        headsup('No suprathreshold voxels. Reverting to previous threshold.');
        set(varargin{1}, 'value', 1);
        setstatus('Ready'); 
        return
    end
    setthresh(C, find(di)); 
    setthreshinfo(T);
    setstatus('Ready'); 
function cb_directmenu(varargin)
    global st
    if ischar(varargin{1}), str = varargin{1}; 
    else str = get(varargin{1}, 'string'); end
    % | See If Colormap Update is in Order
    if ismember(str, {'+' '-'}) & strcmp(st.direct, '+/-')
        htmp        = findobj(st.fig, 'Tag', 'colormaplist'); 
        set(htmp, 'value', find(strcmpi(get(htmp, 'String'), 'hot'))); 
    elseif strcmp(str, '+/-')
        htmp        = findobj(st.fig, 'Tag', 'colormaplist'); 
        set(htmp, 'value', find(strcmpi(get(htmp, 'String'), 'signed'))); 
    end
    allh = findobj(st.fig, 'Tag', 'direct'); 
    allhstr = get(allh, 'String');
    set(allh(strcmp(allhstr, str)), 'Value', 1, 'Enable', 'inactive'); 
    set(allh(~strcmp(allhstr, str)), 'Value', 0, 'Enable', 'on');
    drawnow;
    T       = getthresh;
    di      = strcmpi({'+' '-' '+/-'}, T.direct);
    [st.ol.C0, st.ol.C0IDX] = getclustidx(st.ol.Y, T.thresh, T.extent);
    C       = st.ol.C0(di,:);
    y       = st.ol.Y(C>0); 
    ydi     = [any(y>0) any(y<0) (any(y>0) & any(y<0))];
    if ~ydi(di)
        lab = {'positive' 'negative'};
        if find(di)==3 && any(ydi)
            
            headsup(sprintf('No %s suprathreshold voxels. Showing unthresholded image.', lab{ydi(1:2)==0}));
        else
            headsup('No suprathreshold voxels. Showing unthresholded image.');
        end
        T.thresh = 0.0001; 
        T.pval = bob_t2p(T.thresh, T.df);
        T.extent = 1; 
        [st.ol.C0, st.ol.C0IDX] = getclustidx(st.ol.Y, T.thresh, T.extent);
        C = st.ol.C0(di,:);
        setthreshinfo(T);
    end
    setthreshinfo(T); 
    setthresh(C, find(di));
    
% | CALLBACKS - BSPMVIEW MENU
% =========================================================================
function cb_setasdefault(varargin)
    global st
    % | POSITION
    % st.preferences.guipos   = get(st.fig, 'pos');
    if get(findobj(st.fig, 'Label', 'Light'), 'Checked')
        st.preferences.color = default_colors(0);
    else
        st.preferences.color = default_colors(1); 
    end
    deffile = fullfile(getenv('HOME'), 'bspmview_preferences.mat');
    st.preferences.dark = get(findobj(st.fig, 'label', 'Dark'), 'checked'); 
    st.preferences.light = get(findobj(st.fig, 'label', 'Light'), 'checked'); 
    def     = st.preferences; 
    save(deffile, '-struct', 'def'); 
    h = headsup('Default Appearance Updated', 'Success', 0);
    pause(.50); 
    delete(h);
function cb_changeguisize(varargin)
    global st
    F = 0.9; 
    if strcmp(get(varargin{1}, 'Label'), 'Increase'), F = 1.1; end
    guipos = get(st.fig, 'pos');
    guipos(3:4) = guipos(3:4)*F; 
    set(st.fig, 'pos', guipos);
    pause(.50);
    drawnow;
function cb_changefontname(varargin)
    global st
    T = uisetfont
    T.FontName = 'DejaVu Sans Mono';
    T.FontWeight = 'normal';
    T.FontAngle = 'normal';
    T.FontUnits = 'points';
    T.FontSize = 14;
    pause(.25);
    drawnow;
function cb_changefontsize(varargin)
    global st
    minsize = 5; 
    F = -1; 
    if strcmp(get(varargin{1}, 'Label'), 'Increase'), F = 1; end
    setfontunits('points'); 
    h   = findall(st.fig, '-property', 'FontSize');
    fs  = cell2mat(get(h, 'FontSize')) + F;
    h(fs<minsize) = []; 
    fs(fs<minsize)  = [];
    arrayfun(@set, h, repmat({'FontSize'}, length(h), 1), num2cell(fs))
    pause(.50);
    drawnow;
    setfontunits('norm'); 
function cb_changeskin(varargin)
    if strcmpi(get(varargin{1},'Checked'), 'on'), return; end
    global st
    skin = get(varargin{1}, 'Label');
    h       = gethandles; 
    col     = st.color; 
    switch lower(skin)
        case {'dark'}
            st.color = default_colors(1);
            set(findobj(st.fig, 'Label', 'Dark'), 'Checked', 'on'); 
            set(findobj(st.fig, 'Label', 'Light'), 'Checked', 'off'); 
        case {'light'}
            st.color = default_colors(0);
            set(findobj(st.fig, 'Label', 'Dark'), 'Checked', 'off'); 
            set(findobj(st.fig, 'Label', 'Light'), 'Checked', 'on'); 
    end
    set(st.fig, 'color', st.color.bg); 
    set(findall(st.fig, '-property', 'ycolor'), 'ycolor', st.color.bg);
    set(findall(st.fig, '-property', 'xcolor'), 'xcolor', st.color.bg);
    al = findall(h.lowerpanel, 'type', 'axes'); 
    ul = findall(h.upperpanel, 'type', 'axes'); 
    set([al; ul], 'color', st.color.bg); 
    al = findall(h.lowerpanel, 'type', 'text'); 
    ul = findall(h.upperpanel, 'type', 'text'); 
    set([al; ul], 'color', st.color.fg); 
    set(findall(st.fig, 'type', 'uipanel'), 'backg', st.color.bg, 'foreg', st.color.fg);
    set(findall(st.fig, 'type', 'uicontrol', 'style', 'text'), 'backg', st.color.bg, 'foreg', st.color.fg);
    set(findall(st.fig, 'style', 'radio'), 'backg', st.color.bg, 'foreg', st.color.fg);
    set(h.colorbar, 'ycolor', st.color.fg); 
    set(varargin{1}, 'Checked', 'on'); 
    drawnow;
function cb_opencode(varargin)
    open(mfilename('fullpath'));
function cb_uiinspect(varargin)
    global st
    setstatus('Running UIINSPECT, please wait...'); 
    uiinspect(st.fig);
    setstatus('Ready');
function cb_checkversion(varargin)
    global bspmview_version
    url     = 'https://github.com/spunt/bspmview/blob/master/README.md';
    h       = headsup('Checking GitHub repository. Please be patient.', 'Checking Version', 0);
    try
        str = webread(url);
    catch
        set(h(2), 'String', 'Could not read web data. Are you connected to the internet?');
        figure(h(1)); 
        return
    end
    [idx1, idx2] = regexp(str, 'Version:  ');
    gitversion = str(idx2+1:idx2+8);
    if strcmp(bspmview_version, gitversion)
        delete(h(1)); 
        headsup('You have the latest version.', 'Checking Version', 1);
        return; 
    else
        delete(h(1)); 
        answer = yesorno('An update is available. Would you like to download the latest version?', 'Update Available');
        if strcmpi(answer, 'Yes')
            guidir      = fileparts(mfilename('fullpath')); 
            newguidir   = fullfile(fileparts(guidir), 'bspmview-master');
            url         = 'https://github.com/spunt/bspmview/archive/master.zip';
            h = headsup('Downloading...', 'Please Wait', 0);
            unzip(url, fileparts(guidir));
            delete(h(1));
            h = headsup(sprintf('Latest version saved to: %s', newguidir), 'Update', 1);
        else
            return; 
        end
    end     
function cb_closegui(varargin)
   if length(varargin)==3, h = varargin{3};
   else h = varargin{1}; end
   rmpath(fullfile(fileparts(mfilename('fullpath')), 'supportfiles')); 
   delete(h); % Bye-bye figure 
   
% | CALLBACKS - SAVE MENU
% =========================================================================
function cb_saveimg(varargin)
    global st
    lab     = get(varargin{1}, 'label');
    outimg  = getcurrentoverlay; 
    outhdr  = st.ol.hdr;
    putmsg  = 'Save intensity image as'; 
    outhdr.descrip = 'Thresholded Intensity Image'; 
    [p,n] = fileparts(outhdr.fname); 
    deffn = sprintf('%s%sThresh_%s.nii', p, filesep, n);  
    if regexpi(lab, 'Binary Mask')
        outimg(outimg~=0)     = 1;
        outhdr.descrip = 'Thresholded Mask Image'; 
        putmsg = 'Save mask image as'; 
        deffn = sprintf('%s%sMask_%s.nii', p, filesep, n);  
    end
    fn = uiputvol(deffn, putmsg);
    if isempty(fn), disp('User cancelled.'); return; end
    outhdr.fname = fn; 
    spm_write_vol(outhdr, outimg);
    fprintf('\nImage saved to %s\n', fn);         
function cb_saveclust(varargin)
    global st
    str = get(findobj(st.fig, 'tag', 'clustersize'), 'string'); 
    if strcmp(str, 'n/a'), return; end
    lab            = get(varargin{1}, 'label');
    blob           = getcurrentblob; 
    rname          = sprintf('%s (x=%d, y=%d, z=%d)', blob.label, blob.xyz);
    outimg         = st.ol.Y; 
    outhdr         = st.ol.hdr; 
    outimg(~blob.clidx) = 0; 
    putmsg         = 'Save cluster'; 
    outhdr.descrip = 'Intensity Thresholded Cluster Image'; 
    [p,n]          = fileparts(outhdr.fname); 
    deffn          = sprintf('%s%sCluster_%s_x=%d_y=%d_z=%d_%svoxels.nii', p, filesep, n, blob.xyz, str);  
    if regexp(lab, 'Binary Mask')
        outimg(outimg~=0)     = 1;
        outhdr.descrip        = 'Binary Mask Cluster Image'; 
        putmsg                = 'Save mask image as'; 
        deffn                 = sprintf('%s%sClusterMask_%s_x=%d_y=%d_z=%d_%svoxels.nii', p, filesep, n, blob.xyz, str);   
    end
    fn           = uiputvol(deffn, putmsg);
    if isempty(fn), disp('User cancelled.'); return; end
    outhdr.fname = fn; 
    spm_write_vol(outhdr, outimg);
    fprintf('\nCluster image saved to %s\n', fn);     
function cb_saveroi(varargin)
    global st
    [roi, button] = settingsdlg(...  
    'title'                     ,   'ROI Parameters', ...
    {'Intersect ROI with Overlay?'; 'intersectflag'}    ,  true, ...
    {'Shape'; 'shape'}          ,   {'Sphere' 'Box'}, ...
    {'Size (mm)'; 'size'}       ,   12);
    if strcmpi(button, 'cancel'), return; end
    xyz             = getroundvoxel; 
    cROI            = growregion(roi, xyz);
    cHDR            = st.ol.hdr;
    cHDR.descrip    = sprintf('ROI - x=%d, y=%d, z=%d - %s %d', xyz, roi.shape, roi.size); 
    [p,n]           = fileparts(cHDR.fname); 
    deffn           = sprintf('%s/ROI_x=%d_y=%d_z=%d_%dvoxels_%s%d.nii', p, xyz, sum(cROI(:)), roi.shape, roi.size);  
    putmsg          = 'Save ROI as'; 
    fn              = uiputvol(deffn, putmsg);
    if isempty(fn), disp('User cancelled.'); return; end
    cHDR.fname      = fn; 
    spm_write_vol(cHDR,cROI);
    fprintf('\nROI image saved to %s\n', fn);     
function cb_savergb(varargin)
    %% Handles for axes
    % 1 - transverse
    % 2 - coronal
    % 3 - sagittal 
    % st.vols{1}.ax{1}.ax   - axes
    % st.vols{1}.ax{1}.d    - image
    % st.vols{1}.ax{1}.lx   - crosshair (x)
    % st.vols{1}.ax{1}.ly   - crosshair (y)
    global st
    setbackgcolor;
    im = screencapture(st.fig);
    setbackgcolor(st.color.bg)
    [imname, pname] = uiputfile({'*.png; *.jpg; *.pdf', 'Image'; '*.*', 'All Files (*.*)'}, 'Specify output directory and name', construct_filename);
    if ~imname, disp('User cancelled.'); return; end
    imwrite(im, fullfile(pname, imname)); 
    fprintf('\nImage saved to %s\n', fullfile(pname, imname));   
   
% | CALLBACKS - LOAD MENU
% =========================================================================    
function cb_loadol(varargin)
    global st
    fname = uigetvol('Select an Image File for Overlay', 0);
    if isempty(fname), disp('An overlay image was not selected.'); return; end
    hcorrect = findobj(st.fig, 'tag', 'Correction');
    set(hcorrect, 'value', find(strcmpi(get(hcorrect, 'string'), 'User-specified'))); 
    T       = getthresh;
    if isinf(T.pval)
        load_overlay(fname);
    else
        load_overlay(fname, T.pval, T.extent);
    end
    
    di = strcmpi({'+' '-' '+/-'}, T.direct); 
    setthresh(st.ol.C0(find(di),:), find(di));
    setthreshinfo;
    check4design; 
    drawnow;
function cb_resetol(varargin)
    global st
    set(findobj(st.fig, 'Tag', 'Correction'), 'Value', 1); 
    load_overlay(st.ol.fname, st.preferences.alphauncorrect, st.preferences.clusterextent);
    di = strcmpi({'+' '-' '+/-'}, st.direct); 
    setthresh(st.ol.C0(find(di),:), find(di));
    setthreshinfo;
    drawnow; 
function cb_loadul(varargin)
    
    ul = uigetvol('Select an Image File for Underlay', 0);
    if isempty(ul), disp('An underlay image was not selected.'); return; end
    global st prevsect
    prevsect    = ul;
    h = gethandles_axes; 
    delete(h.ax);
    bspm_orthviews('Delete', st.ho);
    st.ho = bspm_orthviews('Image', ul, [.025 .025 .95 .95]);
    bspm_orthviews('MaxBB');
    bspm_orthviews('AddBlobs', st.ho, st.ol.XYZ, st.ol.Z, st.ol.M);
    bspm_orthviews('Register', st.registry.hReg);
    setposition_axes;
    setxhaircolor;
    put_axesxyz;
    put_axesmenu;
    h = findall(st.fig, 'Tag', 'Crosshairs'); 
    set(h,'Checked','on');
    bspm_orthviews('Xhairs','on') 
    drawnow;
    
% | CALLBACKS - DISPLAY MENU
% =========================================================================    
function cb_preferences(varargin)
    global st
    default_preferences; 
function cb_crosshair(varargin)
    global st
    state   = get(varargin{1},'Checked');
    h       = findall(st.fig, 'Tag', 'Crosshairs');
    switch lower(varargin{3})
        case 'toggle'
            if strcmpi(state,'on');
                bspm_orthviews('Xhairs','off'); set(h,'Checked','off');
            end
            if strcmpi(state,'off');
                bspm_orthviews('Xhairs','on'); set(h,'Checked','on');
            end
        case 'color'
            st.color.xhair = uisetcolor(st.color.xhair, 'Select Crosshair Color'); 
            setxhaircolor;
    end
    drawnow;
function cb_smooth(varargin)
global st
pos = get(st.fig, 'pos'); 
w   = pos(3)*.65;
[prefs, button] = settingsdlg(...
    'title'                             ,   'Smoothing Options',    ...
    'Description'                       ,   'To undo smoothing you apply, select "Reload Current Overlay Image" from the "Load" menu.', ...
    'WindowWidth'                       ,   w*(3/4),                      ...
    'ControlWidth'                      ,   w*(1/2),                    ...
    {'Select Method'; 'method'}         ,   {'Gaussian (spm_smooth.m)' 'Robust (smoothn.m)'}, ...
    {'Rescale result to have same MIN/MAX'; 'dorescale'}, false, ...
    {'Restrict to suprathreshold voxels?'; 'supraonly'}, false ...
    ); 
if strcmpi(button, 'cancel'), return; end
y       = st.ol.Y; 
if prefs.supraonly
    T           = getthresh; 
    di          = strcmpi({'+' '-' '+/-'}, T.direct); 
    clustidx    = st.ol.C0(di,:);
    opt         = [1 -1 1]; 
    y           = y*opt(di);
    y(clustidx==0) = NaN;
end
minmaxy = [nanmin(y(:)) nanmax(y(:))];
y(isnan(y)) = 0; 
switch prefs.method
    case {'Gaussian (spm_smooth.m)'}
        [OPTIONS, button] = settingsdlg(...
            'title'                             ,   'Smoothing Options',            ...
            'WindowWidth'                       ,   w*(2/3),                        ...
            'ControlWidth'                      ,   w*(1/3),                        ...
            {'Kernel (FWHM in mm)'; 'fwhm'}     ,   5);  
        if strcmpi(button, 'cancel'), return; end
        kmm     = repmat(OPTIONS.fwhm, 1, 3);
        kvox    = kmm./st.ol.VOX';
        spm_smooth(y, y, kvox); 
%         y = gauss3filter(y, OPTIONS.fwhm, st.ol.VOX');
    case {'Robust (smoothn.m)'}
         [OPTIONS, button] = settingsdlg(...
            'title'                     ,   'Robust Options', ...
            'WindowWidth'               ,   w,    ...
            'ControlWidth'              ,   w/2,    ...
            {'Tolerance (single value between 0 and 1)'; 'TolZ'}, .001, ...
            {'Maximum number of iterations allowed'; 'MaxIter'}, 100, ...
            {'Weight function for robust smoothing'; 'Weight'}, {'bisquare' 'talworth' 'cauchy'});
        if strcmpi(button, 'cancel'), return; end
        OPTIONS = rmfield(OPTIONS, {'WindowWidth' 'ControlWidth'}); 
        setstatus('Working, please wait...'); 
        y = smoothn(y, 'robust', OPTIONS); 
end
if prefs.dorescale
    y(isnan(y)) = 0; 
    y(y~=0) = scaledata(y(y~=0), minmaxy); 
end
st.ol.Y = y; 
cb_updateoverlay
setstatus('Ready'); 
function cb_mask(varargin)
    global st
    mfname = uigetvol('Select an Image File for Overlay');
    if isempty(mfname), disp('User cancelled.'); return; end
    setstatus('Working, please wait...'); 
    mask    = reslice_image(mfname, st.ol.fname);
    mask    = double(mask > 0);
    y       = st.ol.Y .* mask; 
    % | Check surviving voxels
    ydi     = [any(y(:)>0) any(y(:)<0) (any(y(:)>0) & any(y(:)<0))];
    di      = strcmpi({'+' '-' '+/-'}, st.direct);
    if ~ydi(di)
        headsup('No suprathreshold voxels remain after intersecting with mask. Doing nothing...');
        setstatus('Ready'); 
        return; 
    end
    st.ol.null 	= check4sign(y);
    st.ol.Y     = y; 
    cb_updateoverlay
    setstatus('Ready');
function cb_reversemap(varargin)
    state = get(varargin{1},'Checked');
    if strcmpi(state,'on');
        set(varargin{1},'Checked','off');
    else
        set(varargin{1},'Checked','on');
    end
%     global st
%     for i = 1:size(st.cmap, 1)
%        st.cmap{i,1} = st.cmap{i,1}(end:-1:1,:); 
%     end
    setcolormap;  
function cb_render(varargin)
    global st
    setstatus('Working, please wait...'); 
    T = getthresh; 
    direct = char(T.direct);
    
    obj = [];
    obj.figno = 0;
    obj.newfig = 1;
    obj.nearestneighbor = st.preferences.neighbor; % if = 1, only the value from the closest voxel will be used, useful for maskings and label images
    obj.cmapflag = st.preferences.colorbar;   
    obj.round = st.preferences.round;          % if = 1, rounds all values on the surface to nearest whole number.  Useful for masks       
    obj.shadingrange = [st.preferences.shadingmin st.preferences.shadingmax];
    obj.Nsurfs = st.preferences.surfshow ;
    
    % fsaverage map to use
    switch st.preferences.nverts
        case 642
            obj.fsaverage = 'fsaverage3.mat';
        case 2562
            obj.fsaverage = 'fsaverage4.mat';
        case 10242
            obj.fsaverage = 'fsaverage5.mat';
        case 40962
            obj.fsaverage = 'fsaverage6.mat';
        case 163842
            obj.fsaverage = 'fsaverage.mat';
        otherwise
    end
    
    obj.fsaverage       = fullfile(st.supportpath, obj.fsaverage); 
    obj.background      = [0 0 0];
    obj.figname         = st.ol.fname; 
    obj.mappingfile     = [];         
    obj.medialflag      = 1; 
    obj.direction       = direct; 
    obj.surface         = st.preferences.surface; 
    obj.shading         = st.preferences.shading;
    obj.colorlims       = [st.vols{1}.blobs{1}.min st.vols{1}.blobs{1}.max];
    
%     switch obj.surface
%         case 'white'
%             obj.shading = 'curv';
%             obj.shadingrange = [-2 2];
%         case 'pi'
%             obj.shading = 'mixed';
%             obj.shadingrange = [-2 2];
%         case 'inflated'
%             obj.shading = 'logcurv';
%             obj.shadingrange = [-.75 .75];
%         case 'pial'
%             obj.shading = 'curv';
%             obj.shadingrange = [-2 3];
%         otherwise
%             obj.shading = 'curv';
%             obj.shadingrange = [-2 3];
%     end

    % | Determine Input
    obj.input.m = getcurrentoverlay(st.preferences.dilate);
    obj.input.he = st.ol.hdr; 
    obj.input.m(obj.input.m==0) = NaN; 
    obj.overlaythresh       = 0;
    obj.reverse             = 0;
    if strcmpi(direct, '+/-'), obj.overlaythresh   = [0 0]; end
    obj.colormap    = getcolormap; 
    ss = get(0, 'ScreenSize');
    ts = floor(ss/2);     
    switch obj.Nsurfs
    case 4
       ts(4) = ts(4)*.90;
    case 2
       ts(4) = ts(4)*.60;
    case 'L Lateral'
       obj.Nsurfs = -1;
    case 1.9
       ts(4) = ts(4)*.60;
    case 2.1
       ts(4) = ts(4)*.60;
    otherwise
    end
    obj.position = ts; 
    [h1, hh1] = surfPlot6(obj);
    drawnow;
    setstatus('Ready'); 
 
% | CALLBACKS - WEB MENU
% =========================================================================
function cb_web(varargin)
stat = web(varargin{3}, '-browser');
if stat, headsup('Could not open a browser window.'); end
function cb_neurosynth(varargin)
    baseurl = 'http://neurosynth.org/locations/?x=%d&y=%d&z=%d&r=6';
    stat = web(sprintf(baseurl, getroundvoxel), '-browser');
    if stat, headsup('Could not open a browser window..'); end
       
% | CALLBACKS - CROSSHAIR LOCATION
% =========================================================================
function cb_clustminmax(varargin)
    global st
    str           = get(findobj(st.fig, 'tag', 'clustersize'), 'string'); 
    if strcmp(str, 'n/a'), return; end
    blob    = getcurrentblob;
    if all(blob.values < 0), blob.values = abs(blob.values); end
    xyz     = blob.clxyz(:, blob.values==max(blob.values));
    if size(xyz, 2) > 1
        printmsg(sprintf('Crosshair has been moved to 1 of %d voxels with the cluster maximum value', size(xyz, 2)), 'NOTE');
        xyz = xyz(:,randperm(size(xyz, 2)));
    end
    bspm_orthviews('reposition', xyz(:,1)); 
    drawnow;
function cb_localmax(varargin)
    global st
    xyz = bspm_XYZreg('NearestXYZ', bspm_XYZreg('RoundCoords',st.centre,st.ol.M,st.ol.DIM), st.ol.maxima);
    if size(xyz, 2) > 1
        printmsg(sprintf('Crosshair has been moved to 1 of %d voxels with the local maximum value', size(xyz, 2)), 'NOTE');
        xyz = xyz(:,randperm(size(xyz, 2)));
    end
    bspm_orthviews('reposition', xyz(:,1)); 
    drawnow;
function cb_minmax(varargin)
    global st
    xyz = st.ol.XYZmm(:,st.ol.Z==max(st.ol.Z));
    if size(xyz, 2) > 1
        printmsg(sprintf('Crosshair has been moved to 1 of %d voxels with the maximum value', size(xyz, 2)), 'NOTE');
        xyz = xyz(:,randperm(2));
    end
    bspm_orthviews('reposition', xyz(:,1)); 
    drawnow;
function cb_maxval(varargin)
    global st
    
    % | Check for Numeric Input
    if isnan(str2double(get(varargin{1}, 'string')))
        warndlg('Input must be numerical');
        mm = getminmax;
        set(varargin{1}, 'string', num2str(mm(2))); 
        return
    end
    val = str2double(get(varargin{1}, 'string'));
    bspm_orthviews('SetBlobsMax', 1, 1, val);
    redraw_colourbar(st.hld, 1, getminmax, (1:64)'+64);
    setcolormap; 
function cb_minval(varargin)
    global st
    % | Check for Numeric Input
    if isnan(str2double(get(varargin{1}, 'string')))
        warndlg('Input must be numerical');
        mm = getminmax;
        set(varargin{1}, 'string', num2str(mm(1))); 
        return
    end
    val = str2double(get(varargin{1}, 'string'));
    bspm_orthviews('SetBlobsMin', 1, 1, val);
    redraw_colourbar(st.hld, 1, getminmax, (1:64)'+64);
    setcolormap; 
function cb_changexyz(varargin)
    xyz = str2num(get(varargin{1}, 'string')); 
    bspm_orthviews('reposition', xyz');
    drawnow;
    
% | CALLBACKS - TABLE/REPORT
% =========================================================================
function cb_report(varargin)
    global st
    setstatus('Working, please wait...');    
    LOCMAX = st.ol.tab;
    LABELS = getregionnames(LOCMAX(:,3:5)');
    voxels = [cell(size(LABELS)) LABELS num2cell(LOCMAX)];
    voxels{1,1} = 'Positive'; 
    if any(LOCMAX(:,2)<0)
        tmpidx = find(LOCMAX(:,2)<0); 
        voxels{tmpidx(1),1} = 'Negative'; 
    end
    % get table position
    ss = get(0, 'ScreenSize');
    ts = floor(ss/3);
    fs = get(st.fig, 'Position');
    if ss(3)-sum(fs([1 3])) > ts(3)
        ts(1) = sum(fs([1 3]));
    else
        ts(1) = fs(1)-ts(3);
    end
    ts([2 4]) = fs([2 4]);
    % create table
    ts          = setposition_auxwindow;
    tfig        = figure('pos', ts, 'DockControls','off', 'MenuBar', 'none', 'Name', 'Report', 'Color', [1 1 1], 'NumberTitle', 'off', 'Visible', 'off'); 
    header      = {'Sign' 'Region Name' 'Extent' 'Stat' 'X' 'Y' 'Z'}; 
    colwidth    = repmat({'auto'}, 1, length(header)); 
    colwidth{2} = floor(ss(3)/10);
    th = uitable('Parent', tfig, ...
        'Data', voxels, ...
        'Units', 'norm', ...
        'ColumnName', header, ...
        'Pos', [0 0 1 1], ...
        'RearrangeableColumns', 'on', ...
        'ColumnEditable', [true true false false false false false], ...
        'ColumnWidth', colwidth, ...
        'FontName', 'Fixed-Width', ...
        'FontUnits', 'Points', ...
        'FontSize', st.fonts.sz4, ...
        'CellSelectionCallback',@cb_tablexyz);
    tfigmenu  = uimenu(tfig,'Label','Options');
    uimenu(tfigmenu,'Label','Save Report', 'CallBack', {@cb_savetable, th});
    uimenu(tfig, 'Label', '|  NOTE: "Sign" and "Region Name" columns are editable', 'Enable', 'off', 'Tag', 'status');
    set(th, 'units', 'pix'); 
    tpos    = get(th, 'extent');
    fpos    = get(tfig, 'pos'); 
    set(tfig, 'pos', [fpos(1:2) tpos(3:4)]);
    set(th, 'units', 'norm');
    set(th, 'pos', [0 0 1 1]); 
    set(tfig, 'vis', 'on');
    setstatus('Ready'); 
    drawnow;
function cb_tablexyz(varargin)
    tabrow  = varargin{2}.Indices(1);
    tabdata = get(varargin{1}, 'data'); 
    xyz     = cell2mat(tabdata(tabrow,5:7)); 
    bspm_orthviews('reposition', xyz');
    drawnow;
function cb_savetable(varargin)
    global st
    T       = getthresh;
    di      = strcmpi({'+' '-' '+/-'}, T.direct);
    if nargin < 3
        LOCMAX = st.ol.tab;
        LABELS = getregionnames(LOCMAX(:,3:5)');
        voxels = [cell(size(LABELS)) LABELS num2cell(LOCMAX)];
        voxels{1,1} = 'Positive'; 
        if any(LOCMAX(:,2)<0)
            tmpidx = find(LOCMAX(:,2)<0); 
            voxels{tmpidx(1),1} = 'Negative'; 
        end
    else
        voxels = get(varargin{3}, 'Data');
    end
    sep         = cell(1, size(voxels,2));
    h           = repmat(sep, 3, 1);
    h(:,1)      = {'Source Image' 'Thresholding' 'Note'}';
    h{1,2}        = sprintf('%s', st.ol.fname);
    h{2,2}        = sprintf('t > %2.4f; p < %2.4f; df = %d; minimum extent = %d', T.thresh, T.pval, T.df, T.extent);
    h{3,2}        = sprintf('Table shows all local maxima separated by more than %d mm. Regions were automatically labeled using the %s atlas. ', st.preferences.separation, st.preferences.atlasname);
    h{3,2}        = [h{3,2} 'x, y, and z =Montreal Neurological Institute (MNI) coordinates in the left-right, anterior-posterior, and inferior-superior dimensions, respectively.'];
    headers0    = [h; sep]; 
    headers1    = {'Contrast Name' '' '' '' 'MNI Coordinates' '' ''};
    headers2    = {'' 'Region Label' 'Extent' 't-value' 'x' 'y' 'z'};
    allcell     = [headers0; headers1; headers2; sep; voxels];
    [p, imname] = fileparts(st.ol.fname);
    diname      = {'Positive' 'Negative' 'PosNeg'}; 
    outname     = ['save_table_' imname '_' diname{di} '_I' num2str(T.thresh) '_C' num2str(T.extent) '_S' num2str(st.preferences.separation) '.xlsx'];
    [fname, pname] = uiputfile({'*.xlsx; *.csv', 'Spreadsheet Table'; '*.*', 'All Files (*.*)'}, 'Save Table As', outname);
    if ~fname, disp('User cancelled.'); return; end
    
    [tmp,fnameonly,ext] = fileparts(fname);
    if strcmpi(ext, '.csv'), writereport(allcell, fullfile(pname, fname)); return; end;
    try
        sts = bspm_xlwrite(fullfile(pname, fname), allcell, [], fullfile(st.supportpath, 'TABLE_TEMPLATE.xlsx')); 
    catch

        writereport(allcell, fullfile(pname, strcat(fnameonly, '.csv'))); 
    end    
    
% | CALLBACKS - SLICE MONTAGE
% =========================================================================
function cb_montage(varargin)
    global st
    
    pos = setposition_auxwindow; 
    % | View GUI
    viewopt     = {'sagittal','coronal', 'axial'};
    viewoptin   = strcat('|', viewopt);
    pref = menuN('Montage Settings', ...
                {strcat('p', viewoptin{:}),'Select View'; ...
              'x|hide colorbar|hide labels','Display Options'; ...
              't|t-stat', 'Colorbar Title'; ...
              't|auto', 'N Slices Per Row'}); 
    if strcmpi(pref, 'cancel'), return; end
    theview = viewopt{pref{1}};
    if any(pref{2}==1), cbar = []; else cbar = 2; end
    if any(pref{2}==2), labels = 'none'; else labels = []; end
    cbartitle = pref{3}; 
    if strcmpi(pref{4}, 'auto'), xslices = []; else xslices = str2num(pref{4}); end

    % | Slices GUI
    defslices   = unique(st.ol.maxima(strcmpi(viewopt, theview), :));
    goodset = 0; 
    while ~goodset
        idx = find(diff(defslices) <= st.ol.VOX(1)) + 1;
        if isempty(idx), goodset = 1; else defslices(idx(1)) = []; end
    end
    pref = menuN('Montage Settings', {['t|' num2str(defslices)], 'Slices to Display:'});
    if strcmpi(pref, 'cancel'), return; end
    if ischar(pref)
        slices2show = str2num(pref);
    else
        slices2show = pref; 
    end

    % | SLOVER
    % | ========================================================
    o = slover; 

    % | Underlay
    o.img(1).vol    = spm_vol(st.vols{1}.fname); 
    o.img(1).prop   = 1;

    % | Overlay
    T = getthresh; 
    di = strcmpi({'+' '-' '+/-'}, T.direct); 
    clustidx = st.ol.C0(di,:);
    opt = [1 -1 1]; 
    mat3d = st.ol.Y*opt(di);
    mat3d(clustidx==0) = NaN;
    o.img(2).vol = slover('matrix2vol', mat3d, st.ol.hdr.mat); 
    o.img(2).prop = 1; 
    o.img(2).type = 'split';
    o.img(2).range  = getminmax';
    o.img(2).cmap   = getcolormap;
    o.cbar          = cbar; 
    o.labels        = labels; 

    % | More Settings
    o.slices    = slices2show;
    o.transform = theview;
    o.refreshf  = 0;
    o.clf = 0; 
    o.resurrectf = 0;
    o.area.units = 'normalized';
    o.area.position = [0 0 1 1];
    o.area.halign = 'left';
    o.area.valign = 'bottom';
    if ~isempty(xslices), xslices = min([length(slices2show) xslices]) + ~isempty(cbar); end
    o.xslices = xslices; 
    o = fill_defaults(o); 

    % | Setup Figure Window
    o.figure = figure( ...
            'Renderer', 'painters',       ...
            'Inverthardcopy', 'off',    ...
            'Name', 'Slice Montage',        ...
            'NumberTitle', 'off',       ...
            'Position', setposition_auxwindow,   ...
            'Color', [0 0 0],    ...
            'DockControls','off', ...
            'MenuBar', 'None', ...
            'Visible', 'off');

    % | Menu Bar
    S.menu          = uimenu('Parent', o.figure, 'Label', 'File');
    S.guisize       = uimenu(S.menu, 'Label','GUI Size'); 
    S.gui(1)        = uimenu(S.guisize, 'Label', 'Increase GUI Size', 'Accelerator', 'i', 'Callback', {@cb_changesliceguisize, 1.1});
    S.gui(2)        = uimenu(S.guisize, 'Label', 'Decrease GUI Size', 'Accelerator', 'd', 'Separator', 'on', 'Callback',{@cb_changesliceguisize, 0.9});
    S.save          = uimenu(S.menu, 'Label', 'Save as', 'Callback', {@cb_savemontage, o.figure});
    S.settings      = uimenu(S.menu, 'Label', 'Create New', 'Callback', @cb_montage); 
    if ~strcmpi(o.labels, 'none')
        S.label         = uimenu('Parent', o.figure, 'Label', 'Labels'); 
        S.labelpos      = uimenu(S.label, 'Label', 'Label Position'); 
        S.skin          = uimenu(S.labelpos, 'Label', 'Bottom Left', 'Tag', 'positionmenu', 'Checked', 'on', 'Callback', {@cb_montagelabelposition, o.figure});
        S.skin          = uimenu(S.labelpos, 'Label', 'Bottom Right', 'Tag', 'positionmenu', 'Checked', 'off', 'Callback', {@cb_montagelabelposition, o.figure});
        S.skin          = uimenu(S.labelpos, 'Label', 'Top Left', 'Tag', 'positionmenu', 'Checked', 'off', 'Callback', {@cb_montagelabelposition, o.figure});
        S.skin          = uimenu(S.labelpos, 'Label', 'Top Right', 'Tag', 'positionmenu', 'Checked', 'off', 'Callback', {@cb_montagelabelposition, o.figure});
        S.labelfont     = uimenu(S.label, 'Label', 'Label Font Size', 'Separator', 'on');
        S.skin          = uimenu(S.labelfont, 'Label', 'Increase',  'Accelerator', '=', 'Callback', {@cb_montagelabelsize, o.figure});
        S.skin          = uimenu(S.labelfont, 'Label', 'Decrease',  'Accelerator', '-','Callback', {@cb_montagelabelsize, o.figure});
    end
    S.msg          = uimenu(o.figure, 'Label', '|  Right-Click to Delete Slices', 'Enable', 'off', 'Tag', 'status');

    
    
    % | Context Menu
    obj = paint(o);
    set(obj.figure, 'visible', 'off');
    set(findall(obj.figure, 'type', 'axes'), 'units', 'pixels');
    [hpan, hpos] = getpos_grid(findall(obj.figure, 'tag', 'slice overlay panel'));
    emptyidx = find(cellfun('isempty', get(hpan, 'children')));
    delete(hpan(emptyidx)); 
    hpan(emptyidx) = []; 
    hpos(emptyidx,:) = [];
    nrow = length(unique(hpos(:,2))); 
    if size(hpos, 1) > 1
        cmh = uicontextmenu;
        uimenu(cmh, 'Label', 'Delete Slice', 'callback', @cb_montagepaneldelete, 'separator', 'off');

        hstr = findall(obj.figure,  'type', 'text');
        set(hstr, 'tag', 'slicelabel');
        hpos(:,2) = hpos(:,2) - min(hpos(:,2));

        for i = 1:length(hpan)
           set(hpan(i), 'pos', hpos(i,:), 'uicontextmenu', cmh); 
           set(get(hpan(i), 'children'), 'uicontextmenu', cmh);
        end
    end
    if cbar
        
        hc = findobj(obj.figure, 'tag', 'cbar');
        
    
        % Context Menu
        set(hc, 'units', 'pix', 'fontunits', 'points');
        hcm = uicontextmenu;
        uimenu(hcm, 'Label', 'Edit', 'callback', {@cb_editcbar, hc});
        set(hc, 'uicontextmenu', hcm);
        set(get(hc, 'children'), 'uicontextmenu', hcm);
        
        % Position
        cpos = get(hc, 'position');
        cpos(1) = max(sum(hpos(:,[1 3]), 2)) + 20; 
        gridheight = max(sum(hpos(:,[2 4]), 2));
        cpos(4) = max([cpos(4) gridheight*.33]);
        cpos(2) = gridheight - cpos(4);
        cpos(3) = cpos(3)*.75; 
        set(hc, 'pos', cpos); 
        set(hc, 'units', 'norm');
        set(hc, 'yaxislocation', 'right', ...
            'ytick', get(hc, 'ylim'), ...
            'Box','off', ...
            'YDir','normal', ...
            'fontweight', 'normal', ...
            'XTickLabel',[], ...
            'XTick',[]);
        tick = get(hc, 'ytick'); 
        if any(tick(2:end-1)==0), tick = [tick(1) 0 tick(end)]; else tick = tick([1 end]); end
        set(hc, 'ytick', tick); 
        if ~isempty(cbartitle), ht = title(cbartitle, 'units', 'norm', 'fontunits', get(hc, 'fontunits'), 'parent', hc, 'tag', 'cbartitle', 'color', [1 1 1], 'fontsize', 1.1*get(hc,'fontsize')); end
        tightfig;
    else
        tightfig; 
    end
    if length(hpan) > 1
        ext = sortrows(cell2mat(get(hpan, 'pos')), -2);
        pht = sum([ext(1,[2 4])]);  
    else
        ext = get(hpan, 'pos');
        pht = ext(4);
    end
    set(obj.figure, 'units', 'pixel');
    fpos = get(obj.figure, 'pos');
    fpos(4) = ceil(pht); 
    set(obj.figure, 'pos', fpos); 
    if and(nrow==1, cbar)
       cpos = get(hc, 'pos');
       cpos([2 4]) = [.05 .85];
       set(hc, 'pos', cpos); 
    end
    set(obj.figure, 'units', 'norm', 'visible', 'on');
    arrayset(findall(obj.figure, '-property', 'units'), 'units', 'norm');
    arrayset(findall(obj.figure, '-property', 'fontunits'), 'fontunits', 'norm');
    drawnow; 
function cb_savemontage(varargin)
    defname = 'SliceMontage.png'; 
    [imname, pname] = uiputfile({'*.png; *.jpg; *.pdf; *.tiff; *.pdf; *.ps', 'Image'; '*.*', 'All Files (*.*)'}, 'Valid extensions: png, jpg, tiff, pdf, ps', defname);
    if ~imname, disp('User cancelled.'); return; end
    [p,n,e] = fileparts(imname);
    if isempty(e), e = '.png'; end
    if strcmpi(e, '.ps'), e = '.psc'; end
    if strcmpi(e, '.jpg'), e = '.jpeg'; end
    fmt = strcat('-', regexprep(e, '\.', 'd'));
    print(varargin{3}, fmt, strcat('-', 'painters'), strcat('-', 'noui'), fullfile(pname,n)); 
    fprintf('\nImage saved to %s\n', fullfile(pname, strcat(imname, e)));  
function cb_editcbar(varargin)
    inspect(varargin{3});
function cb_montagelabelposition(varargin)
    set(findall(varargin{3}, 'Tag', 'positionmenu'), 'Checked', 'off'); 
    hstr = findall(varargin{3},  'tag', 'slicelabel'); 
    set(hstr, 'units', 'norm');
    if length(hstr) > 1
        ext = cell2mat(get(hstr, 'extent'));
        ext = max(ext(:,3:4)); 
    else
        ext = get(hstr, 'extent');
        ext = ext(3:4); 
    end
    height = 1 - ext(2); 
    width = 1 - ext(1); 
    chosen = get(varargin{1}, 'Label'); 
    options = {'Bottom Left' 'Bottom Right' 'Top Left' 'Top Right'};
    pos = [ 0 0 0; width 0 0; 0 height 0; width height 0 ]; 
    set(hstr, 'Position', pos(strcmpi(options, chosen), :));
    set(varargin{1}, 'Checked', 'on'); 
    drawnow;
function cb_montagelabelsize(varargin)
    if strcmpi(get(varargin{1}, 'Label'), 'Increase'), F = 1; else F = -1; end
    hstr = findall(varargin{3},  '-property', 'FontSize'); 
    set(hstr, 'FontUnits', 'points');
    fs = cell2mat(get(hstr, 'FontSize')) + F;
    arrayfun(@set, hstr, repmat({'FontSize'}, length(hstr), 1), num2cell(fs))
    pause(.25);
    drawnow;
    set(hstr, 'Units', 'norm');
    tightfig; 
function cb_montagepaneldelete(varargin) 
    [hax, hpos] = getpos_grid(findall(gcf, 'tag', 'slice overlay panel'));
    nrow1 = length(unique(hpos(:,2))); 
    gcapos      = repmat(get(gca, 'pos'), length(hax), 1);
    gcaidx      = find(mean(hpos==gcapos, 2)==1);
    delete(hax(gcaidx)); 
    hax(gcaidx) = []; 
    for i = gcaidx:length(hax)
        set(hax(i), 'pos', hpos(i,:)); 
    end
    [hax, hpos] = getpos_grid(findall(gcf, 'tag', 'slice overlay panel'));
    nrow2 = length(unique(hpos(:,2)));
    hc = findobj(gcf, 'tag', 'cbar');  
    if all([nrow2<nrow1 ~isempty(hc) ])
        set(hc, 'units', 'norm');
        cpos = get(hc, 'position');
        if nrow2*hpos(1,4) < cpos(4)
            cpos(4) = hpos(1,4)*.95;
            cpos(2) = 1 - hpos(1,4); 
            set(hc, 'pos', cpos); 
        end
    end
    tightfig;
    drawnow; 
function cb_changesliceguisize(varargin)    
    [obj, f] = gcbo; 
    guipos = get(f, 'pos');
    guipos(3:4) = guipos(3:4)*varargin{3}; 
    set(f, 'pos', guipos);
    pause(.25);
    drawnow;
    
% | CALLBACKS - PLOT
% =========================================================================
function cb_clustexplore(varargin)

    global st
    
    str = get(findobj(st.fig, 'tag', 'clustersize'), 'string');
    if strcmp(str, 'n/a'), return; end

    %% Get Design Variable %%
    [impath, imname] = fileparts(st.ol.fname);
    if exist([impath filesep 'I.mat'],'file') 
        matfile     = [impath filesep 'I.mat']; 
        maskfile    = [impath filesep 'mask.nii'];
    elseif exist([impath filesep 'SPM.mat'],'file') 
        matfile     = [impath filesep 'SPM.mat'];
    else
        headsup('This feature requires that an SPM.mat or I.mat design in the same directory as the overlay image.'); 
        return; 
    end
    
    %% Load Design Variable %%
    load(matfile);
    if isfield(SPM, 'Sess')
        headsup('Image appears to be based on single-subject data. This feature supports only group-level results.');   
        return; 
    end
    xsDes       = SPM.xsDes;
    subhdr      = SPM.xY.VY;
    subcon      = {subhdr.fname}';
    subdescrip  = {subhdr.descrip}';
    nscan       = length(subcon);
    groupflag   = 0;
    
    switch lower(xsDes.Design)
        case 'one sample t-test'
            ncond       = 1;
            nsub        = nscan/ncond;
            [studydir, subname] = parentpath(subcon(:,1));
            subname     = regexprep(subname, '_', ' ');
            conname     = replace(subdescrip(1:ncond), {'.+\d:', '- All Sessions$', '_'}, {'' '' ' '}); 
        case 'two-sample t-test'
            ncond       = 1;
            npergroup   = sum(SPM.xX.X);
            conidx      = SPM.xX.X; 
            [studydir, subname] = parentpath(subcon(:,1));
            subname     = regexprep(subname, '_', ' ');
            conname     = replace(subdescrip(1:ncond), {'.+\d:', '- All Sessions$', '_'}, {'' '' ' '});
            groupflag   = 1; 
        case 'flexible factorial'
            ncond       = length(SPM.xX.iH);
            nsub        = nscan/ncond;
            subcon      = reshape(subcon, ncond, nsub)';
            [studydir, subname] = parentpath(subcon(:,1));
            subname     = regexprep(subname, '_', ' ');
            conname     = replace(subdescrip(1:ncond), {'.+\d:', '- All Sessions$', '_'}, {'' '' ' '}); 
        otherwise
            headsup('Unrecognized or unsupported design type! Click to return to the main window...'); 
            return; 
    end

    %% Check that contrast images exist on filesystem %%
    existidx = cellfun(@exist, subcon(:));
    if any(existidx==0)
        headsup(sprintf('Single-subject images could not be found. Subject directories should be in: %s', studydir));
        return; 
    end 

    %% Get Cluster Indices %%
    blob           = getcurrentblob; 
    rname          = sprintf('%s (x=%d, y=%d, z=%d)', blob.label, blob.xyz);

    %% Get Subject Data %%
    spacechoice = varargin{3};
    datachoice = varargin{4}; 
    switch lower(varargin{3})
        case 'cluster'
            dataidx = blob.clidx; 
        case 'voxel'
            dataidx = blob.xyzidx; 
        otherwise
            [roi, button] = settingsdlg(...  
            'title'                     ,   'ROI Parameters', ...
            {'Intersect ROI with Overlay?'; 'intersectflag'}    ,  true, ...
            {'Shape'; 'shape'}          ,   {'Sphere' 'Box'}, ...
            {'Size (mm)'; 'size'}       ,   12);
            if strcmpi(button, 'cancel'), return; end
            dataidx = growregion(roi, blob.xyz);
            dataidx = dataidx(:) > 0; 
    end
    data    = spm_get_data(SPM.xY.VY, st.ol.XYZ0(:, dataidx));
    data(data==0) = NaN;
    switch lower(varargin{4})
        case 'whitened and filtered'
            data = spm_filter(SPM.xX.K,SPM.xX.W*data);
    end
    if groupflag
        Mraw = NaN(max(npergroup), length(npergroup));
        M = Mraw; 
        K = Mraw; 
        for i = 1:size(conidx, 2) 
            idx        = find(conidx(:,i)); 
            Mraw(1:npergroup(i), i)    = nanmean(data(idx,:), 2);
            M(1:npergroup(i), i)       = nanmean(data(idx,:), 2);
            K(1:npergroup(i), i)       = sum(isnan(data(idx,:)), 2);
        end
        Z       = abs(oneoutzscore(M));
        DAT     = [subname num2cell([Z(~isnan(Z)) M(~isnan(Z)) K(~isnan(Z))])]; 
        DAT     = sortrows(DAT, -2);
        header  = {'Subject Name' 'Resp Z' 'Resp' 'N Missing Voxels'};
    else
        Mraw    = nanmean(data, 2);
        M       = nanmean(data, 2);
        K       = sum(isnan(data), 2);
        if ncond > 1
            M       = reshape(M, ncond, nsub)';
            K       = reshape(K, ncond, nsub)';
            Mavg    = nanmean(M, 2);
            Z       = abs(oneoutzscore(M)); 
            Zavg    = abs(oneoutzscore(Mavg));
            DAT     = [subname num2cell([Zavg Mavg K(:,1)])]; 
            DAT     = sortrows(DAT, -2);
            header  = {'Subject Name' 'Mean Resp Z' 'Mean Resp' 'N Missing Voxels'};
        else
            Z       = abs(oneoutzscore(M));
            DAT     = [subname num2cell([Z M K])]; 
            DAT     = sortrows(DAT, -2);
            header  = {'Subject Name' 'Resp Z' 'Resp' 'N Missing Voxels'};
        end
    end
    if groupflag
        ncond   = 2; 
        nsub    = nansum(npergroup);
        Mx      = [repmat(1, npergroup(1), 1); repmat(2, npergroup(2), 1)];
    else
        Mx      = repmat(1:ncond, nsub, 1);
    end

    % | CREATE FIGURE
    if length(varargin) < 5
        figpos = setposition_auxwindow; 
        hfig  =  figure( ...
           'Name'                     ,        'bspmview Plot'          ,...
           'Units'                    ,        'pix'                    ,...
           'Position'                 ,        figpos                   ,...
           'Resize'                   ,        'on'                     ,...
           'Color'                    ,        st.color.bg              ,...
           'Renderer'                 ,        'zbuffer'                ,...
           'NumberTitle'              ,        'off'                    ,...
           'DockControls'             ,        'off'                    ,...
           'MenuBar'                  ,        'figure'                 ,...
           'Toolbar'                  ,        'none'                   ,...
           'Tag'                      ,        'bspmviewplot'           ,...
           'Visible'                  ,        'on'                     ...
                               );
    else
        hfig = varargin{5};
    end
    
    % | CREATE GRID LAYOUT
    hgrid = pgrid(2, 1, 'relheight', [1 6], 'backg', [0 0 0]);
%     if ncond > 1, hgrid = pmerge(hgrid, 1:ncond); end

    % | PLOT
    set(hgrid(2:end), 'backg', st.color.fg);
    
%     for i = 1:ncond
        axhist = axes('parent', hgrid(2));
        axes(axhist);
        hscat = scatter(axhist, Mx(:), M(~isnan(M)));
%         plotdata(M(~isnan(M)), subname);
        for i = 1:ncond
            ln(i) = line([i-.125 i+.125], repmat(nanmean(M(:,i)), 1, 2), 'color', [0 0 0]);
            outidx = find(Z(:,i) > 2.5);
            if groupflag 
                csubname = subname(find(conidx(:,i)));
            else
                csubname = subname; 
            end
            if outidx, text(repmat(i+.01, length(outidx), 1), M(outidx, i), csubname(outidx), 'fontsize', st.fonts.sz6); end
        end
%     end

    % | FORMAT
    ylabel(axhist, varargin{4});
    Mmax = max(M(:)); Mmin = min(M(:)); Mrng = range(M(:));
    ylim    = [Mmin-(Mrng*.075) Mmax+(Mrng*.075)];
    set(axhist, ...
        'Fontname', st.fonts.name, ...
        'Fontsize', st.fonts.sz4, ...
        'ylim', ylim, ...
        'xlim', [.5 ncond+.5], ...
        'ytick', linspace(ylim(1), ylim(2), 5), ...
        'xtick', 1:ncond ...
        );
    yt  = get(axhist, 'ytick');
    yts = cell(size(yt)); 
    for i = 1:length(yt), yts{i} = sprintf('%.2f', yt(i)); end
    if groupflag
        set(axhist, 'yticklabel', yts, 'xticklabel', SPM.xX.name); 
        title(sprintf('%s | %s', char(conname), rname), 'Fontname', st.fonts.name, 'Fontsize', st.fonts.sz4);
    else
        set(axhist, 'yticklabel', yts, 'xticklabel', conname);
        title(rname, 'Fontname', st.fonts.name, 'Fontsize', st.fonts.sz4);
    end

%     % | TABLE
%     set(hgrid(1), 'units', 'pix');
%     tw = get(hgrid(1), 'pos');
%     tw = tw(3) - tw(1);
%     set(hgrid(1), 'units', 'norm');
% %     DAT(:,2:3) = cellnum2str(DAT(:,2:3));
% %     DAT(:,4) = cellnum2str(DAT(:,4), 0); 
%     th = uitable('Parent', hgrid(1), ...
%         'Data', DAT, ...
%         'Units', 'norm', ...
%         'RowName', [], ...
%         'ColumnName', header, ...
%         'Pos', [0 0 1 1], ...
%         'RearrangeableColumns', 'on', ...
%         'FontName', 'Fixed-Width', ...
%         'FontUnits', 'Points', ...
%         'FontSize', st.fonts.sz6);
%     set(th, 'units', 'pixels');
%     set(th, 'ColumnWidth', {tw/3 tw*(2/9) tw*(2/9) tw/5});
    
    % | MENU PANEL
    uigrid = pgrid(1, 3, 'marginsep', 0, 'panelsep', 0, 'parent', hgrid(1));
    set(uigrid, 'units', 'pixel');
    uipos = cell2mat(get(uigrid, 'pos'));
    
    % | IMAGE
    setunits('pixel');
    [h, relpos, abspos] = gethandles_axes;
    sim = imresize(screencapture(h.ax(2)), [uipos(1,end) NaN]); 
    cim = imresize(screencapture(h.ax(3)), [uipos(1,end) NaN]); 
    tim = [sim cim];
    axim = axes('parent', uigrid(end));
    axes(axim);
    imdisp(tim);
    set(axim, 'Units', 'Norm', 'Pos', [0 0 1 1]);  axis off; 
    uicontrol('parent', uigrid(1), 'units', 'norm', 'pos', [.1 .25 .8 .5], 'fontsize', st.fonts.sz3, 'style', 'push', 'string', 'Reload for New Location', 'callback', {@cb_clustexplore, spacechoice, datachoice, hfig});
%     h2 = pgrid(2, 1, 'parent', uigrid(2));
%     m(1) = uicontrol('parent', h2(1), 'units', 'norm', 'pos', [0 0 1 .5], 'backg', [0 0 0], 'foreg', [1 1 1], 'fontname', st.fonts.name, 'style', 'text', 'string', 'Change Plotted Variable');
%     dataopt = {'Mean across voxels - Raw' 'Mean across voxels - Whitened And Filtered' 'SD across voxels - Raw' 'SD across voxels - Whitened And Filtered'};
%     m(2) = uicontrol('parent', h2(2), 'units', 'norm', 'HorizontalAlignment', 'center', ....
%         'pos', [.1 .1 .8 .8], 'foreg', st.color.font, 'backg', st.color.edit, 'fontname', 'fixed-width', 'style', 'Popup', 'string', dataopt, 'value', 2, 'Callback', @cb_changevariable)
%     set(m, 'fontsize', st.fonts.sz3); 
    set(hfig, 'visible', 'on');
    setunits('norm');
    drawnow;
function cb_changevariable(varargin)

% | SETTERS
% =========================================================================
function setstatus(msg)
    global st
    basemsg = '|    Status: ';
    set(findobj(st.fig, 'Tag', 'status'), 'Label', sprintf('%s%s', basemsg, msg));
    drawnow; 
function setmaxima
    global st
    Dis = st.preferences.separation; 
    Num = st.preferences.numpeaks; 
    T   = getthresh;
    switch char(T.direct)
        case {'+', '-'}
            LOCMAX      = getmaxima(st.ol.Z, st.ol.XYZ, st.ol.M, Dis, Num);
        otherwise
            POS         = getmaxima(st.ol.Z, st.ol.XYZ, st.ol.M, Dis, Num);
            NEG         = getmaxima(st.ol.Z*-1, st.ol.XYZ, st.ol.M, Dis, Num);
            if ~isempty(NEG), NEG(:,2) = NEG(:,2)*-1; end
            LOCMAX      = [POS; NEG]; 
    end
    st.ol.tab       = LOCMAX; 
    st.ol.maxima    = LOCMAX(:,3:5)';
function setcolormap(varargin)
    global st
    newmap = getcolormap;
    cbh = st.vols{1}.blobs{1}.cbar; 
    cmap = [gray(64); newmap];
    set(findobj(cbh, 'type', 'image'), 'CData', (65:128)', 'CdataMapping', 'direct');
    set(st.fig, 'Colormap', cmap);
    mnmx = getminmax; 
    bspm_orthviews('SetBlobsMax', 1, 1, max(mnmx)); 
    set(findobj(st.fig, 'tag', 'maxval'), 'str',  sprintf('%2.3f',max(mnmx)));
    bspm_orthviews('SetBlobsMin', 1, 1, min(mnmx)); 
    set(findobj(st.fig, 'tag', 'minval'), 'str',  sprintf('%2.3f',min(mnmx)));
    drawnow;
function setfontunits(unitstr)
    if nargin==0, unitstr = 'norm'; end
    global st
    arrayset(findall(st.fig, '-property', 'fontunits'), 'fontunits', unitstr);
    drawnow; 
function setunits(theunits)
    if nargin==0, theunits = 'norm'; end
    global st
    arrayset(findall(st.fig, '-property', 'units'), 'units', theunits);
    set(st.fig, 'units', 'pixels'); 
    drawnow; 
function setposition_axes
    global st
    CBPIXSIZE = 100; 
    %% Handles for axes
    % 1 - transverse
    % 2 - coronal
    % 3 - sagittal 
    % st.vols{1}.ax{1}.ax   - axes
    % st.vols{1}.ax{1}.d    - image
    % st.vols{1}.ax{1}.lx   - crosshair (x)
    % st.vols{1}.ax{1}.ly   - crosshair (y)
    h = gethandles_axes;
    axpos = cell2mat(get(h.ax, 'pos'));
    axpos(1:2, 1)   = 0; 
    axpos(1, 2)     = 0;
    axpos(3, 1)     = sum(axpos(2,[1 3]))+.005; 
    axpos(2:3, 2)   = sum(axpos(1,[2 4]))+.005;
    pz  = axpos(1,:);
    py  = axpos(2,:);
    px  = axpos(3,:);
    zrat = pz(3)/pz(4);
    yrat = py(3)/py(4);
    xrat = px(3)/px(4);
    VL = sum(py([2 4])); 
    while VL < 1
        px(4) = px(4) + .001; 
        px(3) = px(4)*xrat; 
        py(4) = px(4); 
        py(3) = py(4)*yrat; 
        pz(3) = py(3); 
        pz(4) = pz(3)/zrat; 
        px(1) = sum(py([1 3]))+.005;
        py(2) = sum(pz([2 4]))+.005;
        px(2) = py(2); 
        VL = sum(py([2 4]));
    end
    axpos = [pz; py; px]; 
    for a = 1:3, set(h.ax(a), 'position', axpos(a,:)); end
    set(h.ax, 'units', 'pixels'); 
    axpos = cell2mat(get(h.ax, 'pos'));
    HL = round(sum(axpos(3, [1 3])) + CBPIXSIZE); 
    figsize = get(st.fig, 'pos'); 
    figsize(3) = HL; 
    set(st.fig, 'pos', figsize);
    for a = 1:3, set(h.ax(a), 'position', axpos(a,:)); end
    set(h.ax, 'units', 'norm');
    % deal with lower panel
    p = findobj(st.fig, 'tag', 'lowerpanel');
    unit0 = get(p, 'units');
    apos = get(h.ax(1), 'pos'); 
    ppos = [sum(apos([1 3]))+.01 apos(2) 1-.02-sum(apos([1 3])) apos(4)]; 
    set(p, 'units', 'norm', 'pos', ppos); 
    set(p, 'units', unit0); 
    bspm_orthviews('Redraw');
function pos = setposition_auxwindow
global st
ss = get(0, 'ScreenSize');
pos = floor(ss/3);
fs = get(st.fig, 'Position');
if ss(3)-sum(fs([1 3])) > pos(3)
    pos(1) = sum(fs([1 3]));
else
    pos(1) = fs(1)-pos(3);
end
pos([2 4]) = fs([2 4]);
function setthreshinfo(T)
    global st
    if nargin==0
        T = struct( ...
            'extent',   st.ol.K, ...
            'thresh',   st.ol.U, ...
            'pval',     st.ol.P, ...
            'df',       st.ol.DF, ...
            'direct',   st.direct);
    end
    % | Update st
    st.direct   = char(T.direct);
    st.ol.K     = T.extent;
    st.ol.U     = T.thresh;
    st.ol.P     = T.pval;
    st.ol.DF    = T.df;
    Tval        = [T.extent T.thresh T.pval T.df]; 
    Tstr        = {'Extent' 'Thresh' 'P-Value' 'DF'};
    Tstrform    = {'%d' '%2.2f' '%2.3f' '%d'};
    for i = 1:length(Tstr)
        set(findobj(st.fig, 'Tag', Tstr{i}), 'String', num2str(Tval(i))); 
        drawnow; 
    end
function setthresh(C, di)
    global st
    if nargin==1, di = 3; end
    idx = find(C > 0);
    if di==2
        st.ol.Z     = abs(st.ol.Y(idx));
    else
        st.ol.Z     = st.ol.Y(idx);
    end
    st.ol.Nunique   = length(unique(st.ol.Z)); 
    st.ol.XYZ       = st.ol.XYZ0(:,idx);
    st.ol.XYZmm     = st.ol.XYZmm0(:,idx);
    st.ol.C         = C(idx); 
    st.ol.atlas     = st.ol.atlas0(idx);
    if ~isfield(st.vols{1}, 'blobs')
        bspm_orthviews('RemoveBlobs', st.ho, st.ol.XYZ, st.ol.Z, st.ol.M);
        bspm_orthviews('AddBlobs', st.ho, st.ol.XYZ, st.ol.Z, st.ol.M);
    else
        bspm_orthviews('ReplaceBlobs', st.ho, st.ol.XYZ, st.ol.Z, st.ol.M);
    end
    setcolormap; 
    bspm_orthviews('Register', st.registry.hReg);
    bspm_orthviews('Reposition');
    setmaxima; 
    drawnow; 
function [voxval, clsize] = setvoxelinfo
    global st
    [nxyz,voxidx, d]    = getnearestvoxel; 
    [xyz, xyzidx, dist] = getroundvoxel;
    regionidx = st.ol.atlas0(xyzidx);
    if regionidx
        regionname = st.ol.atlaslabels.label{st.ol.atlaslabels.id==regionidx};
    else
        regionname = 'n/a'; 
    end
    if d > min(st.ol.VOX)
        voxval = 'n/a'; 
        clsize = 'n/a';
    else
        voxval = sprintf('%2.3f', st.ol.Z(voxidx));
        clsize = sprintf('%d', st.ol.C(voxidx));
    end
    set(findobj(st.fig, 'tag', 'Location'), 'string', regionname); 
    set(findobj(st.fig, 'tag', 'xyz'), 'string', sprintf('%d, %d, %d', xyz)); 
    set(findobj(st.fig, 'tag', 'voxval'), 'string', voxval); 
    set(findobj(st.fig, 'tag', 'clustersize'), 'string', clsize);
    axidx = [3 2 1];
    xyzstr = num2str([-99; xyz]); xyzstr(1,:) = [];
    for a = 1:length(axidx)
        set(st.vols{1}.ax{axidx(a)}.xyz, 'string', xyzstr(a,:)); 
    end
    drawnow;    % older version called drawnow with "limitrate" option;
function setbackgcolor(newcolor)
    global st
    if nargin==0, newcolor = st.color.bg; end
    prop = {'backg' 'ycolor' 'xcolor' 'zcolor'}; 
    for i = 1:length(prop)
        set(findobj(st.fig, prop{i}, st.color.bg), prop{i}, newcolor); 
    end
    h = gethandles_axes;
    set(h.ax, 'ycolor', newcolor, 'xcolor', newcolor); 
    drawnow;
function setxhaircolor(varargin)
    global st
    h = gethandles_axes;
    set(h.lx, 'color', st.color.xhair); 
    set(h.ly, 'color', st.color.xhair);
    drawnow;
function setregionname(varargin)
    global st
    [nxyz, voxidx, d]   = getnearestvoxel; 
    [xyz, xyzidx, dist] = getroundvoxel;
    regionidx           = st.ol.atlas0(xyzidx);
    if regionidx
        regionname = st.ol.atlaslabels.label{st.ol.atlaslabels.id==regionidx};
    else
        regionname = 'n/a'; 
    end
    set(findobj(st.fig, 'tag', 'Location'), 'string', regionname); 
    drawnow;
function setatlas(varargin)
    global st
    atlas_vol = fullfile(st.supportpath, sprintf('%s_Atlas_Map.nii', st.preferences.atlasname));
    if ~exist(atlas_vol, 'file')
        atlas_vol = fullfile(st.supportpath, sprintf('%s_Atlas_Map.nii.gz', st.preferences.atlasname)); 
    end
    atlas_labels    = fullfile(st.supportpath, sprintf('%s_Atlas_Labels.mat', st.preferences.atlasname)); 
    int             = 0; % 0=Nearest Neighbor, 1=Trilinear(default)
    atlasvol        = reslice_image(atlas_vol, st.ol.fname, int);
    atlasvol        = single(round(atlasvol(:)))';
    load(atlas_labels);
    st.ol.atlaslabels   = atlas; 
    st.ol.atlas0        = atlasvol;

% | GETTERS
% =========================================================================
function h                       = gethandles(varargin)
    global st
    h.axial = st.vols{1}.ax{1}.ax;
    h.coronal = st.vols{1}.ax{2}.ax;
    h.sagittal = st.vols{1}.ax{3}.ax;
    h.colorbar = st.vols{1}.blobs{1}.cbar;
    h.upperpanel = findobj(st.fig, 'tag', 'upperpanel'); 
    h.lowerpanel = findobj(st.fig, 'tag', 'lowerpanel'); 
function [cmap, cmapname]        = getcolormap
    global st
    
    val         = get(findobj(st.fig, 'Tag', 'colormaplist'), 'Value'); 
    list        = get(findobj(st.fig, 'Tag', 'colormaplist'), 'String');
    cmapname    = list{val};
    N = min([st.ol.Nunique, 64]); 
    switch lower(cmapname)
        case {'signed'}
            mnmx = getminmax; 
            zero_loc = (0 - mnmx(1))/(mnmx(2) - mnmx(1));
%             zero_loc = (0 - min(st.ol.Z))/(max(st.ol.Z) - min(st.ol.Z));
%             if zero_loc <= .10, zero_loc = .5; end
            if any([zero_loc <= 0 zero_loc >= 1])
                val = find(strcmpi(list, 'hot')); 
                set(findobj(st.fig, 'Tag', 'colormaplist'), 'Value', val); 
                cmap = st.cmap{val, 1};
            else
                cmap = colormap_signed(64, zero_loc);
            end
        case {'cubehelix'}
            cmap    = cmap_upsample(cubehelix(N), 64); 
        case {'linspecer'}
            if N < 13
                cmap    = cmap_upsample(linspecer(N,'qualitative'), 64);
            else
                cmap    = linspecer(N,'sequential'); 
            end      
        otherwise
            cmap = st.cmap{val, 1};
    end
    hrev = findobj(st.fig, 'tag', 'reversemap');
    revflag = strcmpi(get(hrev, 'Checked'), 'on'); 
    if revflag, cmap = cmap(end:-1:1,:); end
function mnmx                    = getminmax
global st
if isfield(st.vols{1}, 'blobs')
    mnmx = [st.vols{1}.blobs{1}.min st.vols{1}.blobs{1}.max];
else
    mnmx = [min(st.ol.Z) max(st.ol.Z)]; 
end
function [clustsize, clustidx]   = getclustidx(rawol, u, k)

    % raw data to XYZ
    DIM         = size(rawol); 
    [X,Y,Z]     = ndgrid(1:DIM(1),1:DIM(2),1:DIM(3));
    XYZ         = [X(:)';Y(:)';Z(:)'];
    pos         = zeros(1, size(XYZ, 2)); 
    neg         = pos; 
    clustidx    = zeros(3, size(XYZ, 2));
    
    % positive
    supra = (rawol(:)>u)';
    if sum(supra)
        tmp         = spm_clusters(XYZ(:, supra));
        clbin       = repmat(1:max(tmp), length(tmp), 1)==repmat(tmp', 1, max(tmp));
        pos(supra)  = sum(repmat(sum(clbin), size(tmp, 2), 1) .* clbin, 2)';
        clustidx(1,supra) = tmp;
    end
    pos(pos < k)    = 0; 
    
    % negative
    rawol = rawol*-1;
    supra = (rawol(:)>u)';  
    if sum(supra)
        tmp      = spm_clusters(XYZ(:, supra));
        clbin      = repmat(1:max(tmp), length(tmp), 1)==repmat(tmp', 1, max(tmp));
        neg(supra) = sum(repmat(sum(clbin), size(tmp, 2), 1) .* clbin, 2)';
        clustidx(2,supra) = tmp;
    end
    neg(neg < k) = 0;

    % both
    clustsize       = [pos; neg]; 
    clustsize(3,:)  = sum(clustsize);
    clustidx(3,:)   = sum(clustidx); 
function [h, axpos, absaxpos]    = gethandles_axes(varargin)
    global st
    axpos = zeros(3,4);
    if isfield(st.vols{1}, 'blobs');
        h.cb = st.vols{1}.blobs{1}.cbar; 
    end
    ppanel = get(findobj(st.fig, 'Tag', 'hReg'), 'Position');
    for a = 1:3
        tmp = st.vols{1}.ax{a};
        h.ax(a) = tmp.ax; 
        h.d(a)  = tmp.d;
        h.lx(a) = tmp.lx; 
        h.ly(a) = tmp.ly;
        axpos(a,:) = get(h.ax(a), 'position');
    end
    if nargout==3
       absaxpos = axpos; 
       absaxpos(:,1:2) =  absaxpos(:,1:2) + repmat(ppanel(1:2), 3, 1);
    end
function T                       = getthresh
    global st
    T.extent    = str2double(get(findobj(st.fig, 'Tag', 'Extent'), 'String')); 
    T.thresh    = str2double(get(findobj(st.fig, 'Tag', 'Thresh'), 'String'));
    T.pval      = str2double(get(findobj(st.fig, 'Tag', 'P-Value'), 'String'));
    T.df        = str2double(get(findobj(st.fig, 'Tag', 'DF'), 'String'));
    tmph = findobj(st.fig, 'Tag', 'direct'); 
    opt = get(tmph, 'String');
    T.direct = opt(find(cell2mat(get(tmph, 'Value'))));
    if strcmp(T.direct, 'pos/neg'), T.direct = '+/-'; end   
function [xyz, xyzidx, dist]     = getroundvoxel
    global st
    [xyz, dist] = bspm_XYZreg('RoundCoords',st.centre,st.ol.M,st.ol.DIM); 
    xyzidx      = bspm_XYZreg('FindXYZ', xyz, st.ol.XYZmm0); 
function [xyz, voxidx, dist]     = getnearestvoxel 
    global st
    [xyz, voxidx, dist] = bspm_XYZreg('NearestXYZ', bspm_XYZreg('RoundCoords',st.centre,st.ol.M,st.ol.DIM), st.ol.XYZmm);
function blob                    = getcurrentblob
    global st
    str = get(findobj(st.fig, 'tag', 'clustersize'), 'string'); 
    if strcmp(str, 'n/a'), blob = []; return; end
    [blob.xyz, blob.xyzidx]   = getroundvoxel; 
    blob.label          = char(getregionnames(blob.xyz));
    blob.thresh         = getthresh;
    di                  = strcmpi({'+' '-' '+/-'}, blob.thresh.direct);
    blob.clidx          = st.ol.C0IDX(di,:)==st.ol.C0IDX(di, blob.xyzidx);
    blob.clxyz          = st.ol.XYZmm0(:,blob.clidx); 
    blob.extent         = sum(blob.clidx);
    blob.values         = st.ol.Y(find(blob.clidx));
    blob                = orderfields(blob);
function y                       = getcurrentoverlay(dilateflag)
    if nargin==0, dilateflag = 0; end
    global st
    T           = getthresh; 
    di          = strcmpi({'+' '-' '+/-'}, T.direct); 
    clustidx    = st.ol.C0(di,:);
    opt         = [1 -1 1];
    y           = st.ol.Y*opt(di);
    y(clustidx==0)  = 0;
    y(isnan(y))     = 0; 
    if dilateflag, y = st.ol.Y.*dilate_image(double(y~=0)); end
function PEAK                    = getmaxima(Z, XYZ, M, Dis, Num)
[N,Z,XYZ,A,L]       = spm_max(Z,XYZ);
XYZmm               = M(1:3,:)*[XYZ; ones(1,size(XYZ,2))];
npeak   = 0;
PEAK    = [];
while numel(find(isfinite(Z)))
    %-Find largest remaining local maximum
    %------------------------------------------------------------------
    [U,i]   = max(Z);            %-largest maxima
    j       = find(A == A(i));   %-maxima in cluster
    npeak   = npeak + 1;         %-number of peaks
    extent  = N(i); 
    PEAK(npeak,:) = [extent U XYZmm(:,i)']; %-assign peak
    %-Print Num secondary maxima (> Dis mm apart)
    %------------------------------------------------------------------
    [l,q] = sort(-Z(j));                              % sort on Z value
    D     = i;
    for i = 1:length(q)
        d = j(q(i));
        if min(sqrt(sum((XYZmm(:,D)-repmat(XYZmm(:,d),1,size(D,2))).^2)))>Dis
            if length(D) < Num
                D          = [D d];
                npeak   = npeak + 1;         %-number of peaks
                PEAK(npeak,:) = [extent Z(d) XYZmm(:,d)']; %-assign peak
            end
        end
    end
    Z(j) = NaN;     % Set local maxima to NaN
end
function [regionname, regionidx] = getregionnames(xyz)
    global st
    if size(xyz,1)~=3, xyz = xyz'; end
    regionname  = repmat({'Location not in atlas'}, size(xyz, 2), 1); 
    regionidx   = zeros(size(xyz, 2), 1); 
    for i = 1:size(xyz,2)
        regionidx(i) = st.ol.atlas0(bspm_XYZreg('FindXYZ', xyz(:,i), st.ol.XYZmm0));
        if regionidx(i)
            regionname{i} = st.ol.atlaslabels.label{st.ol.atlaslabels.id==regionidx(i)};
        end
    end
function [hout, hpos, griddim]   = getpos_grid(h)
hpos        = [(1:length(h))' cell2mat(get(h, 'pos'))];
hpos        = sortrows(hpos, [-3 2]);
hout        = h(hpos(:,1));
hpos(:,1)   = [];
if nargout==3, griddim = [length(unique(hpos(:,2))) length(unique(hpos(:,1)))]; end

% | BUIPANEL
% =========================================================================
function h      = buipanel(parent, uilabels, uistyles, relwidth, varargin)
% BUIPANEL Create a panel and populate it with uicontrols
%
%  USAGE: h = buipanel(parent, uilabels, uistyles, uiwidths, varargin)
% __________________________________________________________________________
%  INPUTS 
%

% ---------------------- Copyright (C) 2014 Bob Spunt ----------------------
%	Created:  2014-10-08
%	Email:    spunt@caltech.edu
% __________________________________________________________________________
global st

easyparse(varargin, ... 
            { ...
            'panelposition', ...
            'paneltitleposition', ...
            'paneltitle', ...
            'panelborder', ... 
            'panelbackcolor',  ...
            'panelforecolor', ...
            'panelfontsize',  ...
            'panelfontname' ...
            'panelfontweight', ...
            'editbackcolor',  ...
            'editforecolor', ...
            'editfontsize',  ...
            'editfontname', ...
            'labelbackcolor',  ...
            'labelforecolor', ...
            'labelfontsize',  ...
            'labelfontname', ...
            'labelfontweight', ...
            'relheight', ...
            'marginsep', ...
            'uicontrolsep', ...
            'tag'}); 
defaults = easydefaults(...
            'paneltitleposition', 'centertop', ...
            'panelborder',      'none', ... 
            'panelbackcolor',   st.color.bg, ...
            'editbackcolor',    st.color.edit, ...
            'labelbackcolor',   st.color.bg, ...
            'panelforecolor',   st.color.fg, ...
            'editforecolor',    st.color.font, ...
            'labelforecolor',   st.color.fg, ...
            'panelfontname',    st.fonts.name, ...
            'editfontname',     'fixed-width', ...
            'labelfontname',    st.fonts.name, ...
            'panelfontsize',    st.fonts.sz2, ...
            'editfontsize',     st.fonts.sz3, ...
            'labelfontsize',    st.fonts.sz3, ...
            'panelfontweight',  'bold', ...
            'labelfontweight',  'bold', ...
            'relheight',        [6 7], ...
            'marginsep',        .025, ...
            'uicontrolsep',     .025);
if nargin==0, mfile_showhelp; disp(defaults); return; end

% | UNITS
unit0 = get(parent, 'units'); 
        
% | PANEL
set(parent, 'units', 'pixels')
pp          = get(parent, 'pos'); 
pp          = [pp(3:4) pp(3:4)]; 
P           = uipanel(parent, 'units', 'pix', 'pos', panelposition.*pp, 'title', paneltitle, ...
            'backg', panelbackcolor, 'foreg', panelforecolor, 'fontsize', panelfontsize, ...
            'fontname', panelfontname, 'bordertype', panelborder, 'fontweight', panelfontweight, 'titleposition', paneltitleposition);
labelprop   = {'parent', P, 'style', 'text', 'units', 'norm', 'fontsize', labelfontsize, 'fontname', labelfontname, 'foreg', labelforecolor, 'backg', labelbackcolor, 'fontweight', labelfontweight, 'tag', 'uilabel'}; 
editprop    = {'parent', P, 'units', 'norm', 'fontsize', editfontsize, 'fontname', editfontname, 'foreg', editforecolor, 'backg', editbackcolor}; 
propadd     = {'tag'};

% | UICONTROLS

pos         = getpositions(relwidth, relheight, marginsep, uicontrolsep);
editpos     = pos(pos(:,1)==1,3:6); 
labelpos    = pos(pos(:,1)==2, 3:6); 
hc          = zeros(length(uilabels), 1);
he          = zeros(length(uilabels), 1); 
for i = 1:length(uilabels)
    ctag = ~cellfun('isempty', regexpi({'editbox', 'slider', 'listbox', 'popup'}, uistyles{i}));
    ttag = ~cellfun('isempty', regexpi({'text'}, uistyles{i}));
    if sum(ctag)==1
        hc(i) = uibutton(labelprop{:}, 'pos', labelpos(i,:), 'str', uilabels{i}); 
        he(i) = uicontrol(editprop{:}, 'style', uistyles{i}, 'pos', editpos(i,:));
    elseif ttag
        editpos(i,4) = 1 - marginsep*2; 
        he(i) = uibutton(labelprop{:}, 'style', uistyles{i}, 'pos', editpos(i,:), 'str', uilabels{i}); 
    else
        editpos(i,4) = 1 - marginsep*2; 
        he(i) = uicontrol(labelprop{:}, 'style', uistyles{i}, 'pos', editpos(i,:), 'str', uilabels{i});  
    end
    for ii = 1:length(propadd)
           if ~isempty(propadd{ii})
                tmp = eval(sprintf('%s', propadd{ii})); 
                set(he(i), propadd{ii}, tmp{i}); 
           end
    end
end
% | HANDLES
h.panel = P;
h.label = hc; 
h.edit  = he;  

set(parent, 'units', unit0);
function pos    = getpositions(relwidth, relheight, marginsep, uicontrolsep)
    if nargin<2, relheight = [6 7]; end
    if nargin<3, marginsep = .025; end
    if nargin<4, uicontrolsep = .01; end
    ncol = length(relwidth);
    nrow = length(relheight); 

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

    % combine
    pos = zeros(ncol, 4, nrow);
    pos(:,1,:)  = repmat(uilefts', 1, nrow); 
    pos(:,2,:)  = repmat(uibottoms, ncol, 1);
    pos(:,3,:)  = repmat(uiwidths', 1, nrow);
    pos(:,4,:)  = repmat(uiheights, ncol, 1);

    % test
    pos = zeros(ncol*nrow, 6);
    pos(:,1) = reshape(repmat(1:nrow, ncol, 1), size(pos,1), 1);
    pos(:,2) = reshape(repmat(1:ncol, 1, nrow), size(pos,1), 1);
    pos(:,3) = uilefts(pos(:,2)); 
    pos(:,4) = uibottoms(pos(:,1)); 
    pos(:,5) = uiwidths(pos(:,2)); 
    pos(:,6) = uiheights(pos(:,1)); 

% | IMAGE PROCESSING UTILITIES
% =========================================================================
function load_overlay(fname, pval, k)

    global st
    if nargin<3, k = 5; end
    if nargin<2, pval = .001; end
    badfn = 1; 
    while badfn
        oh = spm_vol(fname); 
        od = spm_read_vols(oh);
        od(isnan(od)) = 0;
        if sum(od(:))==0
            headsup('Your image file is empty. Please try a different file.')
            fname = uigetvol('Select an Image File for Overlay', 0);
            if isempty(fname), disp('Must select an overlay!'); return; end
        else
            badfn = 0; 
        end
    end

    % | - IMAGE INFO
    [fpath, fn1, fn2]   = fileparts(fname);
    [dpath, fd]         = fileparts(fpath); 
    finfo.name          = fullfile(fd, strcat(fn1, fn2)); 
    finfo.descrip       = oh.descrip;
    finfo.dimminmax     = sprintf('DIM: %d %d %d; MIN: %2.3f; MAX: %2.3f', size(od), min(od(:)), max(od(:))); 
    
    
    % | - CHECK IMAGE
    posneg  = check4sign(od);  
    df      = check4df(oh);
    if isempty(df)
        u       = .0001;
        k       = 0;
        df      = Inf;
        pval    = Inf; 
    else
        if regexp(oh.descrip, 'SPM\WF')
            u       = spm_invFcdf(1-pval, df);
        else
            u       = spm_invTcdf(1-pval, df);  
        end
    end
    [C, I] = getclustidx(od, u, k);
    if ~any(C(:))
        headsup('No suprathreshold voxels. Showing unthresholded image.'); 
        u = 0.0001; 
        pval = bob_t2p(u, df);
        k = 0; 
        [C, I] = getclustidx(od, u, k); 
    end
    M           = oh.mat;         %-voxels to mm matrix
    DIM         = oh.dim';
    VOX         = abs(diag(M(:,1:3))); 
    [X,Y,Z]     = ndgrid(1:DIM(1),1:DIM(2),1:DIM(3));
    XYZ         = [X(:)';Y(:)';Z(:)'];
    RCP         = XYZ; 
    RCP(4,:)    = 1;
    XYZmm       = M(1:3,:)*RCP;
    st.ol       = struct( ...
                'fname',    fname,...
                'fname_abbr', abridgepath(fname),...
                'finfo', finfo, ...
                'descrip',  oh.descrip, ...
                'hdr',      oh, ...
                'DF',       df, ...
                'null',     posneg, ...
                'U',        u, ...
                'P',        pval, ...
                'K',        k, ...
                'Y',        od, ...
                'M',        M,...
                'DIM',      DIM,...
                'VOX',      VOX, ...
                'C0',       C, ...
                'C0IDX',    I, ...
                'XYZmm0',   XYZmm,...
                'XYZ0',     XYZ);
            
    setatlas;
    set(st.fig, 'Name', abridgepath(st.ol.fname)); 
function u  = voxel_correct(im,alpha)
if nargin < 1, error('USAGE: u = voxel_correct(im,alpha)'); end
if nargin < 2, alpha = .05; end
if iscell(im), im = char(im); end

%% Get Design Variable %%
[impath imname] = fileparts(im);
if exist([impath filesep 'I.mat'],'file') 
    matfile = [impath filesep 'I.mat']; 
    maskfile = [impath filesep 'mask.nii'];
elseif exist([impath filesep 'SPM.mat'],'file') 
    matfile = [impath filesep 'SPM.mat'];
else
    disp('Could not find an SPM.mat or I.mat variable, exiting.'); return
end

%% Defaults %%
STAT = 'T';    % Test statistic
n = 1; % number of conjoint SPMs

%% Determime SPM or GLMFLEX %%
if strfind(matfile,'SPM.mat'), flexflag = 0; else flexflag = 1; end

%% Load and Compute Params %%
if flexflag % GLMFLEX
    load(matfile);
    try
        mask.hdr = spm_vol([I.OutputDir filesep 'mask.nii']);
    catch
        [p mf] = fileparts(im);
        mask.hdr = spm_vol([p filesep 'mask.nii']);
    end
    mask.data = spm_read_vols(mask.hdr);
    img.hdr = spm_vol(im);
    img.data = spm_read_vols(img.hdr);
    tmp = img.hdr.descrip; i1 = find(tmp=='['); i2 = find(tmp==']');
    df = str2num(tmp(i1(1)+1:i2(1)-1));
    df = [1 df];    
    
    FWHM = I.FWHM{1};
    R = spm_resels_vol(mask.hdr,FWHM)';
    S = sum(mask.data(:)==1);
    M = I.v.mat;
    VOX  = sqrt(diag(M(1:3,1:3)'*M(1:3,1:3)))';
    FWHMmm= FWHM.*VOX; % FWHM {mm}
    v2r  = 1/prod(FWHM(~isinf(FWHM)));% voxels to resels

else % SPM
    
    load(matfile)
    df   = [1 SPM.xX.erdf];
    n    = 1;
    R    = SPM.xVol.R;
    S    = SPM.xVol.S;
    M    = SPM.xVol.M;
    VOX  = sqrt(diag(M(1:3,1:3)'*M(1:3,1:3)))';
    FWHM = SPM.xVol.FWHM;
    FWHMmm= FWHM.*VOX; 				% FWHM {mm}
    v2r  = 1/prod(FWHM(~isinf(FWHM))); %-voxels to resels
    
end
%% get threshold
u = spm_uc(alpha,df,STAT,R,n,S); 
function k  = cluster_correct(im,u,alpha,maxk)
% CLUSTER_CORRECT Computer extent for cluster-level correction
%
% USAGE: [k info] = cluster_correct(im,u,alpha,range)
%
%
% THIS IS A MODIFICATION OF A FUNCTION BY DRS. THOMAS NICHOLS AND MARKO
% WILKE, CorrClusTh.m. ORIGINAL DOCUMENTATION PASTED BELOW:
%
% Find the corrected cluster size threshold for a given alpha
% function [k,Pc] =CorrClusTh(SPM,u,alpha,guess)
% SPM   - SPM data structure
% u     - Cluster defining threshold
%         If less than zero, u is taken to be uncorrected P-value
% alpha - FWE-corrected level (defaults to 0.05)
% guess - Set to NaN to use a Newton-Rhapson search (default)
%         Or provide a explicit list (e.g. 1:1000) of cluster sizes to
%         search over.
%         If guess is a (non-NaN) scalar nothing happens, except the the
%         corrected P-value of guess is printed. 
%
% Finds the corrected cluster size (spatial extent) threshold for a given
% cluster defining threshold u and FWE-corrected level alpha. 
%
%_________________________________________________________________________
% $Id: CorrClusTh.m,v 1.12 2008/06/10 19:03:13 nichols Exp $ Thomas Nichols, Marko Wilke
if nargin < 2, u = .001; end
if nargin < 3, alpha = .05; end
if nargin < 4, maxk = 1000; end
if iscell(im), im = char(im); end
range = 1:maxk;
% range = 1:1000; 
% range = NaN;


%% Get Design Variable %%
[impath, imname] = fileparts(im);
if exist([impath filesep 'I.mat'],'file') 
    matfile = [impath filesep 'I.mat']; 
    maskfile = [impath filesep 'mask.nii'];
elseif exist([impath filesep 'SPM.mat'],'file') 
    matfile = [impath filesep 'SPM.mat'];
else
    disp('Could not find an SPM.mat or I.mat variable, exiting.'); extent = []; info = []; return
end

%% Defaults %%
epsP = 1e-6;   % Corrected P-value convergence criterion (fraction of alpha)
du   = 1e-6;   % Step-size for Newton-Rhapson
maxi = 100;    % Maximum interations for refined search
STAT = 'T';    % Test statistic

%% Determime SPM or GLMFLEX %%
if strfind(matfile,'SPM.mat'), flexflag = 0; else flexflag = 1; end

%% Load and Compute Params %%
if flexflag % GLMFLEX
    II = load(matfile);
    try
        mask.hdr = spm_vol([II.I.OutputDir filesep 'mask.nii']);
    catch
        [p mf] = fileparts(im);
        mask.hdr = spm_vol([p filesep 'mask.nii']);
    end
    mask.data = spm_read_vols(mask.hdr);
    img.hdr = spm_vol(im);
    img.data = spm_read_vols(img.hdr);
    tmp = img.hdr.descrip; i1 = find(tmp=='['); i2 = find(tmp==']');
    df = str2num(tmp(i1(1)+1:i2(1)-1));
    df = [1 df];    
    n = 1;
    FWHM = II.I.FWHM{1};
    R = spm_resels_vol(mask.hdr,FWHM)';
    SS = sum(mask.data(:)==1);
    M = II.I.v.mat;
    VOX  = sqrt(diag(M(1:3,1:3)'*M(1:3,1:3)))';
    FWHMmm= FWHM.*VOX; % FWHM {mm}
    v2r  = 1/prod(FWHM(~isinf(FWHM)));% voxels to resels

else % SPM
    
    SPM = load(matfile);
    SPM = SPM.SPM;
    df   = [1 SPM.xX.erdf];
    STAT = 'T';
    n    = 1;
    R    = SPM.xVol.R;
    SS    = SPM.xVol.S;
    M    = SPM.xVol.M;
    VOX  = sqrt(diag(M(1:3,1:3)'*M(1:3,1:3)))';
    FWHM = SPM.xVol.FWHM;
    FWHMmm= FWHM.*VOX; 				% FWHM {mm}
    
    v2r  = 1/prod(FWHM(~isinf(FWHM))); %-voxels to resels
    
end

% | SPM METHOD (spm12)
% global st
% [uc,Pc,k]  = spm_uc_clusterFDR(0.05, df, STAT, R, n, st.ol.Z, st.ol.XYZ, v2r, st.ol.U); 

if ~nargout
    sf_ShowVolInfo(R,SS,VOX,FWHM,FWHMmm)
end
epsP = alpha*epsP;
Status = 'OK';
if u <= 1; u = spm_u(u,df,STAT); end

if length(range)==1 & ~isnan(range)
  
  %
  % Dummy case... just report P-value
  %

  k  = range;
  Pc = spm_P(1,k*v2r,u,df,STAT,R,n,SS);
  
  Status = 'JustPvalue';

elseif (spm_P(1,1*v2r,u,df,STAT,R,n,SS)<alpha)

  %
  % Crazy setting, where 1 voxel cluster is significant
  %

  k = 1;
  Pc = spm_P(1,1*v2r,u,df,STAT,R,n,SS);
  Status = 'TooRough';

elseif isnan(range)

  %
  % Automated search
  % 

  % Initial (lower bound) guess is the expected number of voxels per cluster
  [P Pn Em En EN] = spm_P(1,0,u,df,STAT,R,n,SS);
  kr = En; % Working in resel units
  rad = (kr)^(1/3); % Parameterize proportional to cluster diameter

  %
  % Crude linear search bound answer
  %
  Pcl  = 1;   % Lower bound on P
  radu = rad; % Upper bound on rad
  Pcu  = 0;   % Upper bound on P
  radl = Inf; % Lower bound on rad
  while (Pcl > alpha)
    Pcu  = Pcl;
    radl = radu; % Save previous result
    radu = radu*1.1;
    Pcl  = spm_P(1,radu^3   ,u,df,STAT,R,n,SS);
  end

  %
  % Newton-Rhapson refined search
  %
  d = 1;		    
  os = NaN;     % Old sign
  ms = (radu-radl)/10;  % Max step
  du = ms/100;
  % Linear interpolation for initial guess
  rad = radl*(alpha-Pcl)/(Pcu-Pcl)+radu*(Pcu-alpha)/(Pcu-Pcl);
  iter = 1;
  while abs(d) > epsP
    Pc  = spm_P(1,rad^3   ,u,df,STAT,R,n,SS);
    Pc1 = spm_P(1,(rad+du)^3,u,df,STAT,R,n,SS);
    d   = (alpha-Pc)/((Pc1-Pc)/du);
    os = sign(d);  % save old sign
    % Truncate search if step is too big
    if abs(d)>ms, 
      d = sign(d)*ms;
    end
    % Keep inside the given range
    if (rad+d)>radu, d = (radu-rad)/2; end
    if (rad+d)<radl, d = (rad-radl)/2; end
    % update
    rad = rad + d;
    iter = iter+1;
    if (iter>=maxi), 
      Status = 'TooManyIter';
      break; 
    end
  end
  % Convert back
  kr = rad^3;
  k = ceil(kr/v2r);
  Pc  = spm_P(1,k*v2r,u,df,STAT,R,n,SS);

%
% Brute force!
%
else
  Pc = 1;
  for k = range
    Pc = spm_P(1,k*v2r,u,df,STAT,R,n,SS);
    %fprintf('k=%d Pc=%g\n',k,Pc);
    if Pc <= alpha, 
      break; 
    end
  end;
  if (Pc > alpha)
    Status = 'OutOfRange';
  end
end

function [out, outmat] = reslice_image(in, ref, int)
    % Most of the code is adapted from rest_Reslice in REST toolbox:
    % Written by YAN Chao-Gan 090302 for DPARSF. Referenced from spm_reslice.
    % State Key Laboratory of Cognitive Neuroscience and Learning 
    % Beijing Normal University, China, 100875
    % int:        interpolation, 0=Nearest Neighbor, 1=Trilinear(default)
    if nargin<3, int = 1; end
    if nargin<2, display('USAGE: [out, outmat] = reslice_image(infile, ref, SourceHead, int)'); return; end
    if iscell(ref), ref = char(ref); end
    if iscell(in), in = char(in); end
    % read in reference image
    RefHead = spm_vol(ref); 
    mat=RefHead.mat;
    dim=RefHead.dim;
    SourceHead = spm_vol(in);
    [x1,x2,x3] = ndgrid(1:dim(1),1:dim(2),1:dim(3));
    d       = [int*[1 1 1]' [1 1 0]'];
    C       = spm_bsplinc(SourceHead, d);
    v       = zeros(dim);
    M       = inv(SourceHead.mat)*mat; % M = inv(mat\SourceHead.mat) in spm_reslice.m
    y1      = M(1,1)*x1+M(1,2)*x2+(M(1,3)*x3+M(1,4));
    y2      = M(2,1)*x1+M(2,2)*x2+(M(2,3)*x3+M(2,4));
    y3      = M(3,1)*x1+M(3,2)*x2+(M(3,3)*x3+M(3,4));
    out     = spm_bsplins(C, y1,y2,y3, d);
    tiny = 5e-2; % From spm_vol_utils.c
    Mask = true(size(y1));
    Mask = Mask & (y1 >= (1-tiny) & y1 <= (SourceHead.dim(1)+tiny));
    Mask = Mask & (y2 >= (1-tiny) & y2 <= (SourceHead.dim(2)+tiny));
    Mask = Mask & (y3 >= (1-tiny) & y3 <= (SourceHead.dim(3)+tiny));
    out(~Mask) = 0;
    outmat = mat;
function out = dilate_image(in)
% Dilate non-zero values in 3D volume - Wrapper for spm_dilate.m
kernel  = cat(3,[0 0 0; 0 1 0; 0 0 0],[0 1 0; 1 1 1; 0 1 0],[0 0 0; 0 1 0; 0 0 0]);
out     = spm_dilate(in, kernel);
function out = erode_image(in)
% Dilate non-zero values in 3D volume - Wrapper for spm_dilate.m
kernel  = cat(3,[0 0 0; 0 1 0; 0 0 0],[0 1 0; 1 1 1; 0 1 0],[0 0 0; 0 1 0; 0 0 0]);
out     = spm_erode(in, kernel);
function out = growregion(roi, xyz)
    global st
    refhdr = st.ol.hdr; 
    roihdr = refhdr;
    roihdr.pinfo = [1;0;0];
    [R,C,P]  = ndgrid(1:refhdr.dim(1),1:refhdr.dim(2),1:refhdr.dim(3));
    RCP      = [R(:)';C(:)';P(:)'];
    clear R C P
    RCP(4,:)    = 1;
    XYZmm       = refhdr.mat(1:3,:)*RCP;   
    Q           = ones(1,size(XYZmm,2));
    out         = zeros(roihdr.dim);
    switch roi.shape
        case 'Sphere'
            j = find(sum((XYZmm - xyz*Q).^2) <= roi.size^2);
        case 'Box'
            j = find(all(abs(XYZmm - xyz*Q) <= [roi.size roi.size roi.size]'*Q/2));
    end
    out(j) = 1;
    if roi.intersectflag
        col = getcurrentoverlay; 
        out(col==0) = 0; 
    end

% | IMAGE TYPE CHECKS
% =========================================================================
function flag       = check4design
    global st
    flag = 0; 
    if ~exist(fullfile(fileparts(st.ol.fname), 'I.mat'),'file') & ~exist(fullfile(fileparts(st.ol.fname), 'SPM.mat'),'file') 
        flag = 1; 
        printmsg('No SPM.mat or I.mat - Disabling threshold correction', 'WARNING');
        set(findobj(st.fig, 'Tag', 'Correction'), 'Enable', 'off'); 
    else
        set(findobj(st.fig, 'Tag', 'Correction'), 'Enable', 'on'); 
    end
function flag       = check4mask(img)
    flag = 1; 
    if ~any(ismember(unique(img(:)), [0 1])), flag = 0; end
function flag       = check4sign(img)
    global st
    allh = findobj(st.fig, 'Tag', 'direct'); 
    if ~isempty(allh), cb_directmenu(st.direct); end
    flag = [~any(img(:)>0) ~any(img(:)<0)]; 
    if any(flag)
        opt = {'+' '-'}; 
        st.direct = lower(opt{flag==0});
        if ~isempty(allh)
            allhstr = get(allh, 'String');
            set(allh(strcmp(allhstr, '+/-')), 'Value', 0, 'Enable', 'inactive');
            set(allh(strcmp(allhstr, opt{flag})), 'Value', 0, 'Enable', 'inactive');
            set(allh(strcmp(allhstr, opt{~flag})), 'Value', 1, 'Enable', 'inactive'); 
        end
    end
function df         = check4df(hdr)
    imdir = fileparts(hdr.fname);
    if exist(fullfile(imdir, 'dof'), 'file')
        df = load(fullfile(imdir, 'dof'));
        return; 
    end
    df = regexp(hdr.descrip, '\[\d+.*]', 'match');
    if isempty(df)
        df = []; 
        headsup('Degrees of freedom not found in image header or its parent directory. Showing unthresholded image.')
    else
        df = str2num(char(df));
    end
    
% | MISC UTILITIES
% =========================================================================
function h          = plotdata(v, subname)
    tmp       = sortrows([subname num2cell(v)], -2);
    h.ax      = gca; 
    h.data    = cell2mat(tmp(:,2)); 
    h.subname = tmp(:,1);; 
    h.bar     = barh(h.data);
    xlim      = [floor(2*min(v))/2 ceil(2*max(v))/2];
    set(h.ax, 'xlim', xlim, 'ytick', []);
    x         = get(h.bar, 'xdata');
    y         = get(h.bar, 'ydata');
    y(y<0)    = 0;
    y         = y + range(y)*.005;
    for i = 1:length(x)
        h.label(i) = text(y(i), x(i), h.subname{i}); 
    end
function zx         = oneoutzscore(x, returnas)
% ONEOUTZSCORE Perform columnwise leave-one-out zscoring
% 
% USAGE: zx = oneoutzscore(x, returnas)
% 
%   returnas: 0, signed values (default); 1, absolute values
%
if nargin<1, disp('USAGE: zx = oneoutzscore(x, returnas)'); return; end
if nargin<2, returnas = 0; end
if size(x,1)==1, x=x'; end
zx              = x; 
[nrow, ncol]    = size(x);
for c = 1:ncol
    cin         = repmat(x(:,c), 1, nrow);
    theoneout   = cin(logical(eye(nrow)))';
    theleftin   = reshape(cin(logical(~eye(nrow))),nrow-1,nrow);
    cz          = (theoneout-nanmean(theleftin))./nanstd(theleftin);
    zx(:,c)     = cz';
end
if returnas, zx = abs(zx); end
function str        = nicetime
    str = strtrim(datestr(now,'HH:MM:SS PM on mmm. DD, YYYY'));
function [strw, strh] = strsize(string, varargin)
% STRSIZE Calculate size of string
%
%  USAGE: strsize(string, varargin) 
%

% ---------------------- Copyright (C) 2015 Bob Spunt ----------------------
%	Created:  2015-07-14
%	Email:     spunt@caltech.edu
% __________________________________________________________________________
def = { ... 
	'axhandle',         gca,	...
    'FontSize',         [],     ...
    'FontName',         [],     ...
    'FontWeight',       [],     ...
    'FontAngle',        [],     ...
    'FontUnits',        []      ...
	};
vals = setargs(def, varargin);
if nargin==0, mfile_showhelp; fprintf('\t| - VARARGIN DEFAULTS - |\n'); disp(vals); return; end
if isempty(FontSize), FontSize = axhandle.FontSize; end
if isempty(FontName), FontName = axhandle.FontName; end
if isempty(FontWeight), FontWeight = axhandle.FontWeight; end
if isempty(FontAngle), FontAngle = axhandle.FontAngle; end
if isempty(FontUnits), FontUnits = axhandle.FontUnits; end

% | Get text size in data units
hTest   = text(1,1, string, 'Units','Pixels', 'FontUnits',FontUnits,...
    'FontAngle',FontAngle,'FontName',FontName,'FontSize',FontSize,...
    'FontWeight',FontWeight,'Parent',axhandle, 'Visible', 'off');
textExt = get(hTest,'Extent');
delete(hTest)
strh = textExt(4);
strw = textExt(3);

% | If using a proportional font, shrink text width by a fudge factor to account for kerning.
if ~strcmpi(axhandle.FontName,'FixedWidth'), strw = strw*0.9; end 
function out        = abridgepath(str, maxchar)
    if nargin<2, maxchar =  85; end
    if iscell(str), str = char(str); end
    if length(str) <= maxchar, out = str; return; end
    s   = regexp(str, filesep, 'split');
    s(cellfun('isempty', s)) = [];
    p1 = fullfile(s{1}, '...'); 
    s(1) = []; 
    badpath = 1;
    count = 0; 
    while badpath
        count = count + 1; 
        testpath = s; 
        testpath(1:count) = []; 
        testpath = fullfile(p1, testpath{:}); 
        if length(testpath)<=maxchar, badpath = 0; end
    end
    out = testpath; 
function cmap       = colormap_signed(n, zero_loc)
% Construct colormap for displaying signed data. The function outputs an n x 3
% colormap designed for use with signed data. The user can specify the location
% in the data range that corresponds to zero, and the colormap is then constructed
% so that white maps to zero. 
%
% Input arguments:
%   n: number of rows in colormap (default = 64)
%   zero_loc: location of zero (fractional dist between neg and pos limits
%             of data). If k is a signed function of 2 variables that spans
%             a range from negative to positive, compute the location
%             of the zero value: 
%                   zero_loc = (0 - min(k(:)))/(max(k(:)) - min(k(:))) 
%
% Usage:
% cmap = colormap_signed returns a 64 x 3 colormap in which the middle
% rows tend toward white; lower rows (negative values) tend toward blue
% while higher rows tend toward red. Variables n and zero_loc assume default
% values of 64 and 0.5, respectively.
%
% cmap = colormap_signed(n) returns a n x 3 colormap, otherwise similar to
% above. Variable zero_loc assumes default value of 0.5. 
%
% cmap = colormap_signed(n,zero_loc) returns a n x 3 colormap in which the 
% location of the row corresponding to the 'zero color' is given by zero_loc.
% See section above on input arguments for example of how to compute zero_loc.
%
% NOTE: As the value of zero_loc deviates from 0.5, the colormap created by 
% this function becomes progressively warped so that the portion of the data 
% range mapped to warm colors does not equal that mapped to cool colors. This 
% is intentional and allows the full range of colors to be used for a given
% signed data range. If you want a signed colormap in which the incremental
% color change is constant across the entire data range, one option is to 
% use this function to return a symmetrical signed colormap (i.e., zero_loc 
% = 0.5) and then manually set the colorbar properties to crop the colorbar.
% Written by Peter Hammer, April 2015 and posted on Matlab File Exchange

switch nargin
    case 2
        if (n < 1)
            error('First input argument must be greater than zero.')
        end
        if ((zero_loc < 0) || (zero_loc > 1))
            error('Second input argument must be between 0 and 1.')
        end
    case 1
        zero_loc = 0.5;
        if (n < 1)
            error('First input argument must be greater than zero.')
        end
    case 0
        zero_loc = 0.5;
        n = 64;
    otherwise
        error('Too many input arguments.')
end

% Array c must have odd number of rows with 'zero color' in middle row.
% This is a modified jet colormap with white replacing green in the
% middle (DarkBlue-Blue-Cyan-White-Yellow-Red-DarkRed).
c = [0 0 0.5;...
    0 0 1;...
    0 1 1;...
    1 1 1;...
    1 1 0;...
    1 0 0;...
    0.5 0 0];
i_mid = 0.5*(1+size(c,1));
cmap_neg=c(1:i_mid,:);
cmap_pos=c(i_mid:end,:);
i0 = 1+ round(n * zero_loc); % row of cmap (n rows) corresponding to zero 
x=(1:i_mid)'/i_mid;
cmap_neg_i=interp1(x,cmap_neg,linspace(x(1),1,i0));
cmap_pos_i=interp1(x,cmap_pos,linspace(x(1),1,n-i0));
cmap = [cmap_neg_i; cmap_pos_i];
function RGBmap     = colorGray(numLevels,debugplot)

% BRIEF: creates a rainbor color colormap which also looks good in greyscale
%
% SYNTAX:
%     RGBmap = colorGray(numLevels)
%
%OUTPUTS
%
%INTPUTS
%    numlevels - number of levels in the output colormap
%    plot - boolean, if true outputs a plot showing the range of colors
%    produced and lineplot of the range of grayscale produced verifying
%    grayscale linearity.
%
%****************************************************
%Author: Alexandre R. Tumlinson, October 23, 2006
%****************************************************
%REVISIONS
%16, Nov. 2006 Peder Axensten - sent great suggestions and some nicely rewriten code.
% make the numLevels input optional. Also optimized by vectorizing
% code.  Added the debug plotting options.
%****************************************************

if(nargin < 1), numLevels= size(colormap, 1); end	% Same number of  colors as the present color map. 
if(nargin < 2), debugplot=0; end	% turn off debug plotting by default

%first make a Jet map and then scale it so that it will look good in gray
lightest=0.05;
% Some constants to trim the greymap so lines arent too light.
% Also limit dark end because color sarted looking weird.
offsetbrightlimit=	floor(numLevels*lightest);
offsetdarklimit=	ceil(numLevels*0.25);
grayInt=			gray(numLevels+offsetbrightlimit+offsetdarklimit);
grayInt=			grayInt(offsetdarklimit+1:end-offsetbrightlimit,:);
grayInt=			sum(grayInt,2)/3.4;

% Do something similar for the color map
offsetbluelimit=	floor(numLevels*0.1);
offsetredlimit=		ceil(numLevels*0.0);
jetmap=				jet(numLevels+offsetbluelimit+offsetredlimit);
jetmap=				jetmap(offsetbluelimit+1:end-offsetredlimit,:);
jetmapInt=			jetmap*[0.2989; 0.5870; 0.1140]; %the gray level of the jetmap

scalefactor=		grayInt./jetmapInt;
RGBmap=				jetmap.*repmat(scalefactor, 1, 3);

%find elements greater than 1 and distribute to other colors
%attempts to maintain grey level on redistribution
%redistribution percentages are a litte arbitrary, but it seems to work
% Find elements greater than 1 and distribute to other colors,
% attempts to maintain grey level on redistribution.
% Redistribution percentages are a litte arbitrary, but it seems to work
for trials = 1:5
    isdone=				true;
    bigs=				(RGBmap(:,1) > 1);
    if (any(bigs))
        isdone=				false;
        surplus=			RGBmap(bigs,1) - 1;
        RGBmap(bigs,1)=		1;
        RGBmap(bigs,2)=		RGBmap(bigs,2) + surplus*0.85*(0.2989/0.5870);	% Goes to salmon
        RGBmap(bigs,3)=		RGBmap(bigs,3) + surplus*0.15*(0.2989/0.1140);	% Goes to salmon
        %			RGBmap(bigs,2)=		RGBmap(bigs,2) + surplus*0.00*(0.2989/0.5870);	% Goes to pink
        %			RGBmap(bigs,3)=		RGBmap(bigs,3) + surplus*1.00*(0.2989/0.1140);	% Goes to pink
    end
    bigs=				(RGBmap(:,2) > 1);
    if (any(bigs))
        isdone=				false;
        surplus=			RGBmap(bigs,2) - 1;
        RGBmap(bigs,1)=		RGBmap(bigs,1) + surplus*0.50*(0.5870/0.2989);
        RGBmap(bigs,2)=		1;
        RGBmap(bigs,3)=		RGBmap(bigs,3) + surplus*0.50*(0.5870/0.1140);
    end
    bigs=				(RGBmap(:,3) > 1);
    if (any(bigs))
        isdone=				false;
        surplus=			RGBmap(bigs,3) - 1;
        RGBmap(bigs,1)=		RGBmap(bigs,1) + surplus*0.00*(0.1140/0.2989);
        RGBmap(bigs,2)=		RGBmap(bigs,2) + surplus*1.00*(0.1140/0.5870);
        RGBmap(bigs,3)=		1;
    end
    if(isdone),			break;		end
end

%debugging plot option
if(debugplot)
    testarray=ones(2,numLevels);
    for count=1:numLevels
        testarray(:,count)=testarray(:,count)*count;
    end
    figure
    %create a line plot demonstrating the color range of the colormap
    subplot(1,2,1)
    set(gca,'ColorOrder',RGBmap)
    set(gca,'NextPlot','replaceChildren') %because default operation plot automatically sets default color order
    plot(testarray,'lineWidth',5 )
    title('Colors in colormap');
    ylabel('colormap index');
    set(gca,'Ylim',[0.5 numLevels+0.5]);
    set(gca,'Xtick',[]);

    % Make a plot of grayscale linearity for created colormap
    subplot(1,2,2)
    greyval=			RGBmap*[0.2989; 0.5870; 0.1140]; %the gray level of the output map
    plot(greyval);
    title('Range of grey used');
    xlabel('colormap index');
    ylabel('equivalent greylevel') %would be nice to put this on the right side of plot, any suggestions?
    set(gca,'Ylim',[0 1]);
    set(gca,'Xlim',[0.5 numLevels+0.5]);
end
function out        = cmap_upsample(in, N)
    num = size(in,1);
    ind = repmat(1:num, ceil(N/num), 1);
    rem = numel(ind) - N; 
    if rem, ind(end,end-rem+1:end) = NaN; end
    ind = ind(:); ind(isnan(ind)) = [];
    out = in(ind(:),:);
function out        = cellnum2str(in, ndec)
% NEW2PVAL Convert numeric array of p-values to formatted cell array of p-values
%
%  USAGE: out = num2pval(in)
% __________________________________________________________________________
%  INPUTS
%	in: numeric array of p-values
%   ndec: number of decimal points to display
%

% ---------------------- Copyright (C) 2015 Bob Spunt ----------------------
%	Created:  2015-01-13
%	Email:    spunt@caltech.edu
% __________________________________________________________________________
if nargin < 2, ndec = 2; end
if nargin < 1, disp('USAGE: out = num2pval(in)'); return; end
if ~iscell(in), error('Input array must be cell!'); end
n   = cell2mat(in); 
out = cellfun(@sprintf, repmat({['%2.' num2str(ndec) 'f']}, size(in)), in, 'Unif', false); 
out = regexprep(out, '0\.', '\.');
out(mod(n,1)==0) = cellfun(@num2str, in(mod(n,1)==0), 'unif', false);
function A          = catstruct(varargin)
% CATSTRUCT   Concatenate or merge structures with different fieldnames
%   X = CATSTRUCT(S1,S2,S3,...) merges the structures S1, S2, S3 ...
%   into one new structure X. X contains all fields present in the various
%   structures. An example:
%
%     A.name = 'Me' ;
%     B.income = 99999 ;
%     X = catstruct(A,B) 
%     % -> X.name = 'Me' ;
%     %    X.income = 99999 ;
%
%   If a fieldname is not unique among structures (i.e., a fieldname is
%   present in more than one structure), only the value from the last
%   structure with this field is used. In this case, the fields are 
%   alphabetically sorted. A warning is issued as well. An axample:
%
%     S1.name = 'Me' ;
%     S2.age  = 20 ; S3.age  = 30 ; S4.age  = 40 ;
%     S5.honest = false ;
%     Y = catstruct(S1,S2,S3,S4,S5) % use value from S4
%
%   The inputs can be array of structures. All structures should have the
%   same size. An example:
%
%     C(1).bb = 1 ; C(2).bb = 2 ;
%     D(1).aa = 3 ; D(2).aa = 4 ;
%     CD = catstruct(C,D) % CD is a 1x2 structure array with fields bb and aa
%
%   The last input can be the string 'sorted'. In this case,
%   CATSTRUCT(S1,S2, ..., 'sorted') will sort the fieldnames alphabetically. 
%   To sort the fieldnames of a structure A, you could use
%   CATSTRUCT(A,'sorted') but I recommend ORDERFIELDS for doing that.
%
%   When there is nothing to concatenate, the result will be an empty
%   struct (0x0 struct array with no fields).
%
%   NOTE: To concatenate similar arrays of structs, you can use simple
%   concatenation: 
%     A = dir('*.mat') ; B = dir('*.m') ; C = [A ; B] ;

%   NOTE: This function relies on unique. Matlab changed the behavior of
%   its set functions since 2013a, so this might cause some backward
%   compatibility issues when dulpicated fieldnames are found.
%
%   See also CAT, STRUCT, FIELDNAMES, STRUCT2CELL, ORDERFIELDS

% version 4.1 (feb 2015), tested in R2014a
% (c) Jos van der Geest
% email: jos@jasen.nl

% History
% Created in 2005
% Revisions
%   2.0 (sep 2007) removed bug when dealing with fields containing cell
%                  arrays (Thanks to Rene Willemink)
%   2.1 (sep 2008) added warning and error identifiers
%   2.2 (oct 2008) fixed error when dealing with empty structs (thanks to
%                  Lars Barring)
%   3.0 (mar 2013) fixed problem when the inputs were array of structures
%                  (thanks to Tor Inge Birkenes).
%                  Rephrased the help section as well.
%   4.0 (dec 2013) fixed problem with unique due to version differences in
%                  ML. Unique(...,'last') is no longer the deafult.
%                  (thanks to Isabel P)
%   4.1 (feb 2015) fixed warning with narginchk

% narginchk(1,Inf);
if nargin < 1, error('FEED ME MORE INPUTS, SEYMOUR!'); end
N = nargin;

if ~isstruct(varargin{end}),
    if isequal(varargin{end},'sorted'),
        narginchk(2,Inf) ;
        sorted = 1 ;
        N = N-1 ;
    else
        error('catstruct:InvalidArgument','Last argument should be a structure, or the string "sorted".') ;
    end
else
    sorted = 0 ;
end

sz0 = [] ; % used to check that all inputs have the same size

% used to check for a few trivial cases
NonEmptyInputs = false(N,1) ; 
NonEmptyInputsN = 0 ;

% used to collect the fieldnames and the inputs
FN = cell(N,1) ;
VAL = cell(N,1) ;

% parse the inputs
for ii=1:N,
    X = varargin{ii} ;
    if ~isstruct(X),
        error('catstruct:InvalidArgument',['Argument #' num2str(ii) ' is not a structure.']) ;
    end
    
    if ~isempty(X),
        % empty structs are ignored
        if ii > 1 && ~isempty(sz0)
            if ~isequal(size(X), sz0)
                error('catstruct:UnequalSizes','All structures should have the same size.') ;
            end
        else
            sz0 = size(X) ;
        end
        NonEmptyInputsN = NonEmptyInputsN + 1 ;
        NonEmptyInputs(ii) = true ;
        FN{ii} = fieldnames(X) ;
        VAL{ii} = struct2cell(X) ;
    end
end

if NonEmptyInputsN == 0
    % all structures were empty
    A = struct([]) ;
elseif NonEmptyInputsN == 1,
    % there was only one non-empty structure
    A = varargin{NonEmptyInputs} ;
    if sorted,
        A = orderfields(A) ;
    end
else
    % there is actually something to concatenate
    FN = cat(1,FN{:}) ;    
    VAL = cat(1,VAL{:}) ;    
    FN = squeeze(FN) ;
    VAL = squeeze(VAL) ;
    
    
    [UFN,ind] = unique(FN, 'last') ;
    % If this line errors, due to your matlab version not having UNIQUE
    % accept the 'last' input, use the following line instead
    % [UFN,ind] = unique(FN) ; % earlier ML versions, like 6.5
    
    if numel(UFN) ~= numel(FN),
%         warning('catstruct:DuplicatesFound','Fieldnames are not unique between structures.') ;
        sorted = 1 ;
    end
    
    if sorted,
        VAL = VAL(ind,:) ;
        FN = FN(ind,:) ;
    end
    
    A = cell2struct(VAL, FN);
    A = reshape(A, sz0) ; % reshape into original format
end
function out        = adjustbrightness(in)
    lim = .5;
    dat.min = min(in(in>0)); 
    dat.max = max(in(in>0));
    dat.dim = size(in);
    out = double(in)./255; 
    out(out>0) = out(out>0) + (lim-nanmean(nanmean(out(out>0))))*(1 - out(out>0)); 
    out(out>0) = scaledata(out(out>0), [dat.min dat.max]);
function figpos = align_figure(uiW, uiH, valign, halign)
screenPos   = get(0, 'ScreenSize');
screenW     = screenPos(3);
screenH     = screenPos(4);
figpos      = [0 0 uiW uiH];
switch lower(valign)
    case 'middle'
      figpos(2) = (screenH/2)-(uiH/2);
    case {'top', 'upper'}
      figpos(2) = screenH-uiH; 
    case {'bottom', 'lower'}
      figpos(2) = 1; 
    otherwise
      error('VALIGN options are: middle, top, upper, bottom, lower')
end
switch lower(halign)
    case 'center'
      figpos(1) = (screenW/2) - (uiW/2);
    case 'right'
      figpos(1) = screenW - uiW; 
    case 'left'
      figpos(1) = 1; 
    otherwise
      error('HALIGN options are: center, left, right')
end
function fn         = construct_filename
    global st
    [p,n]   = fileparts(st.ol.hdr.fname);
    idx     = regexp(st.ol.descrip, ': ');
    if ~isempty(idx)
        n = strtrim(st.ol.descrip(idx+1:end));
        n = regexprep(n, ' ', '_'); 
    end
    fn = sprintf('%s/%s_x=%d_y=%d_z=%d.png', p, n, bspm_XYZreg('RoundCoords',st.centre,st.ol.M,st.ol.DIM));        
function s          = easydefaults(varargin)
% easydefaults  Set many default arguments quick and easy.
%
%   - For input arguments x1,x2,x3, set default values x1def,x2def,x3def
%     using easydefaults as parameter-value pairs:
%       easydefaults('x1',x1def,'x2',x2def,'x3',x3def);
%   
%   - Defaults can be set for any input argument, whether explicit or as 
%     part of a parameter-value pair:
%       function dummy_function(x,varargin)
%           easydefaults('x',1,'y',2);
%           ...   
%       end
%
%   - easydefaults and easyparse can in principle be used in either order, 
%     but it is usually better to parse first and fill in defaults after:
%       function dummy_function(x,varargin)
%           easyparse(varargin,'y')
%           easydefaults('x',1,'y',2);
%           ...   
%       end
%
%   CAVEAT UTILITOR: this function relies on evals and assignin statements.
%   Input checking is performed to limit potential damage, but use at your 
%   own risk.
%
%   Author: Jared Schwede 
%   Last update: Jan 14, 2013

    % Check that all inputs come in parameter-value pairs.
    if mod(length(varargin),2)
        error('Default arguments must be specified in pairs!');
    end
    
    for i=1:2:length(varargin)
        if ~ischar(varargin{i})
            error('Variables to easydefaults must be written as strings!');
        end
        
        % We'll check that the varargin is a valid variable name. This
        % should hopefully avoid any nasty code...
        if ~isvarname(varargin{i})
            error('Invalid variable name!');
        end
        
        if exist(varargin{i},'builtin') || (exist(varargin{i},'file') == 2) || exist(varargin{i},'class')
            warning('MATLAB:defined_function',['''' varargin{i} ''' conflicts with the name of a function, m-file, or class along the MATLAB path and will be ignored by easydefaults.' ...
                                        ' Please rename the variable, or use a temporary variable with easydefaults and explicitly define ''' varargin{i} ...
                                        ''' within your function.']);
        else
            if ~evalin('caller',['exist(''' varargin{i} ''',''var'')'])
                % We assign the arguments to a struct, s, which allows us to
                % check that the evalin statement will not either throw an 
                % error or execute some nasty code.
                s.(varargin{i}) = varargin{i+1};
                assignin('caller',varargin{i},varargin{i+1});
            end
        end
end
function s          = easyparse(caller_varargin,allowed_names)
% easyparse    Parse parameter-value pairs without using inputParser
%   easyparse is called by a function which takes parameter value pairs and
%   creates individual variables in that function. It can also be used to
%   generate a struct like inputParser.
%
%   - To create variables in the function workspace according to the
%     varargin of parameter-value pairs, use this syntax in your function:
%       easyparse(varargin)
%
%   - To create only variables with allowed_names, create a cell array of
%     allowed names and use this syntax:
%       easyparse(varargin, allowed_names);
%
%   - To create a struct with fields specified by the names in varargin,
%     (similar to the output of inputParser) ask for an output argument:
%       s = easyparse(...);
%  
%   CAVEAT UTILITOR: this function relies on assignin statements. Input
%   checking is performed to limit potential damage, but use at your own 
%   risk.
%
%   Author: Jared Schwede
%   Last update: January 14, 2013

    % We assume all inputs come in parameter-value pairs. We'll also assume
    % that there aren't enough of them to justify using a containers.Map. 
    for i=1:2:length(caller_varargin)
        if nargin == 2 && ~any(strcmp(caller_varargin{i},allowed_names))
            error(['Unknown input argument: ' caller_varargin{i}]);
        end
        
        if ~isvarname(caller_varargin{i})
            error('Invalid variable name!');
        end
        
        
        % We assign the arguments to the struct, s, which allows us to
        % check that the assignin statement will not either throw an error 
        % or execute some nasty code.
        s.(caller_varargin{i}) = caller_varargin{i+1};
        % ... but if we ask for the struct, don't write all of the
        % variables to the function as well.
        if ~nargout
            if exist(caller_varargin{i},'builtin') || (exist(caller_varargin{i},'file') == 2) || exist(caller_varargin{i},'class')
                warning('MATLAB:defined_function',['''' caller_varargin{i} ''' conflicts with the name of a function, m-file, or class along the MATLAB path and will be ignored by easyparse.' ...
                                            ' Please rename the variable, or use a temporary variable with easyparse and explicitly define ''' caller_varargin{i} ...
                                            ''' within your function.']);
            else
                assignin('caller',caller_varargin{i},caller_varargin{i+1});
            end
        end
    end
function out        = scaledata(in, minmax)
% SCALEDATA
%
% USAGE: out = scaledata(in, minmax)
%
% Example:
% a = [1 2 3 4 5];
% a_out = scaledata(a,0,1);
% 
% Output obtained: 
%            0    0.1111    0.2222    0.3333    0.4444
%       0.5556    0.6667    0.7778    0.8889    1.0000
%
% Program written by:
% Aniruddha Kembhavi, July 11, 2007
if nargin<2, minmax = [0 1]; end
if nargin<1, error('USAGE: out = scaledata(in, minmax)'); end
out = in - repmat(min(in), size(in, 1), 1); 
out = ((out./repmat(range(out), size(out,1), 1))*(minmax(2)-minmax(1))) + minmax(1); 
function p          = bob_t2p(t, df)
% BOB_T2P Get p-value from t-value + df
%
%   ARGUMENTS
%       t = t-value
%       df = degrees of freedom
%
    p = spm_Tcdf(t, df);
    p = 1 - p;
function y          = range(x)
y = nanmax(x) - nanmin(x); 
function out        = replace(in, exp1, exp2)
    out  = in;
    if ischar(exp1), exp1 = cellstr(exp1); end
    if ischar(exp2), exp2 = cellstr(exp2); end
    if numel(exp2)==1, exp2 = repmat(exp2, size(exp1)); end
    for i = 1:length(exp1), out = regexprep(out, exp1{i}, exp2{i}); end
    out = strtrim(out);
function [parpath, branchpar] = parentpath(subpaths)
% PARENTPATH Find parent path from multiple subpaths
%
%   USAGE:      parpath = parentpath(subpaths)
% __________________________________________________________________________
%   SUBPATHS:   CHAR or CELL array containing strings for multiple paths
%

% ---------------------- Copyright (C) 2015 Bob Spunt ----------------------
%	Created:  2015-03-27
%	Email:    spunt@caltech.edu
% __________________________________________________________________________
if      nargin < 1, disp('USAGE: parpath = parentpath(subpaths)'); return; end
if      iscell(subpaths), subpaths = char(subpaths); end
if      size(subpaths, 1)==1
    parpath = fileparts(subpaths); 
    disp('Only one subpath!'); 
    return; 
end

% | Get indices of noncommon characters
if      size(subpaths, 1)==2, diffidx = find(diff(subpaths));
else    diffidx = find(sum(diff(subpaths))); end

% | Assign parent path
parpath = fileparts(subpaths(1, 1:diffidx(1)));

if nargout==2
   tmp = regexp(regexprep(cellstr(subpaths), parpath, ''), filesep, 'split');
   branchpar = cellfun(@(x) x(2), tmp); 
end
function writereport(incell, outname)
% WRITEREPORT Write cell array to CSV file
%
%  USAGE: outname = writereport(incell, outname)	*optional input
% __________________________________________________________________________
%  INPUTS
%	incell:     cell array of character arrays
%	outname:   base name for output csv file 
%

% ---------------------- Copyright (C) 2015 Bob Spunt ----------------------
%	Created:  2015-02-02
%	Email:    spunt@caltech.edu
% __________________________________________________________________________
if nargin < 2, disp('USAGE: outname = writereport(incell, outname)'); return; end


[p,n,e] = fileparts(outname); 
outname = fullfile(p, strcat(n, '.csv')); 

% | Convert all cell contents to character arrays
% | ========================================================================
[nrow, ncol] = size(incell);
for i = 1:numel(incell)
    if isnumeric(incell{i}), incell{i} = num2str(incell{i}); end
    if strcmp(incell{i},'NaN'), incell{i} = ''; end
end
incell = regexprep(incell, ',', '');

% | Write to file
% | ========================================================================
fid = fopen(outname,'w+');
for r = 1:nrow
    fprintf(fid,['%s' repmat(',%s',1,ncol-1) '\n'],incell{r,:});
end
fclose(fid);
function mfile_showhelp(varargin)
% MFILE_SHOWHELP
%
% ------------------------------------------------------------------------
ST = dbstack('-completenames');
if isempty(ST), fprintf('\nYou must call this within a function\n\n'); return; end
eval(sprintf('help %s', ST(2).file));    
function error_handler(err, write)
if nargin<2, write = 0; end
info1 = cellstr(sprintf('UNDEFINED ERROR => %s', err.message));
info2 = [printstruct(err.stack, 'name', 'Error Trace'); {''}];
if write
    day        = datestr(now,'mm_DD_YYYY');
    time       = strtrim(datestr(now,'HHMMPM'));
    errlogname = sprintf('ErrorLog_%s_%s.txt', day, time);
    errdata    = getReport(err);
    eid        = fopen(fullfile(data.defaultdir,errlogname),'w');
    fwrite(eid, errdata);
    fclose(eid);
end   
function save_error(err)
    global st
    answer = yesorno('An unknown error has occured. Would you like to save some files with information about the error?', 'Fatal Error');
    if strcmpi(answer, 'yes')
        outdir      = uigetdir('', 'Select an output folder'); 
        if ~outdir, return; end
        errdata     = getReport(err);
        errlogname  = fullfile(outdir, 'ErrorMsg.txt'); 
        errmatname  = fullfile(outdir, 'ErrorDat.mat'); 
        errfigname  = fullfile(outdir, 'ErrorFig.fig');
        hgsave(errfigname); 
        eid         = fopen(errlogname, 'w');
        fwrite(eid, errdata);
        fclose(eid);
        save(errmatname, 'st');
        fprintf('\nERROR INFORMATION WRITTEN TO:\n\t%s\n\t%s\n\t%s\n\n', errlogname, errmatname, errfigname);
    else
       return 
    end
function arrayset(harray, propname, propvalue) 
% ARRAYGET Set property values for array of handles
%
% USAGE: arrayset(harray, propname, propvalue) 
%
% ==============================================
if nargin<2, error('USAGE: arrayset(harray, propname, propvalue) '); end
if size(harray, 1)==1, harray = harray'; end
if ~iscell(propvalue)
    arrayfun(@set, harray, repmat({propname}, length(harray), 1), ...
            repmat({propvalue}, length(harray), 1)); 
else
    if size(propvalue, 1)==1, propvalue = propvalue'; end
    arrayfun(@set, harray, repmat({propname}, length(harray), 1), propvalue); 
end

% | TALKING TO THE HUMAN
% =========================================================================
function vol        = uigetvol(message, multitag, defaultdir)
    % UIGETVOL Dialogue for selecting image volume file
    %
    %   USAGE: vol = uigetvol(message, multitag)
    %       
    %       message = to display to user
    %       multitag = (default = 0) tag to allow selecting multiple images
    %
    % EX: img = uigetvol('Select Image to Process'); 
    %
    if nargin < 3, defaultdir = pwd; end
    if nargin < 2, multitag = 0; end
    if nargin < 1, message = 'Select Image File'; end
    
    if ~multitag
        [imname, pname] = uigetfile({'*.img;*.nii;*.nii.gz', 'Image File (*.img, *.nii, *.nii.gz)'; '*.*', 'All Files (*.*)'}, message);
    else
        [imname, pname] = uigetfile({'*.img;*.nii;*.nii.gz', 'Image File (*.img, *.nii, *.nii.gz)'; '*.*', 'All Files (*.*)'}, message, 'MultiSelect', 'on');
    end
    if isequal(imname,0) || isequal(pname,0)
        vol = [];
    else
        vol = fullfile(pname, strcat(imname));
    end
function vol        = uiputvol(defname, prompt)
    if nargin < 1, defname = 'myimage.nii'; end
    if nargin < 2, prompt = 'Save image as'; end
    [imname, pname] = uiputfile({'*.img; *.nii', 'Image File'; '*.*', 'All Files (*.*)'}, prompt, defname);
    if isequal(imname,0) || isequal(pname,0)
        vol = [];
    else
        vol = fullfile(pname, imname); 
    end
function outmsg     = printmsg(msg, msgtitle, msgborder, msgwidth, hideoutput)
% PRINTMSG Create and print a formatted message with title
%
%	USAGE: fmtmessage = printmsg(message, msgtitle, msgborder, msgwidth)
%
%

% --------------------------- Copyright (C) 2014 ---------------------------
%	Author: Bob Spunt
%	Email: bobspunt@gmail.com
% 
%	$Created: 2014_09_27
% _________________________________________________________________________
if nargin<5, hideoutput = 0; end
if nargin<4, msgwidth   = 75; end
if nargin<3, msgborder  = {'_' '_'}; end
if nargin<2, msgtitle   = ''; end
if nargin<1,
    msg = 'USAGE: fmtmessage = printmsg(msg, [msgtitle], [msgborder], [msgwidth])';
    msgtitle = 'I NEED MORE INPUT FROM YOU';
end
if ischar(msgborder), msgborder = cellstr(msgborder); end
if length(msgborder)==1, msgborder = [msgborder msgborder]; end
if iscell(msg), msg = char(msg); end
if iscell(msgtitle), msgtitle = char(msgtitle); end
msgtop          = repmat(msgborder{1},1,msgwidth);
msgbottom       = repmat(msgborder{2},1,msgwidth);
if ~isempty(msgtitle), msgtitle = sprintf('%s %s %s', msgborder{1}, strtrim(msgtitle), msgborder{1}); end
titleln         = length(msgtitle);
msgln           = length(msg); 
msgtop(floor(.5*msgwidth-.5*titleln):floor(.5*msgwidth-.5*titleln) + titleln-1) = msgtitle;
outmsg      = repmat(' ', 1, msgwidth);
outmsg(floor(.5*msgwidth-.5*msgln):floor(.5*msgwidth-.5*msgln) + msgln-1) = msg;
outmsg      = sprintf('%s\n\n%s\n%s', msgtop, outmsg, msgbottom);
if ~hideoutput, disp(outmsg); end
function answer     = yesorno(question, titlestr)
% YESORNO Ask Yes/No Question
%
%  USAGE: h = yesorno(question, *titlestr)    *optional input
% __________________________________________________________________________
%  INPUTS
%   question: character array to present to user 
%

% ---------------------- Copyright (C) 2014 Bob Spunt ----------------------
%	Created:  2014-09-30
%	Email:    spunt@caltech.edu
% __________________________________________________________________________
if nargin < 1, disp('USAGE: h = yesorno(question, *titlestr)'); return; end
if nargin < 2, titlestr = 'Yes or No?'; end
if iscell(titlestr), titlestr = char(titlestr); end
if iscell(question), question = char(question); end
global answer st
answer = []; 
h(1) = figure(...
    'Units', 'norm', ...
    'WindowStyle', 'modal', ...
    'Position',[.425 .45 .15 .10],...
    'Resize','off',...
    'Color', [0.8941    0.1020    0.1098]*.60, ...
    'NumberTitle','off',...
    'DockControls','off',...
    'Tag', 'yesorno', ...
    'MenuBar','none',...
    'Name',titlestr,...
    'Visible','on',...
    'Toolbar','none');
h(2) = uicontrol('parent', h(1), 'units', 'norm', 'style',  'text', 'backg', [0.8941    0.1020    0.1098]*.60,'foreg', [248/255 248/255 248/255], 'horiz', 'center', ...
    'pos', [.050 .375 .900 .525], 'fontname', 'arial', 'fontw', 'bold', 'fontsize', st.fonts.sz4, 'string', question, 'visible', 'on'); 
h(3) = uicontrol('parent', h(1), 'units', 'norm', 'style', 'push', 'foreg', [0 0 0], 'horiz', 'center', ...
'pos', [.25 .10 .2 .30], 'fontname', 'arial', 'fontw', 'bold', 'fontsize', st.fonts.sz3, 'string', 'Yes', 'visible', 'on', 'callback', {@cb_answer, h});
h(4) = uicontrol('parent', h(1), 'units', 'norm', 'style', 'push', 'foreg', [0 0 0], 'horiz', 'center', ...
'pos', [.55 .10 .2 .30], 'fontname', 'arial', 'fontw', 'bold', 'fontsize', st.fonts.sz3, 'string', 'No', 'visible', 'on', 'callback', {@cb_answer, h});
uiwait(h(1)); 
function cb_answer(varargin)
    global answer
    answer = get(varargin{1}, 'string');
    delete(findobj(0, 'Tag', 'yesorno'));
function [flag, h]  = waitup(msg, titlestr)
% YESORNO Ask Yes/No Question
%
%  USAGE: h = yesorno(question, *titlestr)    *optional input
% __________________________________________________________________________
%  INPUTS
%   question: character array to present to user 
%

% ---------------------- Copyright (C) 2014 Bob Spunt ----------------------
%	Created:  2014-09-30
%	Email:    spunt@caltech.edu
% __________________________________________________________________________
if nargin < 1, disp('USAGE: [flag, h] = waitup(msg, titlestr)'); return; end
if nargin < 2, titlestr = 'Please Wait'; end
if iscell(titlestr), titlestr = char(titlestr); end
if iscell(msg), msg = char(msg); end
global flag st
flag = []; 
h(1) = figure(...
    'Units', 'norm', ...
    'WindowStyle', 'modal', ...
    'Position',[.425 .45 .15 .10],...
    'Resize','off',...
    'Color', [0.8941    0.1020    0.1098]*.60, ...
    'NumberTitle','off',...
    'DockControls','off',...
    'Tag', 'waitup', ...
    'MenuBar','none',...
    'Name',titlestr,...
    'Visible','on',...
    'Toolbar','none');
h(2) = uicontrol('parent', h(1), 'units', 'norm', 'style',  'text', 'backg', [0.8941    0.1020    0.1098]*.60,'foreg', [248/255 248/255 248/255], 'horiz', 'center', ...
    'pos',[.050 .375 .900 .525], 'fontname', 'arial', 'fontw', 'bold', 'fontsize', st.fonts.sz4, 'string', msg, 'visible', 'on'); 
h(3) = uicontrol('parent', h(1), 'units', 'norm', 'style', 'push', 'foreg', [0 0 0], 'horiz', 'center', ...
'pos', [.4 .075 .2 .30], 'fontname', 'arial', 'fontw', 'bold', 'fontsize', st.fonts.sz3, 'string', 'Cancel', 'visible', 'on', 'callback', {@cb_cancel, h});
uiwait(h(1)); 
function cb_cancel(varargin)
    global flag
    flag = get(varargin{1}, 'string');
    delete(findobj(0, 'Tag', 'waitup'));
function h          = headsup(msg, titlestr, wait4resp)
% HEADSUP Present message to user and wait for a response
%
%  USAGE: h = headsup(msg, *titlestr, *wait4resp)    *optional input
% __________________________________________________________________________
%  INPUTS
%   msg: character array to present to user 
%

% ---------------------- Copyright (C) 2014 Bob Spunt ----------------------
%	Created:  2014-09-30
%	Email:    spunt@caltech.edu
% __________________________________________________________________________
if nargin < 1, disp('USAGE: h = headsup(msg, *titlestr, *wait4resp)'); return; end
if nargin < 2, titlestr = 'Heads Up'; end
if nargin < 3, wait4resp = 1; end
if iscell(msg), msg = char(msg); end
if iscell(titlestr), titlestr = char(titlestr); end
global st
ppos    = get(st.fig, 'pos');  
cwh     = [ppos(3)/2 ppos(4)/4];
clb     = [ppos(1) + (ppos(3)/2)-(cwh(1)/2) ppos(2) + (ppos(4)/2)-(cwh(2)/2)];
cpos    = [clb cwh];
% cpos    = [.425 .45 .15 .10]; 
h(1) = figure(...
    'Units', 'pix', ...
    'Position',cpos,...
    'WindowStyle', 'modal', ...
    'Resize','off',...
    'Color', [0.8941    0.1020    0.1098]*.60, ...
    'NumberTitle','off',...
    'DockControls','off',...
    'Tag', 'headsup', ...
    'MenuBar','none',...
    'Name',titlestr,...
    'Visible','on',...
    'Toolbar','none');
h(2) = uicontrol('parent', h(1), 'units', 'norm', 'style',  'text', 'backg', [0.8941    0.1020    0.1098]*.60,'foreg', [248/255 248/255 248/255], 'horiz', 'center', ...
    'pos', [.050 .375 .900 .525], 'fontname', 'arial', 'fontw', 'bold', 'fontsize', st.fonts.sz4, 'string', msg, 'visible', 'on'); 
if wait4resp
    h(3) = uicontrol('parent', h(1), 'units', 'norm', 'style', 'push', 'foreg', [0 0 0], 'horiz', 'center', ...
    'pos', [.4 .075 .2 .30], 'fontname', 'arial', 'fontw', 'bold', 'fontsize', st.fonts.sz3, 'string', 'OK', 'visible', 'on', 'callback', {@cb_ok, h});
    uiwait(h(1)); 
end
drawnow; 
function cb_ok(varargin)
    delete(findobj(0, 'Tag', 'headsup'));
    drawnow; 

% | BSPM_OPTHVIEWS (MODIFIED FROM SPM8 SPM_OPTHVIEWS)
% =========================================================================
function varargout          = bspm_orthviews(action,varargin)
% John Ashburner et al% Display orthogonal views of a set of images
% The basic fields of st are:
%         n        - the number of images currently being displayed
%         vols     - a cell array containing the data on each of the
%                    displayed images.
%         Space    - a mapping between the displayed images and the
%                    mm space of each image.
%         bb       - the bounding box of the displayed images.
%         centre   - the current centre of the orthogonal views
%         callback - a callback to be evaluated on a button-click.
%         xhairs   - crosshairs off/on
%         hld      - the interpolation method
%         fig      - the figure that everything is displayed in
%         mode     - the position/orientation of the sagittal view.
%                    - currently always 1
%
%         st.registry.hReg \_ See bspm_XYZreg for documentation
%         st.registry.hMe  /
%
% For each of the displayed images, there is a non-empty entry in the
% vols cell array.  Handles returned by "spm_orthviews('Image',.....)"
% indicate the position in the cell array of the newly created ortho-view.
% Operations on each ortho-view require the handle to be passed.
%
% When a new image is displayed, the cell entry contains the information
% returned by spm_vol (type help spm_vol for more info).  In addition,
% there are a few other fields, some of which are documented here:
%
%         premul  - a matrix to premultiply the .mat field by.  Useful
%                   for re-orienting images.
%         window  - either 'auto' or an intensity range to display the
%                   image with.
%         mapping - Mapping of image intensities to grey values. Currently
%                   one of 'linear', 'histeq', loghisteq',
%                   'quadhisteq'. Default is 'linear'.
%                   Histogram equalisation depends on the image toolbox
%                   and is only available if there is a license available
%                   for it.
%         ax      - a cell array containing an element for the three
%                   views.  The fields of each element are handles for
%                   the axis, image and crosshairs.
%
%         blobs   - optional.  Is there for using to superimpose blobs.
%                   vol     - 3D array of image data
%                   mat     - a mapping from vox-to-mm (see spm_vol, or
%                             help on image formats).
%                   max     - maximum intensity for scaling to.  If it
%                             does not exist, then images are auto-scaled.
%
%                   There are two colouring modes: full colour, and split
%                   colour.  When using full colour, there should be a
%                   'colour' field for each cell element.  When using
%                   split colourscale, there is a handle for the colorbar
%                   axis.
%
%                   colour  - if it exists it contains the
%                             red,green,blue that the blobs should be
%                             displayed in.
%                   cbar    - handle for colorbar (for split colourscale).
global st
persistent zoomlist reslist
if isempty(st), reset_st; end
if ~nargin, action = ''; end
% if ~any(strcmpi(action,{'reposition','pos'}))
%     spm('Pointer','Watch');
% end
switch lower(action)
    case 'image'
        H = specify_image(varargin{1});
        if ~isempty(H)
            if numel(varargin)>=2
                st.vols{H}.area = varargin{2};
            else
                st.vols{H}.area = [0 0 1 1];
            end
            if isempty(st.bb), st.bb = maxbb; end
            resolution;
            bbox;
            cm_pos;
        end
        varargout{1} = H;
        mmcentre     = mean(st.Space*[maxbb';1 1],2)';
        st.centre    = mmcentre(1:3);
        redraw_all

    case 'caption'
        if ~isnumeric(varargin{1})
            varargin{1} = cellstr(varargin{1});
            xlh = NaN(numel(varargin{1}),1);
            for i=1:numel(varargin{1})
                h = bspm_orthviews('Caption',i,varargin{1}{i},varargin{3:end});
                if ~isempty(h), xlh(i) = h; end
            end
            varargout{1} = xlh;
            return;
        end
        
        vh = valid_handles(varargin{1});
        nh = numel(vh);
        
        xlh = nan(nh, 1);
        for i = 1:nh
            xlh(i) = get(st.vols{vh(i)}.ax{3}.ax, 'XLabel');
            if iscell(varargin{2})
                if i <= length(varargin{2})
                    set(xlh(i), 'String', varargin{2}{i});
                end
            else
                set(xlh(i), 'String', varargin{2});
            end
            for np = 4:2:nargin
                property = varargin{np-1};
                value = varargin{np};
                set(xlh(i), property, value);
            end
        end
        varargout{1} = xlh;
        
    case 'bb'
        if ~isempty(varargin) && all(size(varargin{1})==[2 3]), st.bb = varargin{1}; end
        bbox;
        redraw_all;
        
    case 'redraw'
        
        redraw_all;
        if isfield(st.vols{1}, 'blobs')
            redraw_colourbar(st.hld, 1, [st.vols{1}.blobs{1}.min st.vols{1}.blobs{1}.max], (1:64)'+64);
        end
        callback;
        if isfield(st,'registry')
            bspm_XYZreg('SetCoords',st.centre,st.registry.hReg,st.registry.hMe);
        end
        
    case 'reload_mats'
        if nargin > 1
            handles = valid_handles(varargin{1});
        else
            handles = valid_handles;
        end
        for i = handles
            fnm = spm_file(st.vols{i}.fname, 'number', st.vols{i}.n);
            st.vols{i}.mat = spm_get_space(fnm);
        end
        
    case 'reposition'

        if isempty(varargin), tmp = findcent;
        else tmp = varargin{1}; end
        if numel(tmp) == 3
            h = valid_handles(st.snap);
            if ~isempty(h)
                tmp = st.vols{h(1)}.mat * ...
                    round(st.vols{h(1)}.mat\[tmp(:); 1]);
            end
%             if isequal(round(tmp),round(st.centre)), return; end
            st.centre = tmp(1:3);
        end        
        redraw_all;
        callback;
        if isfield(st,'registry'), bspm_XYZreg('SetCoords',st.centre,st.registry.hReg,st.registry.hMe); end
        cm_pos;
        setvoxelinfo;

    case 'setcoords'
        st.centre = varargin{1};
        st.centre = st.centre(:);
        redraw_all;
        callback;
        cm_pos;
        
    case 'space'
        if numel(varargin) < 1
            st.Space = eye(4);
            st.bb = maxbb;
            resolution;
            bbox;
            redraw_all;
        else
            space(varargin{:});
            resolution;
            bbox;
            redraw_all;
        end
        
    case 'maxbb'
        st.bb = maxbb;
        bbox;
        redraw_all;
        
    case 'resolution'
        resolution(varargin{:});
        bbox;
        redraw_all;
        
    case 'window'
        if numel(varargin)<2
            win = 'auto';
        elseif numel(varargin{2})==2
            win = varargin{2};
        end
        for i=valid_handles(varargin{1})
            st.vols{i}.window = win;
        end
        redraw(varargin{1});
        
    case 'delete'
        my_delete(varargin{1});
        
    case 'move'
        move(varargin{1},varargin{2});
        % redraw_all;
        
    case 'reset'
        my_reset;
        
    case 'pos'
        if isempty(varargin)
            H = st.centre(:);
        else
            H = pos(varargin{1});
        end
        varargout{1} = H;
        
    case 'interp'
        st.hld = varargin{1};
        redraw_all;
        
    case 'xhairs'
        xhairs(varargin{:});
        
    case 'register'
        register(varargin{1});
        
    case 'addblobs'
        addblobs(varargin{:});
        % redraw(varargin{1});
        
    case 'setblobsmax'
        st.vols{varargin{1}}.blobs{varargin{2}}.max = varargin{3};
        bspm_orthviews('redraw')
    
    case 'setblobsmin'
        st.vols{varargin{1}}.blobs{varargin{2}}.min = varargin{3};
        bspm_orthviews('redraw')
        
    case 'addcolouredblobs'
        addcolouredblobs(varargin{:});
        % redraw(varargin{1});
        
    case 'addimage'
        addimage(varargin{1}, varargin{2});
        % redraw(varargin{1});
        
    case 'addcolouredimage'
        addcolouredimage(varargin{1}, varargin{2},varargin{3});
        % redraw(varargin{1});
        
    case 'addtruecolourimage'
        if nargin < 2
            varargin(1) = {1};
        end
        if nargin < 3
            varargin(2) = {spm_select(1, 'image', 'Image with activation signal')};
        end
        if nargin < 4
            actc = [];
            while isempty(actc)
                actc = getcmap(spm_input('Colourmap for activation image', '+1','s'));
            end
            varargin(3) = {actc};
        end
        if nargin < 5
            varargin(4) = {0.4};
        end
        if nargin < 6
            actv = spm_vol(varargin{2});
            varargin(5) = {max([eps maxval(actv)])};
        end
        if nargin < 7
            varargin(6) = {min([0 minval(actv)])};
        end
        
        addtruecolourimage(varargin{1}, varargin{2},varargin{3}, varargin{4}, ...
            varargin{5}, varargin{6});
        % redraw(varargin{1});
        
    case 'addcolourbar'
        addcolourbar(varargin{1}, varargin{2});
        
    case {'removeblobs','rmblobs'}
        rmblobs(varargin{1});
        redraw(varargin{1});
        
    case 'replaceblobs'
        replaceblobs(varargin{:});
        redraw(varargin{1});

    case 'addcontext'
        if nargin == 1
            handles = 1:max_img;
        else
            handles = varargin{1};
        end
        addcontexts(handles);
        
    case {'removecontext','rmcontext'}
        if nargin == 1
            handles = 1:max_img;
        else
            handles = varargin{1};
        end
        rmcontexts(handles);
        
    case 'context_menu'
        c_menu(varargin{:});
        
    case 'valid_handles'
        if nargin == 1
            handles = 1:max_img;
        else
            handles = varargin{1};
        end
        varargout{1} = valid_handles(handles);

    case 'zoom'
        zoom_op(varargin{:});
        
    case 'zoommenu'
        if isempty(zoomlist)
            zoomlist = [NaN 0 5    10  20 40 80 Inf];
            reslist  = [1   1 .125 .25 .5 .5 1  1  ];
        end
        if nargin >= 3
            if all(cellfun(@isnumeric,varargin(1:2))) && ...
                    numel(varargin{1})==numel(varargin{2})
                zoomlist = varargin{1}(:);
                reslist  = varargin{2}(:);
            else
                warning('bspm_orthviews:zoom',...
                        'Invalid zoom or resolution list.')
            end
        end
        if nargout > 0
            varargout{1} = zoomlist;
        end
        if nargout > 1
            varargout{2} = reslist;
        end
        
    otherwise
        addonaction = strcmpi(st.plugins,action);
        if any(addonaction)
            feval(['spm_ov_' st.plugins{addonaction}],varargin{:});
        end
end
function H                  = specify_image(img)
global st
H = [];
if isstruct(img)
    V = img(1);
else
    try
        V = spm_vol(img);
    catch
        fprintf('Can not use image "%s"\n', img);
        return;
    end
end
if numel(V)>1, V=V(1); end

ii = 1;
while ~isempty(st.vols{ii}), ii = ii + 1; end
DeleteFcn = ['spm_orthviews(''Delete'',' num2str(ii) ');'];
V.ax = cell(3,1);
for i=1:3
    ax = axes('Visible','off', 'Parent', st.figax, ...
        'YDir','normal', 'DeleteFcn', DeleteFcn); 
    d  = image(0, 'Tag','Transverse', 'Parent',ax, 'DeleteFcn',DeleteFcn);
    set(ax, 'Ydir','normal', 'ButtonDownFcn', @repos_start);
    lx = line(0,0, 'Parent',ax, 'DeleteFcn',DeleteFcn, 'Color',[0 0 1]);
    ly = line(0,0, 'Parent',ax, 'DeleteFcn',DeleteFcn, 'Color',[0 0 1]);
    if ~st.xhairs
        set(lx, 'Visible','off');
        set(ly, 'Visible','off');
    end
    V.ax{i} = struct('ax',ax,'d',d,'lx',lx,'ly',ly);
end
V.premul    = eye(4);
V.window    = 'auto';
V.mapping   = 'linear';
st.vols{ii} = V;
H = ii;
function bb                 = maxbb
global st
mn = [Inf Inf Inf];
mx = -mn;
for i=valid_handles
    premul = st.Space \ st.vols{i}.premul;
    bb = spm_get_bbox(st.vols{i}, 'fv', premul);
    mx = max([bb ; mx]);
    mn = min([bb ; mn]);
end
bb = [mn ; mx];
function H                  = pos(handle)
global st
H = [];
for i=valid_handles(handle)
    is = inv(st.vols{i}.premul*st.vols{i}.mat);
    H = is(1:3,1:3)*st.centre(:) + is(1:3,4);
end
function mx                 = maxval(vol)
if isstruct(vol)
    mx = -Inf;
    for i=1:vol.dim(3)
        tmp = spm_slice_vol(vol,spm_matrix([0 0 i]),vol.dim(1:2),0);
        imx = max(tmp(isfinite(tmp)));
        if ~isempty(imx), mx = max(mx,imx); end
    end
else
    mx = max(vol(isfinite(vol)));
end
function mn                 = minval(vol)
if isstruct(vol)
    mn = Inf;
    for i=1:vol.dim(3)
        tmp = spm_slice_vol(vol,spm_matrix([0 0 i]),vol.dim(1:2),0);
        imn = min(tmp(isfinite(tmp)));
        if ~isempty(imn), mn = min(mn,imn); end
    end
else
    mn = min(vol(isfinite(vol)));
end
function m                  = max_img
m = 24;
function centre             = findcent
    global st
    obj    = get(st.fig,'CurrentObject');
    centre = [];
    cent   = [];
    cp     = [];
    for i=valid_handles
        for j=1:3
            if ~isempty(obj)
                if (st.vols{i}.ax{j}.ax == obj),
                    cp = get(obj,'CurrentPoint');
                end
            end
            if ~isempty(cp)
                cp   = cp(1,1:2);
                is   = inv(st.Space);
                cent = is(1:3,1:3)*st.centre(:) + is(1:3,4);
                switch j
                    case 1
                        cent([1 2])=[cp(1)+st.bb(1,1)-1 cp(2)+st.bb(1,2)-1];
                    case 2
                        cent([1 3])=[cp(1)+st.bb(1,1)-1 cp(2)+st.bb(1,3)-1];
                    case 3
                        if st.mode ==0
                            cent([3 2])=[cp(1)+st.bb(1,3)-1 cp(2)+st.bb(1,2)-1];
                        else
                            cent([2 3])=[st.bb(2,2)+1-cp(1) cp(2)+st.bb(1,3)-1];
                        end
                end
                break;
            end
        end
        if ~isempty(cent), break; end
    end
    if ~isempty(cent), centre = st.Space(1:3,1:3)*cent(:) + st.Space(1:3,4); end
function handles            = valid_handles(handles)
    global st
    if ~nargin, handles = 1:max_img; end
    if isempty(st) || ~isfield(st,'vols')
        handles = [];
    elseif ~ishandle(st.fig)
        handles = []; 
    else
        handles = handles(:)';
        handles = handles(handles<=max_img & handles>=1 & ~rem(handles,1));
        for h=handles
            if isempty(st.vols{h}), handles(handles==h)=[]; end
        end
    end
function img                = scaletocmap(inpimg,mn,mx,cmap,miscol)
if nargin < 5, miscol=1; end
cml = size(cmap,1);
scf = (cml-1)/(mx-mn);
img = round((inpimg-mn)*scf)+1;
img(img<1)   = 1;
img(img>cml) = cml;
img(~isfinite(img)) = miscol;
function item_parent        = addcontext(volhandle)
global st
% create context menu
set(0,'CurrentFigure',st.fig);
% contextmenu
item_parent = uicontextmenu;

% contextsubmenu 0
item00 = uimenu(item_parent, 'Label','unknown image', 'UserData','filename');
bspm_orthviews('context_menu','image_info',item00,volhandle);
item0a = uimenu(item_parent, 'UserData','pos_mm', 'Separator','on', ...
    'Callback','bspm_orthviews(''context_menu'',''repos_mm'');');
item0b = uimenu(item_parent, 'UserData','pos_vx', ...
    'Callback','bspm_orthviews(''context_menu'',''repos_vx'');');
item0c = uimenu(item_parent, 'UserData','v_value');

% contextsubmenu 1
item1    = uimenu(item_parent,'Label','Zoom', 'Separator','on');
[zl, rl] = bspm_orthviews('ZoomMenu');
for cz = numel(zl):-1:1
    if isinf(zl(cz))
        czlabel = 'Full Volume';
    elseif isnan(zl(cz))
        czlabel = 'BBox, this image > ...';
    elseif zl(cz) == 0
        czlabel = 'BBox, this image nonzero';
    else
        czlabel = sprintf('%dx%d mm', 2*zl(cz), 2*zl(cz));
    end
    item1_x = uimenu(item1, 'Label',czlabel,...
        'Callback', sprintf(...
        'bspm_orthviews(''context_menu'',''zoom'',%d,%d)',zl(cz),rl(cz)));
    if isinf(zl(cz)) % default display is Full Volume
        set(item1_x, 'Checked','on');
    end
end

% contextsubmenu 2
checked   = {'off','off'};
checked{st.xhairs+1} = 'on';
item2     = uimenu(item_parent,'Label','Crosshairs','Callback','bspm_orthviews(''context_menu'',''Xhair'');','Checked',checked{2});

% contextsubmenu 3
if st.Space == eye(4)
    checked = {'off', 'on'};
else
    checked = {'on', 'off'};
end
item3     = uimenu(item_parent,'Label','Orientation');
item3_1   = uimenu(item3,      'Label','World space', 'Callback','bspm_orthviews(''context_menu'',''orientation'',3);','Checked',checked{2});
item3_2   = uimenu(item3,      'Label','Voxel space (1st image)', 'Callback','bspm_orthviews(''context_menu'',''orientation'',2);','Checked',checked{1});
item3_3   = uimenu(item3,      'Label','Voxel space (this image)', 'Callback','bspm_orthviews(''context_menu'',''orientation'',1);','Checked','off');

% contextsubmenu 3
if isempty(st.snap)
    checked = {'off', 'on'};
else
    checked = {'on', 'off'};
end
item3     = uimenu(item_parent,'Label','Snap to Grid');
item3_1   = uimenu(item3,      'Label','Don''t snap', 'Callback','bspm_orthviews(''context_menu'',''snap'',3);','Checked',checked{2});
item3_2   = uimenu(item3,      'Label','Snap to 1st image', 'Callback','bspm_orthviews(''context_menu'',''snap'',2);','Checked',checked{1});
item3_3   = uimenu(item3,      'Label','Snap to this image', 'Callback','bspm_orthviews(''context_menu'',''snap'',1);','Checked','off');

% contextsubmenu 4
if st.hld == 0
    checked = {'off', 'off', 'on'};
elseif st.hld > 0
    checked = {'off', 'on', 'off'};
else
    checked = {'on', 'off', 'off'};
end
item4     = uimenu(item_parent,'Label','Interpolation');
item4_1   = uimenu(item4,      'Label','NN',    'Callback','bspm_orthviews(''context_menu'',''interpolation'',3);', 'Checked',checked{3});
item4_2   = uimenu(item4,      'Label','Trilin', 'Callback','bspm_orthviews(''context_menu'',''interpolation'',2);','Checked',checked{2});
item4_3   = uimenu(item4,      'Label','Sinc',  'Callback','bspm_orthviews(''context_menu'',''interpolation'',1);','Checked',checked{1});

% contextsubmenu 5
% item5     = uimenu(item_parent,'Label','Position', 'Callback','bspm_orthviews(''context_menu'',''position'');');

% contextsubmenu 6
item6       = uimenu(item_parent,'Label','Image','Separator','on');
item6_1     = uimenu(item6,      'Label','Window');
item6_1_1   = uimenu(item6_1,    'Label','local');
item6_1_1_1 = uimenu(item6_1_1,  'Label','auto', 'Callback','bspm_orthviews(''context_menu'',''window'',2);');
item6_1_1_2 = uimenu(item6_1_1,  'Label','manual', 'Callback','bspm_orthviews(''context_menu'',''window'',1);');
item6_1_1_3 = uimenu(item6_1_1,  'Label','percentiles', 'Callback','bspm_orthviews(''context_menu'',''window'',3);');
item6_1_2   = uimenu(item6_1,    'Label','global');
item6_1_2_1 = uimenu(item6_1_2,  'Label','auto', 'Callback','bspm_orthviews(''context_menu'',''window_gl'',2);');
item6_1_2_2 = uimenu(item6_1_2,  'Label','manual', 'Callback','bspm_orthviews(''context_menu'',''window_gl'',1);');
if license('test','image_toolbox') == 1
    offon = {'off', 'on'};
    checked = offon(strcmp(st.vols{volhandle}.mapping, ...
        {'linear', 'histeq', 'loghisteq', 'quadhisteq'})+1);
    item6_2     = uimenu(item6,      'Label','Intensity mapping');
    item6_2_1   = uimenu(item6_2,    'Label','local');
    item6_2_1_1 = uimenu(item6_2_1,  'Label','Linear', 'Checked',checked{1}, ...
        'Callback','bspm_orthviews(''context_menu'',''mapping'',''linear'');');
    item6_2_1_2 = uimenu(item6_2_1,  'Label','Equalised histogram', 'Checked',checked{2}, ...
        'Callback','bspm_orthviews(''context_menu'',''mapping'',''histeq'');');
    item6_2_1_3 = uimenu(item6_2_1,  'Label','Equalised log-histogram', 'Checked',checked{3}, ...
        'Callback','bspm_orthviews(''context_menu'',''mapping'',''loghisteq'');');
    item6_2_1_4 = uimenu(item6_2_1,  'Label','Equalised squared-histogram', 'Checked',checked{4}, ...
        'Callback','bspm_orthviews(''context_menu'',''mapping'',''quadhisteq'');');
    item6_2_2   = uimenu(item6_2,    'Label','global');
    item6_2_2_1 = uimenu(item6_2_2,  'Label','Linear', 'Checked',checked{1}, ...
        'Callback','bspm_orthviews(''context_menu'',''mapping_gl'',''linear'');');
    item6_2_2_2 = uimenu(item6_2_2,  'Label','Equalised histogram', 'Checked',checked{2}, ...
        'Callback','bspm_orthviews(''context_menu'',''mapping_gl'',''histeq'');');
    item6_2_2_3 = uimenu(item6_2_2,  'Label','Equalised log-histogram', 'Checked',checked{3}, ...
        'Callback','bspm_orthviews(''context_menu'',''mapping_gl'',''loghisteq'');');
    item6_2_2_4 = uimenu(item6_2_2,  'Label','Equalised squared-histogram', 'Checked',checked{4}, ...
        'Callback','bspm_orthviews(''context_menu'',''mapping_gl'',''quadhisteq'');');
end

% contextsubmenu 7
item7     = uimenu(item_parent,'Label','Overlay');
item7_1   = uimenu(item7,      'Label','Add blobs');
item7_1_1 = uimenu(item7_1,    'Label','local',  'Callback','bspm_orthviews(''context_menu'',''add_blobs'',2);');
item7_1_2 = uimenu(item7_1,    'Label','global', 'Callback','bspm_orthviews(''context_menu'',''add_blobs'',1);');
item7_2   = uimenu(item7,      'Label','Add image');
item7_2_1 = uimenu(item7_2,    'Label','local',  'Callback','bspm_orthviews(''context_menu'',''add_image'',2);');
item7_2_2 = uimenu(item7_2,    'Label','global', 'Callback','bspm_orthviews(''context_menu'',''add_image'',1);');
item7_3   = uimenu(item7,      'Label','Add coloured blobs','Separator','on');
item7_3_1 = uimenu(item7_3,    'Label','local',  'Callback','bspm_orthviews(''context_menu'',''add_c_blobs'',2);');
item7_3_2 = uimenu(item7_3,    'Label','global', 'Callback','bspm_orthviews(''context_menu'',''add_c_blobs'',1);');
item7_4   = uimenu(item7,      'Label','Add coloured image');
item7_4_1 = uimenu(item7_4,    'Label','local',  'Callback','bspm_orthviews(''context_menu'',''add_c_image'',2);');
item7_4_2 = uimenu(item7_4,    'Label','global', 'Callback','bspm_orthviews(''context_menu'',''add_c_image'',1);');
item7_5   = uimenu(item7,      'Label','Remove blobs',        'Visible','off','Separator','on');
item7_6   = uimenu(item7,      'Label','Remove coloured blobs','Visible','off');
item7_6_1 = uimenu(item7_6,    'Label','local', 'Visible','on');
item7_6_2 = uimenu(item7_6,    'Label','global','Visible','on');
item7_7   = uimenu(item7,      'Label','Set blobs max', 'Visible','off');

for i=1:3
    set(st.vols{volhandle}.ax{i}.ax,'UIcontextmenu',item_parent);
    st.vols{volhandle}.ax{i}.cm = item_parent;
end

% process any plugins
for k = 1:numel(st.plugins)
    feval(['spm_ov_', st.plugins{k}],'context_menu',volhandle,item_parent);
    if k==1
        h = get(item_parent,'Children');
        set(h(1),'Separator','on'); 
    end
end
function cm_handles         = get_cm_handles
global st
cm_handles = [];
for i = valid_handles
    cm_handles = [cm_handles st.vols{i}.ax{1}.cm];
end
function cmap               = getcmap(acmapname)
% get colormap of name acmapname
if ~isempty(acmapname)
    cmap = evalin('base',acmapname,'[]');
    if isempty(cmap) % not a matrix, is .mat file?
        acmat = spm_file(acmapname, 'ext','.mat');
        if exist(acmat, 'file')
            s    = struct2cell(load(acmat));
            cmap = s{1};
        end
    end
end
if size(cmap, 2)~=3
    warning('Colormap was not an N by 3 matrix')
    cmap = [];
end
function current_handle     = get_current_handle
    cm_handle      = get(gca,'UIContextMenu');
    cm_handles     = get_cm_handles;
    current_handle = find(cm_handles==cm_handle);
function addblobs(handle, xyz, t, mat, name)
global st
if nargin < 5
    name = '';
end
for i=valid_handles(handle)
    if ~isempty(xyz)
        rcp      = round(xyz);
        dim      = max(rcp,[],2)';
        off      = rcp(1,:) + dim(1)*(rcp(2,:)-1 + dim(2)*(rcp(3,:)-1));
        vol      = zeros(dim)+NaN;
        vol(off) = t;
        vol      = reshape(vol,dim);
        st.vols{i}.blobs=cell(1,1);
        mx = max([eps max(t)]);
        mn = min([0 min(t)]);
        st.vols{i}.blobs{1} = struct('vol',vol,'mat',mat,'max',mx, 'min',mn,'name',name);
        addcolourbar(handle,1);
    end
end
function addimage(handle, fname)
global st
for i=valid_handles(handle)
    if isstruct(fname)
        vol = fname(1);
    else
        vol = spm_vol(fname);
    end
    mat = vol.mat;
    st.vols{i}.blobs=cell(1,1);
    mx = max([eps maxval(vol)]);
    mn = min([0 minval(vol)]);
    st.vols{i}.blobs{1} = struct('vol',vol,'mat',mat,'max',mx,'min',mn);
    addcolourbar(handle,1);
end
function addcolouredblobs(handle, xyz, t, mat, colour, name)
if nargin < 6
    name = '';
end
global st
for i=valid_handles(handle)
    if ~isempty(xyz)
        rcp      = round(xyz);
        dim      = max(rcp,[],2)';
        off      = rcp(1,:) + dim(1)*(rcp(2,:)-1 + dim(2)*(rcp(3,:)-1));
        vol      = zeros(dim)+NaN;
        vol(off) = t;
        vol      = reshape(vol,dim);
        if ~isfield(st.vols{i},'blobs')
            st.vols{i}.blobs=cell(1,1);
            bset = 1;
        else
            bset = numel(st.vols{i}.blobs)+1;
        end
        mx = max([eps maxval(vol)]);
        mn = min([0 minval(vol)]);
        st.vols{i}.blobs{bset} = struct('vol',vol, 'mat',mat, ...
            'max',mx, 'min',mn, 'colour',colour, 'name',name);
    end
end
function addcolouredimage(handle, fname,colour)
global st
for i=valid_handles(handle)
    if isstruct(fname)
        vol = fname(1);
    else
        vol = spm_vol(fname);
    end
    mat = vol.mat;
    if ~isfield(st.vols{i},'blobs')
        st.vols{i}.blobs=cell(1,1);
        bset = 1;
    else
        bset = numel(st.vols{i}.blobs)+1;
    end
    mx = max([eps maxval(vol)]);
    mn = min([0 minval(vol)]);
    st.vols{i}.blobs{bset} = struct('vol',vol, 'mat',mat, ...
        'max',mx, 'min',mn, 'colour',colour);
end
function addtruecolourimage(handle,fname,colourmap,prop,mx,mn)
% adds true colour image to current displayed image
global st
for i=valid_handles(handle)
    if isstruct(fname)
        vol = fname(1);
    else
        vol = spm_vol(fname);
    end
    mat = vol.mat;
    if ~isfield(st.vols{i},'blobs')
        st.vols{i}.blobs=cell(1,1);
        bset = 1;
    else
        bset = numel(st.vols{i}.blobs)+1;
    end
    c = struct('cmap', colourmap,'prop',prop);
    st.vols{i}.blobs{bset} = struct('vol',vol, 'mat',mat, ...
        'max',mx, 'min',mn, 'colour',c);
    addcolourbar(handle,bset);
end
function addcontexts(handles)
for ii = valid_handles(handles)
    addcontext(ii);
end
bspm_orthviews('reposition',bspm_orthviews('pos'));
function rmblobs(handle)
global st
for i=valid_handles(handle)
    if isfield(st.vols{i},'blobs')
        for j=1:numel(st.vols{i}.blobs)
            if isfield(st.vols{i}.blobs{j},'cbar') && ishandle(st.vols{i}.blobs{j}.cbar),
                delete(st.vols{i}.blobs{j}.cbar);
            end
        end
        st.vols{i} = rmfield(st.vols{i},'blobs');
    end
end
function replaceblobs(handle, xyz, t, mat, name)
global st
if nargin < 5, name = ''; end
for i=valid_handles(handle)
    if ~isempty(xyz)
        rcp         = round(xyz);
        dim         = max(rcp,[],2)';
        off         = rcp(1,:) + dim(1)*(rcp(2,:)-1 + dim(2)*(rcp(3,:)-1));
        vol         = zeros(dim)+NaN;
        vol(off)    = t;
        st.vols{i}.blobs{1}.vol     = reshape(vol,dim);
        st.vols{i}.blobs{1}.mat     = mat;
        st.vols{i}.blobs{1}.max     = max([eps max(t)]);
        st.vols{i}.blobs{1}.min     = min([0 min(t)]);
        st.vols{i}.blobs{1}.name    = name;
    end
end
function rmcontexts(handles)
global st
for ii = valid_handles(handles)
    for i=1:3
        set(st.vols{ii}.ax{i}.ax,'UIcontextmenu',[]);
        try, st.vols{ii}.ax{i} = rmfield(st.vols{ii}.ax{i},'cm'); end
    end
end
function register(hreg)
global st
%tmp = uicontrol('Position',[0 0 1 1],'Visible','off','Parent',st.fig);
h   = valid_handles;
if ~isempty(h)
    tmp = st.vols{h(1)}.ax{1}.ax;
    st.registry = struct('hReg',hreg,'hMe', tmp);
    bspm_XYZreg('Add2Reg',st.registry.hReg,st.registry.hMe, 'bspm_orthviews');
else
    warning('Nothing to register with');
end
st.centre = bspm_XYZreg('GetCoords',st.registry.hReg);
st.centre = st.centre(:);
function callback
global st
if ~iscell(st.callback), st.callback = { st.callback }; end
for i=1:numel(st.callback)
    if isa(st.callback{i},'function_handle')
        feval(st.callback{i});
    else
        eval(st.callback{i});
    end
end
function xhairs(state)
global st
if ~nargin, if st.xhairs, state = 'off'; else state = 'on'; end; end
st.xhairs = 0;
opt = 'on';
if ~strcmpi(state,'on')
    opt = 'off';
else
    st.xhairs = 1;
end
for i=valid_handles
    for j=1:3
        set(st.vols{i}.ax{j}.lx,'Visible',opt);
        set(st.vols{i}.ax{j}.ly,'Visible',opt);
    end
end
function cm_pos
    global st
    for i = 1:numel(valid_handles)
        if isfield(st.vols{i}.ax{1},'cm')
            set(findobj(st.vols{i}.ax{1}.cm,'UserData','pos_mm'),...
                'Label',sprintf('mm:  %.1f %.1f %.1f',bspm_orthviews('pos')));
            pos = bspm_orthviews('pos',i);
            set(findobj(st.vols{i}.ax{1}.cm,'UserData','pos_vx'),...
                'Label',sprintf('vx:  %.1f %.1f %.1f',pos));
            try
                Y = spm_sample_vol(st.vols{i},pos(1),pos(2),pos(3),st.hld);
            catch
                Y = NaN;
                fprintf('Cannot access file "%s".\n', st.vols{i}.fname);
            end
            set(findobj(st.vols{i}.ax{1}.cm,'UserData','v_value'),...
                'Label',sprintf('Y = %g',Y));
        end
    end
function my_reset
    global st
    % if ~isempty(st) && isfield(st,'registry') && ishandle(st.registry.hMe)
    %     delete(st.registry.hMe); st = rmfield(st,'registry');
    % end
    my_delete(1:max_img);
    reset_st;
function my_delete(handle)
global st
% remove blobs (and colourbars, if any)
rmblobs(handle);
% remove displayed axes
for i=valid_handles(handle)
    kids = get(st.fig,'Children');
    for j=1:3
        try
            if any(kids == st.vols{i}.ax{j}.ax)
                set(get(st.vols{i}.ax{j}.ax,'Children'),'DeleteFcn','');
                delete(st.vols{i}.ax{j}.ax);
            end
        end
    end
    st.vols{i} = [];
end
function resolution(res)
global st
if ~nargin, res = 1; end % Default minimum resolution 1mm
for i=valid_handles
    % adapt resolution to smallest voxel size of displayed images
    res  = min([res,sqrt(sum((st.vols{i}.mat(1:3,1:3)).^2))]);
end
res      = res/mean(svd(st.Space(1:3,1:3)));
Mat      = diag([res res res 1]);
st.Space = st.Space*Mat;
st.bb    = st.bb/res;
function move(handle,pos)
global st
for i=valid_handles(handle)
    st.vols{i}.area = pos;
end
bbox;
function space(handle,M,dim)
global st
if ~isempty(st.vols{handle})
    if nargin < 2
        M = st.vols{handle}.mat;
        dim = st.vols{handle}.dim(1:3);
    end
    Mat   = st.vols{handle}.premul(1:3,1:3)*M(1:3,1:3);
    vox   = sqrt(sum(Mat.^2));
    if det(Mat(1:3,1:3))<0, vox(1) = -vox(1); end
    Mat   = diag([vox 1]);
    Space = (M)/Mat;
    bb    = [1 1 1; dim];
    bb    = [bb [1;1]];
    bb    = bb*Mat';
    bb    = bb(:,1:3);
    bb    = sort(bb);
    st.Space = Space;
    st.bb = bb;
end
function zoom_op(fov,res)
global st
if nargin < 1, fov = Inf; end
if nargin < 2, res = Inf; end

if isinf(fov)
    st.bb = maxbb;
elseif isnan(fov) || fov == 0
    current_handle = valid_handles;
    if numel(current_handle) > 1 % called from check reg context menu
        current_handle = get_current_handle;
    end
    if fov == 0
        % zoom to bounding box of current image ~= 0
        thr = 'nz';
    else
        % zoom to bounding box of current image > chosen threshold
        thr = spm_input('Threshold (Y > ...)', '+1', 'r', '0', 1);
    end
    premul = st.Space \ st.vols{current_handle}.premul;
    st.bb = spm_get_bbox(st.vols{current_handle}, thr, premul);
else
    vx    = sqrt(sum(st.Space(1:3,1:3).^2));
    vx    = vx.^(-1);
    pos   = bspm_orthviews('pos');
    pos   = st.Space\[pos ; 1];
    pos   = pos(1:3)';
    st.bb = [pos-fov*vx; pos+fov*vx];
end
resolution(res);
bbox;
redraw_all;
if isfield(st.vols{1},'sdip')
    spm_eeg_inv_vbecd_disp('RedrawDip');
end
function bbox
global st
Dims = diff(st.bb)'+1;

TD = Dims([1 2])';
CD = Dims([1 3])';
if st.mode == 0, SD = Dims([3 2])'; else SD = Dims([2 3])'; end

un    = get(st.fig,'Units');set(st.fig,'Units','Pixels');
sz    = get(st.fig,'Position');set(st.fig,'Units',un);
sz    = sz(3:4);
sz(2) = sz(2)-40;

for i=valid_handles
    area   = st.vols{i}.area(:);
    area   = [area(1)*sz(1) area(2)*sz(2) area(3)*sz(1) area(4)*sz(2)];
    if st.mode == 0
        sx = area(3)/(Dims(1)+Dims(3))/1.02;
    else
        sx = area(3)/(Dims(1)+Dims(2))/1.02;
    end
    sy     = area(4)/(Dims(2)+Dims(3))/1.02;
    s      = min([sx sy]);
    
    offy   = (area(4)-(Dims(2)+Dims(3))*1.02*s)/2 + area(2);
    sky    = s*(Dims(2)+Dims(3))*0.02;
    if st.mode == 0
        offx = (area(3)-(Dims(1)+Dims(3))*1.02*s)/2 + area(1);
        skx  = s*(Dims(1)+Dims(3))*0.02;
    else
        offx = (area(3)-(Dims(1)+Dims(2))*1.02*s)/2 + area(1);
        skx  = s*(Dims(1)+Dims(2))*0.02;
    end
    
    % Transverse
    set(st.vols{i}.ax{1}.ax,'Units','pixels', ...
        'Position',[offx offy s*Dims(1) s*Dims(2)],...
        'Units','normalized','Xlim',[0 TD(1)]+0.5,'Ylim',[0 TD(2)]+0.5,...
        'Visible','on','XTick',[],'YTick',[]);
    
    % Coronal
    set(st.vols{i}.ax{2}.ax,'Units','Pixels',...
        'Position',[offx offy+s*Dims(2)+sky s*Dims(1) s*Dims(3)],...
        'Units','normalized','Xlim',[0 CD(1)]+0.5,'Ylim',[0 CD(2)]+0.5,...
        'Visible','on','XTick',[],'YTick',[]);
    
    % Sagittal
    if st.mode == 0
        set(st.vols{i}.ax{3}.ax,'Units','Pixels', 'Box','on',...
            'Position',[offx+s*Dims(1)+skx offy s*Dims(3) s*Dims(2)],...
            'Units','normalized','Xlim',[0 SD(1)]+0.5,'Ylim',[0 SD(2)]+0.5,...
            'Visible','on','XTick',[],'YTick',[]);
    else
        set(st.vols{i}.ax{3}.ax,'Units','Pixels', 'Box','on',...
            'Position',[offx+s*Dims(1)+skx offy+s*Dims(2)+sky s*Dims(2) s*Dims(3)],...
            'Units','normalized','Xlim',[0 SD(1)]+0.5,'Ylim',[0 SD(2)]+0.5,...
            'Visible','on','XTick',[],'YTick',[]);
    end
end
function redraw(arg1)
    global st
    bb   = st.bb;
    Dims = round(diff(bb)'+1);
    is   = inv(st.Space);
    cent = is(1:3,1:3)*st.centre(:) + is(1:3,4);
    for i = valid_handles(arg1)
        M = st.Space\st.vols{i}.premul*st.vols{i}.mat;
        TM0 = [ 1 0 0 -bb(1,1)+1
                0 1 0 -bb(1,2)+1
                0 0 1 -cent(3)
                0 0 0 1];
        TM = inv(TM0*M);
        TD = Dims([1 2]);

        CM0 = [ 1 0 0 -bb(1,1)+1
                0 0 1 -bb(1,3)+1
                0 1 0 -cent(2)
                0 0 0 1];
        CM = inv(CM0*M);
        CD = Dims([1 3]);
        if st.mode ==0
            SM0 = [ 0 0 1 -bb(1,3)+1
                    0 1 0 -bb(1,2)+1
                    1 0 0 -cent(1)
                    0 0 0 1];
            SM = inv(SM0*M); 
            SD = Dims([3 2]);
        else
            SM0 = [ 0 -1 0 +bb(2,2)+1
                    0  0 1 -bb(1,3)+1
                    1  0 0 -cent(1)
                    0  0 0 1];
            SM = inv(SM0*M);
            SD = Dims([2 3]);
        end
        try
            imgt = spm_slice_vol(st.vols{i},TM,TD,st.hld)';
            imgc = spm_slice_vol(st.vols{i},CM,CD,st.hld)';
            imgs = spm_slice_vol(st.vols{i},SM,SD,st.hld)';
%             imgc2 = adjustbrightness(imgc); 
%             imgs2 = adjustbrightness(imgs); 
%             imgt2 = adjustbrightness(imgt); 
            ok   = true;
        catch
%             fprintf('Cannot access file "%s".\n', st.vols{i}.fname);
%             fprintf('%s\n',getfield(lasterror,'message'));
            ok   = false;
        end
        if ok
            % get min/max threshold
            if strcmp(st.vols{i}.window,'auto')
                mn = -Inf;
                mx = Inf;
            else
                mn = min(st.vols{i}.window);
                mx = max(st.vols{i}.window);
            end
            % threshold images
            imgt = max(imgt,mn); imgt = min(imgt,mx);
            imgc = max(imgc,mn); imgc = min(imgc,mx);
            imgs = max(imgs,mn); imgs = min(imgs,mx);
            % compute intensity mapping, if histeq is available
            if license('test','image_toolbox') == 0
                st.vols{i}.mapping = 'linear';
            end
            switch st.vols{i}.mapping
                case 'linear'
                case 'histeq'
                    % scale images to a range between 0 and 1
                    imgt1=(imgt-min(imgt(:)))/(max(imgt(:)-min(imgt(:)))+eps);
                    imgc1=(imgc-min(imgc(:)))/(max(imgc(:)-min(imgc(:)))+eps);
                    imgs1=(imgs-min(imgs(:)))/(max(imgs(:)-min(imgs(:)))+eps);
                    img  = histeq([imgt1(:); imgc1(:); imgs1(:)],1024);
                    imgt = reshape(img(1:numel(imgt1)),size(imgt1));
                    imgc = reshape(img(numel(imgt1)+(1:numel(imgc1))),size(imgc1));
                    imgs = reshape(img(numel(imgt1)+numel(imgc1)+(1:numel(imgs1))),size(imgs1));
                    mn = 0;
                    mx = 1;
                case 'quadhisteq'
                    % scale images to a range between 0 and 1
                    imgt1=(imgt-min(imgt(:)))/(max(imgt(:)-min(imgt(:)))+eps);
                    imgc1=(imgc-min(imgc(:)))/(max(imgc(:)-min(imgc(:)))+eps);
                    imgs1=(imgs-min(imgs(:)))/(max(imgs(:)-min(imgs(:)))+eps);
                    img  = histeq([imgt1(:).^2; imgc1(:).^2; imgs1(:).^2],1024);
                    imgt = reshape(img(1:numel(imgt1)),size(imgt1));
                    imgc = reshape(img(numel(imgt1)+(1:numel(imgc1))),size(imgc1));
                    imgs = reshape(img(numel(imgt1)+numel(imgc1)+(1:numel(imgs1))),size(imgs1));
                    mn = 0;
                    mx = 1;
                case 'loghisteq'
                    sw = warning('off','MATLAB:log:logOfZero');
                    imgt = log(imgt-min(imgt(:)));
                    imgc = log(imgc-min(imgc(:)));
                    imgs = log(imgs-min(imgs(:)));
                    warning(sw);
                    imgt(~isfinite(imgt)) = 0;
                    imgc(~isfinite(imgc)) = 0;
                    imgs(~isfinite(imgs)) = 0;
                    % scale log images to a range between 0 and 1
                    imgt1=(imgt-min(imgt(:)))/(max(imgt(:)-min(imgt(:)))+eps);
                    imgc1=(imgc-min(imgc(:)))/(max(imgc(:)-min(imgc(:)))+eps);
                    imgs1=(imgs-min(imgs(:)))/(max(imgs(:)-min(imgs(:)))+eps);
                    img  = histeq([imgt1(:); imgc1(:); imgs1(:)],1024);
                    imgt = reshape(img(1:numel(imgt1)),size(imgt1));
                    imgc = reshape(img(numel(imgt1)+(1:numel(imgc1))),size(imgc1));
                    imgs = reshape(img(numel(imgt1)+numel(imgc1)+(1:numel(imgs1))),size(imgs1));
                    mn = 0;
                    mx = 1;
            end
            % recompute min/max for display
            if strcmp(st.vols{i}.window,'auto')
                mx = -inf; mn = inf;
            end
            if ~isempty(imgt)
                tmp = imgt(isfinite(imgt));
                mx = max([mx max(max(tmp))]);
                mn = min([mn min(min(tmp))]);
            end
            if ~isempty(imgc)
                tmp = imgc(isfinite(imgc));
                mx = max([mx max(max(tmp))]);
                mn = min([mn min(min(tmp))]);
            end
            if ~isempty(imgs)
                tmp = imgs(isfinite(imgs));
                mx = max([mx max(max(tmp))]);
                mn = min([mn min(min(tmp))]);
            end
            if mx==mn, mx=mn+eps; end
            if isfield(st.vols{i},'blobs')
                if ~isfield(st.vols{i}.blobs{1},'colour')
                    % Add blobs for display using the split colourmap
                    scal = 64/(mx-mn);
                    dcoff = -mn*scal;
                    imgt = imgt*scal+dcoff;
                    imgc = imgc*scal+dcoff;
                    imgs = imgs*scal+dcoff;

                    if isfield(st.vols{i}.blobs{1},'max')
                        mx = st.vols{i}.blobs{1}.max;
                    else
                        mx = max([eps maxval(st.vols{i}.blobs{1}.vol)]);
                        st.vols{i}.blobs{1}.max = mx;
                    end
                    if isfield(st.vols{i}.blobs{1},'min')
                        mn = st.vols{i}.blobs{1}.min;
                    else
                        mn = min([0 minval(st.vols{i}.blobs{1}.vol)]);
                        st.vols{i}.blobs{1}.min = mn;
                    end

                    vol  = st.vols{i}.blobs{1}.vol;
                    M    = st.Space\st.vols{i}.premul*st.vols{i}.blobs{1}.mat;
                    tmpt = spm_slice_vol(vol,inv(TM0*M),TD,[0 NaN])';
                    tmpc = spm_slice_vol(vol,inv(CM0*M),CD,[0 NaN])';
                    tmps = spm_slice_vol(vol,inv(SM0*M),SD,[0 NaN])';

                    %tmpt_z = find(tmpt==0);tmpt(tmpt_z) = NaN;
                    %tmpc_z = find(tmpc==0);tmpc(tmpc_z) = NaN;
                    %tmps_z = find(tmps==0);tmps(tmps_z) = NaN;

                    sc   = 64/(mx-mn);
                    off  = 65.51-mn*sc;
                    msk  = find(isfinite(tmpt)); imgt(msk) = off+tmpt(msk)*sc;
                    msk  = find(isfinite(tmpc)); imgc(msk) = off+tmpc(msk)*sc;
                    msk  = find(isfinite(tmps)); imgs(msk) = off+tmps(msk)*sc;


                    cmap = get(st.fig,'Colormap');
                    if size(cmap,1)~=128
                        setcolormap(jet(64));
    %                     spm_figure('Colormap','gray-hot')
                    end
                    figure(st.fig)
                    
%                     redraw_colourbar(i,1,[mn mx],(1:64)'+64);
                elseif isstruct(st.vols{i}.blobs{1}.colour)
                    % Add blobs for display using a defined colourmap

                    % colourmaps
                    gryc = (0:63)'*ones(1,3)/63;

                    % scale grayscale image, not isfinite -> black
                    gimgt = scaletocmap(imgt,mn,mx,gryc,65);
                    gimgc = scaletocmap(imgc,mn,mx,gryc,65);
                    gimgs = scaletocmap(imgs,mn,mx,gryc,65);
                    gryc  = [gryc; 0 0 0];
                    cactp = 0;

                    for j=1:numel(st.vols{i}.blobs)
                        % colourmaps
                        actc = st.vols{i}.blobs{j}.colour.cmap;
                        actp = st.vols{i}.blobs{j}.colour.prop;

                        % get min/max for blob image
                        if isfield(st.vols{i}.blobs{j},'max')
                            cmx = st.vols{i}.blobs{j}.max;
                        else
                            cmx = max([eps maxval(st.vols{i}.blobs{j}.vol)]);
                        end
                        if isfield(st.vols{i}.blobs{j},'min')
                            cmn = st.vols{i}.blobs{j}.min;
                        else
                            cmn = -cmx;
                        end

                        % get blob data
                        vol  = st.vols{i}.blobs{j}.vol;
                        M    = st.Space\st.vols{i}.premul*st.vols{i}.blobs{j}.mat;
                        tmpt = spm_slice_vol(vol,inv(TM0*M),TD,[0 NaN])';
                        tmpc = spm_slice_vol(vol,inv(CM0*M),CD,[0 NaN])';
                        tmps = spm_slice_vol(vol,inv(SM0*M),SD,[0 NaN])';

                        % actimg scaled round 0, black NaNs
                        topc = size(actc,1)+1;
                        tmpt = scaletocmap(tmpt,cmn,cmx,actc,topc);
                        tmpc = scaletocmap(tmpc,cmn,cmx,actc,topc);
                        tmps = scaletocmap(tmps,cmn,cmx,actc,topc);
                        actc = [actc; 0 0 0];

                        % combine gray and blob data to truecolour
                        if isnan(actp)
                            if j==1, imgt = gryc(gimgt(:),:); end
                            imgt(tmpt~=size(actc,1),:) = actc(tmpt(tmpt~=size(actc,1)),:);
                            if j==1, imgc = gryc(gimgc(:),:); end
                            imgc(tmpc~=size(actc,1),:) = actc(tmpc(tmpc~=size(actc,1)),:);
                            if j==1, imgs = gryc(gimgs(:),:); end
                            imgs(tmps~=size(actc,1),:) = actc(tmps(tmps~=size(actc,1)),:);
                        else
                            cactp = cactp + actp;
                            if j==1, imgt = actc(tmpt(:),:)*actp; else imgt = imgt + actc(tmpt(:),:)*actp; end
                            if j==numel(st.vols{i}.blobs), imgt = imgt + gryc(gimgt(:),:)*(1-cactp); end
                            if j==1, imgc = actc(tmpc(:),:)*actp; else imgc = imgc + actc(tmpc(:),:)*actp; end
                            if j==numel(st.vols{i}.blobs), imgc = imgc + gryc(gimgc(:),:)*(1-cactp); end
                            if j==1, imgs = actc(tmps(:),:)*actp; else imgs = imgs + actc(tmps(:),:)*actp; end
                            if j==numel(st.vols{i}.blobs), imgs = imgs + gryc(gimgs(:),:)*(1-cactp); end
                        end
                        if j==numel(st.vols{i}.blobs)
                            imgt = reshape(imgt,[size(gimgt) 3]);
                            imgc = reshape(imgc,[size(gimgc) 3]);
                            imgs = reshape(imgs,[size(gimgs) 3]);
                        end

                         % colourbar
                        csz   = size(st.vols{i}.blobs{j}.colour.cmap);
                        cdata = reshape(st.vols{i}.blobs{j}.colour.cmap, [csz(1) 1 csz(2)]);
                        redraw_colourbar(i,j,[cmn cmx],cdata);
                    end

                else
                    % Add full colour blobs - several sets at once
                    scal  = 1/(mx-mn);
                    dcoff = -mn*scal;

                    wt = zeros(size(imgt));
                    wc = zeros(size(imgc));
                    ws = zeros(size(imgs));

                    imgt  = repmat(imgt*scal+dcoff,[1,1,3]);
                    imgc  = repmat(imgc*scal+dcoff,[1,1,3]);
                    imgs  = repmat(imgs*scal+dcoff,[1,1,3]);

                    cimgt = zeros(size(imgt));
                    cimgc = zeros(size(imgc));
                    cimgs = zeros(size(imgs));

                    colour = zeros(numel(st.vols{i}.blobs),3);
                    for j=1:numel(st.vols{i}.blobs) % get colours of all images first
                        if isfield(st.vols{i}.blobs{j},'colour')
                            colour(j,:) = reshape(st.vols{i}.blobs{j}.colour, [1 3]);
                        else
                            colour(j,:) = [1 0 0];
                        end
                    end
                    %colour = colour/max(sum(colour));

                    for j=1:numel(st.vols{i}.blobs)
                        if isfield(st.vols{i}.blobs{j},'max')
                            mx = st.vols{i}.blobs{j}.max;
                        else
                            mx = max([eps max(st.vols{i}.blobs{j}.vol(:))]);
                            st.vols{i}.blobs{j}.max = mx;
                        end
                        if isfield(st.vols{i}.blobs{j},'min')
                            mn = st.vols{i}.blobs{j}.min;
                        else
                            mn = min([0 min(st.vols{i}.blobs{j}.vol(:))]);
                            st.vols{i}.blobs{j}.min = mn;
                        end

                        vol  = st.vols{i}.blobs{j}.vol;
                        M    = st.Space\st.vols{i}.premul*st.vols{i}.blobs{j}.mat;
                        tmpt = spm_slice_vol(vol,inv(TM0*M),TD,[0 NaN])';
                        tmpc = spm_slice_vol(vol,inv(CM0*M),CD,[0 NaN])';
                        tmps = spm_slice_vol(vol,inv(SM0*M),SD,[0 NaN])';
                        % check min/max of sampled image
                        % against mn/mx as given in st
                        tmpt(tmpt(:)<mn) = mn;
                        tmpc(tmpc(:)<mn) = mn;
                        tmps(tmps(:)<mn) = mn;
                        tmpt(tmpt(:)>mx) = mx;
                        tmpc(tmpc(:)>mx) = mx;
                        tmps(tmps(:)>mx) = mx;
                        tmpt = (tmpt-mn)/(mx-mn);
                        tmpc = (tmpc-mn)/(mx-mn);
                        tmps = (tmps-mn)/(mx-mn);
                        tmpt(~isfinite(tmpt)) = 0;
                        tmpc(~isfinite(tmpc)) = 0;
                        tmps(~isfinite(tmps)) = 0;

                        cimgt = cimgt + cat(3,tmpt*colour(j,1),tmpt*colour(j,2),tmpt*colour(j,3));
                        cimgc = cimgc + cat(3,tmpc*colour(j,1),tmpc*colour(j,2),tmpc*colour(j,3));
                        cimgs = cimgs + cat(3,tmps*colour(j,1),tmps*colour(j,2),tmps*colour(j,3));

                        wt = wt + tmpt;
                        wc = wc + tmpc;
                        ws = ws + tmps;
                        cdata=permute(shiftdim((1/64:1/64:1)'* ...
                            colour(j,:),-1),[2 1 3]);   
                        redraw_colourbar(i,j,[mn mx],cdata);
                    end

                    imgt = repmat(1-wt,[1 1 3]).*imgt+cimgt;
                    imgc = repmat(1-wc,[1 1 3]).*imgc+cimgc;
                    imgs = repmat(1-ws,[1 1 3]).*imgs+cimgs;

                    imgt(imgt<0)=0; imgt(imgt>1)=1;
                    imgc(imgc<0)=0; imgc(imgc>1)=1;
                    imgs(imgs<0)=0; imgs(imgs>1)=1;
                end
            else
                scal = 64/(mx-mn);
                dcoff = -mn*scal;
                imgt = imgt*scal+dcoff;
                imgc = imgc*scal+dcoff;
                imgs = imgs*scal+dcoff;
            end
            set(st.vols{i}.ax{1}.d,'HitTest','off', 'Cdata',imgt);
            set(st.vols{i}.ax{1}.lx,'HitTest','off',...
                'Xdata',[0 TD(1)]+0.5,'Ydata',[1 1]*(cent(2)-bb(1,2)+1));
            set(st.vols{i}.ax{1}.ly,'HitTest','off',...
                'Ydata',[0 TD(2)]+0.5,'Xdata',[1 1]*(cent(1)-bb(1,1)+1));
            set(st.vols{i}.ax{2}.d,'HitTest','off', 'Cdata',imgc);
            set(st.vols{i}.ax{2}.lx,'HitTest','off',...
                'Xdata',[0 CD(1)]+0.5,'Ydata',[1 1]*(cent(3)-bb(1,3)+1));
            set(st.vols{i}.ax{2}.ly,'HitTest','off',...
                'Ydata',[0 CD(2)]+0.5,'Xdata',[1 1]*(cent(1)-bb(1,1)+1));
            set(st.vols{i}.ax{3}.d,'HitTest','off','Cdata',imgs);
            if st.mode ==0
                set(st.vols{i}.ax{3}.lx,'HitTest','off',...
                    'Xdata',[0 SD(1)]+0.5,'Ydata',[1 1]*(cent(2)-bb(1,2)+1));
                set(st.vols{i}.ax{3}.ly,'HitTest','off',...
                    'Ydata',[0 SD(2)]+0.5,'Xdata',[1 1]*(cent(3)-bb(1,3)+1));
            else
                set(st.vols{i}.ax{3}.lx,'HitTest','off',...
                    'Xdata',[0 SD(1)]+0.5,'Ydata',[1 1]*(cent(3)-bb(1,3)+1));
                set(st.vols{i}.ax{3}.ly,'HitTest','off',...
                    'Ydata',[0 SD(2)]+0.5,'Xdata',[1 1]*(bb(2,2)+1-cent(2)));
            end
            if ~isempty(st.plugins) % process any addons
                for k = 1:numel(st.plugins)
                    if isfield(st.vols{i},st.plugins{k})
                        feval(['spm_ov_', st.plugins{k}], ...
                            'redraw', i, TM0, TD, CM0, CD, SM0, SD);
                    end
                end
            end
        end
    end
function redraw_all
redraw(1:max_img);
function reset_st
    global st
    fig     = spm_figure('FindWin','Graphics');
    bb      = []; %[ [-78 78]' [-112 76]' [-50 85]' ];
    stdef   = struct('n', 0, 'vols',{cell(max_img,1)}, 'bb',bb, 'Space',eye(4), ...
                 'centre',[0 0 0], 'callback',';', 'xhairs',1, 'hld',1, ...
                 'fig',fig, 'mode',1, 'plugins',{{}}, 'snap',[]);
    st      = catstruct(stdef, st); 
    xTB = spm('TBs');
    if ~isempty(xTB)
        pluginbase = {spm('Dir') xTB.dir};
    else
        pluginbase = {spm('Dir')};
    end
    for k = 1:numel(pluginbase)
        pluginpath = fullfile(pluginbase{k},'spm_orthviews');
        pluginpath = fileparts(mfilename); 
        if isdir(pluginpath)
            pluginfiles = dir(fullfile(pluginpath,'spm_ov_*.m'));
            if ~isempty(pluginfiles)
                if ~isdeployed, addpath(pluginpath); end
                for l = 1:numel(pluginfiles)
                    pluginname = spm_file(pluginfiles(l).name,'basename');
                    st.plugins{end+1} = strrep(pluginname, 'spm_ov_','');
                end
            end
        end
    end
function c_menu(varargin)
global st

switch lower(varargin{1})
    case 'image_info'
        if nargin <3
            current_handle = get_current_handle;
        else
            current_handle = varargin{3};
        end
        if isfield(st.vols{current_handle},'fname')
            [p,n,e,v] = spm_fileparts(st.vols{current_handle}.fname);
            if isfield(st.vols{current_handle},'n')
                v = sprintf(',%d',st.vols{current_handle}.n);
            end
            set(varargin{2}, 'Label',[n e v]);
        end
        delete(get(varargin{2},'children'));
        if exist('p','var')
            item1 = uimenu(varargin{2}, 'Label', p);
        end
        if isfield(st.vols{current_handle},'descrip')
            item2 = uimenu(varargin{2}, 'Label',...
                st.vols{current_handle}.descrip);
        end
        dt = st.vols{current_handle}.dt(1);
        item3 = uimenu(varargin{2}, 'Label', sprintf('Data type: %s', spm_type(dt)));
        str   = 'Intensity: varied';
        if size(st.vols{current_handle}.pinfo,2) == 1
            if st.vols{current_handle}.pinfo(2)
                str = sprintf('Intensity: Y = %g X + %g',...
                    st.vols{current_handle}.pinfo(1:2)');
            else
                str = sprintf('Intensity: Y = %g X', st.vols{current_handle}.pinfo(1)');
            end
        end
        item4  = uimenu(varargin{2}, 'Label',str);
        item5  = uimenu(varargin{2}, 'Label', 'Image dimensions', 'Separator','on');
        item51 = uimenu(varargin{2}, 'Label',...
            sprintf('%dx%dx%d', st.vols{current_handle}.dim(1:3)));
        
        prms   = spm_imatrix(st.vols{current_handle}.mat);
        item6  = uimenu(varargin{2}, 'Label', 'Voxel size', 'Separator','on');
        item61 = uimenu(varargin{2}, 'Label', sprintf('%.2f %.2f %.2f', prms(7:9)));
        
        O      = st.vols{current_handle}.mat\[0 0 0 1]'; O=O(1:3)';
        item7  = uimenu(varargin{2}, 'Label', 'Origin', 'Separator','on');
        item71 = uimenu(varargin{2}, 'Label', sprintf('%.2f %.2f %.2f', O));
        
        R      = spm_matrix([0 0 0 prms(4:6)]);
        item8  = uimenu(varargin{2}, 'Label', 'Rotations', 'Separator','on');
        item81 = uimenu(varargin{2}, 'Label', sprintf('%.2f %.2f %.2f', R(1,1:3)));
        item82 = uimenu(varargin{2}, 'Label', sprintf('%.2f %.2f %.2f', R(2,1:3)));
        item83 = uimenu(varargin{2}, 'Label', sprintf('%.2f %.2f %.2f', R(3,1:3)));
        item9  = uimenu(varargin{2},...
            'Label','Specify other image...',...
            'Callback','bspm_orthviews(''context_menu'',''swap_img'');',...
            'Separator','on');
        
    case 'repos_mm'
        oldpos_mm = bspm_orthviews('pos');
        newpos_mm = spm_input('New Position (mm)','+1','r',sprintf('%.2f %.2f %.2f',oldpos_mm),3);
        bspm_orthviews('reposition',newpos_mm);
        
    case 'repos_vx'
        current_handle = get_current_handle;
        oldpos_vx = bspm_orthviews('pos', current_handle);
        newpos_vx = spm_input('New Position (voxels)','+1','r',sprintf('%.2f %.2f %.2f',oldpos_vx),3);
        newpos_mm = st.vols{current_handle}.mat*[newpos_vx;1];
        bspm_orthviews('reposition',newpos_mm(1:3));
        
    case 'zoom'
        zoom_all(varargin{2:end});
        bbox;
        redraw_all;
        
    case 'xhair'
        bspm_orthviews('Xhairs',varargin{2:end});
        cm_handles = get_cm_handles;
        for i = 1:numel(cm_handles)
            z_handle = findobj(cm_handles(i),'label','Crosshairs');
            if st.xhairs
                set(z_handle,'Checked','on');
            else
                set(z_handle,'Checked','off');
            end
        end
        
    case 'orientation'
        cm_handles = get_cm_handles;
        for i = 1:numel(cm_handles)
            z_handle = get(findobj(cm_handles(i),'label','Orientation'),'Children');
            set(z_handle,'Checked','off');
        end
        if varargin{2} == 3
            bspm_orthviews('Space');
            for i = 1:numel(cm_handles),
                z_handle = findobj(cm_handles(i),'label','World space');
                set(z_handle,'Checked','on');
            end
        elseif varargin{2} == 2,
            bspm_orthviews('Space',1);
            for i = 1:numel(cm_handles)
                z_handle = findobj(cm_handles(i),'label',...
                    'Voxel space (1st image)');
                set(z_handle,'Checked','on');
            end
        else
            bspm_orthviews('Space',get_current_handle);
            z_handle = findobj(st.vols{get_current_handle}.ax{1}.cm, ...
                'label','Voxel space (this image)');
            set(z_handle,'Checked','on');
            return;
        end
        
    case 'snap'
        cm_handles = get_cm_handles;
        for i = 1:numel(cm_handles)
            z_handle = get(findobj(cm_handles(i),'label','Snap to Grid'),'Children');
            set(z_handle,'Checked','off');
        end
        if varargin{2} == 3
            st.snap = [];
        elseif varargin{2} == 2
            st.snap = 1;
        else
            st.snap = get_current_handle;
            z_handle = get(findobj(st.vols{get_current_handle}.ax{1}.cm,'label','Snap to Grid'),'Children');
            set(z_handle(1),'Checked','on');
            return;
        end
        for i = 1:numel(cm_handles)
            z_handle = get(findobj(cm_handles(i),'label','Snap to Grid'),'Children');
            set(z_handle(varargin{2}),'Checked','on');
        end
        
    case 'interpolation'
        tmp        = [-4 1 0];
        st.hld     = tmp(varargin{2});
        cm_handles = get_cm_handles;
        for i = 1:numel(cm_handles)
            z_handle = get(findobj(cm_handles(i),'label','Interpolation'),'Children');
            set(z_handle,'Checked','off');
            set(z_handle(varargin{2}),'Checked','on');
        end
        redraw_all;
        
    case 'window'
        current_handle = get_current_handle;
        if varargin{2} == 2
            bspm_orthviews('window',current_handle);
        elseif varargin{2} == 3
            pc = spm_input('Percentiles', '+1', 'w', '3 97', 2, 100);
            wn = spm_summarise(st.vols{current_handle}, 'all', ...
                @(X) spm_percentile(X, pc));
            bspm_orthviews('window',current_handle,wn);
        else
            if isnumeric(st.vols{current_handle}.window)
                defstr = sprintf('%.2f %.2f', st.vols{current_handle}.window);
            else
                defstr = '';
            end
            [w,yp] = spm_input('Range','+1','e',defstr,[1 inf]);
            while numel(w) < 1 || numel(w) > 2
                uiwait(warndlg('Window must be one or two numbers','Wrong input size','modal'));
                [w,yp] = spm_input('Range',yp,'e',defstr,[1 inf]);
            end
            if numel(w) == 1
                w(2) = w(1)+eps;
            end
            bspm_orthviews('window',current_handle,w);
        end
        
    case 'window_gl'
        if varargin{2} == 2
            for i = 1:numel(get_cm_handles)
                st.vols{i}.window = 'auto';
            end
        else
            current_handle = get_current_handle;
            if isnumeric(st.vols{current_handle}.window)
                defstr = sprintf('%d %d', st.vols{current_handle}.window);
            else
                defstr = '';
            end
            [w,yp] = spm_input('Range','+1','e',defstr,[1 inf]);
            while numel(w) < 1 || numel(w) > 2
                uiwait(warndlg('Window must be one or two numbers','Wrong input size','modal'));
                [w,yp] = spm_input('Range',yp,'e',defstr,[1 inf]);
            end
            if numel(w) == 1
                w(2) = w(1)+eps;
            end
            for i = 1:numel(get_cm_handles)
                st.vols{i}.window = w;
            end
        end
        redraw_all;
        
    case 'mapping'
        checked = strcmp(varargin{2}, ...
            {'linear', 'histeq', 'loghisteq', 'quadhisteq'});
        checked = checked(end:-1:1); % Handles are stored in inverse order
        current_handle = get_current_handle;
        cm_handles = get_cm_handles;
        st.vols{current_handle}.mapping = varargin{2};
        z_handle = get(findobj(cm_handles(current_handle), ...
            'label','Intensity mapping'),'Children');
        for k = 1:numel(z_handle)
            c_handle = get(z_handle(k), 'Children');
            set(c_handle, 'checked', 'off');
            set(c_handle(checked), 'checked', 'on');
        end
        redraw_all;
        
    case 'mapping_gl'
        checked = strcmp(varargin{2}, ...
            {'linear', 'histeq', 'loghisteq', 'quadhisteq'});
        checked = checked(end:-1:1); % Handles are stored in inverse order
        cm_handles = get_cm_handles;
        for k = valid_handles
            st.vols{k}.mapping = varargin{2};
            z_handle = get(findobj(cm_handles(k), ...
                'label','Intensity mapping'),'Children');
            for l = 1:numel(z_handle)
                c_handle = get(z_handle(l), 'Children');
                set(c_handle, 'checked', 'off');
                set(c_handle(checked), 'checked', 'on');
            end
        end
        redraw_all;
        
    case 'swap_img'
        current_handle = get_current_handle;
        newimg = spm_select(1,'image','select new image');
        if ~isempty(newimg)
            new_info = spm_vol(newimg);
            fn = fieldnames(new_info);
            for k=1:numel(fn)
                st.vols{current_handle}.(fn{k}) = new_info.(fn{k});
            end
            bspm_orthviews('context_menu','image_info',get(gcbo, 'parent'));
            redraw_all;
        end
        
    case 'add_blobs'
        % Add blobs to the image - in split colortable
        cm_handles = valid_handles;
        if varargin{2} == 2, cm_handles = get_current_handle; end
        spm_input('!DeleteInputObj');
        [SPM,xSPM] = spm_getSPM;
        if ~isempty(SPM)
            for i = 1:numel(cm_handles)
                addblobs(cm_handles(i),xSPM.XYZ,xSPM.Z,xSPM.M);
                % Add options for removing blobs
                c_handle = findobj(findobj(st.vols{cm_handles(i)}.ax{1}.cm,'label','Overlay'),'Label','Remove blobs');
                set(c_handle,'Visible','on');
                delete(get(c_handle,'Children'));
                item7_3_1 = uimenu(c_handle,'Label','local','Callback','bspm_orthviews(''context_menu'',''remove_blobs'',2);');
                if varargin{2} == 1,
                    item7_3_2 = uimenu(c_handle,'Label','global','Callback','bspm_orthviews(''context_menu'',''remove_blobs'',1);');
                end
                % Add options for setting maxima for blobs
                c_handle = findobj(findobj(st.vols{cm_handles(i)}.ax{1}.cm,'label','Overlay'),'Label','Set blobs max');
                set(c_handle,'Visible','on');
                delete(get(c_handle,'Children'));
                uimenu(c_handle,'Label','local','Callback','bspm_orthviews(''context_menu'',''setblobsmax'',2);');
                if varargin{2} == 1
                    uimenu(c_handle,'Label','global','Callback','bspm_orthviews(''context_menu'',''setblobsmax'',1);');
                end
            end
            redraw_all;
        end
        
    case 'remove_blobs'
        cm_handles = valid_handles;
        if varargin{2} == 2, cm_handles = get_current_handle; end
        for i = 1:numel(cm_handles)
            rmblobs(cm_handles(i));
            % Remove options for removing blobs
            c_handle = findobj(findobj(st.vols{cm_handles(i)}.ax{1}.cm,'label','Overlay'),'Label','Remove blobs');
            delete(get(c_handle,'Children'));
            set(c_handle,'Visible','off');
            % Remove options for setting maxima for blobs
            c_handle = findobj(findobj(st.vols{cm_handles(i)}.ax{1}.cm,'label','Overlay'),'Label','Set blobs max');
            set(c_handle,'Visible','off');
        end
        redraw_all;
        
    case 'add_image'
        % Add blobs to the image - in split colortable
        cm_handles = valid_handles;
        if varargin{2} == 2, cm_handles = get_current_handle; end
        spm_input('!DeleteInputObj');
        fname = spm_select(1,'image','select image');
        if ~isempty(fname)
            for i = 1:numel(cm_handles)
                addimage(cm_handles(i),fname);
                % Add options for removing blobs
                c_handle = findobj(findobj(st.vols{cm_handles(i)}.ax{1}.cm,'label','Overlay'),'Label','Remove blobs');
                set(c_handle,'Visible','on');
                delete(get(c_handle,'Children'));
                item7_3_1 = uimenu(c_handle,'Label','local','Callback','bspm_orthviews(''context_menu'',''remove_blobs'',2);');
                if varargin{2} == 1
                    item7_3_2 = uimenu(c_handle,'Label','global','Callback','bspm_orthviews(''context_menu'',''remove_blobs'',1);');
                end
                % Add options for setting maxima for blobs
                c_handle = findobj(findobj(st.vols{cm_handles(i)}.ax{1}.cm,'label','Overlay'),'Label','Set blobs max');
                set(c_handle,'Visible','on');
                delete(get(c_handle,'Children'));
                uimenu(c_handle,'Label','local','Callback','bspm_orthviews(''context_menu'',''setblobsmax'',2);');
                if varargin{2} == 1
                    uimenu(c_handle,'Label','global','Callback','bspm_orthviews(''context_menu'',''setblobsmax'',1);');
                end
            end
            redraw_all;
        end
        
    case 'add_c_blobs'
        % Add blobs to the image - in full colour
        cm_handles = valid_handles;
        if varargin{2} == 2, cm_handles = get_current_handle; end
        spm_input('!DeleteInputObj');
        [SPM,xSPM] = spm_getSPM;
        if ~isempty(SPM)
            c = spm_input('Colour','+1','m',...
                'Red blobs|Yellow blobs|Green blobs|Cyan blobs|Blue blobs|Magenta blobs',[1 2 3 4 5 6],1);
            colours = [1 0 0;1 1 0;0 1 0;0 1 1;0 0 1;1 0 1];
            c_names = {'red';'yellow';'green';'cyan';'blue';'magenta'};
            hlabel = sprintf('%s (%s)',xSPM.title,c_names{c});
            for i = 1:numel(cm_handles)
                addcolouredblobs(cm_handles(i),xSPM.XYZ,xSPM.Z,xSPM.M,colours(c,:),xSPM.title);
                addcolourbar(cm_handles(i),numel(st.vols{cm_handles(i)}.blobs));
                c_handle    = findobj(findobj(st.vols{cm_handles(i)}.ax{1}.cm,'label','Overlay'),'Label','Remove coloured blobs');
                ch_c_handle = get(c_handle,'Children');
                set(c_handle,'Visible','on');
                %set(ch_c_handle,'Visible',on');
                item7_4_1   = uimenu(ch_c_handle(2),'Label',hlabel,'ForegroundColor',colours(c,:),...
                    'Callback','c = get(gcbo,''UserData'');bspm_orthviews(''context_menu'',''remove_c_blobs'',2,c);',...
                    'UserData',c);
                if varargin{2} == 1
                    item7_4_2 = uimenu(ch_c_handle(1),'Label',hlabel,'ForegroundColor',colours(c,:),...
                        'Callback','c = get(gcbo,''UserData'');bspm_orthviews(''context_menu'',''remove_c_blobs'',1,c);',...
                        'UserData',c);
                end
            end
            redraw_all;
        end
        
    case 'remove_c_blobs'
        cm_handles = valid_handles;
        if varargin{2} == 2, cm_handles = get_current_handle; end
        colours = [1 0 0;1 1 0;0 1 0;0 1 1;0 0 1;1 0 1];
        for i = 1:numel(cm_handles)
            if isfield(st.vols{cm_handles(i)},'blobs')
                for j = 1:numel(st.vols{cm_handles(i)}.blobs)
                    if all(st.vols{cm_handles(i)}.blobs{j}.colour == colours(varargin{3},:));
                        if isfield(st.vols{cm_handles(i)}.blobs{j},'cbar')
                            delete(st.vols{cm_handles(i)}.blobs{j}.cbar);
                        end
                        st.vols{cm_handles(i)}.blobs(j) = [];
                        break;
                    end
                end
                rm_c_menu = findobj(st.vols{cm_handles(i)}.ax{1}.cm,'Label','Remove coloured blobs');
                delete(gcbo);
                if isempty(st.vols{cm_handles(i)}.blobs)
                    st.vols{cm_handles(i)} = rmfield(st.vols{cm_handles(i)},'blobs');
                    set(rm_c_menu, 'Visible', 'off');
                end
            end
        end
        redraw_all;
        
    case 'add_c_image'
        % Add truecolored image
        cm_handles = valid_handles;
        if varargin{2} == 2, cm_handles = get_current_handle; end
        spm_input('!DeleteInputObj');
        fname = spm_select([1 Inf],'image','select image(s)');
        for k = 1:size(fname,1)
            c = spm_input(sprintf('Image %d: Colour',k),'+1','m',...
                'Red blobs|Yellow blobs|Green blobs|Cyan blobs|Blue blobs|Magenta blobs',[1 2 3 4 5 6],1);
            colours = [1 0 0;1 1 0;0 1 0;0 1 1;0 0 1;1 0 1];
            c_names = {'red';'yellow';'green';'cyan';'blue';'magenta'};
            hlabel = sprintf('%s (%s)',fname(k,:),c_names{c});
            for i = 1:numel(cm_handles)
                addcolouredimage(cm_handles(i),fname(k,:),colours(c,:));
                addcolourbar(cm_handles(i),numel(st.vols{cm_handles(i)}.blobs));
                c_handle    = findobj(findobj(st.vols{cm_handles(i)}.ax{1}.cm,'label','Overlay'),'Label','Remove coloured blobs');
                ch_c_handle = get(c_handle,'Children');
                set(c_handle,'Visible','on');
                %set(ch_c_handle,'Visible',on');
                item7_4_1 = uimenu(ch_c_handle(2),'Label',hlabel,'ForegroundColor',colours(c,:),...
                    'Callback','c = get(gcbo,''UserData'');bspm_orthviews(''context_menu'',''remove_c_blobs'',2,c);','UserData',c);
                if varargin{2} == 1
                    item7_4_2 = uimenu(ch_c_handle(1),'Label',hlabel,'ForegroundColor',colours(c,:),...
                        'Callback','c = get(gcbo,''UserData'');bspm_orthviews(''context_menu'',''remove_c_blobs'',1,c);',...
                        'UserData',c);
                end
            end
            redraw_all;
        end
        
    case 'setblobsmax'
        if varargin{2} == 1
            % global
            cm_handles = valid_handles;
            mx = -inf;
            for i = 1:numel(cm_handles)
                if ~isfield(st.vols{cm_handles(i)}, 'blobs'), continue, end
                for j = 1:numel(st.vols{cm_handles(i)}.blobs)
                    mx = max(mx, st.vols{cm_handles(i)}.blobs{j}.max);
                end
            end
            mx = spm_input('Maximum value', '+1', 'r', mx, 1);
            for i = 1:numel(cm_handles)
                if ~isfield(st.vols{cm_handles(i)}, 'blobs'), continue, end
                for j = 1:numel(st.vols{cm_handles(i)}.blobs)
                    st.vols{cm_handles(i)}.blobs{j}.max = mx;
                end
            end
        else
            % local (should handle coloured blobs, but not implemented yet)
            cm_handle = get_current_handle;
            colours = [1 0 0;1 1 0;0 1 0;0 1 1;0 0 1;1 0 1];
            if ~isfield(st.vols{cm_handle}, 'blobs'), return, end
            for j = 1:numel(st.vols{cm_handle}.blobs)
                if nargin < 4 || ...
                        all(st.vols{cm_handle}.blobs{j}.colour == colours(varargin{3},:))
                    mx = st.vols{cm_handle}.blobs{j}.max;
                    mx = spm_input('Maximum value', '+1', 'r', mx, 1);
                    st.vols{cm_handle}.blobs{j}.max = mx;
                end
            end
        end
        redraw_all;
end
function zoom_all(zoom,res)
cm_handles = get_cm_handles;
zoom_op(zoom,res);
for i = 1:numel(cm_handles)
    z_handle = get(findobj(cm_handles(i),'label','Zoom'),'Children');
    set(z_handle,'Checked','off');
    if isinf(zoom)
        set(findobj(z_handle,'Label','Full Volume'),'Checked','on');
    elseif zoom > 0
        set(findobj(z_handle,'Label',sprintf('%dx%d mm', 2*zoom, 2*zoom)),'Checked','on');
    end % leave all unchecked if either bounding box option was chosen
end
function addcolourbar(vh,bh)
    global st
    axpos = zeros(3, 4);
    for a = 1:3, axpos(a,:) = get(st.vols{vh}.ax{a}.ax, 'position'); end
    cbpos = axpos(3,:); 
    cbpos(4) = cbpos(4)*.9; 
    cbpos(2) = cbpos(2) + (axpos(3,4)-cbpos(4))/2; 
    cbpos(1) = sum(cbpos([1 3])); 
    cbpos(3) = (1 - cbpos(1))/2; 
    cbpos(3) = min([cbpos(3) .30]); 
    cbpos(1) = cbpos(1) + (cbpos(3)/4); 
    yl      = [st.vols{vh}.blobs{bh}.min st.vols{vh}.blobs{bh}.max];
    yltick  = [ceil(min(yl)) floor(max(yl))];
    yltick(abs(yl) < 1) = yl(abs(yl) < 1); 
    if strcmpi(st.direct, '+/-') & min(yltick)<0
        yltick = [yltick(1) 0 yltick(2)]; 
    end
    ylab = cellnum2str(num2cell(yltick), 2); 
    st.vols{vh}.blobs{bh}.cbar = axes('Parent', st.figax, 'ycolor', st.color.fg, ...
        'position', cbpos, 'YAxisLocation', 'right', 'fontsize', st.fonts.sz3, ...
        'ytick', yltick, 'tag', 'colorbar', ...
        'Box','on', 'YDir','normal', 'XTickLabel',[], 'XTick',[]); 
    set(st.vols{vh}.blobs{bh}.cbar, 'YTickLabel', ylab, 'fontweight', 'bold', 'fontsize', st.fonts.sz3, 'fontname', st.fonts.name); 
    if isfield(st.vols{vh}.blobs{bh},'name')
        ylabel(st.vols{vh}.blobs{bh}.name,'parent',st.vols{vh}.blobs{bh}.cbar);
    end    
function redraw_colourbar(vh,bh,interval,cdata)
    global st
    setunits('norm');
    axpos = zeros(3, 4);
    for a = 1:3
        axpos(a,:) = get(st.vols{vh}.ax{a}.ax, 'position');
    end
    cbpos = axpos(3,:); 
    cbpos(4) = cbpos(4)*.9; 
    cbpos(2) = cbpos(2) + (axpos(3,4)-cbpos(4))/2; 
    cbpos(1) = sum(cbpos([1 3])); 
    cbpos(3) = (1 - cbpos(1))/2; 
    cbpos(1) = cbpos(1) + (cbpos(3)/4);
    % only scale cdata if we have out-of-range truecolour values
    if ndims(cdata)==3 && max(cdata(:))>1
        cdata=cdata./max(cdata(:));
    end
    yl = interval;
    yltick  = [ceil(min(yl)) floor(max(yl))];
    yltick(abs(yl) < 1) = yl(abs(yl) < 1); 
    if strcmpi(st.direct, '+/-') & min(yltick)<0
        yltick = [yltick(1) 0 yltick(2)]; 
    end
    ylab = cellnum2str(num2cell(yltick), 2); 
    h = st.vols{vh}.blobs{bh}.cbar; 
    image([0 1],interval,cdata,'Parent',h);
    set(h, 'ycolor', st.color.fg, ...
        'position', cbpos, 'YAxisLocation', 'right', ...
        'ytick', yltick, ...
        'Box','on', 'YDir','normal', 'XTickLabel',[], 'XTick',[]); 
    set(h, 'YTickLabel', ylab, 'fontweight', 'bold', 'fontsize', st.fonts.sz3, 'fontname', st.fonts.name); 
    if isfield(st.vols{vh}.blobs{bh},'name')
        ylabel(st.vols{vh}.blobs{bh}.name,'parent',st.vols{vh}.blobs{bh}.cbar);
    end
function repos_start(varargin)
    if ~strcmpi(get(gcbf,'SelectionType'),'alt')
        set(gcbf, 'Pointer', 'crosshair'); 
        xylim = [get(gca, 'xlim'); get(gca, 'ylim')]; 
        set(gcbf, 'windowbuttonmotionfcn', {@repos_move, xylim}, ...
                  'windowbuttonupfcn', @repos_end);
        bspm_orthviews('reposition');
    end
function repos_move(varargin)
    p = get(gca, 'currentpoint');
    if any([p(1,1:2)' < varargin{3}(:,1); p(1,1:2)' > varargin{3}(:,2)])
        drawnow; 
        repos_end; 
    end
    bspm_orthviews('reposition');
function repos_end(varargin)
    set(gcbf, 'Pointer', 'arrow'); 
    set(gcbf, 'windowbuttonmotionfcn','', 'windowbuttonupfcn','');
    
% | BSPM_XYZREG (MODIFIED FROM SPM8 SPM_XYXREG)
% =========================================================================
function varargout = bspm_XYZreg(varargin)
% Registry for GUI XYZ locations, and point list utility functions
%
%                           ----------------
%
% PointList & voxel centre utilities...
%
% FORMAT [xyz,d] = bspm_XYZreg('RoundCoords',xyz,M,D)
% FORMAT [xyz,d] = bspm_XYZreg('RoundCoords',xyz,V)
% Rounds specified xyz location to nearest voxel centre
% xyz - (Input) 3-vector of X, Y & Z locations, in "real" co-ordinates
% M   - 4x4 transformation matrix relating voxel to "real" co-ordinates
% D   - 3 vector of image X, Y & Z dimensions (DIM)
% V   - 9-vector of image and voxel sizes, and origin [DIM,VOX,ORIGIN]'
%       M derived as [ [diag(V(4:6)), -(V(7:9).*V(4:6))]; [zeros(1,3) ,1]]
%       DIM    - D
%       VOX    - Voxel dimensions in units of "real" co-ordinates
%       ORIGIN - Origin of "real" co-ordinates in voxel co-ordinates
% xyz - (Output) co-ordinates of nearest voxel centre in "real" co-ordinates
% d   - Euclidean distance between requested xyz & nearest voxel centre
%
% FORMAT i = bspm_XYZreg('FindXYZ',xyz,XYZ)
% finds position of specified voxel in XYZ pointlist
% xyz - 3-vector of co-ordinates
% XYZ - Pointlist: 3xn matrix of co-ordinates
% i   - Column(s) of XYZ equal to xyz
%
% FORMAT [xyz,i,d] = bspm_XYZreg('NearestXYZ',xyz,XYZ)
% find nearest voxel in pointlist to specified location
% xyz - (Input) 3-vector of co-ordinates
% XYZ - Pointlist: 3xn matrix of co-ordinates
% xyz - (Output) co-ordinates of nearest voxel in XYZ pointlist
%       (ties are broken in favour of the first location in the pointlist)
% i   - Column of XYZ containing co-ordinates of nearest pointlist location
% d   - Euclidean distance between requested xyz & nearest pointlist location
%
% FORMAT d = bspm_XYZreg('Edist',xyz,XYZ)
% Euclidean distances between co-ordinates xyz & points in XYZ pointlist
% xyz - 3-vector of co-ordinates
% XYZ - Pointlist: 3xn matrix of co-ordinates
% d   - n row-vector of Euclidean distances between xyz & points of XYZ
%
%                           ----------------
% Registry functions
%
% FORMAT [hReg,xyz] = bspm_XYZreg('InitReg',hReg,M,D,xyz)
% Initialise registry in graphics object
% hReg - Handle of HandleGraphics object to build registry in. Object must
%        be un'Tag'ged and have empty 'UserData'
% M    - 4x4 transformation matrix relating voxel to "real" co-ordinates, used
%        and stored for checking validity of co-ordinates
% D    - 3 vector of image X, Y & Z dimensions (DIM), used
%        and stored for checking validity of co-ordinates
% xyz  - (Input) Initial co-ordinates [Default [0;0;0]]
%        These are rounded to the nearest voxel centre
% hReg - (Output) confirmation of registry handle
% xyz  - (Output) Current registry co-ordinates, after rounding
%
% FORMAT bspm_XYZreg('UnInitReg',hReg)
% Clear registry information from graphics object
% hReg - Handle of 'hReg' 'Tag'ged registry HandleGraphics object.
%        Object's 'Tag' & 'UserData' are cleared
%
% FORMAT xyz = bspm_XYZreg('GetCoords',hReg)
% Get current registry co-ordinates
% hReg - Handle of 'hReg' 'Tag'ged registry HandleGraphics object
% 
% FORMAT [xyz,d] = bspm_XYZreg('SetCoords',xyz,hReg,hC,Reg)
% Set co-ordinates in registry & update registered HGobjects/functions
% xyz  - (Input) desired co-ordinates
% hReg - Handle of 'hReg' 'Tag'ged registry HandleGraphics object
%        If hReg doesn't contain a registry, a warning is printed.
% hC   - Handle of caller object (to prevent circularities) [Default 0]
%        If caller object passes invalid registry handle, then bspm_XYZreg
%        attempts to blank the 'hReg' fiend of hC's 'UserData', printing
%        a warning notification.
% Reg  - Alternative nx2 cell array Registry of handles / functions
%        If specified, overrides use of registry held in hReg
%        [Default getfield(get(hReg,'UserData'),'Reg')]
% xyz  - (Output) Desired co-ordinates are rounded to nearest voxel if hC
%        is not specified, or is zero. Otherwise, caller is assummed to
%        have checked verity of desired xyz co-ordinates. Output xyz returns
%        co-ordinates actually set.
% d    - Euclidean distance between desired and set co-ordinates.
%
% FORMAT nReg = bspm_XYZreg('XReg',hReg,{h,Fcn}pairs)
% Cross registration object/function pairs with the registry, push xyz co-ords
% hReg - Handle of 'hReg' 'Tag'ged registry HandleGraphics object
% h    - Handle of HandleGraphics object to be registered
%        The 'UserData' of h must be a structure with an 'Reg' field, which
%        is set to hReg, the handle of the registry (back registration)
% Fcn  - Handling function for HandleGraphics object h
%        This function *must* accept XYZ updates via the call:
%                feval(Fcn,'SetCoords',xyz,h,hReg)
%        and should *not* call back the registry with the update!
%        {h,Fcn} are appended to the registry (forward registration)
% nReg - New registry cell array: Handles are checked for validity before
%        entry. Invalid handles are omitted, generating a warning.
%
% FORMAT nReg = bspm_XYZreg('Add2Reg',hReg,{h,Fcn}pairs)
% Add object/function pairs for XYZ updates to registry (forward registration)
% hReg - Handle of 'hReg' 'Tag'ged registry HandleGraphics object
% h    - Handle of HandleGraphics object to be registered
% Fcn  - Handling function for HandleGraphics object h
%        This function *must* accept XYZ updates via the call:
%                feval(Fcn,'SetCoords',xyz,h,hReg)
%        and should *not* call back the registry with the update!
%        {h,Fcn} are appended to the registry (forward registration)
% nReg - New registry cell array: Handles are checked for validity before
%        entry. Invalid handles are omitted, generating a warning.
%
% FORMAT bspm_XYZreg('SetReg',h,hReg)
% Set registry field of object's UserData (back registration)
% h    - Handle of HandleGraphics object to be registered
%        The 'UserData' of h must be a structure with an 'Reg' field, which
%        is set to hReg, the handle of the registry (back registration)
% hReg - Handle of 'hReg' 'Tag'ged registry HandleGraphics object
%
% FORMAT nReg = bspm_XYZreg('unXReg',hReg,hD1,hD2,hD3,...)
% Un-cross registration of HandleGraphics object hD
% hReg - Handle of 'hReg' 'Tag'ged registry HandleGraphics object
% hD?  - Handles of HandleGraphics object to be unregistered
%        The 'UserData' of hD must be a structure with a 'Reg' field, which
%        is set to empty (back un-registration)
% nReg - New registry cell array: Registry entries with handle entry hD are 
%        removed from the registry (forward un-registration)
%        Handles not in the registry generate a warning
%
% FORMAT nReg = bspm_XYZreg('Del2Reg',hReg,hD)
% Delete HandleGraphics object hD from registry (forward un-registration)
% hReg - Handle of 'hReg' 'Tag'ged registry HandleGraphics object
% hD?  - Handles of HandleGraphics object to be unregistered
% nReg - New registry cell array: Registry entries with handle entry hD are 
%        removed from the registry. Handles not in registry generate a warning
%
% FORMAT bspm_XYZreg('UnSetReg',h)
% Unset registry field of object's UserData (back un-registration)
% h - Handle of HandleGraphics object to be unregistered
%     The 'UserData' of hD must be a structure with a 'Reg' field, which
%     is set to empty (back un-registration)
%
% FORMAT bspm_XYZreg('CleanReg',hReg)
% Clean invalid handles from registry
% hReg - Handle of 'hReg' 'Tag'ged registry HandleGraphics object
%
% FORMAT Reg = bspm_XYZreg('VReg',Reg,Warn)
% Prune invalid handles from Registry cell array
% Reg  - (Input) nx2 cell array of {handle,function} pairs
% Warn - If specified, print warning if find invalid handles
% Reg  - (Output) mx2 cell array of valid {handle,function} pairs
%
% FORMAT hReg = bspm_XYZreg('FindReg',h)
% Find/check registry object
% h    - handle of Registry, or figure containing Registry (default gcf)
%        If ischar(h), then uses spm_figure('FindWin',h) to locate named figures
% hReg - handle of confirmed registry object
%        Errors if h is not a registry or a figure containing a unique registry
%        Registry object is identified by 'hReg' 'Tag'
%_______________________________________________________________________
%
% bspm_XYZreg provides a framework for modular inter-GUI communication of
% XYZ co-orginates, and various utility functions for pointlist handling
% and rounding in voxel co-ordinates.
%
%-----------------------------------------------------------------------
%                                                           THE REGISTRY
%
% The concept of the registry is of a central entity which "knows"
% about other GUI objects holding XYZ co-ordinates, and keeps them all
% in sync. Changes to the registry's XYZ co-ordinates are passed on to
% registered functions by the registry (forward registration).
% Individual objects which can change the XYZ co-ordinates should
% therefore update the registry with the new co-ordinates (back
% registration), so that the registry can tell all registered objects
% about the new location, and a framework is provided for this.
%
% The registry is held as the 'UserData of a HandleGraphics object,
% whose handle therefore identifies the registry. The registry object
% is 'Tag'ged 'hReg' for identification (though this 'Tag' is not used
% for locating the registry, so multiple registry incarnations are
% possible). The registry object's 'UserData' is a structure containing
% the current XYZ co-ordinates, the voxel-to-co-ordinates matrix M, the
% image dimensions D, and the Registry itself. The registry is a nx2
% cell array containing n handle/function pairs.
%
% The model is that all GUI objects requiring linking to a common XYZ
% location via the registry each be identified by a HandleGraphics
% handle. This handle can be the handle of the particular instantiation
% of the GUI control itself (as is the case with the MIP-GUI of
% spm_mip_ui where the axis handle is used to identify the MIP to use);
% the handle of another HandleGraphics object associated with the GUI
% control (as is the case with the XYZ editable widgets of
% spm_results_ui where the handle of the bounding frame uicontrol is
% used); or may be 0, the handle of the root object, which allows non
% GUI functions (such as a function that just prints information) to be
% added to the registry. The registry itself thus conforms to this
% model. Each object has an associated "handling function" (so this
% function is the registry's handling function). The registry itself
% consists of object-handle/handling-function pairs.
%
% If an object and it's handling function are entered in the registry,
% then the object is said to be "forward registered", because the
% registry will now forward all location updates to that object, via
% it's handling function. The assummed syntax is:
% feval(Fcn,'SetCoords',xyz,h,hReg), where Fcn is the handling function
% for the GUI control identified by handle h, xyz are the new
% co-ordinates, and hReg is the handle of the registry.
%
% An optional extension is "back registration", whereby the GUI
% controls inform the registry of the new location when they are
% updated. All that's required is that the objects call the registry's
% 'SetCoords' function: bspm_XYZreg('SetCoords',xyz,hReg,hC), where hReg
% is the registry object's handle, and hC is the handle associated with
% the calling GUI control. The specification of the caller GUI control
% allows the registry to avoid circularities: If the object is "forward
% registered" for updates, then the registry function doesn't try to
% update the object which just updated the registry! (Similarly, the
% handle of the registry object, hReg, is passed to the handling
% function during forward XYZ updating, so that the handling function's
% 'SetCoords' facility can be constructed to accept XYZ updates from
% various sources, and only inform the registry if not called by the
% registry, and hence avoid circularities.)
%
% A framework is provided for "back" registration. Really all that is
% required is that the GUI controls know of the registry object (via
% it's handle hReg), and call the registry's 'SetCoords' facility when
% necessary. This can be done in many ways, but a simple structure is
% provided, mirroring that of the registry's operation. This framework
% assummes that the GUI controls identification object's 'UserData' is
% a structure with a field named 'hReg', which stores the handle of the
% registry (if back registered), or is empty (if not back registered,
% i.e. standalone). bspm_XYZreg provides utility functions for
% setting/unsetting this field, and for "cross registering" - that is
% both forward and back registration in one command. Cross registering
% involves adding the handle/function pair to the registry, and setting
% the registry handle in the GUI control object's 'UserData' 'hReg'
% field. It's up to the handling function to read the registry handle
% from it's objects 'UserData' and act accordingly. A simple example of
% such a function is provided in bspm_XYZreg_Ex2.m, illustrated below.
%
% SubFunctions are provided for getting and setting the current
% co-ordinates; adding and deleting handle/function pairs from the
% registry (forward registration and un-registration), setting and
% removing registry handle information from the 'hReg' field of the
% 'UserData' of a HG object (backward registration & un-registration);
% cross registration and unregistration (including pushing of current
% co-ordinates); setting and getting the current XYZ location. See the
% FORMAT statements and the example below...
%
%                           ----------------
% Example
% %-Create a window:
% F = figure;
% %-Create an object to hold the registry
% hReg = uicontrol(F,'Style','Text','String','hReg',...
%   'Position',[100 200 100 025],...
%   'FontName','Times','FontSize',14,'FontWeight','Bold',...
%   'HorizontalAlignment','Center');
% %-Setup M & D
% V = [65;87;26;02;02;04;33;53;08];
% M = [ [diag(V(4:6)), -(V(7:9).*V(4:6))]; [zeros(1,3) ,1]];
% D = V(1:3);
% %-Initialise a registry in this object, with initial co-ordinates [0;0;0]
% bspm_XYZreg('InitReg',hReg,M,D,[0;0;0])
% % (ans returns [0;0;0] confirming current co-ordinates
% %-Set co-ordinates to [10;10;10]
% bspm_XYZreg('SetCoords',[10,10,10],hReg)
% % (warns of co-ordinate rounding to [10,10,12], & returns ans as [10;10;12])
%
% %-Forward register a command window xyz reporting function: bspm_XYZreg_Ex1.m
% bspm_XYZreg('Add2Reg',hReg,0,'bspm_XYZreg_Ex1')
% % (ans returns new registry, containing just this handle/function pair
% %-Set co-ordinates to [0;10;12]
% [xyz,d] = bspm_XYZreg('SetCoords',[0,10,12],hReg);
% % (bspm_XYZreg_Ex1 called, and prints co-ordinates and handles)
% %-Have a peek at the registry information
% RD = get(hReg,'UserData')
% RD.xyz    %-The current point according to the registry
% RD.Reg    %-The nx2 cell array of handle/function pairs
%
% %-Create an example GUI XYZ control, using bspm_XYZreg_Ex2.m
% hB = bspm_XYZreg_Ex2('Create',M,D,xyz);
% % (A figure window with a button appears, whose label shows the current xyz
% %-Press the button, and enter new co-ordinates [0;0;0] in the Cmd window...
% % (...the button's internal notion of the current location is changed, but
% % (the registry isn't informed:
% bspm_XYZreg('GetCoords',hReg)
% (...returns [0;10;12])
% %-"Back" register the button
% bspm_XYZreg('SetReg',hB,hReg)
% %-Check the back registration
% if ( hReg == getfield(get(hB,'UserData'),'hReg') ), disp('yes!'), end
% %-Now press the button, and enter [0;0;0] again...
% % (...this time the registry is told, and the registry tells bspm_XYZreg_Ex1,
% % (which prints out the new co-ordinates!
% %-Forward register the button to receive updates from the registry
% nReg = bspm_XYZreg('Add2Reg',hReg,hB,'bspm_XYZreg_Ex2')
% % (The new registry is returned as nReg, showing two entries
% %-Set new registry co-ordinates to [10;10;12]
% [xyz,d] = bspm_XYZreg('SetCoords',[10;10;12],hReg);
% % (...the button updates too!
%
% %-Illustration of robustness: Delete the button & use the registry
% delete(hB)
% [xyz,d] = bspm_XYZreg('SetCoords',[10;10;12],hReg);
% % (...the invalid handle hB in the registry is ignored)
% %-Peek at the registry
% getfield(get(hReg,'UserData'),'Reg')
% %-Delete hB from the registry by "cleaning"
% bspm_XYZreg('CleanReg',hReg)
% % (...it's gone
%
% %-Make a new button and cross register
% hB = bspm_XYZreg_Ex2('Create',M,D)
% % (button created with default co-ordinates of [0;0;0]
% nReg = bspm_XYZreg('XReg',hReg,hB,'bspm_XYZreg_Ex2')
% % (Note that the registry pushes the current co-ordinates to the button
% %-Use the button & bspm_XYZreg('SetCoords'... at will!
%_______________________________________________________________________
% Copyright (C) 2008 Wellcome Trust Centre for Neuroimaging

% Andrew Holmes, Chloe Hutton
% $Id: bspm_XYZreg.m 3664 2010-01-07 16:08:51Z volkmar $



%=======================================================================
switch lower(varargin{1}), case 'roundcoords'
%=======================================================================
% [xyz,d] = bspm_XYZreg('RoundCoords',xyz,M,D)
% [xyz,d] = bspm_XYZreg('RoundCoords',xyz,V)
if nargin<3, error('Insufficient arguments'), end
if nargin<4
    V = varargin{3};
    M = [ [diag(V(4:6)), -(V(7:9).*V(4:6))]; [zeros(1,3) ,1]];
    D = V(1:3);
else
    M = varargin{3};
    D = varargin{4};
end
    
%-Round xyz to coordinates of actual voxel centre
%-Do rounding in voxel coordinates & ensure within image size
%-Watch out for infinities!
%-----------------------------------------------------------------------
xyz  = [varargin{2}(:); 1];
xyz(isinf(xyz)) = 1e10*sign(xyz(isinf(xyz)));
rcp  = round(inv(M)*xyz);
rcp  = max([min([rcp';[D',1]]);[1,1,1,1]])';
rxyz = M*rcp;

%-Work out Euclidean distance between points xyz & rounded xyz
d = sqrt(sum((xyz-rxyz).^2));

varargout = {rxyz(1:3),d};



%=======================================================================
case 'findxyz'
%=======================================================================
% i = bspm_XYZreg('FindXYZ',xyz,XYZ)
if nargin<3, error('Insufficient arguments'), end
XYZ = varargin{3};
xyz = varargin{2};
    
%-Find XYZ = xyz
%-----------------------------------------------------------------------
i = find(all([XYZ(1,:)==xyz(1);XYZ(2,:)==xyz(2);XYZ(3,:)==xyz(3)],1));

varargout = {i};



%=======================================================================
case 'nearestxyz'
%=======================================================================
% [xyz,i,d] = bspm_XYZreg('NearestXYZ',xyz,XYZ)
if nargin<3, error('Insufficient arguments'), end
    
%-Find in XYZ nearest point to coordinates xyz (Euclidean distance) 
%-----------------------------------------------------------------------
[d,i] = min(bspm_XYZreg('Edist',varargin{2},varargin{3}));
varargout = {varargin{3}(:,i),i,d};



%=======================================================================
case 'edist'
%=======================================================================
% d = bspm_XYZreg('Edist',xyz,XYZ)
if nargin<3, error('Insufficient arguments'), end
    
%-Calculate (Euclidean) distances from pointlist co-ords to xyz
%-----------------------------------------------------------------------
varargout = {sqrt(sum([ (varargin{3}(1,:) - varargin{2}(1));...
            (varargin{3}(2,:) - varargin{2}(2));...
            (varargin{3}(3,:) - varargin{2}(3)) ].^2))};



%=======================================================================
case 'initreg'      % Initialise registry in handle h
%=======================================================================
% [hReg,xyz] = bspm_XYZreg('InitReg',hReg,M,D,xyz)
if nargin<5, xyz=[0;0;0]; else, xyz=varargin{5}; end
if nargin<4, error('Insufficient arguments'), end

D    = varargin{4};
M    = varargin{3};
hReg = varargin{2};

%-Check availability of hReg object for building a registry in
%-----------------------------------------------------------------------
if ~isempty(get(hReg,'UserData')), error('Object already has UserData...'), end
if ~isempty(get(hReg,'Tag')), error('Object already ''Tag''ed...'), end

%-Check co-ordinates are in range
%-----------------------------------------------------------------------
[xyz,d] = bspm_XYZreg('RoundCoords',xyz,M,D);
if d>0 & nargout<2
    printmsg(sprintf('Co-ordinates rounded to nearest voxel center: Discrepancy %.2f', d), 'NOTE'); 
    % warning(sprintf('%s: Co-ords rounded to nearest voxel center: Discrepancy %.2f',mfilename,d)); 
end

%-Set up registry
%-----------------------------------------------------------------------
RD = struct('xyz',xyz,'M',M,'D',D,'Reg',[]);
RD.Reg = {};
set(hReg,'Tag','hReg','UserData',RD)

%-Return current co-ordinates
%-----------------------------------------------------------------------
varargout = {hReg,xyz};



%=======================================================================
case 'uninitreg'    % UnInitialise registry in handle hReg
%=======================================================================
% bspm_XYZreg('UnInitReg',hReg)
hReg = varargin{2};
if ~strcmp(get(hReg,'Tag'),'hReg'), warning('Not an XYZ registry'), return, end
set(hReg,'Tag','','UserData',[])



%=======================================================================
case 'getcoords'    % Get current co-ordinates
%=======================================================================
% xyz = bspm_XYZreg('GetCoords',hReg)
if nargin<2, hReg=bspm_XYZreg('FindReg'); else, hReg=varargin{2}; end
if ~ishandle(hReg), error('Invalid object handle'), end
if ~strcmp(get(hReg,'Tag'),'hReg'), error('Not a registry'), end
varargout = {getfield(get(hReg,'UserData'),'xyz')};



%=======================================================================
case 'setcoords'    % Set co-ordinates & update registered functions
%=======================================================================
% [xyz,d] = bspm_XYZreg('SetCoords',xyz,hReg,hC,Reg)
% d returned empty if didn't check, warning printed if d not asked for & round
% Don't check if callerhandle specified (speed)
% If Registry cell array Reg is specified, then only these handles are updated
hC=0; mfn=''; if nargin>=4
    if ~ischar(varargin{4}), hC=varargin{4}; else mfn=varargin{4}; end
end
hReg = varargin{3};

%-Check validity of hReg registry handle
%-----------------------------------------------------------------------
%-Return if hReg empty, in case calling objects functions don't check isempty
if isempty(hReg), return, end
%-Check validity of hReg registry handle, correct calling objects if necc.
if ~ishandle(hReg)
    str = sprintf('%s: Invalid registry handle (%.4f)',mfilename,hReg);
    if hC>0
        %-Remove hReg from caller
        bspm_XYZreg('SetReg',hC,[])
        str = [str,sprintf('\n\t\t\t...removed from caller (%.4f)',hC)];
    end
    warning(str)
    return
end
xyz  = varargin{2};
RD      = get(hReg,'UserData');

%-Check validity of coords only when called without a caller handle
%-----------------------------------------------------------------------
if hC<=0
    [xyz,d] = bspm_XYZreg('RoundCoords',xyz,RD.M,RD.D);
    if d>0 & nargout<2, warning(sprintf(...
        '%s: Co-ords rounded to neatest voxel center: Discrepancy %.2f',...
        mfilename,d)), end
else
    d = 0;
end

%-Sort out valid handles, eliminate caller handle, update co-ords with
% registered handles via their functions
%-----------------------------------------------------------------------
if nargin<5
    RD.Reg = bspm_XYZreg('VReg',RD.Reg);
    Reg    = RD.Reg;
else
    Reg = bspm_XYZreg('VReg',varargin{5});
end
if hC>0 & length(Reg), Reg(find([Reg{:,1}]==varargin{4}),:) = []; end
for i = 1:size(Reg,1)
    feval(Reg{i,2},'SetCoords',xyz,Reg{i,1},hReg);
end

%-Update registry (if using hReg) with location & cleaned Reg cellarray
%-----------------------------------------------------------------------
if nargin<5
    RD.xyz  = xyz;
    set(hReg,'UserData',RD)
end

varargout = {xyz,d};
if ~strcmp(mfn,'spm_graph')
    sHdl=findobj(0,'Tag','SPMGraphSatelliteFig');
    axHdl=findobj(sHdl,'Type','axes','Tag','SPMGraphSatelliteAxes');
    %tag for true axis, as legend is of type axis, too
    for j=1:length(axHdl)
        autoinp=get(axHdl(j),'UserData');
        if ~isempty(autoinp), spm_graph([],[],hReg,axHdl(j)); end
    end
end


%=======================================================================
case 'xreg'     % Cross register object handles & functions
%=======================================================================
% nReg = bspm_XYZreg('XReg',hReg,{h,Fcn}pairs)
if nargin<4, error('Insufficient arguments'), end
hReg = varargin{2};

%-Quick check of registry handle
%-----------------------------------------------------------------------
if isempty(hReg),   warning('Empty registry handle'), return, end
if ~ishandle(hReg), warning('Invalid registry handle'), return, end

%-Condition nReg cell array & check validity of handles to be registered
%-----------------------------------------------------------------------
nReg = varargin(3:end);
if mod(length(nReg),2), error('Registry items must be in pairs'), end
if length(nReg)>2, nReg = reshape(nReg,length(nReg)/2,2)'; end
nReg = bspm_XYZreg('VReg',nReg,'Warn');

%-Set hReg registry link for registry candidates (Back registration)
%-----------------------------------------------------------------------
for i = 1:size(nReg,1)
    bspm_XYZreg('SetReg',nReg{i,1},hReg);
end

%-Append registry candidates to existing registry & write back to hReg
%-----------------------------------------------------------------------
RD     = get(hReg,'UserData');
Reg    = RD.Reg;
Reg    = cat(1,Reg,nReg);
RD.Reg = Reg;
set(hReg,'UserData',RD)

%-Synch co-ordinates of newly registered objects
%-----------------------------------------------------------------------
bspm_XYZreg('SetCoords',RD.xyz,hReg,hReg,nReg);

varargout = {Reg};



%=======================================================================
case 'add2reg'      % Add handle(s) & function(s) to registry
%=======================================================================
% nReg = bspm_XYZreg('Add2Reg',hReg,{h,Fcn}pairs)
if nargin<4, error('Insufficient arguments'), end
hReg = varargin{2};

%-Quick check of registry handle
%-----------------------------------------------------------------------
if isempty(hReg),   warning('Empty registry handle'), return, end
if ~ishandle(hReg), warning('Invalid registry handle'), return, end

%-Condition nReg cell array & check validity of handles to be registered
%-----------------------------------------------------------------------
nReg = varargin(3:end);
if mod(length(nReg),2), error('Registry items must be in pairs'), end
if length(nReg)>2, nReg = reshape(nReg,length(nReg)/2,2)'; end
nReg = bspm_XYZreg('VReg',nReg,'Warn');

%-Append to existing registry & put back in registry object
%-----------------------------------------------------------------------
RD     = get(hReg,'UserData');
Reg    = RD.Reg;
Reg    = cat(1,Reg,nReg);
RD.Reg = Reg;
set(hReg,'UserData',RD)

varargout = {Reg};



%=======================================================================
case 'setreg'           %-Set registry field of object's UserData
%=======================================================================
% bspm_XYZreg('SetReg',h,hReg)
if nargin<3, error('Insufficient arguments'), end
h    = varargin{2};
hReg = varargin{3};
if ( ~ishandle(h) | h==0 ), return, end
UD = get(h,'UserData');
if ~isstruct(UD) | ~any(strcmp(fieldnames(UD),'hReg'))
    error('No UserData structure with hReg field for this object')
end
UD.hReg = hReg;
set(h,'UserData',UD)



%=======================================================================
case 'unxreg'       % Un-cross register object handles & functions
%=======================================================================
% nReg = bspm_XYZreg('unXReg',hReg,hD1,hD2,hD3,...)
if nargin<3, error('Insufficient arguments'), end
hD   = [varargin{3:end}];
hReg = varargin{2};

%-Get Registry information
%-----------------------------------------------------------------------
RD         = get(hReg,'UserData');
Reg        = RD.Reg;

%-Find registry entires to delete
%-----------------------------------------------------------------------
[null,i,e] = intersect([Reg{:,1}],hD);
hD(e)      = [];
dReg       = bspm_XYZreg('VReg',Reg(i,:));
Reg(i,:)   = [];
if length(hD), warning('Not all handles were in registry'), end

%-Write back new registry
%-----------------------------------------------------------------------
RD.Reg = Reg;
set(hReg,'UserData',RD)

%-UnSet hReg registry link for hD's still existing (Back un-registration)
%-----------------------------------------------------------------------
for i = 1:size(dReg,1)
    bspm_XYZreg('SetReg',dReg{i,1},[]);
end

varargout = {Reg};



%=======================================================================
case 'del2reg'      % Delete handle(s) & function(s) from registry
%=======================================================================
% nReg = bspm_XYZreg('Del2Reg',hReg,hD)
if nargin<3, error('Insufficient arguments'), end
hD   = [varargin{3:end}];
hReg = varargin{2};

%-Get Registry information
%-----------------------------------------------------------------------
RD         = get(hReg,'UserData');
Reg        = RD.Reg;

%-Find registry entires to delete
%-----------------------------------------------------------------------
[null,i,e] = intersect([Reg{:,1}],hD);
Reg(i,:)   = [];
hD(e)      = [];
if length(hD), warning('Not all handles were in registry'), end

%-Write back new registry
%-----------------------------------------------------------------------
RD.Reg = Reg;
set(hReg,'UserData',RD)

varargout = {Reg};



%=======================================================================
case 'unsetreg'         %-Unset registry field of object's UserData
%=======================================================================
% bspm_XYZreg('UnSetReg',h)
if nargin<2, error('Insufficient arguments'), end
bspm_XYZreg('SetReg',varargin{2},[])



%=======================================================================
case 'cleanreg'     % Clean invalid handles from registry
%=======================================================================
% bspm_XYZreg('CleanReg',hReg)
%if ~strcmp(get(hReg,'Tag'),'hReg'), error('Not a registry'), end
hReg = varargin{2};
RD = get(hReg,'UserData');
RD.Reg = bspm_XYZreg('VReg',RD.Reg,'Warn');
set(hReg,'UserData',RD)


%=======================================================================
case 'vreg'     % Prune invalid handles from registry cell array
%=======================================================================
% Reg = bspm_XYZreg('VReg',Reg,Warn)
if nargin<3, Warn=0; else, Warn=1; end
Reg = varargin{2};
if isempty(Reg), varargout={Reg}; return, end
i = find(~ishandle([Reg{:,1}]));
%-***check existance of handling functions : exist('','file')?
if Warn & length(i), warning([...
    sprintf('%s: Disregarding invalid registry handles:\n\t',...
        mfilename),sprintf('%.4f',Reg{i,1})]), end
Reg(i,:)  = [];
varargout = {Reg};



%=======================================================================
case 'findreg'          % Find/check registry object
%=======================================================================
% hReg = bspm_XYZreg('FindReg',h)
if nargin<2, h=get(0,'CurrentFigure'); else, h=varargin{2}; end
if ischar(h), h=spm_figure('FindWin',h); end
if ~ishandle(h), error('invalid handle'), end
if ~strcmp(get(h,'Tag'),'hReg'), h=findobj(h,'Tag','hReg'); end
if isempty(h), error('Registry object not found'), end
if length(h)>1, error('Multiple registry objects found'), end
varargout = {h};

%=======================================================================
otherwise
%=======================================================================
warning('Unknown action string')

%=======================================================================
end

% | NAN SUITE
% =========================================================================
function y       = nanmean(x,dim)
% FORMAT: Y = NANMEAN(X,DIM)
% 
%    Average or mean value ignoring NaNs
%
%    This function enhances the functionality of NANMEAN as distributed in
%    the MATLAB Statistics Toolbox and is meant as a replacement (hence the
%    identical name).  
%
%    NANMEAN(X,DIM) calculates the mean along any dimension of the N-D
%    array X ignoring NaNs.  If DIM is omitted NANMEAN averages along the
%    first non-singleton dimension of X.
%
%    Similar replacements exist for NANSTD, NANMEDIAN, NANMIN, NANMAX, and
%    NANSUM which are all part of the NaN-suite.
%
%    See also MEAN

% -------------------------------------------------------------------------
%    author:      Jan Gl?scher
%    affiliation: Neuroimage Nord, University of Hamburg, Germany
%    email:       glaescher@uke.uni-hamburg.de
%    
%    $Revision: 1.1 $ $Date: 2004/07/15 22:42:13 $

if isempty(x)
	y = NaN;
	return
end

if nargin < 2
	dim = min(find(size(x)~=1));
	if isempty(dim)
		dim = 1;
	end
end

% Replace NaNs with zeros.
nans = isnan(x);
x(isnan(x)) = 0; 

% denominator
count = size(x,dim) - sum(nans,dim);

% Protect against a  all NaNs in one dimension
i = find(count==0);
count(i) = ones(size(i));

y = sum(x,dim)./count;
y(i) = i + NaN;
function y       = nanmedian(x,dim)
% FORMAT: Y = NANMEDIAN(X,DIM)
% 
%    Median ignoring NaNs
%
%    This function enhances the functionality of NANMEDIAN as distributed
%    in the MATLAB Statistics Toolbox and is meant as a replacement (hence
%    the identical name).  
%
%    NANMEDIAN(X,DIM) calculates the mean along any dimension of the N-D
%    array X ignoring NaNs.  If DIM is omitted NANMEDIAN averages along the
%    first non-singleton dimension of X.
%
%    Similar replacements exist for NANMEAN, NANSTD, NANMIN, NANMAX, and
%    NANSUM which are all part of the NaN-suite.
%
%    See also MEDIAN

% -------------------------------------------------------------------------
%    author:      Jan Gl?scher
%    affiliation: Neuroimage Nord, University of Hamburg, Germany
%    email:       glaescher@uke.uni-hamburg.de
%    
%    $Revision: 1.2 $ $Date: 2007/07/30 17:19:19 $

if isempty(x)
	y = [];
	return
end

if nargin < 2
	dim = min(find(size(x)~=1));
	if isempty(dim)
		dim = 1;
	end
end

siz  = size(x);
n    = size(x,dim);

% Permute and reshape so that DIM becomes the row dimension of a 2-D array
perm = [dim:max(length(size(x)),dim) 1:dim-1];
x = reshape(permute(x,perm),n,prod(siz)/n);


% force NaNs to bottom of each column
x = sort(x,1);

% identify and replace NaNs
nans = isnan(x);
x(isnan(x)) = 0;

% new dimension of x
[n m] = size(x);

% number of non-NaN element in each column
s = size(x,1) - sum(nans);
y = zeros(size(s));

% now calculate median for every element in y
% (does anybody know a more eefficient way than with a 'for'-loop?)
for i = 1:length(s)
	if rem(s(i),2) & s(i) > 0
		y(i) = x((s(i)+1)/2,i);
	elseif rem(s(i),2)==0 & s(i) > 0
		y(i) = (x(s(i)/2,i) + x((s(i)/2)+1,i))/2;
	end
end

% Protect against a column of NaNs
i = find(y==0);
y(i) = i + nan;

% permute and reshape back
siz(dim) = 1;
y = ipermute(reshape(y,siz(perm)),perm);
function y       = nanstd(x,flag,dim)
% FORMAT: Y = NANSTD(X,FLAG,DIM)
% 
%    Standard deviation ignoring NaNs
%
%    This function enhances the functionality of NANSTD as distributed in
%    the MATLAB Statistics Toolbox and is meant as a replacement (hence the
%    identical name).  
%
%    NANSTD(X,DIM) calculates the standard deviation along any dimension of
%    the N-D array X ignoring NaNs.  
%
%    NANSTD(X,DIM,0) normalizes by (N-1) where N is SIZE(X,DIM).  This make
%    NANSTD(X,DIM).^2 the best unbiased estimate of the variance if X is
%    a sample of a normal distribution. If omitted FLAG is set to zero.
%    
%    NANSTD(X,DIM,1) normalizes by N and produces the square root of the
%    second moment of the sample about the mean.
%
%    If DIM is omitted NANSTD calculates the standard deviation along first
%    non-singleton dimension of X.
%
%    Similar replacements exist for NANMEAN, NANMEDIAN, NANMIN, NANMAX, and
%    NANSUM which are all part of the NaN-suite.
%
%    See also STD

% -------------------------------------------------------------------------
%    author:      Jan Gl?scher
%    affiliation: Neuroimage Nord, University of Hamburg, Germany
%    email:       glaescher@uke.uni-hamburg.de
%    
%    $Revision: 1.1 $ $Date: 2004/07/15 22:42:15 $

if isempty(x)
	y = NaN;
	return
end
if nargin < 3
	dim = min(find(size(x)~=1));
	if isempty(dim)
		dim = 1; 
	end	  
end
if nargin < 2
	flag = 0;
end




% Find NaNs in x and nanmean(x)
nans = isnan(x);
avg = nanmean(x,dim);

% create array indicating number of element 
% of x in dimension DIM (needed for subtraction of mean)
tile = ones(1,max(ndims(x),dim));
tile(dim) = size(x,dim);

% remove mean
x = x - repmat(avg,tile);

count = size(x,dim) - sum(nans,dim);

% Replace NaNs with zeros.
x(isnan(x)) = 0; 


% Protect against a  all NaNs in one dimension
i = find(count==0);

if flag == 0
	y = sqrt(sum(x.*x,dim)./max(count-1,1));
else
	y = sqrt(sum(x.*x,dim)./max(count,1));
end
y(i) = i + NaN;
function y       = nanvar(x,dim,flag)
% FORMAT: Y = NANVAR(X,DIM,FLAG)
% 
%    Variance ignoring NaNs
%
%    This function enhances the functionality of NANVAR as distributed in
%    the MATLAB Statistics Toolbox and is meant as a replacement (hence the
%    identical name).  
%
%    NANVAR(X,DIM) calculates the standard deviation along any dimension of
%    the N-D array X ignoring NaNs.  
%
%    NANVAR(X,DIM,0) normalizes by (N-1) where N is SIZE(X,DIM).  This make
%    NANVAR(X,DIM).^2 the best unbiased estimate of the variance if X is
%    a sample of a normal distribution. If omitted FLAG is set to zero.
%    
%    NANVAR(X,DIM,1) normalizes by N and produces second moment of the 
%    sample about the mean.
%
%    If DIM is omitted NANVAR calculates the standard deviation along first
%    non-singleton dimension of X.
%
%    Similar replacements exist for NANMEAN, NANMEDIAN, NANMIN, NANMAX, 
%    NANSTD, and NANSUM which are all part of the NaN-suite.
%
%    See also STD

% -------------------------------------------------------------------------
%    author:      Jan Gl?scher
%    affiliation: Neuroimage Nord, University of Hamburg, Germany
%    email:       glaescher@uke.uni-hamburg.de
%    
%    $Revision: 1.1 $ $Date: 2008/05/02 21:46:17 $

if isempty(x)
	y = NaN;
	return
end

if nargin < 3
	flag = 0;
end

if nargin < 2
	dim = min(find(size(x)~=1));
	if isempty(dim)
		dim = 1; 
	end	  
end


% Find NaNs in x and nanmean(x)
nans = isnan(x);
avg = nanmean(x,dim);

% create array indicating number of element 
% of x in dimension DIM (needed for subtraction of mean)
tile = ones(1,max(ndims(x),dim));
tile(dim) = size(x,dim);

% remove mean
x = x - repmat(avg,tile);

count = size(x,dim) - sum(nans,dim);

% Replace NaNs with zeros.
x(isnan(x)) = 0; 


% Protect against a  all NaNs in one dimension
i = find(count==0);

if flag == 0
	y = sum(x.*x,dim)./max(count-1,1);
else
	y = sum(x.*x,dim)./max(count,1);
end
y(i) = i + NaN;
function y       = nansem(x,dim)
% FORMAT: Y = NANSEM(X,DIM)
% 
%    Standard error of the mean ignoring NaNs
%
%    NANSTD(X,DIM) calculates the standard error of the mean along any
%    dimension of the N-D array X ignoring NaNs.  
%
%    If DIM is omitted NANSTD calculates the standard deviation along first
%    non-singleton dimension of X.
%
%    Similar functions exist: NANMEAN, NANSTD, NANMEDIAN, NANMIN, NANMAX, and
%    NANSUM which are all part of the NaN-suite.

% -------------------------------------------------------------------------
%    author:      Jan Gl?scher
%    affiliation: Neuroimage Nord, University of Hamburg, Germany
%    email:       glaescher@uke.uni-hamburg.de
%    
%    $Revision: 1.1 $ $Date: 2004/07/22 09:02:27 $

if isempty(x)
	y = NaN;
	return
end

if nargin < 2
	dim = min(find(size(x)~=1));
	if isempty(dim)
		dim = 1; 
	end	  
end


% Find NaNs in x and nanmean(x)
nans = isnan(x);

count = size(x,dim) - sum(nans,dim);


% Protect against a  all NaNs in one dimension
i = find(count==0);
count(i) = 1;

y = nanstd(x,dim)./sqrt(count);

y(i) = i + NaN;
function y       = nansum(x,dim)
% FORMAT: Y = NANSUM(X,DIM)
% 
%    Sum of values ignoring NaNs
%
%    This function enhances the functionality of NANSUM as distributed in
%    the MATLAB Statistics Toolbox and is meant as a replacement (hence the
%    identical name).  
%
%    NANSUM(X,DIM) calculates the mean along any dimension of the N-D array
%    X ignoring NaNs.  If DIM is omitted NANSUM averages along the first
%    non-singleton dimension of X.
%
%    Similar replacements exist for NANMEAN, NANSTD, NANMEDIAN, NANMIN, and
%    NANMAX which are all part of the NaN-suite.
%
%    See also SUM

% -------------------------------------------------------------------------
%    author:      Jan Gl?scher
%    affiliation: Neuroimage Nord, University of Hamburg, Germany
%    email:       glaescher@uke.uni-hamburg.de
%    
%    $Revision: 1.2 $ $Date: 2005/06/13 12:14:38 $

if isempty(x)
	y = [];
	return
end

if nargin < 2
	dim = min(find(size(x)~=1));
	if isempty(dim)
		dim = 1;
	end
end

% Replace NaNs with zeros.
nans = isnan(x);
x(isnan(x)) = 0; 

% Protect against all NaNs in one dimension
count = size(x,dim) - sum(nans,dim);
i = find(count==0);

y = sum(x,dim);
y(i) = NaN;
function [y,idx] = nanmin(a,dim,b)
% FORMAT: [Y,IDX] = NANMIN(A,DIM,[B])
% 
%    Minimum ignoring NaNs
%
%    This function enhances the functionality of NANMIN as distributed in
%    the MATLAB Statistics Toolbox and is meant as a replacement (hence the
%    identical name).
%
%    If fact NANMIN simply rearranges the input arguments to MIN because
%    MIN already ignores NaNs.
%
%    NANMIN(A,DIM) calculates the minimum of A along the dimension DIM of
%    the N-D array X. If DIM is omitted NANMIN calculates the minimum along
%    the first non-singleton dimension of X.
%
%    NANMIN(A,[],B) returns the minimum of the N-D arrays A and B.  A and
%    B must be of the same size.
%
%    Comparing two matrices in a particular dimension is not supported,
%    e.g. NANMIN(A,2,B) is invalid.
%    
%    [Y,IDX] = NANMIN(X,DIM) returns the index to the minimum in IDX.
%    
%    Similar replacements exist for NANMAX, NANMEAN, NANSTD, NANMEDIAN and
%    NANSUM which are all part of the NaN-suite.
%
%    See also MIN

% -------------------------------------------------------------------------
%    author:      Jan Gl?scher
%    affiliation: Neuroimage Nord, University of Hamburg, Germany
%    email:       glaescher@uke.uni-hamburg.de
%    
%    $Revision: 1.1 $ $Date: 2004/07/15 22:42:14 $

if nargin < 1
	error('Requires at least one input argument')
end

if nargin == 1
	if nargout > 1
		[y,idx] = min(a);
	else
		y = min(a);
	end
elseif nargin == 2
	if nargout > 1
		[y,idx] = min(a,[],dim);
	else
		y = min(a,[],dim);
	end
elseif nargin == 3
	if ~isempty(dim)
		error('Comparing two matrices along a particular dimension is not supported')
	else
		if nargout > 1
			[y,idx] = min(a,b);
		else
			y = min(a,b);
		end
	end
elseif nargin > 3
	error('Too many input arguments.')
end
function [y,idx] = nanmax(a,dim,b)
% FORMAT: [Y,IDX] = NANMAX(A,DIM,[B])
% 
%    Maximum ignoring NaNs
%
%    This function enhances the functionality of NANMAX as distributed in
%    the MATLAB Statistics Toolbox and is meant as a replacement (hence the
%    identical name).
%
%    If fact NANMAX simply rearranges the input arguments to MAX because
%    MAX already ignores NaNs.
%
%    NANMAX(A,DIM) calculates the maximum of A along the dimension DIM of
%    the N-D array X. If DIM is omitted NANMAX calculates the maximum along
%    the first non-singleton dimension of X.
%
%    NANMAX(A,[],B) returns the minimum of the N-D arrays A and B.  A and
%    B must be of the same size.
%
%    Comparing two matrices in a particular dimension is not supported,
%    e.g. NANMAX(A,2,B) is invalid.
%    
%    [Y,IDX] = NANMAX(X,DIM) returns the index to the maximum in IDX.
%    
%    Similar replacements exist for NANMIN, NANMEAN, NANSTD, NANMEDIAN and
%    NANSUM which are all part of the NaN-suite.
%
%    See also MAX

% -------------------------------------------------------------------------
%    author:      Jan Gl?scher
%    affiliation: Neuroimage Nord, University of Hamburg, Germany
%    email:       glaescher@uke.uni-hamburg.de
%    
%    $Revision: 1.1 $ $Date: 2004/07/15 22:42:11 $

if nargin < 1
	error('Requires at least one input argument')
end

if nargin == 1
	if nargout > 1
		[y,idx] = max(a);
	else
		y = max(a);
	end
elseif nargin == 2
	if nargout > 1
		[y,idx] = max(a,[],dim);
	else
		y = max(a,[],dim);
	end
elseif nargin == 3
	if ~isempty(dim)
		error('Comparing two matrices along a particular dimension is not supported')
	else
		if nargout > 1
			[y,idx] = max(a,b);
		else
			y = max(a,b);
		end
	end
elseif nargin > 3
	error('Too many input arguments.')
end

% =========================================================================
% *
% * XLWRITE
% *
% =========================================================================
function status = bspm_xlwrite(filename, A, sheet, templatefile, range)
% XLWRITE Write to Microsoft Excel spreadsheet file using Java
%   XLWRITE(FILE,ARRAY) writes ARRAY to the first worksheet in the Excel
%   file named FILE, starting at cell A1. It aims to have exactly the same
%   behaviour as XLSWRITE. See also XLSWRITE.
%
%   XLWRITE(FILE,ARRAY,SHEET) writes to the specified worksheet.
%
%   XLWRITE(FILE,ARRAY,RANGE) writes to the rectangular region
%   specified by RANGE in the first worksheet of the file. Specify RANGE
%   using the syntax 'C1:C2', where C1 and C2 are opposing corners of the
%   region.
%
%   XLWRITE(FILE,ARRAY,SHEET,RANGE) writes to the specified SHEET and
%   RANGE.
%
%   STATUS = XLWRITE(FILE,ARRAY,SHEET,RANGE) returns the completion
%   status of the write operation: TRUE (logical 1) for success, FALSE
%   (logical 0) for failure.  Inputs SHEET and RANGE are optional.
%
%   Input Arguments:
%
%   FILE    String that specifies the file to write. If the file does not
%           exist, XLWRITE creates a file, determining the format based on
%           the specified extension. To create a file compatible with Excel
%           97-2003 software, specify an extension of '.xls'. If you do not 
%           specify an extension, XLWRITE applies '.xls'.
%   ARRAY   Two-dimensional logical, numeric or character array or, if each
%           cell contains a single element, a cell array.
%   SHEET   Worksheet to write. One of the following:
%           * String that contains the worksheet name.
%           * Positive, integer-valued scalar indicating the worksheet
%             index.
%           If SHEET does not exist, XLWRITE adds a new sheet at the end
%           of the worksheet collection. 
%   RANGE   String that specifies a rectangular portion of the worksheet to
%           read. Not case sensitive. Use Excel A1 reference style.
%           * If you specify a SHEET, RANGE can either fit the size of
%             ARRAY or specify only the first cell (such as 'D2').
%           * If you do not specify a SHEET, RANGE must include both 
%             corners and a colon character (:), even for a single cell
%             (such as 'D2:D2').
%           * If RANGE is larger than the size of ARRAY, Excel fills the
%             remainder of the region with #N/A. If RANGE is smaller than
%             the size of ARRAY, XLWRITE writes only the subset that fits
%             into RANGE to the file.
%
%   Note
%   * This function requires the POI library to be in your javapath.
%     To add the Apache POI Library execute commands: 
%     (This assumes the POI lib files are in folder 'poi_library')
%       javaaddpath('poi_library/poi-3.8-20120326.jar');
%       javaaddpath('poi_library/poi-ooxml-3.8-20120326.jar');
%       javaaddpath('poi_library/poi-ooxml-schemas-3.8-20120326.jar');
%       javaaddpath('poi_library/xmlbeans-2.3.0.jar');
%       javaaddpath('poi_library/dom4j-1.6.1.jar');
%   * Excel converts Inf values to 65535. XLWRITE converts NaN values to
%     empty cells.
%
%   EXAMPLES
%   % Write a 7-element vector to testdata.xls:
%   xlwrite('testdata.xls', [12.7, 5.02, -98, 63.9, 0, -.2, 56])
%
%   % Write mixed text and numeric data to testdata2.xls
%   % starting at cell E1 of Sheet1:
%   d = {'Time','Temperature'; 12,98; 13,99; 14,97};
%   xlwrite('testdata2.xls', d, 1, 'E1')
%
%
%   REVISIONS
%   20121004 - First version using JExcelApi
%   20121101 - Modified to use POI library instead of JExcelApi (allows to
%           generate XLSX)
%   20121127 - Fixed bug: use existing rows if present, instead of 
%           overwrite rows by default. Thanks to Dan & Jason.
%   20121204 - Fixed bug: if a numeric sheet is given & didn't exist,
%           an error was returned instead of creating the sheet. Thanks to Marianna
%   20130106 - Fixed bug: use existing cell if present, instead of
%           overwriting. This way original XLS formatting is kept & not
%           overwritten.
%   20130125 - Fixed bug & documentation. Incorrect working of NaN. Thanks Klaus
%   20130227 - Fixed bug when no sheet number given & added Stax to java
%               load. Thanks to Thierry
%
%   Copyright 2012-2013, Alec de Zegher
%==============================================================================

% If no sheet & xlrange is defined, attribute an empty value to it
if nargin < 3; sheet = []; end
if nargin < 4, templatefile = []; end
if nargin < 5; range = []; end
if regexpi(computer, '^PCWIN')
    if all([~isempty(templatefile) ~exist(filename, 'file')]), copyfile(templatefile, filename); end
    xlswrite(filename, A); 
    status = 1;
    return; 
end

if exist('org.apache.poi.ss.usermodel.WorkbookFactory', 'class')~=8 ...
    || exist('org.apache.poi.hssf.usermodel.HSSFWorkbook', 'class')~=8 ...
    || exist('org.apache.poi.xssf.usermodel.XSSFWorkbook', 'class')~=8
    global st
    javaaddpath(fullfile(st.supportpath, 'poi-3.8-20120326.jar'));
    javaaddpath(fullfile(st.supportpath, 'poi-ooxml-3.8-20120326.jar'));
    javaaddpath(fullfile(st.supportpath, 'poi-ooxml-schemas-3.8-20120326.jar'));
    javaaddpath(fullfile(st.supportpath, 'xmlbeans-2.3.0.jar'));
    javaaddpath(fullfile(st.supportpath, 'dom4j-1.6.1.jar'));
    javaaddpath(fullfile(st.supportpath, 'stax-api-1.0.1.jar'));
end

% Import required POI Java Classes
import org.apache.poi.ss.usermodel.*;
import org.apache.poi.hssf.usermodel.*;
import org.apache.poi.xssf.usermodel.*;
import org.apache.poi.ss.usermodel.*;
import org.apache.poi.ss.util.*;
status = 0;

% If no sheet & xlrange is defined, attribute an empty value to it
if nargin < 3; sheet = []; end
if nargin < 4, templatefile = []; end
if nargin < 5; range = []; end

% Template file
if all([~isempty(templatefile) ~exist(filename, 'file')])
    copyfile(templatefile, filename); 
end

% Check if sheetvariable contains range data
if nargin < 4 && ~isempty(strfind(sheet,':'))
    range = sheet;
    sheet = [];
end

% check if input data is given
if isempty(A)
    error('cs_xlwrite:EmptyInput', 'Input array is empty!');
end
% Check that input data is not bigger than 2D
if ndims(A) > 2
	error('cs_xlwrite:InputDimension', ...
        'Dimension of input array should not be higher than two.');
end

% Set java path to same path as Matlab path
java.lang.System.setProperty('user.dir', pwd);

% Open a file
xlsFile = java.io.File(filename);

% If file does not exist create a new workbook
if xlsFile.isFile()
    % create XSSF or HSSF workbook from existing workbook
    fileIn = java.io.FileInputStream(xlsFile);
    xlsWorkbook = WorkbookFactory.create(fileIn);
else
    % Create a new workbook based on the extension. 
    [~,~,fileExt] = fileparts(filename);
    
    % Check based on extension which type to create. If no (valid)
    % extension is given, create XLSX file
    switch lower(fileExt)
        case '.xls'
            xlsWorkbook = HSSFWorkbook();
        case '.xlsx'
            xlsWorkbook = XSSFWorkbook();
        otherwise
            xlsWorkbook = XSSFWorkbook();
            
            % Also update filename with added extension
            filename = [filename '.xlsx'];
    end
end

% If sheetname given, enter data in this sheet
if ~isempty(sheet)
    if isnumeric(sheet)
        % Java uses 0-indexing, so take sheetnumer-1
        % Check if the sheet can exist 
        if xlsWorkbook.getNumberOfSheets() >= sheet && sheet >= 1
            xlsSheet = xlsWorkbook.getSheetAt(sheet-1);
        else
            % There are less number of sheets, that the requested sheet, so
            % return an empty sheet
            xlsSheet = [];
        end
    else
        xlsSheet = xlsWorkbook.getSheet(sheet);
    end
    
    % Create a new sheet if it is empty
    if isempty(xlsSheet)
        warning('cs_xlwrite:AddSheet', 'Added specified worksheet.');
        
        % Add the sheet
        if isnumeric(sheet)
            xlsSheet = xlsWorkbook.createSheet(['Sheet ' num2str(sheet)]);
        else
            % Create a safe sheet name
            sheet = WorkbookUtil.createSafeSheetName(sheet);
            xlsSheet = xlsWorkbook.createSheet(sheet);
        end
    end
    
else
    % check number of sheets
    nSheets = xlsWorkbook.getNumberOfSheets();
    
    % If no sheets, create one
    if nSheets < 1
        xlsSheet = xlsWorkbook.createSheet('Sheet 1');
    else
        % Select the first sheet
        xlsSheet = xlsWorkbook.getSheetAt(0);
    end
end

% if range is not specified take start row & col at A1
% locations are 0 indexed
if isempty(range)
    iRowStart = 0;
    iColStart = 0;
    iRowEnd = size(A, 1)-1;
    iColEnd = size(A, 2)-1;
else
    % Split range in start & end cell
    iSeperator = strfind(range, ':');
    if isempty(iSeperator)
        % Only start was defined as range
        % Create a helper to get the row and column
        cellStart = CellReference(range);
        iRowStart = cellStart.getRow();
        iColStart = cellStart.getCol();
        % End column calculated based on size of A
        iRowEnd = iRowStart + size(A, 1)-1;
        iColEnd = iColStart + size(A, 2)-1;
    else
        % Define start & end cell
        cellStart = range(1:iSeperator-1);
        cellEnd = range(iSeperator+1:end);
        
        % Create a helper to get the row and column
        cellStart = CellReference(cellStart);
        cellEnd = CellReference(cellEnd);
        
        % Get start & end locations
        iRowStart = cellStart.getRow();
        iColStart = cellStart.getCol();
        iRowEnd = cellEnd.getRow();
        iColEnd = cellEnd.getCol();
    end
end

% Get number of elements in A (0-indexed)
nRowA = size(A, 1)-1;
nColA = size(A, 2)-1;

% If data is a cell, convert it
if ~iscell(A)
    A = num2cell(A);
end

% Iterate over all data
for iRow = iRowStart:iRowEnd
    % Fetch the row (if it exists)
    currentRow = xlsSheet.getRow(iRow); 
    if isempty(currentRow)
        % Create a new row, as it does not exist yet
        currentRow = xlsSheet.createRow(iRow);
    end
    
    % enter data for all cols
    for iCol = iColStart:iColEnd
        % Check if cell exists
        currentCell = currentRow.getCell(iCol);
        if isempty(currentCell)
            % Create a new cell, as it does not exist yet
            currentCell = currentRow.createCell(iCol);
        end
        
        % Check if we are still in array A
        if (iRow-iRowStart)<=nRowA && (iCol-iColStart)<=nColA
            % Fetch the data
            data = A{iRow-iRowStart+1, iCol-iColStart+1};
            
            if ~isempty(data)          
                % if it is a NaN value, convert it to an empty string
                if isnumeric(data) && isnan(data)
                    data = '';
                end
                
                % Write data to cell
                currentCell.setCellValue(data);
            end

        else
            % Set field to NA
            currentCell.setCellErrorValue(FormulaError.NA.getCode());
        end
    end
end

% Write & close the workbook
fileOut = java.io.FileOutputStream(filename);
xlsWorkbook.write(fileOut);
fileOut.close();

status = 1;


    
