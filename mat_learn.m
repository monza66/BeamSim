function [ mat_matrix ] = mat_learn( mat_type, mat_matrix )
%Version space learning for materials engineer

% remove current material and those known to be lower performing
           % from mat_matrix for version space learning for materials
           % engineer
           if mat_type==1
               mat_matrix(1) = 0; 
           elseif mat_type==2
               mat_matrix(1) = 0;
               mat_matrix(2)=0;
           elseif mat_type==3
               mat_matrix(3) = 0;
               mat_matrix(4)=0;
           elseif mat_type==4
               mat_matrix(4) = 0;
           else
               disp('Error, invalid value for mat_type')
           end

%check mat_matrix for errors
if sum(mat_matrix)==0
    disp ('Error, no material choices remaining')
end
           
end

