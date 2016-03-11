function [h, hh] = surfPlot6(obj)
%%% Written by Aaron P. Schultz - aschultz@martinos.org
%%%
%%% Copyright (C) 2014,  Aaron P. Schultz
%%%
%%% Supported in part by the NIH funded Harvard Aging Brain Study (P01AG036694) and NIH R01-AG027435 
%%%
%%% This program is free software: you can redistribute it and/or modify
%%% it under the terms of the GNU General Public License as published by
%%% the Free Software Foundation, either version 3 of the License, or
%%% any later version.
%%% 
%%% This program is distributed in the hope that it will be useful,
%%% but WITHOUT ANY WARRANTY; without even the implied warranty of
%%% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%%% GNU General Public License for more details.
%%%

load(obj.fsaverage);

switch lower(obj.surface)
    case 'inflated'
        lVert = T.inflated.lVert;
        lFace = T.inflated.lFace;
        rVert = T.inflated.rVert;
        rFace = T.inflated.rFace;
        ucol = 'lightergray';
    case 'pial'
        lVert = T.pial.lVert;
        lFace = T.pial.lFace;
        rVert = T.pial.rVert;
        rFace = T.pial.rFace;
        ucol = 'gray';
    case 'white'
        lVert = T.white.lVert;
        lFace = T.white.lFace;
        rVert = T.white.rVert;
        rFace = T.white.rFace;
        ucol = 'lightgray';
    case 'pi'
        lVert = (T.inflated.lVert+T.pial.lVert)/2;
        lFace = (T.inflated.lFace+T.pial.lFace)/2;
        rVert = (T.inflated.rVert+T.pial.rVert)/2;
        rFace = (T.inflated.rFace+T.pial.rFace)/2;
        ucol = 'gray';
    otherwise
        error('Surface option Not Found:  Available options are inflated, pial, and white');
end

switch lower(obj.shading)
    case 'curv'
        lShade = -T.lCurv;
        rShade = -T.rCurv;
    case 'logcurv'
        lShade = -T.lCurv;
        sgn = sign(lShade); 
        if strcmpi('inflated',obj.surface)
            ind = abs(lShade)>0;
            lShade(ind) = lShade(ind)+(.15*sgn(ind));
        else
            ind = abs(lShade)>.1;
            lShade(ind) = lShade(ind)+(.05*sgn(ind));
        end
        rShade = -T.rCurv;
        sgn = sign(rShade); 
        if strcmpi('inflated',obj.surface)
            ind = abs(rShade)>0;
            rShade(ind) = rShade(ind)+(.15*sgn(ind));
        else
            ind = abs(rShade)>.1;
            rShade(ind) = rShade(ind)+(.05*sgn(ind));
        end
    case 'sulc'
        lShade = -(T.lSulc);
        rShade = -(T.rSulc);
    case 'thk'
        lShade = T.lThk;
        rShade = T.rThk;
    case 'mixed'
        lShade = -((1*(T.lSulc))+(4*(T.lCurv)));
        rShade = -((1*(T.rSulc))+(4*(T.rCurv)));
    otherwise
         error('Shading option Not Found:  Available options are curv, sulc, and thk');
end

