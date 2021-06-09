%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Simulation of a simply supported beam design activity
%       The activity consists of two designers a materials engineer
%       who picks the material of the beam and a mechanical engineer
%       who picks the cross section of the beam. 
%       The design team is given a goal to develop a beam with a FoS of
%       at least 2, for a given Mz, for less than $37K
%       
%
%       Each cycle represents 4 hours of work (1/2 a work day)
%
%   
%   Mitch Bott 11-15-16
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% clear simulation variables and MATLAB workspace
clear all;
close all;
clc;


%Set problem constants
FOS_min = 2;
Mz = 100; %Pa, assume beam is 10 meters long

% Set random variable stream
rand_seed=23;
stream = RandStream('mlfg6331_64','seed',rand_seed);

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

% Set design options for materials engineer
% ASTM A36 Steel, Aluminium 2014-T6, ASTM A514 steel, Titanium alloy
% yield strength is in MPa
% Sourced from https://en.wikipedia.org/wiki/Yield_(engineering)
mat_matrix = [ 1, 1, 1, 1];
sigma_Y = [250, 400, 690, 830];
% dollars per m^3
costpervol = [12945.69, 17630.07, 20941.53, 277487.5]; % Cost data from http://www.discountsteel.com/ for first 3 options. Titanium cost from http://www.onlinemetals.com/merchant.cfm?pid=12682&step=4&showunits=inches&id=322&top_cat=1353

% Set design options for mechanical engineer

%Assume a square cross section for this problem
% MOI = a^4/12
% a (the height and width of the cross section) will be set during design loop
% c= a/2
% assume design range of a is 10 cm to 300 cm

%% create design response surface
a=zeros (30,4);
FOS=zeros(30,4);
cost=zeros(30,4);
bestcost = 1000000000;
beam_cost(1)=0;
for i=1:30
    for j=1:4
        a(i,j)=i*.1;
        sigma_max = a(i,j)/2*Mz/(a(i,j)^4/12);
        FOS(i,j)=sigma_Y(j)/sigma_max;
        cost(i,j)=a(i,j)^2*10*costpervol(j);
        %determine optimum design point
        if FOS(i,j)>=2
            if cost (i,j)< bestcost
                opti=i;
                optj=j;
                bestcost=cost (i,j);
            end
        end
                
    end
end
    
    
%% Waterfall simulation
for k=1:10000 %do 10,000 monte-carlo iterations

    
    %% Materials engineer
    % Schedule has  materials engineer go first then mechanical designer
%initialize variables
state_WF_mat='Rq';
state_WF_mech='Rq';
FOS_WF(1,k)=0;
 cntr_WF_mat(k)=0;
 cntr_WF_mech(k)=0;
 mat_type(k)=0;
 %while beam_cost>37000
 
  [mat_type(k), proc_mat, cntr_WF_mat(k)] = mat_eng( mat, state_WF_mat,stream, mat_matrix );
 
 
 % find design space given material choice
 local_opt=0;
  for i=1:30
      if FOS(i,mat_type(k))>=2
      local_opt =i;
      break
      end
               
  end
 
  %% Mechanical designer
 cntr_WF_mech(k)=0; 
 mech_design_formulation=0;
 reform1_space = 5;
 reform2_space=5;
 reform3_space=local_opt-reform1_space-reform1_space-1;
 d_space= size (FOS,1) -local_opt;
 i=1;
 mech = [ .1 .9 0 0 0 
0 .2 .8 0 0 
0 0 .3 .7 0
0 .1 .2 .4 .3
0 0 0 0 1];
 % Mechanical engineer starts work
 while FOS_WF(i,k)<2 %effort stops once requirement is met
         
       [ cntr_WF_mech(k), state_WF_mech, proc_mech,mech, mech_design_formulation, reform1_space, reform2_space, reform3_space, FOS_WF(i+1,k), beam_profit(i+1,k)  ] = mech_eng( mech, state_WF_mech,stream, mech_design_formulation, cntr_WF_mech(k), reform1_space, reform2_space, reform3_space,d_space, mat_type(k),local_opt,FOS, cost ); 
        i=i+1;      
       
 end
%end
end
%% Post processing for Waterfall simulation
%Find average and standard deviation for material engineer time worked

mat_WF_avg=mean(cntr_WF_mat);
mat_WF_std=std(cntr_WF_mat);

figure(1)
plot (cntr_WF_mat)
hold on
plot ([0 k],[mat_WF_avg mat_WF_avg],'k');
plot ([0 k],[mat_WF_avg-mat_WF_std mat_WF_avg-mat_WF_std],'k--');
plot ([0 k],[mat_WF_avg+mat_WF_std mat_WF_avg+mat_WF_std],'k--');
xlabel('Iteration Number');
ylabel('Number of 4 hour design sessions to complete materials design');
title ('Materials Engineer Monte-Carlo Simulation');
legend('Simulation data', 'Mean of Simulation Data', 'Standard Deviation from the mean');
hold off

%Find average and standard deviation for mechanical engineer time worked

mech_WF_avg=mean(cntr_WF_mech);
mech_WF_std=std(cntr_WF_mech);

figure(2)
plot (cntr_WF_mech)
hold on
plot ([0 k],[mech_WF_avg mech_WF_avg],'k');
plot ([0 k],[mech_WF_avg-mech_WF_std mech_WF_avg-mech_WF_std],'k--');
plot ([0 k],[mech_WF_avg+mech_WF_std mech_WF_avg+mech_WF_std],'k--');
xlabel('Iteration Number');
ylabel('Number of 4 hour design sessions to complete mechanical design');
title ('Mechanical Engineer Monte-Carlo Simulation');
legend('Simulation data', 'Mean of Simulation Data', 'Standard Deviation from the mean');
hold off

%total time evaluation
total_WF=cntr_WF_mat+cntr_WF_mech;

total_WF_avg=mean(total_WF);
total_WF_std=std(total_WF);

figure(3)
plot (total_WF)
hold on
plot ([0 k],[total_WF_avg total_WF_avg],'k');
plot ([0 k],[total_WF_avg-total_WF_std total_WF_avg-total_WF_std],'k--');
plot ([0 k],[total_WF_avg+total_WF_std total_WF_avg+total_WF_std],'k--');
xlabel('Iteration Number');
ylabel('Number of 4 hour design sessions to complete total beam design');
title ('Beam Design Monte-Carlo Simulation');
legend('Simulation data', 'Mean of Simulation Data', 'Standard Deviation from the mean');
hold off
