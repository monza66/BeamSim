function [num] = state2num(state)
%converts FBS states into a numbered sequence from 1 to 5
if state=='Rq'
    num=1;
elseif state =='Fn'
    num=2;
elseif state =='Be'
    num=3;
elseif state =='St'
    num=4;
elseif state =='Dc'
    num=5;
else
    disp('Error, attempted to convert invalid state ',state)
    
end


end