if obj.newfig

    if obj.figno>0
        figure(obj.figno); clf;
        set(gcf,'color',obj.background, 'position', obj.position); shg
    else
        obj.figno = figure( ...
        'Renderer', 'zbuffer',      ...
        'Inverthardcopy', 'off',    ...
        'Name', obj.figname,        ...
        'NumberTitle', 'off',       ...
        'Position', obj.position,   ...
        'Color', obj.background,    ...
        'Visible', 'off');
    end
    rang = obj.shadingrange;
    c = lShade;
    c = demean(c);
    c = c./spm_range(c);
    c = c.*diff(rang);
    c = c-min(c)+rang(1);
    col1 = [c c c];

    if obj.Nsurfs == 4;

        subplot(2,12,1:5);
        h(1) = patch('vertices',lVert,'faces', lFace,'FaceVertexCdata',col1);
        shading interp;
        axis equal; axis tight; axis off;
        view(270,0)

        subplot(2,12,13:17);
        h(2) = patch('vertices',lVert,'faces', lFace,'FaceVertexCdata',col1);
        shading interp;
        axis equal; axis tight; axis off;
        view(90,0)   

    elseif obj.Nsurfs == 2;

        subplot(1,11,1:5);
        h(1) = patch('vertices',lVert,'faces', lFace,'FaceVertexCdata',col1);
        shading interp;
        axis equal; axis tight; axis off;
        view(270,0)

    elseif obj.Nsurfs == 1.9;
        
        subplot(1,24,1:10);
        h(1) = patch('vertices',lVert,'faces', lFace,'FaceVertexCdata',col1);
        shading interp;
        axis equal; axis tight; axis off;
        view(270,0)
        
        subplot(1,24,13:22);
        h(2) = patch('vertices',lVert,'faces', lFace,'FaceVertexCdata',col1);
        shading interp;
        axis equal; axis tight; axis off;
        view(90,0)
        
    elseif obj.Nsurfs == -1;    
        
        subplot(1,11,1:10);
        h(1) = patch('vertices',lVert,'faces', lFace,'FaceVertexCdata',col1);
        shading interp;
        axis equal; axis tight; axis off;
        if ~obj.medialflag, view(270,0); end
        
    end

    c = rShade;
    c = demean(c);
    c = c./spm_range(c);
    c = c.*diff(rang);
    c = c-min(c)+rang(1);
    
    col2 = [c c c];
    
    if obj.Nsurfs == 4;
        
        subplot(2,12,6:10);
        h(3) = patch('vertices',rVert,'faces', rFace,'FaceVertexCdata',col2);
        shading interp;
        axis equal; axis tight; axis off
        view(90,0)
        
        subplot(2,12,18:22);
        h(4) = patch('vertices',rVert,'faces', rFace,'FaceVertexCdata',col2);
        shading interp;
        axis equal; axis tight; axis off
        view(270,0)
        
    elseif obj.Nsurfs == 2;
        
        subplot(1,11,6:10);
        h(2) = patch('vertices',rVert,'faces', rFace,'FaceVertexCdata',col2);
        shading interp;
        axis equal; axis tight; axis off
        view(90,0)
        
    elseif obj.Nsurfs == 2.1;
        
        subplot(1,24,1:10);
        h(3) = patch('vertices',rVert,'faces', rFace,'FaceVertexCdata',col2);
        shading interp;
        axis equal; axis tight; axis off
        view(90,0)
        
        subplot(1,24,13:22);
        h(4) = patch('vertices',rVert,'faces', rFace,'FaceVertexCdata',col2);
        shading interp;
        axis equal; axis tight; axis off
        view(270,0)
        
    elseif obj.Nsurfs == 1;
        
        subplot(1,11,1:10);
        h(1) = patch('vertices',rVert,'faces', rFace,'FaceVertexCdata',col2);
        shading interp;
        axis equal; axis tight; axis off
        view(90,0)
        
    end
        
else
    
    tmp     = get(obj.figno,'UserData');
    col1    = tmp{1};
    col2    = tmp{2};
    h       = tmp{3};
    
end

%%%
lMNI    = T.map.lMNI;
lv      = T.map.lv;
rMNI    = T.map.rMNI;
rv      = T.map.rv;
try
    m = obj.input.m;
    he = obj.input.he;
catch
    he = obj.input;
    m = spm_read_vols(he);
