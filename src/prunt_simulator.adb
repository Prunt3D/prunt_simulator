-----------------------------------------------------------------------------
--                                                                         --
--                   Part of the Prunt Motion Controller                   --
--                                                                         --
--            Copyright (C) 2024 Liam Powell (liam@prunt3d.com)            --
--                                                                         --
--  This program is free software: you can redistribute it and/or modify   --
--  it under the terms of the GNU General Public License as published by   --
--  the Free Software Foundation, either version 3 of the License, or      --
--  (at your option) any later version.                                    --
--                                                                         --
--  This program is distributed in the hope that it will be useful,        --
--  but WITHOUT ANY WARRANTY; without even the implied warranty of         --
--  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the          --
--  GNU General Public License for more details.                           --
--                                                                         --
--  You should have received a copy of the GNU General Public License      --
--  along with this program.  If not, see <http://www.gnu.org/licenses/>.  --
--                                                                         --
-----------------------------------------------------------------------------

with Prunt;                   use Prunt;
with Prunt.Controller;
with System.Multiprocessors;
with Ada.Text_IO;             use Ada.Text_IO;
with Prunt.Controller_Generic_Types;
with Prunt.TMC_Types.TMC2240; use Prunt.TMC_Types.TMC2240;
with Prunt.TMC_Types;         use Prunt.TMC_Types;
with Prunt.Heaters;

procedure Prunt_Simulator is

   type Stepper_Name is new Axis_Name;

   type Heater_Name is (Hotend, Bed);

   type Fan_Name is (Fan_1, Fan_2);

   type Board_Temperature_Probe_Name is range 1..0;

   package My_Controller_Generic_Types is new Prunt.Controller_Generic_Types
     (Stepper_Name                 => Stepper_Name,
      Heater_Name                  => Heater_Name,
      Thermistor_Name              => Heater_Name,
      Board_Temperature_Probe_Name => Board_Temperature_Probe_Name,
      Fan_Name                     => Fan_Name,
      Input_Switch_Name            => Stepper_Name);

   use My_Controller_Generic_Types;

   procedure Setup
     (Heater_Thermistors : Heater_Thermistor_Map; Thermistors : Thermistor_Parameters_Array_Type) is null;
   procedure Reconfigure_Heater (Heater : Heater_Name; Params : Prunt.Heaters.Heater_Parameters) is null;
   procedure Reconfigure_Fan (Fan : Fan_Name; PWM_Freq : Fan_PWM_Frequency) is null;
   procedure Autotune_Heater (Heater : Heater_Name; Params : Prunt.Heaters.Heater_Parameters) is null;
   procedure Enable_Stepper (Stepper : Stepper_Name) is null;
   procedure Disable_Stepper (Stepper : Stepper_Name) is null;
   procedure Setup_For_Loop_Move (Switch : Stepper_Name; Hit_State : Pin_State) is null;
   procedure Setup_For_Conditional_Move (Switch : Stepper_Name; Hit_State : Pin_State) is null;
   procedure Reset_Position (Pos : Stepper_Position) is null;
   procedure Wait_Until_Idle (Last_Command : Command_Index) is null;
   procedure Shutdown is null;

   procedure Enqueue_Command (Command : Queued_Command) is
   begin
      Put_Line
        ("," & Command.Pos (X_Axis)'Image & "," & Command.Pos (Y_Axis)'Image & "," & Command.Pos (Z_Axis)'Image & "," &
         Command.Pos (E_Axis)'Image & ",,,,,");
   end Enqueue_Command;

   package My_Controller is new Prunt.Controller
     (Generic_Types              => My_Controller_Generic_Types,
      Stepper_Hardware           =>
        (others =>
           (Kind => Basic_Kind, Enable_Stepper => Enable_Stepper'Access, Disable_Stepper => Disable_Stepper'Access)),
      Interpolation_Time         => 0.000_1 * s,
      Loop_Interpolation_Time    => 0.000_1 * s,
      Setup                      => Setup,
      Reconfigure_Heater         => Reconfigure_Heater,
      Reconfigure_Fan            => Reconfigure_Fan,
      Autotune_Heater            => Autotune_Heater,
      Setup_For_Loop_Move        => Setup_For_Loop_Move,
      Setup_For_Conditional_Move => Setup_For_Conditional_Move,
      Enqueue_Command            => Enqueue_Command,
      Reset_Position             => Reset_Position,
      Wait_Until_Idle            => Wait_Until_Idle,
      Shutdown                   => Shutdown,
      Config_Path                => "./prunt_sim.toml");
begin
   My_Controller.Run;
end Prunt_Simulator;
