with Physical_Types; use Physical_Types;

package Basic_Thermal_Model is

   type Block_Type is record
      Heater_PWM            : PWM_Scale;
      Heater_Max_Power      : Power;
      Block_Heat_Capacity   : Heat_Capacity;
      Block_Temperature     : Temperature;
      Block_To_Air_Transfer : Specific_Heat_Transfer_Coefficient;
      Air_Temperature       : Temperature;
   end record;

   procedure Update (Block : in out Block_Type; Step : Time);

end Basic_Thermal_Model;
