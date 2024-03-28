package body Basic_Thermal_Model is

   procedure Update (Block : in out Block_Type; Step : Time) is
   begin
      Block.Block_Temperature :=
        Block.Block_Temperature + Block.Heater_Max_Power * Block.Heater_PWM * Step / Block.Block_Heat_Capacity;
      Block.Block_Temperature :=
        Block.Block_Temperature -
        (Block.Block_Temperature - Block.Air_Temperature) * Block.Block_To_Air_Transfer * Step /
          Block.Block_Heat_Capacity;
   end Update;

end Basic_Thermal_Model;
