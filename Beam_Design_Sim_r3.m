%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Simulation of a simply supported beam design activity
%       The activity consists of two designers a materials engineer
%       who picks the material of the beam and a mechanical engineer
%       who picks the cross section of the beam. 
%       The design team is given a goal to develop a beam that maximizes
%       profit for the company. The team is given an objective function to
%       maximize that includes a value function equating the beam's FOS to
%       revenue for the company and information about the cost of the beam 
%       is used to determine the company's profit. 
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
FOS_min = 2; % minimum allowed factor of safety
Mz = 100; %Pa, assume beam is 10 meters long
%nbins=50;

% Set random variable stream
rand_seed=23;
stream = RandStream('mlfg6331_64','seed',rand_seed);
%t original probabilities. can remove later
% % initialize design transition matrix for the materials engineer
% mat = [ .1 .9 0 0 0 
% 0 .2 .8 0 0 
% 0 0 .3 .7 0
% 0 .1 .1 .3 .5
% 0 0 0 0 1];
% % initialize design transition matrix for the mechanical engineer
% mech = [ .1 .9 0 0 0 
% 0 .2 .8 0 0 
% 0 0 .3 .7 0
% 0 .1 .2 .4 .3
% 0 0 0 0 1];

% initialize design transition matrix for the materials engineer
mat = [ .14 .86 0 0 0 
0 .18 .82 0 0 
0 0 .12 .88 0
0 .06 .15 .55 .24
0 0 0 0 1];

% initialize design transition matrix for the mechanical engineer
mech = [ .1 .9 0 0 0 
0 .2 .8 0 0 
0 0 .32 .68 0
0 .1 .2 .5 .2
0 0 0 0 1];

% Set design options for materials engineer
% ASTM A36 Steel, Aluminium 2014-T6, ASTM A514 steel, Titanium alloy
% Sourced from https://en.wikipedia.org/wiki/Yield_(engineering)

sigma_Y = [250, 400, 690, 830]; % yield strength is in MPa
% dollars per m^3
costpervol = [12945.69, 17630.07, 20941.53, 277487.5]; % Cost data from http://www.discountsteel.com/ for first 3 options. Titanium cost from http://www.onlinemetals.com/merchant.cfm?pid=12682&step=4&showunits=inches&id=322&top_cat=1353

% Set design options for mechanical engineer

%Assume a square cross section for this problem
% MOI = a^4/12
% a (the height and width of the cross section) will be set during design loop
% c= a/2
% assume design range of a is 10 cm to 300 cm

%% create design response surface
a=zeros (30,4); %the height and width of the square cross section
FOS=zeros(30,4); %factor of safety
cost=zeros(30,4); %cost of the beam
profit = zeros (30,4); %profit to be made from the beam
bestprof = -10000000000; %variable initialized with a very low value used to store the highest profit
%beam_cost(1)=0;
for i=1:30 %loop to create design response surface i loop is for cross section
    for j=1:4 %j loop is for material
        a(i,j)=i*.1; %convert a to meters of length for height and width of beam
        sigma_max = a(i,j)/2*Mz/(a(i,j)^4/12); %Calculate maximum stress in beam
        FOS(i,j)=sigma_Y(j)/sigma_max; % calculate factor of safety
        cost(i,j)=a(i,j)^2*10*costpervol(j); %Calculate the cost of the beam
        profit(i,j)=Beam_rev(FOS(i,j))-cost(i,j); %Calculate the profit from the beam based on the revenue (Beam_rev) function.
        %determine optimum design point
        %if FOS(i,j)>=2
            if profit (i,j)> bestprof %If the profit from the beam is better than the highest value found so far, store it as the new best profit.
                opti=i;% Store the indices of the best profit
                optj=j;
                bestprof=profit (i,j); %Store the best profit
            end
        %end
                
    end
end
    
    
%% Waterfall simulation
init_mat_WF=zeros (1,10000); %Initialize matrix to store the initial material selection from the WF sim
for k=1:10000 %do 10,000 monte-carlo iterations

    
    %% Materials engineer
    % Schedule has  materials engineer go first then mechanical designer