end
[x y z]     = ind2sub(he.dim,(1:numel(m))');
mat         = [x y z ones(numel(z),1)];
mni         = mat*he.mat';
mni         = mni(:,1:3);

if obj.reverse==1, m = m*-1; end

% keyboard;
if ~isempty(obj.mappingfile);

    load(obj.mappingfile);
    lVoxels = MP.lVoxels;
    rVoxels = MP.rVoxels;
    lWeights = MP.lWeights;
    rWeights = MP.rWeights;    
    lVals = m(lVoxels);
    lWeights(isnan(lVals))=NaN;
    lVals = nansum(lVals.*lWeights,2)./nansum(lWeights,2);
    rVals = m(rVoxels);
    rWeights(isnan(rVals))=NaN;
    rVals = nansum(rVals.*rWeights,2)./nansum(rWeights,2);

else    
    
    if isfield(obj,'nearestneighbor') && obj.nearestneighbor == 1;
        mloc = ([T.map.lMNI ones(size(T.map.lMNI,1),1)]*inv(he.mat'));
        lVoxels = sub2ind(he.dim,round(mloc(:,1)),round(mloc(:,2)),round(mloc(:,3)));
        lWeights = 1;
        mloc = ([T.map.rMNI ones(size(T.map.rMNI,1),1)]*inv(he.mat'));
        rVoxels = sub2ind(he.dim,round(mloc(:,1)),round(mloc(:,2)),round(mloc(:,3)));
        rWeights = 1;
    else
        mloc = ([T.map.lMNI ones(size(T.map.lMNI,1),1)]*inv(he.mat'));
        lVoxels = [sub2ind(he.dim,floor(mloc(:,1)),floor(mloc(:,2)),floor(mloc(:,3))) sub2ind(he.dim,ceil(mloc(:,1)),ceil(mloc(:,2)),ceil(mloc(:,3))) sub2ind(he.dim,round(mloc(:,1)),round(mloc(:,2)),round(mloc(:,3)))];
        lWeights = (1/3);
        mloc = ([T.map.rMNI ones(size(T.map.rMNI,1),1)]*inv(he.mat'));
        rVoxels = [sub2ind(he.dim,floor(mloc(:,1)),floor(mloc(:,2)),floor(mloc(:,3))) sub2ind(he.dim,ceil(mloc(:,1)),ceil(mloc(:,2)),ceil(mloc(:,3))) sub2ind(he.dim,round(mloc(:,1)),round(mloc(:,2)),round(mloc(:,3)))];
        rWeights = (1/3);
    end
    lVals = nansum(m(lVoxels).*lWeights,2);
    rVals = nansum(m(rVoxels).*rWeights,2);
end
if isfield(obj,'round') && obj.round == 1;
    lVals = round(lVals);
    rVals = round(rVals);
end
if numel(obj.overlaythresh) == 1;
    if obj.direction == '+'
        ind1 = find(lVals>obj.overlaythresh);
        ind2 = find(rVals>obj.overlaythresh);
    elseif obj.direction == '-'
        ind1 = find(lVals>obj.overlaythresh);
        ind2 = find(rVals>obj.overlaythresh);
    end
else
    ind1 = find(lVals<=obj.overlaythresh(1) | lVals>=obj.overlaythresh(2));
    ind2 = find(rVals<=obj.overlaythresh(1) | rVals>=obj.overlaythresh(2));
end
%%%
val = max([abs(min([lVals; rVals])) abs(max([lVals; rVals]))]);
if obj.colorlims(1) == -inf
    obj.colorlims(1)=-val;
end
if obj.colorlims(2) == inf
    obj.colorlims(2)=val;
end

% obj.colormap = cmap_upsample(obj.colormap, length(ind1)); 
[cols, CD] = cmap(lVals(ind1), obj.colorlims, obj.colormap);
col = nan(size(col1));
col(lv(ind1)+1,:) = cols;
if obj.Nsurfs == 4;
    
    subplot(2,12,1:5);
    hh(1) = patch('vertices',lVert,'faces', lFace,'FaceVertexCdata',col);
    shading interp
    
    subplot(2,12,13:17);
    hh(2) = patch('vertices',lVert,'faces', lFace,'FaceVertexCdata',col);
    shading interp;
    
elseif obj.Nsurfs == 1.9;
    
    subplot(1,24,1:10);
    hh(1) = patch('vertices',lVert,'faces', lFace,'FaceVertexCdata',col);
    shading interp
    
    subplot(1,24,13:22);
    hh(2) = patch('vertices',lVert,'faces', lFace,'FaceVertexCdata',col);
    shading interp;    
    
elseif obj.Nsurfs == 2;
    
    subplot(1,11,1:5);
    hh(1) = patch('vertices',lVert,'faces', lFace,'FaceVertexCdata',col);
    shading interp
    
elseif obj.Nsurfs == -1;
    
    subplot(1,11,1:10);
    hh(1) = patch('vertices',lVert,'faces', lFace,'FaceVertexCdata',col);
    shading interp
    if obj.medialflag
        view(90,0)
    end
    
end
[cols CD] = cmap(rVals(ind2), obj.colorlims ,obj.colormap);
col = nan(size(col2));
col(rv(ind2)+1,:) = cols;
if obj.Nsurfs == 4;
    
    subplot(2,12,6:10);
    hh(3) = patch('vertices',rVert,'faces', rFace,'FaceVertexCdata',col);
    shading interp
    
    subplot(2,12,18:22);
    hh(4) = patch('vertices',rVert,'faces', rFace,'FaceVertexCdata',col);
    shading interp;
    
elseif obj.Nsurfs == 2.1;
    
    subplot(1,24,1:10);
    hh(3) = patch('vertices',rVert,'faces', rFace,'FaceVertexCdata',col);
    shading interp
    
    subplot(1,24,13:22);
    hh(4) = patch('vertices',rVert,'faces', rFace,'FaceVertexCdata',col);
    shading interp;    
    
elseif obj.Nsurfs == 2;
    
    subplot(1,11,6:10);
    hh(2) = patch('vertices',rVert,'faces', rFace,'FaceVertexCdata',col);
    shading interp
    
elseif obj.Nsurfs == 1;
    
    subplot(1,11,1:10);
    hh(1) = patch('vertices',rVert,'faces', rFace,'FaceVertexCdata',col);
    shading interp

end

set(gcf,'UserData',{col1 col2,h});
drawnow;

if obj.cmapflag

    if      obj.Nsurfs == 4, subplot(2,12,[12 24])
    elseif  obj.Nsurfs == 1.9 || obj.Nsurfs == 2.1; subplot(1, 22, 22);
    else    subplot(1,11,11); 
    end
    cla
    mp = [];
    mp(1:256,1,1:3) = CD;
    ch = imagesc((1:256)');
    set(ch,'CData',mp)
    apos = get(gca, 'position');

    % | Figure out positioning
    for i = 1:length(hh), pos(i,:) = get(get(hh(i), 'parent'), 'position'); end
    rightedge   = max(sum(pos(:,[1 3]), 2));
    topedge     = max(sum(pos(:,[2 4]), 2));
    bottomedge  = min(pos(:,2));
    spacer      = .075;
    apos(1)     = rightedge + (spacer/2); 
    apos(2)     = bottomedge + spacer; 
    apos(4)     = 1 - (apos(2)*2); 
    set(gca, 'position', apos); 
    yl          = obj.colorlims;
    tickmark    = [ceil(min(yl)) floor(max(yl))];
    tickmark(abs(yl) < 1) = yl(abs(yl) < 1); 
    try
        [cl, trash, indice] = cmap(obj.overlaythresh, [ceil(min(obj.colorlims)) floor(max(obj.colorlims))], obj.colormap);
    catch
        keyboard; 
    end
    if strcmpi(obj.direction, '+/-') & min(tickmark)<0
        tickmark = [tickmark(1) 0 tickmark(2)]; 
    end
    ytick       = unique(sort([1 255 indice(:)']));
%     ticklabel   = unique(sort([obj.colorlims(1) mean(obj.colorlims) obj.colorlims(2) obj.overlaythresh])');
    set(gca,'YDir','normal','YAxisLocation','right','XTick',[],'YTick', ytick, 'YTickLabel',tickmark,'fontsize',16,'YColor','w');
    shading interp

end

% final cleanup
set(obj.figno, 'units', 'points', 'paperunits', 'points');
figpos = get(obj.figno, 'pos');
set(obj.figno, 'papersize', figpos(3:4), 'paperposition', [0 0 figpos(3:4)], 'visible', 'on');
tightfig(obj.figno);

function y = spm_range(x,dim)
% Computes the difference between the min and max of a vector. If you need
% to use it on a matrix, then you need to specify which dimension to
% operate on.
if nargin < 2
    y = max(x) - min(x);
else
    y = max(x,[],dim) - min(x,[],dim);
end

function [cols, cm ,cc] = cmap(X, lims, cm)
    %%% Written by Aaron P. Schultz - aschultz@martinos.org
    %%%
    %%% Copyright (C) 2014,  Aaron P. Schultz
    %%%
    %%% Supported in part by the NIH funded Harvard Aging Brain Study (P01AG036694) and NIH R01-AG027435 
    %%%
    %%% This program is free software: you can redistribute it and/or modify
    %%% it under the terms of the GNU General Public License as published by
    %%% the Free Software Foundation, either version 3 of the License, or
    %%% any later version.
    %%% 
    %%% This program is distributed in the hope that it will be useful,
    %%% but WITHOUT ANY WARRANTY; without even the implied warranty of
    %%% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    %%% GNU General Public License for more details.X = X(:);
    lims = sort(lims);
    nBins = 256;
    if ischar(cm)
        eval(['cm = colmap(''' cm ''',' num2str(nBins) ');']);
    elseif size(cm, 1)~=nBins
        cm = cmap_upsample(cm, nBins);  
    end
    X(find(X<lims(1)))=lims(1);
    X(find(X>lims(2)))=lims(2);
    cc = [X(:); lims(:)];
    cc = cc/(diff(lims));
    cc = (cc*(nBins));
    dd = cc;
    cc = cc+(nBins-max(cc));
    cc = floor(cc(1:end-2))+1;
    cc(cc>nBins)=nBins;
    cc(cc<1)=1;
    cols = nan(numel(cc),3);
    cols(~isnan(cc),:) = cm(cc(~isnan(cc)),:);

function X = demean(x)
%%% Written by Aaron Schultz (aschultz@martinos.org)
%%% Copyright (C) 2014,  Aaron P. Schultz
%%%
%%% Supported in part by the NIH funded Harvard Aging Brain Study (P01AG036694) and NIH R01-AG027435 
%%%
%%% This program is free software: you can redistribute it and/or modify
%%% it under the terms of the GNU General Public License as published by
%%% the Free Software Foundation, either version 3 of the License, or
%%% any later version.
%%% 
%%% This program is distributed in the hope that it will be useful,
%%% but WITHOUT ANY WARRANTY; without even the implied warranty of
%%% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%%% GNU General Public License for more details.
X = x-repmat(mean(x),size(x,1),1);
function out = cmap_upsample(in, N)
    num = size(in,1);
    ind = repmat(1:num, ceil(N/num), 1);
    rem = numel(ind) - N; 
    if rem, ind(end,end-rem+1:end) = NaN; end
    ind = ind(:); ind(isnan(ind)) = [];
    out = in(ind(:),:);
    
function y = nansum(x,dim)
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
%    author:      Jan Gläscher
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