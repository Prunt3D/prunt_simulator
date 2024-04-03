with Physical_Types; use Physical_Types;

package Basic_Thermal_Model is

   type Block_Type is record
      Heater_PWM            : PWM_Scale with Volatile;
      Heater_Max_Power      : Power with Volatile;
      Block_Heat_Capacity   : Heat_Capacity with Volatile;
      Block_Temperature     : Temperature with Volatile;
      Block_To_Air_Transfer : Specific_Heat_Transfer_Coefficient with Volatile;
      Air_Temperature       : Temperature with Volatile;
   end record;

   procedure Update (Block : in out Block_Type; Step : Time);

end Basic_Thermal_Model;
