function [NEWstate, proc] = FBStrans(mat,curr,stream)
% Given a FBS transition matrix and current state, the function returns
% a new state
% FBS transition matrix is setup as follows:
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
% The Be state, the analysis process, and evaluation process are
% modeled as being part of the Structure state as they must be performed
% anytime the structure state is reached and including them would also require
% setting up a complex logic framework to indicate next states based on states that
% had previously been visited.
%
% mat is a 6x6 matrix
% Curr is the current state either R, F, Be, S or D
% stream is a random variable stream provided through the functions below
% rand_seed=23;
% stream = RandStream('mlfg6331_64','seed',rand_seed);
% NEWstate is the new state that was transitioned to
% proc is the process that was performed to get to the new state
%
% Mitch Bott 11-14-16

% Get random value

prob=rand(stream);

% Determine next state possibilities based on current state

if curr == 'Rq'
	%Current state is requirements, all successful transitions lead to function through the 
	% formulation process
	if prob >= mat(1,1) %random draw indicates transition was successful
		NEWstate='Fn';
        proc= 'frm';
	else %transition was unsuccessful
		NEWstate='Rq';
        proc= 'inc'; %State incomplete
    end
elseif curr == 'Fn'
	%Current state is function. All successfultransitions lead to expected behavior through
	% the formulation process
	if prob >= mat(2,2) %random draw indicates transition was successful
		NEWstate='Be';
        proc= 'frm';
	else %transition was unsuccessful
		NEWstate='Fn';
        proc= 'inc'; %State incomplete
    end
elseif curr == 'Be'
	%Current state is expected behavior. All successful transitions lead to structure through
	% the synthesis process
	if prob >= mat(3,3) %random draw indicates transition was successful
		NEWstate='St';
        proc= 'syn'; 
	else %transition was unsuccessful
		NEWstate='Be';
        proc= 'inc'; %State incomplete
    end
elseif curr =='St'
	%Current state is structure. The analysis and evaluation processes are being 
	% abstracted as part of the structure step. This is done because Bs and the evaluation
	% process are only performed once a structure exists. Transitions vary between documentation, D
	% and the three types of reformulation R1, R2, and R3.

	if (prob <=mat(4,2))%Type 3 reformulation
		NEWstate='Fn';
        proc= 'rf3'; 
	elseif ((prob >(mat(4,2))) && (prob <= (mat(4,2)+mat(4,3) )))%Type 2 reformulation
		NEWstate='Be';
        proc= 'rf2'; 
	elseif (prob >(mat(4,2)+mat(4,3))) && (prob<= (mat(4,2)+mat(4,3)+mat(4,4)))%Type 1 reformulation
		NEWstate='St';
        proc= 'rf1'; 
	else %Start documentation
		NEWstate='Dc';
        proc= 'Doc'; 
    end
elseif curr=='Dc'
	%Current state is documentation. No further transitions occur
	NEWstate='Dc';
    proc= 'Doc';
else
	%Error, invalid state
	disp('Error, Invalid state');
end

% end FBStrans