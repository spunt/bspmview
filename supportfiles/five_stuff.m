function tmp
drawFresh(ax1,1);
drawFresh(ax2,2);
drawFresh(ax3,3);
% Link CrossHair Positions
hListener1 = addlistener(ch(1,1),'XData','PostSet',@AutoUpdate);
hListener2 = addlistener(ch(2,1),'XData','PostSet',@AutoUpdate);
hListener3 = addlistener(ch(1,2),'YData','PostSet',@AutoUpdate);


function setupFigure

tss = Obj(1).axLims;

tmp = [1 1 1];
tss = tss.*tmp;

height = tss(2)+tss(3);
width =  tss(1)+tss(2);
rat = height/width;

ff = get(0,'ScreenSize');

if ff(4)>800
    pro = 3.25;
else
    pro = 2.5;
end
%         [junk user] = UserTime;  if strcmp(user,'aschultz'); keyboard; end

ss = get(0,'ScreenSize');
if (ss(3)/ss(4))>2
    ss(3)=ss(3)/2;
end
op = floor([50 ss(4)-75-((ss(3)/pro)*rat)  ss(3)/pro (ss(3)/pro)*rat]);

pane = figure;

set(gcf, 'Position', op,'toolbar','none', 'Name', 'FIVE','Visible','off');
set(gcf, 'WindowButtonUpFcn', @buttonUp);
set(gcf, 'WindowButtonDownFcn', @buttonDown);
set(gcf, 'WindowButtonMotionFcn', @buttonMotion);
set(gcf, 'ResizeFcn', @resizeFig);
set(gcf, 'WindowKeyPressFcn', @keyMove);
set(gcf, 'WindowScrollWheelFcn',@scrollMove);
set(gcf, 'WindowKeyReleaseFcn',@keyHandler);

hcmenu = uicontextmenu;
set(hcmenu,'CallBack','movego = 0;');
item = [];

wid(1) = tss(2)/width;
hei(1) = tss(3)/height;
wid(2) = tss(1)/width;
hei(2) = tss(3)/height;
wid(3) = tss(1)/width;
hei(3) = tss(2)/height;

ax1 = axes; set(ax1,'Color','k','Position',[wid(2) hei(3) wid(1) hei(1)],'XTick',[],'YTick',[]); hold on; colormap(gray(256));
ax2 = axes; set(ax2,'Color','k','Position',[0      hei(3) wid(2) hei(2)],'XTick',[],'YTick',[]); hold on; colormap(gray(256));
ax3 = axes; set(ax3,'Color','k','Position',[0      0      wid(3) hei(3)],'XTick',[],'YTick',[]); hold on; colormap(gray(256));
ax4 = axes; set(ax4,'Color','w','Position',[wid(2) 0      .04     hei(3)*.99],'XTick',[],'YAxisLocation','right','YTick',[]);

%st = wid(2)+.01+.04+.03;
st = wid(2)+.125;
len1 = (1-st)-.01;
len2 = len1/2;
len3 = len1/3;
len4 = len1/4;
inc = (hei(3))/11;
inc2 = .75*inc;