%initialize variables
stop=0;%Simulation stop flag
state_WF(1,k)=string(0); %String for FBS transition
state_indx=1; %index for FBS state
state_WF_mat='Rq'; %string for materials engineer FBS state
state_WF_mech='Rq';%string for mechanical engineer FBS state
FOS_WF(1,k)=0; %Factor of safety for current WF sim solution
beam_profit(1,k)=0; %profit for each beam solution
 cntr_WF_mat(k)=0; %Counter for the number of iterations the materials engineer goes through
 cntr_WF_mech(k)=0; %Counter for the number of iterations the mechanical engineer goes through
 mat_type(k)=0; %Number to track the type of material in the beam
 mat_matrix = [ 1, 1, 1, 1]; %Matrix to keep track of what materials have been used of the 4 possible. The number goes to 0 when a material is eliminated from possibility
 i=1; %initize iteration counter at 1
% cntr_WF_mech(k)=0; 
% cntr_WF_mat(k)=0;
 while stop<=1
 % Materials engineer waterfall simulation. The materials engineer performs
 % design efforts until a material is chosen
  [mat_type(k), proc_mat, state_WF_mat, cntr_WF_mat(k),state_WF_temp,state_indx2] = mat_eng( mat, state_WF_mat,stream, mat_matrix,cntr_WF_mat(k),state_indx);
 if init_mat_WF(k)==0 %set the initial material type in case it had not yet been chosen (part of study examining how initial material selection drove the remaining design effort)
     init_mat_WF(k)=mat_type(k);
 end
 state_indx2=state_indx2-1; %adjust index to store the current state transition
 state_WF(state_indx:state_indx2,k)=state_WF_temp(state_indx:state_indx2); %store the current state transition
 state_indx=state_indx2+1; %adjust index back to original value
 % find local optimum given material choice
 local_opt=0;
 profmax=-10000000;
  for j=1:30
      if profit(j,mat_type(k))> profmax
          profmax =profit(j,mat_type(k));
          local_opt =j;
      end
               
  end

  %% Mechanical designer
 
 mech_design_formulation=0; %Flag for when mechanical design is done
 %d_spaceH= 2;% size (FOS,1) -local_opt;
 %d_spaceL=2;
 %Setup what design variables result in D, RF1, RF2, and RF3
 if mat_type(k)==4 %Titanium has a 1 sided design space (29 options to one side of optimum)
     reform_space = [4 6 6 13];
 else
     reform_space = [local_opt-2-3-3-1 3 3 2 2 3 3 30-local_opt-2-3-3]; %Other materials have a 2-sided design space (29 options to either side of the local optimum
 end
 
 
 %reform1_spaceH = 5;
 %reform1_spaceL = 5;
 %reform2_spaceH=5;
 %reform2_spaceL=5;
 %reform3_spaceL=local_opt-d_spaceL-reform1_spaceL-reform1_spaceL-1;
 %reform3_spaceH=30 - local_opt-d_spaceH-reform1_spaceH-reform1_spaceH;
 
 %i=1;
 mech = [ .1 .9 0 0 0 %setup mechanical engineer state transition matrix
0 .2 .8 0 0 
0 0 .3 .7 0
0 .1 .2 .4 .3
0 0 0 0 1];
%initialize stop variable
stop=0;
% Mechanical engineer starts work
 while stop==0 %effort stops once a design is found that meets stop criteria
       % Call mechanical engineer to perform design effort  
       %need to add in two sides to reform spaces and d space
       [ cntr_WF_mech(k), state_WF_mech, proc_mech,mech, mech_design_formulation, reform_space, FOS_WF(i+1,k), beam_profit(i+1,k)  ] = mech_eng( mech, state_WF_mech,stream, mech_design_formulation, cntr_WF_mech(k), reform_space, mat_type(k),local_opt,FOS, profit) ;
        i=i+1;   
        state_indx=state_indx+1; %increment state index by 1
        state_WF(state_indx,k)=proc_mech+string('_mech'); %add current mechanical state to waterfall state tracker.
       if beam_profit(i,k)>0
        %satisficing design criteria has been met, there is positive profit
        stop =2;
        break;
       end
       %evaluate if mechanical engineer has completely covered design space. 
        if (sum(reform_space) <=5) %assume that enough design space has been covered to know that current design process won't work and material needs to be changed. 5 is the width of d_space (the designs that would result in going to the documentation phase)
           [ mat_matrix ] = mat_learn( mat_type(k), mat_matrix ); %Perform version space learning for materials engineer
          % start test
          %q=rand(stream);
           % if q<0.25
           %     mat_type(k)=1;
           % elseif (q>=.25) && (q<0.5)
           %     mat_type(k)=2;
           % elseif(q>=.5) && (q<0.75)
           %     mat_type(k)=3;
           % else
           %     mat_type(k)=4;
           % end
            %end test
           % reset materials engineer's effort
           state_WF_mat='Fn';
           state_WF_mech='Fn';
           
           stop=1;
           break
       end
        
        
 end
end
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

x_ax=(1:10000); %X points for plotting

figure(3)
scatter (x_ax, total_WF,5)
hold on
plot ([0 k],[total_WF_avg total_WF_avg],'k','LineWidth',3);
plot ([0 k],[total_WF_avg-total_WF_std total_WF_avg-total_WF_std],'k--','LineWidth',3);
plot ([0 k],[total_WF_avg+total_WF_std total_WF_avg+total_WF_std],'k--','LineWidth',3);
xlabel('Simulation Run Number');
ylabel('Number of 4 hour design sessions to complete beam design');
title ('Waterfall Beam Design Monte-Carlo Simulation');
legend('Simulation data', 'Mean of Simulation Data', 'Standard Deviation from the mean');
ylim ([0 100])
hold off

%histograms
figure (4)
histogram (total_WF);%,nbins);
hold on
xlabel ('Number of 4 hour design sessions to complete total beam design');
ylabel ('count');
title ('Histogram of waterfall simulation times');
xlim([0 80]);
ylim ([0 800]);
hold off

