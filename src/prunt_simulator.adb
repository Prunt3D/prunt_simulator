with Prunt_Glue;     use Prunt_Glue;
with Prunt_Glue.Glue;
with Physical_Types; use Physical_Types;
with System.Multiprocessors;
with Basic_Thermal_Model;
with Basic_Stepper_Model;
with Ada.Text_IO;    use Ada.Text_IO;

procedure Prunt_Simulator is

   type Heater_Name is (Hotend, Bed);

   Heater_Models : array (Heater_Name) of Basic_Thermal_Model.Block_Type :=
     [Hotend =>
       (Heater_PWM            => 0.0,
        Heater_Max_Power      => 50.0 * watt,
        Block_Heat_Capacity   => 30.0 * gram * 0.9 * joule / (gram * celcius),
        Block_Temperature     => 20.0 * celcius,
        Block_To_Air_Transfer => 0.2 * watt / celcius,
        Air_Temperature       => 20.0 * celcius),
     Bed     =>
       (Heater_PWM            => 0.0,
        Heater_Max_Power      => 50.0 * watt,
        Block_Heat_Capacity   => 300.0 * gram * 0.9 * joule / (gram * celcius),
        Block_Temperature     => 20.0 * celcius,
        Block_To_Air_Transfer => 0.5 * watt / celcius,
        Air_Temperature       => 20.0 * celcius)];

   subtype Stepper_Name is Axis_Name;

   Stepper_Models : array (Stepper_Name) of Basic_Stepper_Model.Stepper_Type :=
     [E_Axis => (Pos => 0.0 * mm, Mm_Per_Step => 0.000_001 * mm, others => <>),
     X_Axis  => (Pos => 50.0 * mm, Mm_Per_Step => 0.000_001 * mm, others => <>),
     Y_Axis  => (Pos => 0.1 * mm, Mm_Per_Step => 0.000_001 * mm, others => <>),
     Z_Axis  => (Pos => 50.0 * mm, Mm_Per_Step => 0.000_001 * mm, others => <>)];

   type Low_Level_Time_Type is mod 2**64;

   Ticks_Per_Second : constant Low_Level_Time_Type := 540_000_000;

   function Time_To_Low_Level (T : Time) return Low_Level_Time_Type is
   begin
      return Low_Level_Time_Type (T / s * Dimensioned_Float (Ticks_Per_Second));
   end Time_To_Low_Level;

   function Low_Level_To_Time (T : Low_Level_Time_Type) return Time is
   begin
      return Dimensioned_Float (T) / Dimensioned_Float (Ticks_Per_Second) * s;
   end Low_Level_To_Time;

   Last_Time        : Low_Level_Time_Type := 0 with
     Volatile;
   Last_Update_Time : Low_Level_Time_Type := 0 with
     Volatile;

   function Get_Time return Low_Level_Time_Type is
   begin
      --  TODO: Add locking here when more things start calling Get_Time.

      if Last_Time mod 270_000 = 0 then
         Put_Line
           (Low_Level_To_Time (Last_Time)'Image & "," & Stepper_Models (X_Axis).Pos'Image & "," &
            Stepper_Models (Y_Axis).Pos'Image & "," & Stepper_Models (Z_Axis).Pos'Image & "," &
            Stepper_Models (E_Axis).Pos'Image);
      end if;

      Last_Time := @ + 1;

      for I in Heater_Name loop
         Basic_Thermal_Model.Update (Heater_Models (I), Low_Level_To_Time (Last_Time - Last_Update_Time));
      end loop;

      Last_Update_Time := Last_Time;

      return Last_Time;
   end Get_Time;

   procedure Waiting_For_Time (T : Low_Level_Time_Type) is
      Next_Mod : constant Low_Level_Time_Type := (Last_Time + 269_999) / 270_000 * 270_000;
   begin
      if T > Last_Time then
         Last_Time := Low_Level_Time_Type'Min (T - 1, Next_Mod);
      end if;
   end Waiting_For_Time;

   procedure Set_Stepper_Pin_State (Stepper : Stepper_Name; Pin : Stepper_Output_Pins; State : Pin_State) is
   begin
      case Pin is
         when Step_Pin =>
            if Stepper_Models (Stepper).Step /= State then
               Basic_Stepper_Model.Take_Step (Stepper_Models (Stepper));
            end if;
            Stepper_Models (Stepper).Step := State;
         when Dir_Pin =>
            Stepper_Models (Stepper).Dir := State;
         when Enable_Pin =>
            null;
      end case;
   end Set_Stepper_Pin_State;

   procedure Set_Heater_PWM (Heater : Heater_Name; PWM : PWM_Scale) is
   begin
      Heater_Models (Heater).Heater_PWM := PWM;
   end Set_Heater_PWM;

   function Get_Thermistor_Voltage (Thermistor : Heater_Name) return Voltage is
   begin
      return Heater_Models (Thermistor).Block_Temperature * 1.0 * volt / celcius;
   end Get_Thermistor_Voltage;

   type Fan_Name is (Fan_1, Fan_2);

   procedure Set_Fan_PWM (Fan : Fan_Name; PWM : PWM_Scale) is
   begin
      null;
   end Set_Fan_PWM;

   procedure Set_Fan_Voltage (Fan : Fan_Name; Volts : Voltage) is
   begin
      null;
   end Set_Fan_Voltage;

   function Get_Fan_Frequency (Fan : Fan_Name) return Frequency is
   begin
      return 123.0 * hertz;
   end Get_Fan_Frequency;

   function Get_Input_Switch_State (Switch : Stepper_Name) return Pin_State is
   begin
      if Switch = Z_Axis then
         return (if Stepper_Models (Switch).Pos >= 100.0 * mm then High_State else Low_State);
      else
         return (if Stepper_Models (Switch).Pos <= 0.0 * mm then High_State else Low_State);
      end if;
   end Get_Input_Switch_State;

   function Get_Stepper_Pin_State (Stepper : Stepper_Name; Pin : Stepper_Input_Pins) return Pin_State is
   begin
      return Low_State;
   end Get_Stepper_Pin_State;

   package My_Glue is new Prunt_Glue.Glue
     (Low_Level_Time_Type         => Low_Level_Time_Type,
      Time_To_Low_Level           => Time_To_Low_Level,
      Low_Level_To_Time           => Low_Level_To_Time,
      Get_Time                    => Get_Time,
      Stepper_Name                => Stepper_Name,
      Set_Stepper_Pin_State       => Set_Stepper_Pin_State,
      Get_Stepper_Pin_State       => Get_Stepper_Pin_State,
      Heater_Name                 => Heater_Name,
      Set_Heater_PWM              => Set_Heater_PWM,
      Thermistor_Name             => Heater_Name,
      Get_Thermistor_Voltage      => Get_Thermistor_Voltage,
      Fan_Name                    => Fan_Name,
      Set_Fan_PWM                 => Set_Fan_PWM,
      Set_Fan_Voltage             => Set_Fan_Voltage,
      Get_Fan_Frequency           => Get_Fan_Frequency,
      Input_Switch_Name           => Stepper_Name,
      Get_Input_Switch_State      => Get_Input_Switch_State,
      Stepgen_Preprocessor_CPU    => 3,
      Stepgen_Pulse_Generator_CPU => 4,
      Config_Path                 => "./prunt_sim.toml",
      Interpolation_Time          => Time_To_Low_Level (0.000_5 * s),
      Waiting_For_Time            => Waiting_For_Time,
      Ignore_Empty_Queue          => True);

begin
   My_Glue.Run;
end Prunt_Simulator;