con(27,1)   = uicontrol(pane,'style','slider',    'Units','Normalized','Position',[wid(2)+.045      0  .025   hei(3)*.9],'Value',.8,'CallBack', @adjustUnderlay);
con(28,1)   = uicontrol(pane,'style','slider',    'Units','Normalized','Position',[wid(2)+.070      0  .025   hei(3)*.9],'Value',.15,'CallBack', @adjustUnderlay);
con(29,1)   = uicontrol(pane,'style','slider',    'Units','Normalized','Position',[wid(2)+.095      0  .025   hei(3)*.9],'Value',0,'CallBack', @adjustUnderlay);
con(30,1)   = uicontrol(pane,'style','edit',       'Units','Normalized','Position',[wid(2)+.0450    hei(3)*.9   .075 .05]);
% con(28,1)   = uicontrol(pane,'style','slider',    'Units','Normalized','Position',[st-.1          (.01+(1*inc)+(0*inc2))  len1*.75   inc],'Value',1,'CallBack', @adjustTrans);
con(1,1)   = uicontrol(pane,'style','popupmenu', 'Units','Normalized','Position',[st          .01+(0*inc)+(0*inc2)    len1   inc],'String',[{'Colormap'} cmaps(:)'],'CallBack', @changeColorMap); shg
%con(1,1)   = uicontrol(pane,'style','popupmenu', 'Units','Normalized','Position',[st          .01+(0*inc)+(0*inc2)    len1   inc],'String',[{'Colormap' 'A' 'B' 'C' 'D'}],'CallBack', @changeColorMap); shg
con(2,1)   = uicontrol(pane,'style','slider',    'Units','Normalized','Position',[st          (.01+(1*inc)+(0*inc2))  len1*.75   inc],'Value',1,'CallBack', @adjustTrans);
con(23,1)  = uicontrol(pane,'style','pushbutton','Units','Normalized','Position',[st+len1*.75 (.01+(1*inc)+(0*inc2))  len1*.25   inc],'String','All','CallBack', @applyToAll);
con(3,1)   = uicontrol(pane,'style','text',      'Units','Normalized','Position',[st          .01+(2*inc)+(0*inc2)  len1   inc2],'String', 'Transparency','fontsize',12);
con(4,1)   = uicontrol(pane,'style','edit',      'Units','Normalized','Position',[st          .01+(2*inc)+(1*inc2)  len2   inc],'CallBack',@UpdateThreshold);
con(5,1)   = uicontrol(pane,'style','edit',      'Units','Normalized','Position',[st+len2     .01+(2*inc)+(1*inc2)  len2   inc],'CallBack',@UpdateThreshold);
con(6,1)   = uicontrol(pane,'style','text',      'Units','Normalized','Position',[st          .01+(3*inc)+(1*inc2)  len2   inc2],'String', 'Thresh','fontsize',12);
con(7,1)   = uicontrol(pane,'style','text',      'Units','Normalized','Position',[st+len2     .01+(3*inc)+(1*inc2)  len2   inc2],'String', 'Color Limits','fontsize',12);
con(8,1)   = uicontrol(pane,'style','edit',      'Units','Normalized','Position',[st          .01+(3*inc)+(2*inc2)  len3   inc],'CallBack',@UpdatePVal);
con(9,1)   = uicontrol(pane,'style','edit',      'Units','Normalized','Position',[st+len3     .01+(3*inc)+(2*inc2)  len3   inc],'CallBack',@UpdatePVal);
con(23,1)  = uicontrol(pane,'style','edit',      'Units','Normalized','Position',[st+len3+len3     .01+(3*inc)+(2*inc2)  len3   inc],'CallBack',@ExtentThresh);
con(10,1)  = uicontrol(pane,'style','text',      'Units','Normalized','Position',[st          .01+(4*inc)+(2*inc2)  len3   inc2],'String', 'DF','fontsize',12);
con(11,1)  = uicontrol(pane,'style','text',      'Units','Normalized','Position',[st+len3     .01+(4*inc)+(2*inc2)  len3   inc2],'String', 'P-Value','fontsize',12);
con(24,1)  = uicontrol(pane,'style','text',      'Units','Normalized','Position',[st+len3+len3     .01+(4*inc)+(2*inc2)  len3   inc2],'String', 'Extent','fontsize',12);
con(15,1)  = uicontrol(pane,'style','edit',      'Units','Normalized','Position',[st          .01+(4*inc)+(3*inc2)  len2   inc],'String',num2str(loc),'CallBack',@goTo);
%con(15,1)  = uicontrol(pane,'style','edit',      'Units','Normalized','Position',[st          .01+(4*inc)+(3*inc2)  len2   inc],'String',['0 0 0'],'CallBack',@goTo);
con(25,1)  = uicontrol(pane,'style','pushbutton','Units','Normalized','Position',[st+len2     .01+(4*inc)+(3*inc2)  len2/2   inc],'String','FDR','CallBack', @correctThresh);
con(26,1)  = uicontrol(pane,'style','pushbutton','Units','Normalized','Position',[st+(len2*1.5)  .01+(4*inc)+(3*inc2)  len2/2   inc],'String','FWE','CallBack', @correctThresh);
con(17,1)  = uicontrol(pane,'style','text',      'Units','Normalized','Position',[st          .01+(5*inc)+(3*inc2)  len2   inc2],'String', 'MNI Coord',  'fontsize',12);
con(18,1)  = uicontrol(pane,'style','text',      'Units','Normalized','Position',[st+len2     .01+(5*inc)+(3*inc2)  len2   inc2],'String', 'MC Correct','fontsize',12);
con(12,1)  = uicontrol(pane,'style','pushbutton','Units','Normalized','Position',[st          .01+(5*inc)+(4*inc2) len2   inc],'String',{'Move Up'},'CallBack',@changeLayer);
con(13,1)  = uicontrol(pane,'style','pushbutton','Units','Normalized','Position',[st+len2     .01+(5*inc)+(4*inc2) len2   inc],'String',{'Move Down'},'CallBack',@changeLayer);
con(21,1)  = uicontrol(pane,'style','popupmenu', 'Units','Normalized','Position',[st          .01+(5*inc)+(5*inc2) len1   inc],'String',{'Overlays'},'CallBack',@switchObj);
con(22,1)  = uicontrol(pane,'style','edit',      'Units','Normalized','Position',[wid(2)-(len2/2) hei(3)-(inc*1.05) (len2/2) inc]);
con(19,1)  = uicontrol(pane,'style','PushButton','Units','Normalized','Position',[st          .01+(6*inc)+(5*inc2) len2   inc],'String','Open Overlay','FontWeight','Bold','CallBack',@openOverlay);
con(20,1)  = uicontrol(pane,'style','PushButton','Units','Normalized','Position',[st+len2     .01+(6*inc)+(5*inc2) len2   inc],'String','Remove Volume', 'FontWeight','Bold','CallBack',@removeVolume);
menu(1) = uimenu(pane,'Label','Options');
menu(2) = uimenu(menu(1),'Label','CrossHair Toggle','Checked','on','CallBack', @toggleCrossHairs);
menu(43) = uimenu(menu(1),'Label','Reverse Image','CallBack', @changeSign);
menu(15) = uimenu(menu(1),'Label','Change Underlay','CallBack', @changeUnderlay);
menu(3) = uimenu(menu(1),'Label','Send Overlay To New Fig','CallBack',@newFig);
if nargin<2
    menu(4) = uimenu(menu(1),'Label','Sync Views','Enable','on','CallBack',@syncViews);
else
    menu(4) = uimenu(menu(1),'Label','Sync Views','Enable','on','Checked','on','CallBack',@syncViews);
end
menu(16) = uimenu(menu(1),'Label','SliceViews');
menu(6) = uimenu(menu(16),'Label','Axial Slice View','CallBack',@axialView);
menu(7) = uimenu(menu(16),'Label','Coronal Slice View','CallBack',@coronalView);
menu(8) = uimenu(menu(16),'Label','Sagittal Slice View','CallBack',@sagittalView);
menu(9) = uimenu(menu(16),'Label','All Slice View','CallBack',@allSliceView);
menu(17) = uimenu(menu(1),'Label','Ploting');
menu(10) = uimenu(menu(17),'Label','Load Plot Data','CallBack',@loadData);
menu(13) = uimenu(menu(17),'Label','JointPlot','CallBack',@JointPlot);
menu(12) = uimenu(menu(17),'Label','PaperPlot-Vert','CallBack',@PaperFigure_Vert);
menu(33) = uimenu(menu(17),'Label','PaperPlot-Horz','CallBack',@PaperFigure_Horz);
menu(23) = uimenu(menu(17),'Label','PaperPlot Overlay','Checked','off','CallBack', @toggle);
menu(41) = uimenu(menu(17),'Label','Surface Render','Checked','off','CallBack', @surfView);
menu(5) = uimenu(menu(1),'Label','Glass Brain', 'CallBack', @glassBrain);
menu(14) = uimenu(menu(1),'Label','Transparent Overlay','CallBack',@TestFunc);
menu(11) = uimenu(menu(1),'Label','Get Peak Info','CallBack',@getPeakInfo);
menu(25) = uimenu(menu(1),'Label','Resample');
menu(26) = uimenu(menu(25),'Label','.5x.5x.5', 'CallBack', @resampleIm);
menu(27) = uimenu(menu(25),'Label','1x1x1'   , 'CallBack', @resampleIm);
menu(28) = uimenu(menu(25),'Label','2x2x2'   , 'CallBack', @resampleIm);
menu(29) = uimenu(menu(25),'Label','3x3x3'   , 'CallBack', @resampleIm);
menu(30) = uimenu(menu(25),'Label','4x4x4'   , 'CallBack', @resampleIm);
menu(31) = uimenu(menu(25),'Label','5x5x5'   , 'CallBack', @resampleIm);
menu(32) = uimenu(menu(25),'Label','6x6x6'   , 'CallBack', @resampleIm);
menu(18) = uimenu(menu(1),'Label','Save Options');
menu(19) = uimenu(menu(18),'Label','Save Thresholded Image','Enable','on','CallBack',@saveImg);
menu(20) = uimenu(menu(18),'Label','Save Masked Image','Enable','on','CallBack',@saveImg);
menu(21) = uimenu(menu(18),'Label','Save Cluster Image','Enable','on','CallBack',@saveImg);
menu(22) = uimenu(menu(18),'Label','Save Cluster Mask','Enable','on','CallBack',@saveImg);
menu(34) = uimenu(menu(1),'Label','Mask');
menu(35) = uimenu(menu(34),'Label','Mask In','Enable','on','CallBack',@maskImage);
menu(36) = uimenu(menu(34),'Label','Mask Out','Enable','on','CallBack',@maskImage);
menu(37) = uimenu(menu(34),'Label','Un-Mask','Enable','on','CallBack',@maskImage);
menu(38) = uimenu(menu(1),'Label','Movie Mode','Enable','on','CallBack',@movieMode);
menu(39) = uimenu(menu(1),'Label','Conn Explore','Enable','on','CallBack',@initializeConnExplore);
menu(40) = uimenu(menu(1),'Label','SS Connectivity','Enable','on','CallBack',@ssConn);
item(1) = uimenu(hcmenu, 'Label', 'Go to local max',  'Callback', @gotoMinMax);
item(2) = uimenu(hcmenu, 'Label', 'Go to local min',  'Callback', @gotoMinMax);
item(3) = uimenu(hcmenu, 'Label', 'Go to global max',  'Callback', @gotoMinMax);
item(4) = uimenu(hcmenu, 'Label', 'Go to global min',  'Callback', @gotoMinMax);
item(5) = uimenu(hcmenu, 'Label', 'Plot Cluster', 'Callback', @plotVOI);
item(6) = uimenu(hcmenu, 'Label', 'Plot Sphere', 'Callback', @plotVOI);
item(7) = uimenu(hcmenu, 'Label', 'Plot Voxel',  'Callback', @plotVOI);
item(8) = uimenu(hcmenu, 'Label', 'Plot Cached Cluster',  'Callback', @plotVOI);
item(9) = uimenu(hcmenu, 'Label', 'Cache Cluster Index',  'Callback', @CachedPlot);
%item(8) = uimenu(hcmenu, 'Label', 'RegionName',  'Callback', @regionName);
menu(42) = uimenu(menu(1),'Label','Return Obj','Checked','off','CallBack', @returnInfo);
%menu(43) = uimenu(menu(1),'Label','Return Obj as Global','Checked','off','CallBack', @returnInfoGlob);
Obj(1).ax1 = ax1;
Obj(1).ax2 = ax2;
Obj(1).ax3 = ax3;
Obj(1).ax4 = ax4;
Obj(1).con = con;
Obj(1).menu = menu;
function setupFrames(n,opt)
for ii = n;
    ss = Obj(ii).axLims;            
    if Obj(ii).point(1)~=Obj(ii).lastpoint(1) || opt==1
        tmp = Obj(ii).I(Obj(ii).point(1),:,:);
        tmp(Obj(ii).mask(Obj(ii).point(1),:,:)==0)=NaN;
        if numel(Obj(ii).Thresh)==2
            ind = find(tmp<Obj(ii).Thresh(1) | tmp>Obj(ii).Thresh(2));
        else
            ind = find(tmp<Obj(ii).Thresh(1) | tmp>Obj(ii).Thresh(4) | (tmp>Obj(ii).Thresh(2) & tmp<Obj(ii).Thresh(3)));
        end
        tmp(ind) = NaN;
        tmp(tmp==0)=NaN;
        tmp = flip(rot90(squeeze(tmp),1),1);
        [cols cm cc] = cmap(tmp, Obj(ii).clim, cmaps{Obj(ii).col});
        Obj(ii).frame{1} = reshape(cols,[size(tmp) 3]);
    end
    if Obj(ii).point(2)~=Obj(ii).lastpoint(2) || opt==1
        tmp = Obj(ii).I(:,Obj(ii).point(2),:);
        tmp(Obj(ii).mask(:,Obj(ii).point(2),:)==0)=NaN;
        if numel(Obj(ii).Thresh)==2
            ind = find(tmp<Obj(ii).Thresh(1) | tmp>Obj(ii).Thresh(2));
        else
            ind = find(tmp<Obj(ii).Thresh(1) | tmp>Obj(ii).Thresh(4) | (tmp>Obj(ii).Thresh(2) & tmp<Obj(ii).Thresh(3)));
        end
        tmp(ind) = NaN;
        tmp(tmp==0)=NaN;
        tmp = flip(flip(rot90(squeeze(tmp),1),1),2);
        [cols cm cc] = cmap(tmp, Obj(ii).clim, cmaps{Obj(ii).col});
        Obj(ii).frame{2} = reshape(cols,[size(tmp) 3]);
    end
    if Obj(ii).point(3)~=Obj(ii).lastpoint(3) || opt==1
        tmp = Obj(ii).I(:,:,Obj(ii).point(3));
        tmp(Obj(ii).mask(:,:,Obj(ii).point(3))==0)=NaN;
        if numel(Obj(ii).Thresh)==2
            ind = find(tmp<Obj(ii).Thresh(1) | tmp>Obj(ii).Thresh(2));
        else
            ind = find(tmp<Obj(ii).Thresh(1) | tmp>Obj(ii).Thresh(4) | (tmp>Obj(ii).Thresh(2) & tmp<Obj(ii).Thresh(3)));
        end
        tmp(ind) = NaN;
        tmp(tmp==0)=NaN;
        tmp = flip(flip(rot90(squeeze(tmp),1),1),2);
        [cols cm cc] = cmap(tmp, Obj(ii).clim, cmaps{Obj(ii).col});
        Obj(ii).frame{3} = reshape(cols,[size(tmp) 3]);
    end
end
function AutoUpdate(varargin)
    vn = get(con(21,1),'Value');
    y = get(ch(1,1),'XData');
    x = get(ch(2,1),'XData');
    z = get(ch(1,2),'YData');
    xyz = [x(1) y(1) z(1)];
    xyz((mniLims(1,:)-xyz)>0) = mniLims(1,(mniLims(1,:)-xyz)>0);
    xyz((mniLims(2,:)-xyz)<0) = mniLims(2,(mniLims(2,:)-xyz)<0);
    x = xyz(1); y = xyz(2); z = xyz(3);
    for ii = 1:length(Obj)
        Obj(ii).point =  ceil([x y z 1] * inv(Obj(ii).h.mat)');

        Obj(ii).point(Obj(ii).point(1:3)<1) = 1;
        ind = find((Obj(ii).axLims-Obj(ii).point(1:3))<0);
        Obj(ii).point(ind) = Obj(ii).axLims(ind);

        if ii == 1; 
            p = ceil([x y z 1] * inv(RNH.mat)');
           try
               nm = RNames.ROI(RNI(p(1),p(2),p(3)));
               set(paramenu1(2),'Label',nm.Nom_L); 
           catch
               set(paramenu1(2),'Label','undefined');
           end
        end
    end
    setupFrames(1:length(Obj),1);
    updateGraphics([1 2 3],0);
    set(con(15,1),'String',num2str(round([x y z])));
    mc = round([x y z 1] * inv(Obj(get(con(21,1),'Value')).h.mat)'); 
    vn = get(con(21,1),'Value');
    try
        set(con(22,1),'String',num2str(Obj(get(con(21,1),'Value')).I(mc(1),mc(2),mc(3))));
    catch
        set(con(22,1),'String','NaN');
    end
    shg
function drawFresh(axx,opt,opt2,opt3)
if nargin == 2;
    opt2 = 1:length(Obj);
end
if nargin < 4
    opt3 = 1;
end
axes(axx);

for ii = opt2;
    if opt == 1;
        tmp = image(Obj(ii).pos{2}, Obj(ii).pos{3}, Obj(ii).frame{opt});
        if opt3; hand{opt}(ii) = tmp; end
        set(tmp,'AlphaData', ~isnan(Obj(ii).frame{opt}(:,:,1))*Obj(ii).Trans);
        set(axx, 'YDir','Normal'); set(gca, 'XDir','reverse'); axis equal;
    end
    if opt == 2;
        tmp = image(Obj(ii).pos{1}, Obj(ii).pos{3}, Obj(ii).frame{opt});
        if opt3; hand{opt}(ii) = tmp; end
        set(tmp,'AlphaData', ~isnan(Obj(ii).frame{opt}(:,:,1))*Obj(ii).Trans);
        set(axx, 'YDir','Normal'); set(gca, 'XDir','Normal');axis equal;
    end
    if opt == 3;
        tmp = image(Obj(ii).pos{1}, Obj(ii).pos{2}, Obj(ii).frame{opt});
        if opt3; hand{opt}(ii) = tmp; end
        set(tmp,'AlphaData', ~isnan(Obj(ii).frame{opt}(:,:,1))*Obj(ii).Trans);
        set(axx, 'YDir','Normal'); set(gca, 'XDir','Normal');axis equal;
    end
end

set(axx,'XTick',[],'YTick',[]);
axis equal;
axis tight