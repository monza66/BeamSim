function [ cntr_WF_mech, state_WF_mech, proc_mech,mech, mech_design_formulation, reform_space, FOS_WF, beam_profit  ] = mech_eng( mech, state_WF_mech,stream, mech_design_formulation, cntr_WF_mech, reform_space, mat_type,local_opt,FOS, prof_mat )
% FBS simulation of a mechanical engineer working on a beam desgin


cntr_WF_mech=cntr_WF_mech+1; %Increment iteration counter by 1
         [state_WF_mech, proc_mech]= FBStrans(mech, state_WF_mech,stream);
               
        FOS_WF=0; %Initialize factor of safety
        beam_profit = 0; %Initialize profit
        design_choicei=0; % Setup marker to indicate that design has been synthesized
        % Unpack reform space vector
        if mat_type==4 % titanium has a different reform space vector since its profit is continuously decreasing
            reform3_space = reform_space(4);
            reform2_space = reform_space(3);
            reform1_space = reform_space(2);
            d_space = reform_space(1);
            
        else
            % other materials have a bell-shaped profit curve          
            
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
        
        if mech_design_formulation==1 %design variable choice and learning logic
           %design variable can't be chosen until next state is known
           % assume reformulation areas are 5 increments from the local
           % optimum
           if  proc_mech == 'rf1' %Type 1 reformulatin
               %choose random design variable 
               design_choice=rand(stream);
               %size design choice per reformulation 1 design space
               design_choice=round(design_choice*reform1_space);
              if mat_type==4
                  %one-sided version space learning
                   [ mech, reform1_space ] = FBSmatUpdate( 'rf1', mech, design_choice, reform1_space, 1,0 );
                   reform2_space=0;
                   reform3_space=0;
                   design_choicei=local_opt+d_space+design_choice;
              else
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
              end              
               FOS_WF=FOS(design_choicei,mat_type); %Set factor of safety
               beam_profit=prof_mat(design_choicei,mat_type);     %Determine profit
                              
           elseif proc_mech == 'rf2' %Type 2 reformulation
               %choose random design variable 
               design_choice=rand(stream);
               %size design choice per reformulation 2 design space
               design_choice=round(design_choice*reform2_space);
             if mat_type==4
                  %one-sided version space learning
                   [ mech, reform2_space ] = FBSmatUpdate( 'rf2', mech, design_choice, reform2_space, 1,0 );
                   reform3_space=0;
                   design_choicei=local_opt+d_space+reform1_space+design_choice;
              else
              
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
               FOS_WF=FOS(design_choicei,mat_type);
               beam_profit=prof_mat(design_choicei,mat_type); 
               mech_design_formulation=0; %design has to be reformulated
           elseif proc_mech =='rf3' %Type 3 reformulation
               %choose random design variable 
               design_choice=rand(stream);
               %size design choice per reformulation 3 design space
               design_choice=round(design_choice*reform3_space);
               if mat_type==4
                  %one-sided version space learning
                   [ mech, reform3_space ] = FBSmatUpdate( 'rf3', mech, design_choice, reform3_space, 1,0 );
                   design_choicei=local_opt+d_space+design_choice+reform1_space+reform2_space;
              else
               
            %find if design choice was in high or low space
               if design_choice<= reform3_spaceL
                   %low side choice
                   design_choicei=local_opt-d_spaceL-reform1_spaceL-reform2_spaceL-reform3_spaceL+design_choice;
                   %update transformation matrix based on version space
               %learning
                   [ mech, reform3_spaceL ] = FBSmatUpdate( 'rf3', mech, design_choice, reform3_spaceL, 2,reform3_space );
               else %high side choice
   
                   design_choicei=local_opt+d_spaceH+design_choice+reform2_spaceH+reform1_spaceH-reform3_spaceL;
                   %update transformation matrix based on version space
               %learning
                   [ mech, reform3_spaceH ] = FBSmatUpdate( 'rf3', mech, design_choice, reform3_spaceH, 3,reform3_space );
               end
               end
               
               FOS_WF=FOS(design_choicei,mat_type); %Set factor of safety
               beam_profit=prof_mat(design_choicei,mat_type); %Determine profit
               mech_design_formulation=0; %design has to be reformulated
           elseif proc_mech =='Doc'%Design has closed and documentation phase has been reached
               
               %choose random design variable 
               design_choice=rand(stream);
               %size design choice per documentation design space
               design_choice=round(design_choice*d_space);
               if mat_type==4
                  design_choicei=local_opt+design_choice;
                  reform1_space=0;
                  reform2_space=0;
                  reform3_space=0;
               else
                 design_choicei=local_opt-d_spaceL+design_choice; %Since using satisficing criteria, no need to further reduce version space once d space is reached,
                 reform3_spaceL= 0;
                reform3_spaceH= 0;
                reform2_spaceL=0;
                reform2_spaceH= 0;
                reform1_spaceL=0;
                reform1_spaceH= 0;
               end
               
               
               FOS_WF=FOS(design_choicei,mat_type); %Set factor of safety
               beam_profit=prof_mat(design_choicei,mat_type); %Determine profit
          else %error
               disp('Error: invalid state in mech_eng');
                              
           end
      
        end
        if proc_mech == 'syn' %design has been synthesized and first variable can be chosen
        mech_design_formulation=1; %design has been formulated    
        end
            
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


end

