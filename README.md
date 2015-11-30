### BSPMVIEW 
#### MATLAB Program for playing with fMRI statistical maps

Online documentation can be found here: http://spunt.github.io/bspmview/.

Requires that Statistical Parametric Mapping (SPM; Wellcome Trust Centre for Neuroimaging; www.fil.ion.ucl.ac.uk/spm/)
be in your MATLAB search path. It has only been tested on SPM8/SPM12 operating in MATLAB 2014b. It requires a number of
supporting utility functions and data files that should have been included in the distribution of BSPMVIEW. When
BSPMVIEW is launched, it will look for these files in a folder called "supportfiles" that should be contained in the
same folder as BSPMVIEW.

#### OPTIONAL INPUTS
**ol**: filename for statistical image to overlay   
**ul**: filename for anatomical image to use as underlay

#### COMMAND LINE USAGE EXAMPLES
<pre><code>
>> bspmview                               % open dialogue for selecting overlay
>> S = bspmview;                          % returns struct 'S' containing GUI obj handles
>> bspmview('spmT_0001.img')              % overlay on default underlay   
>> bspmview('spmT_0001.img','T1.nii')     % overlay on 'T1.nii'
</code></pre>
  
#### CREDITS    
This software heavily relies on functions contained within the SPM software, and is essentially an attempt to translate some of it into a simpler and more user-friendly format. In addition, this software was   inspired by and in some cases uses code from two other statistical image viewers: XJVIEW.m by Xu Cui, Jian Li, and Xiaowei Song
(http://www.alivelearn.net/xjview8/developers/), and FIVE.m by Aaron P. Schultz (http://mrtools.mgh.harvard.edu/index.php/Main_Page). This also employs some of the functionality of PEAK_NII.m by Donald McLaren (http://www.nmr.mgh.harvard.edu/~mclaren/ftp/Utilities_DGM/). Finally, several contributions to the MATLAB File Exchange (http://www.mathworks.com/matlabcentral/fileexchange/) are called by the code. These are included in the "supporting files" folder that should have been included in the distribution of the main BSPMVIEW function.


<p>------ Copyright (C) Bob Spunt, California Institute of Technology ------</p>   
* Email:    spunt@caltech.edu
* Created:  2014-09-27   
* Version:  20151129

<p>This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public
License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later
version. This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details. You should have received a copy of the GNU General Public License along with this program. If not, see: http://www.gnu.org/licenses/.</p>