%create first success histogram
j=1;
k=1;
for i=1:10000
    if init_mat_WF(i)==3
        first_success_WF(j)=total_WF(k);
        j=j+1;
    else
        other_success_WF(k)=total_WF(k);
        k=k+1;
    end
end

bins1=[6:2:80];

figure (5)
histogram (cntr_WF_mat,bins1);%,nbins);%histogram (first_success_WF);
hold on
xlabel ('Number of 4 hour design sessions to complete material design');
ylabel ('count');
title ('Histogram of waterfall simulation times for material design');% with first pass success for materials design');
xlim([0 80]);
ylim ([0 1200]);
hold off

bins2=[6:2:60];

figure (6)
histogram(cntr_WF_mech,bins2);%,nbins);%histogram (other_success_WF);
hold on
xlabel ('Number of 4 hour design sessions to complete mechanical design');
ylabel ('count');
title ('Histogram of waterfall simulation times for mechanical design');% with other than first pass success for materials design');
xlim([0 80]);
ylim ([0 1200]);
hold off


%% Agile simulation
% initialize variables
init_mat_A=zeros(1,10000);
% initialize design transition matrix for the materials engineer
mat = [ .14 .86 0 0 0 
0 .18 .82 0 0 
0 0 .12 .88 0
0 .06 .15 .55 .24
0 0 0 0 1];
% initialize design transition matrix for the mechanical engineer
mech = [ .1 .9 0 0 0 
0 .2 .8 0 0 
0 0 .32 .68 0
0 .1 .2 .5 .2
0 0 0 0 1];
%original probabilites. Can remove later
% % initialize design transition matrix for the materials engineer
% mat = [ .1 .9 0 0 0 
% 0 .2 .8 0 0 
% 0 0 .3 .7 0
% 0 .1 .1 .3 .5
% 0 0 0 0 1];
% % initialize design transition matrix for the mechanical engineer
% mech = [ .1 .9 0 0 0 
% 0 .2 .8 0 0 
% 0 0 .3 .7 0
% 0 .1 .2 .4 .3
% 0 0 0 0 1];
for k=1:10000 % do 10,000 monte-carlo interations
   
    %initialize agile variables
    stop=0; %simulation stop flag
    state_A_mat='Rq';%intialize state of materials engineer
    state_A_mech='Rq';%Initialize state of mechanical engineer
    state_A_beam='Rq';%Initialize state of team (kept at lowest state of the 2 engineers)
    FOS_A(1,k)=0; %Factor of safety for agile sim
    beam_profit_A(1,k)=0; %Profit for agile sim
    cntr_A_mat(k)=0; % counter for number of design sessions that materials engineer goes through
    cntr_A_mech(k)=0; % counter for number of design sessions that mechanical engineer goes through
    total_A(k)=0; %Counter for total iterations needed to create beam design
    mat_typeA(k)=0; %Type of material
    mat_matrix = [ 1, 1, 1, 1]; %Matrix to keep track of what materials have been used of the 4 possible. The number goes to 0 when a material is eliminated from possibility
    design_formulation=0; %flag for when design reformulation is taking place
    reform_space = 0; %Number of designs in the reformulation space
    %Convert states to numbers to ease logic for agile activities
        state_A_mat_num = state2num(state_A_mat);
        state_A_mech_num = state2num(state_A_mech);
        state_A_beam_num = state2num(state_A_beam);
       
        i=1;
    while stop<=1 % loop for design effort
        % materials engineer and mechanical engineer start work in parallel
        %Need to keep the two engineers in sync, representing an FBS for
        %the system
       

        if (state_A_mat_num == state_A_mech_num) && (state_A_beam_num~=4) %ensure that both engineers are at the same state
            total_A(k)=total_A(k)+1; % add to total agile iteration counter
            [mat_temp, proc_mat, state_A_mat, cntr_A_mat(k)] = mat_engA( mat, state_A_mat,stream, mat_matrix, cntr_A_mat(k) ); %Materials engineer performs work
            [ cntr_A_mech(k), state_A_mech, proc_mech] = mech_engA( mech, state_A_mech,stream, cntr_A_mech(k)); %Mechanical engineer performs work
            state_A_mat_num = state2num(state_A_mat); %Convert state to number
            state_A_mech_num = state2num(state_A_mech); %Convert state to number
            if mat_typeA(k)==0 %if a material hasn't been chosen, pick the one from the materials engineer's work
                mat_typeA(k)=mat_temp;
            end
            % Set system state to lowest number
            if state_A_mat_num < state_A_mech_num
                state_A_beam = state_A_mat;
                state_A_beam_num = state_A_mat_num;
            else
                state_A_beam = state_A_mech;
                state_A_beam_num = state_A_mech_num;
            end
            
            
            
                
            % i=i+1;  
        elseif state_A_mat_num < state_A_mech_num %Materials engineer is lagging
            total_A(k)=total_A(k)+1; % add to total agile iteration counter
            [mat_temp, proc_mat, state_A_mat, cntr_A_mat(k)] = mat_engA( mat, state_A_mat,stream, mat_matrix, cntr_A_mat(k) );%Materials engineer does work
            state_A_mat_num = state2num(state_A_mat);
           
            %i=i+1;
            if mat_typeA(k)==0 %If material hasn't been chosen, set material to the one chosen by the materials engineer
                mat_typeA(k)=mat_temp;
            end
            % Set system state to lowest number
            if state_A_mat_num < state_A_mech_num
                state_A_beam = state_A_mat;
                state_A_beam_num = state_A_mat_num;
            else
                state_A_beam = state_A_mech;
                state_A_beam_num = state_A_mech_num;
            end
