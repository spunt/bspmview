function [mhpanel, mhpidx] = pmerge(hpanel, grididx)
% PMERGE Utility for merging cells in a uipanel array created by PGRID
%
%  USAGE: mhpanel = pmerge(hpanel, grididx)
%
%  INPUT
%   hpanel:     array of handles to uipanel grid (output from PGRID)
%   grididx:    indices to the uipanels to merge
% ________________________________________________________________________________________

if nargin < 2, disp('USAGE: mhpanel = pmerge(hgrid, grididx)'); mhpanel = []; return; end
p       = hpanel(grididx);
pidx    = get(p, 'UserData');
pidx    = cell2mat(vertcat(pidx{:})); 

% | GET DIMENSIONS 
ppos    = cell2mat(get(p, 'pos'));
ncell   = length(grididx);
urow    = unique(pidx(:,1));
ucol    = unique(pidx(:,2)); 
nrow    = length(urow);
ncol    = length(ucol);

% | CHECK VALIDITY
if all([nrow>1, ncol>1, mod(ncell, 2)]), error('Invalid grid indices!'); end
rowidx  = unique(pidx(:,1));
colidx  = unique(pidx(:,2)); 
if any(diff(rowidx)>1), error('Invalid row indices!'); end
if any(diff(colidx)>1), error('Invalid column indices'); end

% | COMPUTE WIDTH AND HEIGHT OF MERGED PANEL
pleft   = unique(ppos(:,1));
pright  = unique(sum(ppos(:,[1 3]), 2));
pbottom = unique(ppos(:,2)); 
ptop    = unique(sum(ppos(:,[2 4]), 2)); 
w       = max(pright) - min(pleft);
h       = max(ptop) - min(pbottom); 

% | DELETE OLD, CREATE NEW
urowtag = unique(pidx(:,1));
ucoltag = unique(pidx(:,2)); 
if nrow > 1
    rowtag = sprintf('%d:%d', urowtag(1), urowtag(end));
else
    rowtag = sprintf('%d', urowtag); 
end
if ncol > 1
    coltag = sprintf('%d:%d', ucoltag(1), ucoltag(end)); 
else
    coltag = sprintf('%d', ucoltag); 
end

mtag    = sprintf('[%s] x [%s]', rowtag, coltag);
userd   = {repmat(eval(rowtag)', ncol, 1) repmat(eval(coltag)', nrow, 1)};
mhgrid  = p(1);
delete(p(2:end));
mpos    = [min(ppos(:,1:2)) w h];
set(mhgrid, 'position', mpos, 'tag', mtag, 'userdata', userd);
drawnow; 
mhpanel = hpanel;
mhpanel(grididx(2:end)) = [];

if nargout==2
    mhpidx = get(mhpanel, 'UserData');
    mhpidx = [num2cell(1:length(mhpidx))' vertcat(mhpidx{:})];
    mhpidx(:,1) = cellfun(@repmat, mhpidx(:,1), num2cell(cellfun('length', mhpidx(:,2))), repmat({1}, length(mhpidx), 1), 'Unif', false); 
    mhpidx = cell2mat(mhpidx);
end

end
