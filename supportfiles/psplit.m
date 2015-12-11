function shpanel = psplit(hpanel, grididx, vertical, panelsep)
% PSPLIT Utility for splitting cells in a uipanel array created by PGRID
%
%  USAGE: shpanel = psplit(hpanel, grididx, vertical, panelsep)
%
%  INPUT
%   hpanel:     array of handles to uipanel grid (output from PGRID)
%   grididx:    index to uipanel to split
%   vertical:   flag to split vertical (top/bottom) rather than horizontal (left/right)
%   panelsep:   separation between the split panels
% ________________________________________________________________________________________
%
    if nargin < 2, disp('USAGE: shpanel = psplit(hpanel, grididx, vertical, panelsep)'); return; end
    if nargin < 3, vertical = 0; end
    if nargin < 4, panelsep = .005; end
    if length(grididx) > 1, disp('You can only split one panel at a time'); return; end
    p       = hpanel(grididx);
    ptag    = get(p, 'Tag');
    ppos    = get(p, 'pos');
    p1      = ppos;
    p2      = ppos;
    if vertical
        p1(4) = ppos(4)/2; 
        p2(4) = ppos(4)/2; 
        p2(2) = ppos(2) + ppos(4)/2 + panelsep; 
        ptag1  = sprintf('%s (lower)', ptag);
        ptag2  = sprintf('%s (upper)', ptag);  
    else
        p1(3) = ppos(3)/2; 
        p2(3) = ppos(3)/2; 
        p2(1) = ppos(1) + ppos(3)/2 + panelsep; 
        ptag1  = sprintf('%s (left)', ptag);
        ptag2  = sprintf('%s (right)', ptag);  
    end 
    set(p, 'position', p1, 'tag', ptag1);
    hp2 = copyobj(p, get(p, 'parent')); 
    set(hp2, 'position', p2, 'tag', ptag2); 
    drawnow;
    shpanel = gobjects(length(hpanel) + 1, 1);
    shpanel(1:grididx) = hpanel(1:grididx); 
    shpanel(grididx+1) = hp2;
    if length(shpanel) > grididx+1, shpanel(grididx+2:end) = hpanel(grididx+1:end); end
end
