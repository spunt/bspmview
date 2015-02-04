function [voxels, regions, invar]=peak_nii(image,mapparameters)
%%
% peak_nii will write out the maximum T (or F) of the local maxima that are
% not closer than a specified separation distance.  
% SPM=0: Those that are closer are collapsed based on the COG using number 
%   of voxels at each collapsing point. The maximum T 
%   (or F) is retained. This program should be similar to peak_4dfp in use at
%   WashU (although I haven't seen their code).
% SPM=1: Eliminates the peaks closer than a specified distance to mimic
%   result tables.
%
% INPUTS:
% image string required. This should be a nii or img file.
% mapparameters is either a .mat file or a pre-load structure with the
% following fields:
%           out: output prefix, default is to define using imagefile
%          sign: 'pos' or 'neg', default is 'pos' NOTE: only can do one
%                direction at a time
%          type: statistic type, 'T' or 'F' or 'none'
%      voxlimit: number of peak voxels in image
%    separation: distance to collapse or eliminate peaks
%           SPM: 0 or 1, see above for details
%          conn: connectivity radius, either 6,18, or 26
%       cluster: cluster extent threshold in voxels
%          mask: optional to mask your data
%           df1: numerator degrees of freedom for T/F-test (if 0<thresh<1)
%           df2: denominator degrees of freedom for F-test (if 0<thresh<1)
%       nearest: 0 or 1, 0 for leaving some clusters/peaks undefined, 1 for finding the
%                nearest label
%         label: optional to label clusters, options are 'aal_MNI_V4';
%                'Nitschke_Lab'; FSL ATLASES: 'JHU_tracts', 'JHU_whitematter',
%                'Thalamus', 'Talairach', 'MNI', 'HarvardOxford_cortex', 'Cerebellum-flirt', 'Cerebellum-fnirt', and 'Juelich'. 
%                'HarvardOxford_subcortical' is not available at this time because
%                the labels don't match the image.
%                Other atlas labels may be added in the future
%        thresh: T/F statistic or p-value to threshold the data or 0
%
% OUTPUTS:
%   voxels  -- table of peaks
%       cell{1}-
%         col. 1 - Cluster size
%         col. 2 - T/F-statistic
%         col. 3 - X coordinate
%         col. 4 - Y coordinate
%         col. 5 - Z coordinate
%         col. 6 - number of peaks collapsed
%         col. 7 - sorted cluster number
%       cell{2}- region names
%   regions -- region of each peak -- optional
%
% NIFTI FILES SAVED:
%   *_clusters.nii:                     
%                               contains the clusters and their numbers (column 7)
%   (image)_peaks_date_thresh*_cluster*.nii:             
%                               contains the thresholded data
%   (image)_peaks_date_thresh*_cluster*peaknumber.nii:   
%                               contains the peaks of the data,
%                               peaks are numbered by their order
%                               in the table (voxels)
%   (image)_peaks_date_thresh*_cluster*peakcluster.nii:  
%                               contains the peaks of the data,
%                               peaks are numbered by their cluster (column 7)
%   *(image) is the image name with the the path or extension
%
% MAT-FILES SAVED:
%   Peak_(image)_peaks_date.mat:        contains voxelsT variable and regions, if applicable 
%   (image)_peaks_date_structure:       contains parameter variable with
%                                       parameters used
%   *(image) is the image name with the the path or extension
%
% EXAMPLE: voxels=peak_nii('imagename',mapparameters)
%
% License:
%   Copyright (c) 2011, Donald G. McLaren and Aaron Schultz
%   All rights reserved.
%
%    Redistribution, with or without modification, is permitted provided that the following conditions are met:
%    1. Redistributions must reproduce the above copyright
%        notice, this list of conditions and the following disclaimer in the
%        documentation and/or other materials provided with the distribution.
%    2. All advertising materials mentioning features or use of this software must display the following acknowledgement:
%        This product includes software developed by the Harvard Aging Brain Project.
%    3. Neither the Harvard Aging Brain Project nor the
%        names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
%    4. You are not permitted under this Licence to use these files
%        commercially. Use for which any financial return is received shall be defined as commercial use, and includes (1) integration of all 	
%        or part of the source code or the Software into a product for sale or license by or on behalf of Licensee to third parties or (2) use 	
%        of the Software or any derivative of it for research with the final aim of developing software products for sale or license to a third 	
%        party or (3) use of the Software or any derivative of it for research with the final aim of developing non-software products for sale 
%        or license to a third party, or (4) use of the Software to provide any service to an external organisation for which payment is received.
%
%   THIS SOFTWARE IS PROVIDED BY DONALD G. MCLAREN (mclaren@nmr.mgh.harvard.edu) AND AARON SCHULTZ (aschultz@nmr.mgh.harvard.edu)
%   ''AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND 
%   FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL <COPYRIGHT HOLDER> BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, 
%   SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, 
%   DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR 
%   TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
%   USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
%
%   peak_nii.v3 -- Last modified on 12/10/2010 by Donald G. McLaren, PhD
%   (mclaren@nmr.mgh.harvard.edu)
%   Wisconsin Alzheimer's Disease Research Center - Imaging Core, Univ. of
%   Wisconsin - Madison
%   Neuroscience Training Program and Department of Medicine, Univ. of
%   Wisconsin - Madison
%   GRECC, William S. Middleton Memorial Veteren's Hospital, Madison, WI
%   GRECC, Bedford VAMC
%   Department of Neurology, Massachusetts General Hospital and Havard
%   Medical School
%
%   In accordance with the licences of the atlas sources as being distibuted solely
%   for non-commercial use; neither this program, also soley being distributed for non-commercial use,
%   nor the atlases containe herein should therefore not be used for commercial purposes; for such
%   purposes please contact the primary co-ordinator for the relevant
%   atlas:
%       Harvard-Oxford: steve@fmrib.ox.ac.uk
%       JHU: susumu@mri.jhu.edu
%       Juelich: S.Eickhoff@fz-juelich.de
%       Thalamus: behrens@fmrib.ox.ac.uk
%       Cerebellum: j.diedrichsen@bangor.ac.uk
%       AAL_MNI_V4: maldjian@wfubmc.edu and/or bwagner@wfubmc.edu
%
%   For the program in general, please contact mclaren@nmr.mgh.harvard.edu
%

global st

%% make sure image is char
if iscell(image), image = char(image); end

%% Check inputs
if exist(image,'file')==2
    I1=spm_vol(image);
    infoI1=I1;
    [I1,voxelcoord]=spm_read_vols(I1);
    if nansum(nansum(nansum(abs(I1))))==0
        error(['Error: ' image ' is all zeros or all NaNs'])        
    end
else
    error(['File ' image ' does not exist'])
end
try
if exist(mapparameters,'file')==2
    mapparameters=load(mapparameters);
end
end
invar=peak_nii_inputs(mapparameters,infoI1.fname,nargout);
if strcmpi(invar.sign,'neg')
    I1=-1.*I1;
end
I=I1; 

% Find significant voxels
ind=find(I>invar.thresh);
if isempty(ind)
    voxels=[]; regions={};
    display(['NO MAXIMA ABOVE ' num2str(invar.thresh) '.'])
    return
else
   [L(1,:),L(2,:),L(3,:)]=ind2sub(infoI1.dim,ind);
end

% Cluster signficant voxels
A=peakcluster(L,invar.conn,infoI1); % A is the cluster of each voxel
% A=transpose(A);
n=hist(A,1:max(A));
for ii=1:size(A,1)
    if n(A(ii))<invar.cluster % removes clusters smaller than extent threshold
        A(ii,1:2)=NaN;
    else
        A(ii,1:2)=[n(A(ii)) A(ii,1)];
    end
end

% Combine A (cluster labels) and L (voxel indicies)
L=L';
A(:,3:5)=L(:,1:3);

% Remove voxels that are in small clusters
A(any(isnan(A),2),:) = [];

% Save clusters
[T, Iclust]=peakcluster(transpose(A(:,3:5)),invar.conn,infoI1);
A(:,2)=T(:,1); clear T

% Find all peaks, only look at current cluster to determine the peak
Ic=zeros(infoI1.dim(1),infoI1.dim(2),infoI1.dim(3),max(A(:,2)));
for ii=1:max(A(:,2))
    Ic(:,:,:,ii)=I.*(Iclust==ii);
end
N=0;
voxelsT=zeros(size(A,1),7);
for ii=1:size(A,1)
    if A(ii,3)==1 || A(ii,4)==1 || A(ii,5)==1 || A(ii,3)==size(Ic,1) || A(ii,4)==size(Ic,2) || A(ii,5)==size(Ic,3)
    else
        if I(A(ii,3),A(ii,4),A(ii,5))==max(max(max(Ic(A(ii,3)-1:A(ii,3)+1,A(ii,4)-1:A(ii,4)+1,A(ii,5)-1:A(ii,5)+1,A(ii,2)))))
            N=N+1;
            voxind=sub2ind(infoI1.dim,A(ii,3),A(ii,4),A(ii,5));
            voxelsT(N,1)=A(ii,1);
            voxelsT(N,2)=I(voxind);
            voxelsT(N,3)=voxelcoord(1,voxind);
            voxelsT(N,4)=voxelcoord(2,voxind);
            voxelsT(N,5)=voxelcoord(3,voxind);
            voxelsT(N,6)=1;
            voxelsT(N,7)=A(ii,2);
        end
    end
end

%Remove empty rows
voxelsT=voxelsT(any(voxelsT'),:);
if isempty(voxelsT)
    voxels=[]; regions={};
    display(['NO CLUSTERS LARGER THAN ' num2str(invar.cluster) ' voxels.'])
    return
end

%Check number of peaks
if size(voxelsT,1)>invar.voxlimit
    voxelsT=sortrows(voxelsT,-2);
    voxelsT=voxelsT(1:invar.voxlimit,:); % Limit peak voxels to invar.voxlimit
end

% Sort table by cluster w/ max T then by T value within cluster (negative
% data was inverted at beginning, so we are always looking for the max).
uniqclust=unique(voxelsT(:,7));
maxT=zeros(length(uniqclust),2);
for ii=1:length(uniqclust)
    maxT(ii,1)=uniqclust(ii);
    maxT(ii,2)=max(voxelsT(voxelsT(:,7)==uniqclust(ii),2));
end
maxT=sortrows(maxT,-2);
for ii=1:size(maxT,1)
    voxelsT(voxelsT(:,7)==maxT(ii,1),8)=ii;
end
voxelsT=sortrows(voxelsT,[8 -2]);
[cluster,uniq,ind]=unique(voxelsT(:,8)); % get rows of each cluster

%Collapse or elimintate peaks closer than a specified distance
voxelsF=zeros(size(voxelsT,1),size(voxelsT,2));
nn=[1 zeros(1,length(cluster)-1)];
for numclust=1:length(cluster)
    Distance=eps;
    voxelsC=voxelsT(ind==numclust,:);
    while min(min(Distance(Distance>0)))<invar.separation
            [voxelsC,Distance]=vox_distance(voxelsC);
            minD=min(min(Distance(Distance>0)));
            if minD<invar.separation
               min_ind=find(Distance==(min(min(Distance(Distance>0)))));
               [ii,jj]=ind2sub(size(Distance),min_ind(1));
               if invar.SPM==1
                    voxelsC(ii,:)=NaN; % elimate peak
               else
                    voxelsC(jj,1)=voxelsC(jj,1);
                    voxelsC(jj,2)=voxelsC(jj,2);
                    voxelsC(jj,3)=((voxelsC(jj,3).*voxelsC(jj,6))+(voxelsC(ii,3).*voxelsC(ii,6)))/(voxelsC(jj,6)+voxelsC(ii,6)); % avg coordinate
                    voxelsC(jj,4)=((voxelsC(jj,4).*voxelsC(jj,6))+(voxelsC(ii,4).*voxelsC(ii,6)))/(voxelsC(jj,6)+voxelsC(ii,6)); % avg coordinate
                    voxelsC(jj,5)=((voxelsC(jj,5).*voxelsC(jj,6))+(voxelsC(ii,5).*voxelsC(ii,6)))/(voxelsC(jj,6)+voxelsC(ii,6)); % avg coordinate
                    voxelsC(jj,6)=voxelsC(jj,6)+voxelsC(ii,6);
                    voxelsC(jj,7)=voxelsC(jj,7);
                    voxelsC(jj,8)=voxelsC(jj,8);
                    voxelsC(ii,:)=NaN; % eliminate second peak
               end
               voxelsC(any(isnan(voxelsC),2),:) = [];
            end
    end
    try
        nn(numclust+1)=nn(numclust)+size(voxelsC,1);
    end
    voxelsF(nn(numclust):nn(numclust)+size(voxelsC,1)-1,:)=voxelsC;
end
voxelsT=voxelsF(any(voxelsF'),:);
clear voxelsF voxelsC nn

% Modify T-values for negative
if strcmpi(invar.sign,'neg')
    voxelsT(:,2)=-1*voxelsT(:,2);
end
voxelsT(:,7)=[];

% Label Peaks
allxyz = voxelsT(:,3:5);
regionname = cell(size(allxyz,1),1); 
for i = 1:size(allxyz,1)
    xyzidx      = bspm_XYZreg('FindXYZ', allxyz(i,:), st.ol.XYZmm0); 
    regionidx   = st.ol.atlas0(xyzidx);
    if regionidx
        regionname{i} = st.ol.atlaslabels.label{st.ol.atlaslabels.id==regionidx};
    else
        regionname{i} = 'Unknown Label'; 
    end
end
voxels = [regionname num2cell(voxelsT(:,1:5))]; 
function [N,Distance] = vox_distance(voxelsT)
% vox_distance compute the distance between local maxima in an image
% The input is expected to be an N-M matrix with columns 2,3,4 being X,Y,Z
% coordinates
%
% pdist is only available with Statistics Toolbox in recent versions of
% MATLAB, thus, the slower code is secondary if the toolbox is unavailable.
% Speed difference is dependent on cluster sizes, 3x at 1000 peaks.
N=sortrows(voxelsT,-1);
try
    Distance=squareform(pdist(N(:,3:5)));
catch
    Distance = zeros(size(N,1),size(N,1));
    for ii = 1:size(N,1);
        TmpD = zeros(size(N,1),3);
        for kk = 1:3;
            TmpD(:,kk) = (N(:,kk+2)-N(ii,kk+2)).^2;
        end
        TmpD = sqrt(sum(TmpD,2));
        Distance(:,ii) = TmpD;
    end
end
%Distance=zeros(length(N(:,1)),length(N(:,1)))*NaN;
%for ii=1:length(N(:,1))
%    for jj=ii+1:length(N(:,1))
%           Distance(ii,jj)=((N(jj,2)-N(ii,2)).^2)+((N(jj,3)-N(ii,3)).^2)+((N(jj,4)-N(ii,4)).^2);
%    end
%end
return
function [A, vol]=peakcluster(L,conn,infoI1)
    dim = infoI1.dim;
    vol = zeros(dim(1),dim(2),dim(3));
    indx = sub2ind(dim,L(1,:)',L(2,:)',L(3,:)');
    vol(indx) = 1;
    [cci,num] = spm_bwlabel(vol,conn);
    A = cci(indx');
    A=transpose(A);
    L=transpose(L);
    A(:,2:4)=L(:,1:3);
    vol=zeros(dim(1),dim(2),dim(3));
    for ii=1:size(A,1)
        vol(A(ii,2),A(ii,3),A(ii,4))=A(ii,1);
    end
function outstructure=peak_nii_inputs(instructure,hdrname,outputargs)
% Checks whether inputs are valid or not.
%   
%   ppi_nii_inputs.v2 last modified by Donald G. McLaren, PhD
%   (mclaren@nmr.mgh.harvard.edu)
%   GRECC, Bedford VAMC
%   Department of Neurology, Massachusetts General Hospital and Havard
%   Medical School
%
% License:
%   Copyright (c) 2011, Donald G. McLaren and Aaron Schultz
%   All rights reserved.
%
%    Redistribution, with or without modification, is permitted provided that the following conditions are met:
%    1. Redistributions must reproduce the above copyright
%        notice, this list of conditions and the following disclaimer in the
%        documentation and/or other materials provided with the distribution.
%    2. All advertising materials mentioning features or use of this software must display the following acknowledgement:
%        This product includes software developed by the Harvard Aging Brain Project.
%    3. Neither the Harvard Aging Brain Project nor the
%        names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
%    4. You are not permitted under this Licence to use these files
%        commercially. Use for which any financial return is received shall be defined as commercial use, and includes (1) integration of all 	
%        or part of the source code or the Software into a product for sale or license by or on behalf of Licensee to third parties or (2) use 	
%        of the Software or any derivative of it for research with the final aim of developing software products for sale or license to a third 	
%        party or (3) use of the Software or any derivative of it for research with the final aim of developing non-software products for sale 
%        or license to a third party, or (4) use of the Software to provide any service to an external organisation for which payment is received.
%
%   THIS SOFTWARE IS PROVIDED BY DONALD G. MCLAREN (mclaren@nmr.mgh.harvard.edu) AND AARON SCHULTZ (aschultz@nmr.mgh.harvard.edu)
%   ''AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND 
%   FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL <COPYRIGHT HOLDER> BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, 
%   SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, 
%   DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR 
%   TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
%   USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
%   
%   In accordance with the licences of the atlas sources as being distibuted solely
%   for non-commercial use; neither this program, also soley being distributed for non-commercial use,
%   nor the atlases containe herein should therefore not be used for commercial purposes; for such
%   purposes please contact the primary co-ordinator for the relevant
%   atlas:
%       Harvard-Oxford: steve@fmrib.ox.ac.uk
%       JHU: susumu@mri.jhu.edu
%       Juelich: S.Eickhoff@fz-juelich.de
%       Thalamus: behrens@fmrib.ox.ac.uk
%       Cerebellum: j.diedrichsen@bangor.ac.uk
%       AAL_MNI_V4: maldjian@wfubmc.edu and/or bwagner@wfubmc.edu
%
%   For the program in general, please contact mclaren@nmr.mgh.harvard.edu
%
%   Change Log:
%     4/11/2001: Allows threshold to be -Inf

%% Format input instructure
while numel(fields(instructure))==1
    F=fieldnames(instructure);
    instructure=instructure.(F{1}); %Ignore coding error flag.
end

%% outfile
try
    outstructure.out=instructure.out;
    if isempty(outstructure.out)
        vardoesnotexist; % triggers catch statement
    end
catch
    [path,file]=fileparts(hdrname);
    if ~isempty(path)
        outstructure.out=[path filesep file '_peaks_' date];
    else
        outstructure.out=[file '_peaks_' date];
    end
end

%% sign of data
try
    outstructure.sign=instructure.sign;
    if ~strcmpi(outstructure.sign,'pos') && ~strcmpi(outstructure.sign,'neg')
        vardoesnotexist; % triggers catch statement
    end
catch
    outstructure.sign='pos';
end

%% threshold
try
    outstructure.thresh=instructure.thresh;
    if ~isnumeric(outstructure.thresh)
        vardoesnotexist; % triggers catch statement
    end
    if outstructure.thresh<0
        if strcmpi(outstructure.sign,'neg')  
            outstructure.thresh=outstructure.thresh*-1;
        elseif outstructure.thresh==-Inf
        else
            vardoesnotexist; % triggers catch statement
        end
    end
catch
    outstructure.thresh=0;
end

%% statistic type (F or T)
try 
    outstructure.type=instructure.type;
    if ~strcmpi(outstructure.type,'T') && ~strcmpi(outstructure.type,'F') && ~strcmpi(outstructure.type,'none') && ~strcmpi(outstructure.type,'Z')
        vardoesnotexist; % triggers catch statement
    end
catch
    if outstructure.thresh<1 && outstructure.thresh>0
        error(['Statistic must defined using: ' instructure.type])
    else
        outstructure.type='none';
    end
end

%% voxel limit
try
    outstructure.voxlimit=instructure.voxlimit;
    if ~isnumeric(outstructure.voxlimit) || outstructure.voxlimit<0
        vardoesnotexist; % triggers catch statement
    end
catch
    outstructure.voxlimit=1000;
end

%% separation distance for peaks
try
    outstructure.separation=instructure.separation;
    if ~isnumeric(outstructure.separation) || outstructure.separation<0
        vardoesnotexist; % triggers catch statement
    end
catch
    outstructure.separation=20;
end

%% Output peaks or collapse peaks within a cluster (0 collapse peaks closer
% than separation distance, 1 remove peaks closer than separation distance
% to mirror SPM)
try
    outstructure.SPM=instructure.SPM;
    if ~isnumeric(outstructure.SPM) || (outstructure.SPM~=0 && outstructure.SPM~=1)
        vardoesnotexist; % triggers catch statement
    end
catch
    outstructure.SPM=1;
end
%% Connectivity radius
try
    outstructure.conn=instructure.conn;
    if ~isnumeric(outstructure.conn) || (outstructure.conn~=6 && outstructure.conn~=18 && outstructure.conn~=26)
        vardoesnotexist; % triggers catch statement
    end
catch
    outstructure.conn=18;
end
%% Cluster extent threshold
try
    outstructure.cluster=instructure.cluster;
    if ~isnumeric(outstructure.cluster) || outstructure.cluster<0
        vardoesnotexist; % triggers catch statement
    end
catch
    outstructure.cluster=0;
end
%% mask file
try
    outstructure.mask=instructure.mask;
    if ~isempty(outstructure.mask) && ~exist(outstructure.mask,'file')
        vardoesnotexist; % triggers catch statement
    end
catch
    outstructure.mask={};
end

%% degrees of freedom numerator
try
    outstructure.df1=instructure.df1;
    if ~isnumeric(outstructure.df1) || outstructure.df1<1
        vardoesnotexist; % triggers catch statement
    end
catch
    if (strcmpi(outstructure.type,'T') || strcmpi(outstructure.type,'F')) && (outstructure.thresh>0 && outstructure.thresh<1)
        disp('Using numerator degrees of freedom in image header')
        tmp = instructure.df1;
        hdr = spm_vol(hdrname);
        d = hdr.descrip;
        pos1 = regexp(d,'[','ONCE');
        pos2 = regexp(d,']','ONCE');
        tmpdf = str2num(d(pos1+1:pos2-1));
        outstructure.df1 = tmpdf;
    else
    outstructure.df1=[];
    end
end

%% degrees of freedom denominator
try
    outstructure.df2=instructure.df2;
    if ~isnumeric(outstructure.df2) || outstructure.df2<1
        vardoesnotexist; % triggers catch statement
    end
catch
    if (strcmpi(outstructure.type,'F')) && (outstructure.thresh>0 && outstructure.thresh<1)
        error('degrees of freedom numerator must be defined using df2 field; can be gotten from SPM')
    else
    outstructure.df2=[];
    end
end

%% Make threshold a non-decimal
if (strcmpi(outstructure.type,'T') || strcmpi(outstructure.type,'F') || strcmpi(outstructure.type,'Z')) && (outstructure.thresh>0 && outstructure.thresh<1)
    if strcmpi(outstructure.type,'T')
        outstructure.thresh = spm_invTcdf(1-outstructure.thresh,outstructure.df1);
    elseif strcmpi(outstructure.type,'F')
        outstructure.thresh = spm_invFcdf(1-outstructure.thresh,outstructure.df1,outstructure.df2);
    else 
        outstructure.thresh=norminv(1-outstructure.thresh,0,1);
    end
end
parameters=outstructure;
try
	parameters.label=instructure.label;
end
try
	parameters.nearest=instructure.nearest;
end