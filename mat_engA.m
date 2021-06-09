function [ mat_type, proc_mat, state_WF_mat, cntr_WF_mat ] = mat_engA( mat, state_WF_mat,stream, mat_matrix,cntr_WF_mat )
% FBS model of a materials engineer working on a beam design
%   mat_matrix is the materials design matrix. It has 1's where a choice is
%   valid and 0's where a choice is not
% Modified for agile simulation, it only advances one cycle at a time
mat_type=0;
%cntr_WF_mat=0;

%while mat_type==0 % Stop materials engineer design effort once material type is chosen
     cntr_WF_mat=cntr_WF_mat+1; %Increment iteration counter by 1
     
     [state_WF_mat, proc_mat]= FBStrans(mat, state_WF_mat,stream); %Advance FBS State
     
     % Learning and intermediate designs not modeled for materials engineer
     % since there are no requirements that only apply to the materials
     % engineer
     if state_WF_mat == 'St' %the material design structure has been determined
         % pick material solution based on random draw
         %Unifrom distribution assumed
         mat_choice=rand(stream);
         % determine design space
         mat_choice=ceil(sum(mat_matrix)*mat_choice);
         %Make design choice
         j=0;
         for i=1:size(mat_matrix,2)
             if mat_matrix(i)~=0
                 j=j+1;
                 if j==mat_choice
                    mat_type=i; 
                    break
                 end
            end
         end
               
         
     end
 %end
 
 



end

