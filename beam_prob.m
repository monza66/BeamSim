%% Beam design probability analysis
% Used to find basic probabilities of process
clear all;
close all;
% initialize design transition matrix for the materials engineer
mat = [ .1 .9 0 0 0 
0 .2 .8 0 0 
0 0 .3 .7 0
0 .1 .1 .3 .5
0 0 0 0 1];
% initialize design transition matrix for the mechanical engineer
mech = [ .1 .9 0 0 0 
0 .2 .8 0 0 
0 0 .3 .7 0
0 .1 .2 .4 .3
0 0 0 0 1];

% Set random variable stream
rand_seed=23;
stream = RandStream('mlfg6331_64','seed',rand_seed);

for k=1:10000
state_mat='Rq';
state_mech='Rq';
cntr_mech(k)=0; 
cntr_mat(k)=0;
stop =0;
stop2=0;
% materials engineer process
    while stop<1

    [state_mat, proc] = FBStrans(mat,state_mat,stream);
    cntr_mat(k)=cntr_mat(k)+1;
        if state_mat=='Dc'
            stop=2;
            q=rand;
            if q<=0.75
                %assume wrong material picked
                stop=0;
                state_mat='Fn';
            end
        end
    end


% mechanical engineer process
    while stop2<1

    [state_mech, proc] = FBStrans(mech,state_mech,stream);
    cntr_mech(k)=cntr_mech(k)+1;
        if state_mech=='Dc'
            stop2=2;
        end
    end
end

%post processing
cntr_tot=cntr_mat+cntr_mech;

figure (1)
histogram(cntr_tot)
xlabel('Numer of 4 hour design sessions to complete design')
ylabel('Count')
xlim([0 80]);

title('Histogram of Beam design with no learning function')