%             if mat_type(k)~=0 %setup reformulation space
%                 if mat_type(k)==4
%                      reform_space = [4 6 6 13];
%                  else
%                      reform_space = [local_opt-2-3-3-1 3 3 2 2 3 3 30-local_opt-2-3-3];
%                 end
%             end
         elseif state_A_mat_num > state_A_mech_num %Mechanical engineer is lagging
             total_A(k)=total_A(k)+1; % add to total agile iteration counter
          [ cntr_A_mech(k), state_A_mech, proc_mech] = mech_engA( mech, state_A_mech,stream, cntr_A_mech(k) ); %Mechanical engineer performs work
           state_A_mech_num = state2num(state_A_mech);
          %i=i+1;
          % Set system state to lowest number
            if state_A_mat_num < state_A_mech_num
                state_A_beam = state_A_mat;
                state_A_beam_num = state_A_mat_num;
            else
                state_A_beam = state_A_mech;
                state_A_beam_num = state_A_mech_num;
            end
        end
        if state_A_beam_num ==4 %structure has been determined and an evaluation needs to be made
            total_A(k)=total_A(k)+1; % add to total agile iteration counter
                %setup reformulation space if it doesn't exist
                if reform_space==0
                    % find local optimum given material choice
                         local_opt=0;
                         profmax=-10000000;

                          for j=1:30
                              if profit(j,mat_typeA(k))> profmax
                                  profmax =profit(j,mat_typeA(k));
                                  local_opt =j;
                              end

                          end
                    %Setup reformulation space                    
                    if mat_typeA(k)==4 %One-sided reformulation space for Titanium
                         reform_space = [4 12 13 0]; %Reformulation space is for the d-state, tyep 1 reformulation and type 2 reformulation. Type 3 reformulation is reserved for being forced to change the material
                    else %two-sided reformulation space for other options
                         reform_space = [0 local_opt-2-6-1 6 2 2 6 30-local_opt-2-6 0]; %Reformulation space is for the d-state, tyep 1 reformulation and type 2 reformulation. Type 3 reformulation is reserved for being forced to change the material
                    end  
                end
                % call evaluation function
                i=i+1;                
                
                [ beam_profit_A(i,k),  mat_matrix, reform_space, mech, mat, state_A_mat, state_A_mech, cntr_A_mat(k), cntr_A_mech(k),mat_typeA(k) ] = Agile_eval( mat_typeA(k), profit, reform_space, mat_matrix, mech, mat, stream, state_A_mat, state_A_mech, cntr_A_mat(k), cntr_A_mech(k));
                %Convert states to numbers
                state_A_mat_num = state2num(state_A_mat);
                state_A_mech_num = state2num(state_A_mech);
                % Set system state to lowest number
                
                if state_A_mat_num < state_A_mech_num
                    state_A_beam = state_A_mat;
                    state_A_beam_num = state_A_mat_num;
                else
                    state_A_beam = state_A_mech;
                    state_A_beam_num = state_A_mech_num;
                end
            
        end
     if init_mat_A (k)==0
            init_mat_A(k)=mat_typeA(k); %track inital material assignment
     end
    
        
       if beam_profit_A(i,k)>0
        %satisficing design criteria has been met, there is positive profit
        stop =2;
        break;
       end

        

    
    
    end
