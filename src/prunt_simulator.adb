with Prunt_Glue;     use Prunt_Glue;
with Prunt_Glue.Glue;
with Physical_Types; use Physical_Types;
with System.Multiprocessors;
with Basic_Thermal_Model;

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

   type Low_Level_Time_Type is mod 2**64;

   Ticks_Per_Second : constant Low_Level_Time_Type := 54_000_000;

   function Time_To_Low_Level (T : Time) return Low_Level_Time_Type is
   begin
      return Low_Level_Time_Type (T / s * Dimensioned_Float (Ticks_Per_Second));
   end Time_To_Low_Level;

   function Low_Level_To_Time (T : Low_Level_Time_Type) return Time is
   begin
      return Dimensioned_Float (T) / Dimensioned_Float (Ticks_Per_Second) * s;
   end Low_Level_To_Time;

   Last_Time : Low_Level_Time_Type := 0;

   function Get_Time return Low_Level_Time_Type is
   begin
      for I in Heater_Name loop
         Basic_Thermal_Model.Update (Heater_Models (I), Low_Level_To_Time (1));
      end loop;

      Last_Time := @ + 1;
      return Last_Time;
   end Get_Time;

   type Stepper_Name is (X, Y, Z, E);

   procedure Set_Stepper_Pin_State (Stepper : Stepper_Name; Pin : Stepper_Output_Pins; State : Pin_State) is
   begin
      null;
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

   type Input_Switch_Name is (J5, J6, J7, J8);

   function Get_Input_Switch_State (Switch : Input_Switch_Name) return Pin_State is
   begin
      return Low_State;
   end Get_Input_Switch_State;

   procedure Toggle_Stepper_Pin_State (Stepper : Stepper_Name; Pin : Stepper_Output_Pins) is
   begin
      null;
   end Toggle_Stepper_Pin_State;

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
      Toggle_Stepper_Pin_State    => Toggle_Stepper_Pin_State,
      Get_Stepper_Pin_State       => Get_Stepper_Pin_State,
      Heater_Name                 => Heater_Name,
      Set_Heater_PWM              => Set_Heater_PWM,
      Thermistor_Name             => Heater_Name,
      Get_Thermistor_Voltage      => Get_Thermistor_Voltage,
      Fan_Name                    => Fan_Name,
      Set_Fan_PWM                 => Set_Fan_PWM,
      Set_Fan_Voltage             => Set_Fan_Voltage,
      Get_Fan_Frequency           => Get_Fan_Frequency,
      Input_Switch_Name           => Input_Switch_Name,
      Get_Input_Switch_State      => Get_Input_Switch_State,
      Planner_CPU                 => System.Multiprocessors.Not_A_Specific_CPU,
      Stepgen_Preprocessor_CPU    => 3,
      Stepgen_Pulse_Generator_CPU => 4,
      Config_Path                 => "./prunt_sim.toml",
      Interpolation_Time          => Time_To_Low_Level (0.005 * s));

begin
   My_Glue.Run;
end Prunt_Simulator;
