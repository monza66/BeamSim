function [ beam_profit,  mat_matrix, reform_space, mech, mat, state_A_mat, state_A_mech, cntr_A_mat, cntr_A_mech, mat_type ] = Agile_eval( mat_type, profit, reform_space, mat_matrix, mech, mat, stream,state_A_mat, state_A_mech, cntr_A_mat, cntr_A_mech   )
%Converts mechanical engineer and materials engineer design choices to a
%profit and modifies design space based on random draw
%   Mechanical engineer design choices are made in this function
%   A type 1 or type 2 reformulation only changes the mechanical design. A type 3
%   reformulation changes the material design as well. Type 1 reformulation
%   will change material design if mechanical design space has been
%   narrowed to a small number (5 or less).

[unused, proc_mat, state_A_mat, cntr_A_mat] = mat_engA( mat, state_A_mat,stream, mat_matrix,cntr_A_mat ); %Advance materials engineer
[cntr_A_mech, state_A_mech, proc_mech] = mech_engA( mech, state_A_mech,stream, cntr_A_mech); %Advance mechanical engineer
%use worst-case reformulation as the system reformulation compare all
%possibilities and use worst-case reformulation

if (strcmp(proc_mat,'rf3')) || (strcmp(proc_mech,'rf3'))
    proc_beam = 'rf3';
    state_A_mat= 'Fn';
    state_A_mech = 'Fn';
elseif(strcmp(proc_mat,'rf2')) || (strcmp(proc_mech,'rf2'))
    proc_beam = 'rf2';
    state_A_mat= 'St';
    state_A_mech = 'Be';
elseif(strcmp(proc_mat,'rf1')) || (strcmp(proc_mech,'rf1'))
    proc_beam = 'rf1';
    state_A_mat= 'St';
    state_A_mech = 'St';
elseif(strcmp(proc_mat,'Doc')) && (strcmp(proc_mech,'Doc'))
    proc_beam = 'Doc';
    state_A_mat= 'Dc';
    state_A_mech = 'Dc';
else
    disp('Error: invalid state in Agile_eval reformulations')
end

%divide design space into reformulation space - assuming that reformulation
%is fundamentally different with an agile approach. Since both designers
%are involved at the same time they reformulate the design together rather
%than a piece at a time.

% find local optimum for 30 cross section choices given material choice
 local_opt=0;
 profmax=-10000000;
 
  for j=1:30
      if profit(j,mat_type)> profmax
          profmax =profit(j,mat_type);
          local_opt =j;
      end
               
  end
% reform space needs to be created for each material for reformulation
% types 1, 2 and 3. Documentation is another possible state and is the
% D_space
  if mat_type==4 % titanium has a different reform space vector since its profit is continuously decreasing
    reform3_space = reform_space(4);
    reform2_space = reform_space(3);
    reform1_space = reform_space(2);
    d_space = reform_space(1);