end
%% Agile simulation data post-processing
mat_A_avg=mean(cntr_A_mat);
mat_A_std=std(cntr_A_mat);

figure(7)
plot (cntr_A_mat)
hold on
plot ([0 k],[mat_A_avg mat_A_avg],'k');
plot ([0 k],[mat_A_avg-mat_A_std mat_A_avg-mat_A_std],'k--');
plot ([0 k],[mat_A_avg+mat_A_std mat_A_avg+mat_A_std],'k--');
xlabel('Iteration Number');
ylabel('Number of 4 hour design sessions to complete materials design');
title ('Materials Engineer Agile Monte-Carlo Simulation');
legend('Simulation data', 'Mean of Simulation Data', 'Standard Deviation from the mean');
hold off

%Find average and standard deviation for mechanical engineer time worked

mech_A_avg=mean(cntr_A_mech);
mech_A_std=std(cntr_A_mech);

figure(8)
plot (cntr_A_mech)
hold on
plot ([0 k],[mech_A_avg mech_A_avg],'k');
plot ([0 k],[mech_A_avg-mech_A_std mech_A_avg-mech_A_std],'k--');
plot ([0 k],[mech_A_avg+mech_A_std mech_A_avg+mech_A_std],'k--');
xlabel('Iteration Number');
ylabel('Number of 4 hour design sessions to complete mechanical design');
title ('Mechanical Engineer Agile Monte-Carlo Simulation');
legend('Simulation data', 'Mean of Simulation Data', 'Standard Deviation from the mean');
hold off

%total time evaluation


total_A_avg=mean(total_A);
total_A_std=std(total_A);



figure(9)
scatter (x_ax, total_A,5)
hold on
plot ([0 k],[total_A_avg total_A_avg],'k','LineWidth',3);
plot ([0 k],[total_A_avg-total_A_std total_A_avg-total_A_std],'k--','LineWidth',3);
plot ([0 k],[total_A_avg+total_A_std total_A_avg+total_A_std],'k--','LineWidth',3);
xlabel('Simulation Run Number');
ylabel('Number of 4 hour design sessions to complete beam design');
title ('Agile Beam Design Monte-Carlo Simulation');
legend('Simulation data', 'Mean of Simulation Data', 'Standard Deviation from the mean');
ylim ([0 100])
hold off
%histograms
figure (10)
histogram (total_A);%,nbins);
hold on
xlabel ('Number of 4 hour design sessions to complete total beam design');
ylabel ('count');
title ('Histogram of agile simulation times');
xlim([0 80]);
ylim ([0 800]);
hold off

%create first success histogram
j=1;
k=1;
for i=1:10000
    if init_mat_A(i)==3
        first_success_A(j)=total_A(k);
        j=j+1;
    else
        other_success_A(k)=total_A(k);
        k=k+1;
    end
end

figure (11)
histogram(cntr_A_mat,bins1);%,nbins);%histogram (first_success_A);
hold on
xlabel ('Number of 4 hour design sessions to complete material design');
ylabel ('count');
title ('Histogram of agile simulation for materials design');
xlim([0 80]);
ylim ([0 1200]);
hold off

figure (12)
histogram (cntr_A_mech,bins2);%,nbins); %histogram (other_success_A);
hold on
xlabel ('Number of 4 hour design sessions to complete mechanical design');
ylabel ('count');
title ('Histogram of agile simulation times for mechanical design');
xlim([0 80]);
ylim ([0 1200]);
hold off
