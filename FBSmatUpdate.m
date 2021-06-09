function [ mat, reform_space ] = FBSmatUpdate( rf, mat, design_choice, reform_space, sides, total_reform_space )
%Update a FBS matrix based on version space learning
%   Depending on the type of reformulation, apply the correct alterations
%   to the version space
% rf is the reformulation type as a string: rf1, rf2, or rf3
% mat is the FBS transition matrix
% FBS transition matrix (mat) is setup as follows:
%
%			R	F	Be	S	D
%		R	X	X	0	0	0
%		F	0	X	X	0	0
%		Be	0	0	X	X	0
%		S	0	X	X	X	X
%		D	0	0	0	0	X
%
% X's denote a value and 0's denote an enforced 0, i.e. there is no
% possibility of making a transition to that state.
% Learning affects row 4 (the "S" row) where the probability of creating a
% valid design exist.
%
% design choice is the index of the design choice
% reform space is the length of the reformulation space (the number of
% indices that make up the reforumulation space
% sides is the number of sides of the design variable, either 1,  2, or 3 the
% design variable is either continuously improving, or is bounded on either
% side by reformulation space. 2 indicates the lower side of the double
% sided design variable and 3 indicates the upper side.
% total_reform_space is needed only for 2 sided design variables. It
% indicates the size of both sides of the reform space


if sides==1
    if  rf == 'rf1'
               mat  (4,2)=0;
               mat (4,3)=0;
               mat (4,4)=mat (4,4)*(1-design_choice/reform_space);
               mat (4,5)=1-mat(4,4);
                reform_space = design_choice;
    elseif rf =='rf2'
               mat (4,2)=0;
               mat (4,3)=mat (4,3)*(1-design_choice/reform_space);
               mat (4,4)=mat (4,4);
               mat (4,5)=1-mat(4,4)-mat (4,3);
              %Update design space based on version space learning
               reform_space = design_choice;
    elseif rf=='rf3'
               mat (4,2)=mat (4,2)*(1-design_choice/reform_space);
               mat (4,3)=mat (4,3);
               mat (4,4)=mat (4,4);
               mat (4,5)=1-mat(4,4)-mat (4,3)-mat(4,2);
              %Update design space based on version space learning
               reform_space = design_choice;
    end
elseif sides == 2 %double sided design variable lower end
    if  rf == 'rf1'
               mat  (4,2)=0;
               mat (4,3)=0;
               mat (4,4)=mat (4,4)*(1-design_choice/total_reform_space);
               mat (4,5)=1-mat(4,4);
                reform_space = reform_space-design_choice;
    elseif rf =='rf2'
               mat (4,2)=0;
               mat (4,3)=mat (4,3)*(1-design_choice/total_reform_space);
               mat (4,4)=mat (4,4);
               mat (4,5)=1-mat(4,4)-mat (4,3);
              %Update design space based on version space learning
               reform_space = reform_space-design_choice;
    elseif rf=='rf3'
               mat (4,2)=mat (4,2)*(1-design_choice/total_reform_space);
               mat (4,3)=mat (4,3);
               mat (4,4)=mat (4,4);
               mat (4,5)=1-mat(4,4)-mat (4,3)-mat(4,2);
              %Update design space based on version space learning
               reform_space = reform_space-design_choice;
    end

elseif sides == 3 %double sided design variable upper end
    if  rf == 'rf1'
               mat  (4,2)=0;
               mat (4,3)=0;
               mat (4,4)=mat (4,4)*(design_choice/total_reform_space);
               mat (4,5)=1-mat(4,4);
                reform_space = design_choice- (total_reform_space-reform_space);
    elseif rf =='rf2'
               mat (4,2)=0;
               mat (4,3)=mat (4,3)*(design_choice/total_reform_space);
               mat (4,4)=mat (4,4);
               mat (4,5)=1-mat(4,4)-mat (4,3);
              %Update design space based on version space learning
               reform_space = design_choice- (total_reform_space-reform_space);
    elseif rf=='rf3'
               mat (4,2)=mat (4,2)*(design_choice/total_reform_space);
               mat (4,3)=mat (4,3);
               mat (4,4)=mat (4,4);
               mat (4,5)=1-mat(4,4)-mat (4,3)-mat(4,2);
              %Update design space based on version space learning
               reform_space = design_choice- (total_reform_space-reform_space);
               
    end
end