else
    % other materials have a bell-shaped profit curve L= low side H= high side          

    reform3_spaceL= reform_space(1);
    reform3_spaceH= reform_space(8);
    reform2_spaceL=reform_space(2);
    reform2_spaceH= reform_space(7);
    reform1_spaceL=reform_space(3);
    reform1_spaceH= reform_space(6);
    d_spaceL=reform_space(4);
    d_spaceH=reform_space(5);
    
        %Sum up total available space   
    reform3_space = reform3_spaceL+reform3_spaceH;
    reform2_space = reform2_spaceL+reform2_spaceH;
    reform1_space = reform1_spaceL+reform1_spaceH;
    d_space = d_spaceL+d_spaceH;
    
  end
 %For type 1 reformulation
           if  proc_beam == 'rf1'
               %'rf1'
               %choose random design variable 
               design_choice=rand(stream);
               %size design choice per reformulation 1 design space
               design_choice=round(design_choice*reform1_space);
              if mat_type==4 %for titanium
                  %one-sided version space learning
                   [ mech, reform1_space ] = FBSmatUpdate( 'rf1', mech, design_choice, reform1_space, 1,0 );
                   reform2_space=0;
                   reform3_space=0;
                   design_choicei=local_opt+d_space+design_choice;
                   % setup materials update if design space is sufficiently
                   % narrowed
                   %repack reform space matrix
                    reform_space(1)=d_space;
                    reform_space(2)=reform1_space;
                    reform_space(3)=reform2_space;
                    reform_space(4)=reform3_space;
                   if (sum(reform_space) <=5) %assume that enough design space has been covered to know that current design process won't work and material needs to be changed. 5 is the width of d_space
                       old_mat= sum(mat_matrix);
                       
                       [ mat_matrix ] = mat_learn( mat_type, mat_matrix ); %Perform version space learning for materials engineer
                       % reset materials engineer's effort
                       state_A_mat='Fn';
                       [ mat, unused ] = FBSmatUpdate( 'rf3', mat, sum(mat_matrix), old_mat, 1,0 ); %treat the change as a rf3 process
                       mat_type=0;
                       %reset mechanical engineer's effort
                      mech = [ .1 .9 0 0 0 
                                0 .2 .8 0 0 
                                0 0 .3 .7 0
                                0 .1 .2 .4 .3
                                0 0 0 0 1];
                      reform_space= 0;
                           
                      state_A_mech='Fn';
                   end
              else % for other material choices
               %find if design choice was in high or low space
               if design_choice<= reform1_spaceL
                   %low side choice
                   design_choicei=local_opt-d_spaceL-reform1_spaceL+design_choice;
                   %update transformation matrix based on version space
               %learning
                   [ mech, reform1_spaceL ] = FBSmatUpdate( 'rf1', mech, design_choice, reform1_spaceL, 2,reform1_space );
                   reform2_spaceL=0;
                   reform3_spaceL=0;
               else %high side choice
                   design_choicei=local_opt+d_spaceH+design_choice-reform1_spaceL;
                   reform2_spaceH=0;
                   reform3_spaceH=0;
                   %update transformation matrix based on version space
               %learning
                   [ mech, reform1_spaceH ] = FBSmatUpdate( 'rf1', mech, design_choice, reform1_spaceH, 3,reform1_space );
               end
               %repack reform_space vector
               reform_space(1)= reform3_spaceL;
                reform_space(8)= reform3_spaceH;
                reform_space(2)=reform2_spaceL;
                reform_space(7)=reform2_spaceH;
                reform_space(3)=reform1_spaceL;
                reform_space(6)=reform1_spaceH;
                reform_space(4)=d_spaceL;
                reform_space(5)= d_spaceH;
                    if (sum(reform_space) <=5)&& (mat_type~=3) %assume that enough design space has been covered to know that current design process won't work and material needs to be changed. 5 is the width of d_space
                       old_mat= sum(mat_matrix);
                       
                       [ mat_matrix ] = mat_learn( mat_type, mat_matrix ); %Perform version space learning for materials engineer
                       % reset materials engineer's effort
                       state_A_mat='Fn';
                       [ mat, unused ] = FBSmatUpdate( 'rf3', mat, sum(mat_matrix), old_mat, 1,0 ); %treat the change as a rf3 process
                       mat_type=0;
                       %reset mechanical engineer's effort
                      mech = [ .1 .9 0 0 0 
                                0 .2 .8 0 0 
                                0 0 .3 .7 0
                                0 .1 .2 .4 .3
                                0 0 0 0 1];
                      d_space = 4;
                      reform_space = 0;
                      state_A_mech='Fn';
                   end 
               
               
              end
               %FOS_WF=FOS(design_choicei,mat_type);
               if mat_type ~=0
                    beam_profit=profit(design_choicei,mat_type); %current evaluation of beam profit
               else
                   beam_profit=0;
               end    
                              
                    
           
          %Type 2 reformulation 
           elseif proc_beam == 'rf2'
              % 'rf2'
               % type 2 reformulation is assumed to be limitied to
               % mechanical design space narrowing
                %choose random design variable 
               design_choice=rand(stream);
               %size design choice per reformulation 2 design space
               design_choice=round(design_choice*reform2_space);
             if mat_type==4 %Titanium
                  %one-sided version space learning
                   [ mech, reform2_space ] = FBSmatUpdate( 'rf2', mech, design_choice, reform2_space, 1,0 );
                   reform3_space=0;
                  % local_opt
                  % d_space
                  % reform1_space
                  % design_choice
                  % reform2_space
                   design_choicei=local_opt+d_space+reform1_space+design_choice;
                   
             else %Other materials
              
               %find if design choice was in high or low space
               if design_choice<= reform2_spaceL
                   %low side choice
                   design_choicei=local_opt-d_spaceL-reform1_spaceL-reform2_spaceL+design_choice;
                   
                   %update transformation matrix based on version space
               %learning
                   [ mech, reform2_spaceL ] = FBSmatUpdate( 'rf2', mech, design_choice, reform2_spaceL, 2,reform2_space );
                   reform3_spaceL=0;
               else %high side choice
                   design_choicei=local_opt+d_spaceH+reform1_spaceH+design_choice-reform2_spaceL;
               %update transformation matrix based on version space
               %learning
                   [ mech, reform2_spaceH ] = FBSmatUpdate( 'rf2', mech, design_choice, reform2_spaceH, 3,reform2_space );
                   reform3_spaceH=0;
                   
               end
             end           
               %FOS_WF=FOS(design_choicei,mat_type);
               
               if mat_type ~=0
                   
                   beam_profit=profit(design_choicei,mat_type); %current evaluation of beam profit
               else
                   beam_profit=0;
               end 
              % mech_design_formulation=0; %design has to be reformulated
               
                          %repack reform_space vector
                    if mat_type==4
                        reform_space(1)=d_space;
                        reform_space(2)=reform1_space;
                        reform_space(3)=reform2_space;
                        reform_space(4)=reform3_space;
                    else
                            reform_space(1)= reform3_spaceL;
                            reform_space(8)= reform3_spaceH;
                            reform_space(2)=reform2_spaceL;
                            reform_space(7)=reform2_spaceH;
                            reform_space(3)=reform1_spaceL;
                            reform_space(6)=reform1_spaceH;
                            reform_space(4)=d_spaceL;
                            reform_space(5)= d_spaceH;
                    end
               
               
          %Type 3 reformulation     
           elseif proc_beam =='rf3'
            
              % type 3 reformulation is of material type
              %choose mechanical engineer's random design variable 
               design_choice=rand(stream);
               %size design choice as a random variable across full design
               %set since RF3 doesn't narrow any of the mechanical
               %engineer's design decisions.
               design_choicei=ceil(design_choice*30);
              
              if mat_type ==3 % optimal material is chosen, but it isn't known that it is optimal yet, 
                  %assume that reformulation effort discovers this is the
                  %best material to use
                  mat_matrix = [0, 0, 1, 0];
                  [ mat, unused ] = FBSmatUpdate( 'rf3', mat, 1, 1, 1,0 );
                  % reform space stays the same since it is for the mechanical
               % engineer
              else % non-optimal material selected, use version space learning to narrow down design space
              old_mat= sum(mat_matrix);
              
              [ mat_matrix ] = mat_learn( mat_type, mat_matrix );
              mat_type=0;
              reform_space=0;
              [ mat, unused ] = FBSmatUpdate( 'rf3', mat, sum(mat_matrix), old_mat, 1,0 );
              end
               
               if mat_type ~=0
                   
                    beam_profit=profit(design_choicei,mat_type); %current evaluation of beam profit
               else
                   beam_profit=0;
               end
                         
               
         % Documentation phase is the final possibility      
           elseif proc_beam =='Doc' %Design has closed and documentation phase has been reached
            
               %choose random design variable 
               design_choice=rand(stream);
               %size design choice per design space
               design_choice=round(design_choice*d_space);
               if mat_type==4
                   design_choicei=local_opt+design_choice;
               else
                   design_choicei=local_opt-d_spaceL+design_choice; 
               end
               %Perform type 3 reformulation if material is not optimal
               %assuming that once a design reaches documentation space
               %enough is known to know that further improvements will need
               %a materials change
               if mat_type ~=3  % non-optimal material selected, use version space learning to narrow down design space
                  old_mat= sum(mat_matrix);
                  
                  [ mat_matrix ] = mat_learn( mat_type, mat_matrix ); %perform material engineer learning
                  mat_type=0;
                  [ mat, unused ] = FBSmatUpdate( 'rf3', mat, sum(mat_matrix), old_mat, 1,0 );
                  
                  % reset materials engineer's effort
                       state_A_mat='Fn';
                                             
                       %reset mechanical engineer's effort
                      mech = [ .1 .9 0 0 0 
                                0 .2 .8 0 0 
                                0 0 .3 .7 0
                                0 .1 .2 .4 .3
                                0 0 0 0 1];
                      %d_space = 4;
                      reform_space = 0;
                      state_A_mech='Fn';
                  
                                              
                  
               else %optimal material has been chosen and design can close
                 
                reform3_spaceL= 0;
                reform3_spaceH= 0;
                reform2_spaceL=0;
                reform2_spaceH= 0;
                reform1_spaceL=0;
                reform1_spaceH= 0;
                %repack reform space vector
                    
                reform_space(1)= reform3_spaceL;
                reform_space(8)= reform3_spaceH;
                reform_space(2)=reform2_spaceL;
                reform_space(7)=reform2_spaceH;
                reform_space(3)=reform1_spaceL;
                reform_space(6)=reform1_spaceH;
                reform_space(4)=d_spaceL;
                reform_space(5)= d_spaceH;
                
                
               end

               
               
               %FOS_WF=FOS(design_choicei,mat_type);
               if mat_type ~=0
                    beam_profit=profit(design_choicei,mat_type); %current evaluation of beam profit
               else
                   beam_profit=0;
               end
           else %error 
               disp('Invalid beam state for agile evaluation');
               
           end






end

