function [ cntr_WF_mech, state_WF_mech, proc_mech  ] = mech_engA( mech, state_WF_mech,stream, cntr_WF_mech)
% FBS simulation of a mechanical engineer working on a beam desgin
%   Detailed explanation goes here

cntr_WF_mech=cntr_WF_mech+1; %Increment iteration counter by 1
         [state_WF_mech, proc_mech]= FBStrans(mech, state_WF_mech,stream); %advance FBS state
        

end

