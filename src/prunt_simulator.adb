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

procedure Prunt_Simulator is

   package Dimensionless_Text_IO is new Ada.Text_IO.Float_IO (Dimensionless);

   type Stepper_Name is new Axis_Name;

   type Heater_Name is (Hotend, Bed);

   type Fan_Name is (Fan_1, Fan_2);

   type Board_Temperature_Probe_Name is range 1 .. 0;

   package My_Controller_Generic_Types is new
     Prunt.Controller_Generic_Types
       (Stepper_Name                 => Stepper_Name,
        Heater_Name                  => Heater_Name,
        Thermistor_Name              => Heater_Name,
        Board_Temperature_Probe_Name => Board_Temperature_Probe_Name,
        Fan_Name                     => Fan_Name,
        Input_Switch_Name            => Stepper_Name);

   use My_Controller_Generic_Types;

   procedure Setup (Heater_Thermistors : Heater_Thermistor_Map; Thermistors : Thermistor_Parameters_Array_Type)
   is null;
   procedure Reconfigure_Heater (Heater : Heater_Name; Params : Heater_Parameters) is null;
   procedure Reconfigure_Fan (Fan : Fan_Name; PWM_Freq : Fan_PWM_Frequency) is null;
   procedure Autotune_Heater (Heater : Heater_Name; Params : Heater_Parameters) is null;
   procedure Enable_Stepper (Stepper : Stepper_Name) is null;
   procedure Disable_Stepper (Stepper : Stepper_Name) is null;
   procedure Setup_For_Loop_Move (Switch : Stepper_Name; Hit_State : Pin_State);
   procedure Setup_For_Conditional_Move (Switch : Stepper_Name; Hit_State : Pin_State);
   procedure Reset_Position (Pos : Stepper_Position);
   procedure Wait_Until_Idle (Last_Command : Command_Index) is null;
   procedure Reset is null;
   procedure Enqueue_Command (Command : Queued_Command);

   Max_Fan_Frequency : constant Frequency := 50_000.0 * hertz;

   package My_Controller is new
     Prunt.Controller
       (Generic_Types              => My_Controller_Generic_Types,
        Stepper_Hardware           =>
          (others =>
             (Kind => Basic_Kind, Enable_Stepper => Enable_Stepper'Access, Disable_Stepper => Disable_Stepper'Access)),
        Fan_Hardware               =>
          (others =>
             (Kind                            => Fixed_Switching_Kind,
              Reconfigure_Fixed_Switching_Fan => Reconfigure_Fan'Access,
              Maximum_PWM_Frequency           => Max_Fan_Frequency)),
        Interpolation_Time         => 0.000_1 * s,
        Loop_Interpolation_Time    => 0.000_1 * s,
        Setup                      => Setup,
        Reconfigure_Heater         => Reconfigure_Heater,
        Autotune_Heater            => Autotune_Heater,
        Setup_For_Loop_Move        => Setup_For_Loop_Move,
        Setup_For_Conditional_Move => Setup_For_Conditional_Move,
        Enqueue_Command            => Enqueue_Command,
        Reset_Position             => Reset_Position,
        Wait_Until_Idle            => Wait_Until_Idle,
        Reset                      => Reset,
        Config_Path                => "./prunt_sim.json");

   Loop_Switch              : Stepper_Name;
   Loop_Switch_Target_State : Pin_State;

   In_Conditional_Mode : Boolean := False;

   Current_Pos : Stepper_Position := (others => 0.0);
   Offset_Pos  : Stepper_Position := (others => 0.0);

   function "+" (Left, Right : Stepper_Position) return Stepper_Position is
   begin
      return (for S in Stepper_Name => Left (S) + Right (S));
   end "+";

   function "-" (Left, Right : Stepper_Position) return Stepper_Position is
   begin
      return (for S in Stepper_Name => Left (S) - Right (S));
   end "-";

   procedure Reset_Position (Pos : Stepper_Position) is
   begin
      Offset_Pos := Offset_Pos + Pos - Current_Pos;
      Current_Pos := Pos;
   end Reset_Position;

   procedure Setup_For_Loop_Move (Switch : Stepper_Name; Hit_State : Pin_State) is
   begin
      Loop_Switch := Switch;
      Loop_Switch_Target_State := Hit_State;
   end Setup_For_Loop_Move;

   procedure Setup_For_Conditional_Move (Switch : Stepper_Name; Hit_State : Pin_State) is
   begin
      if Hit_State = High_State then
         In_Conditional_Mode := Current_Pos (Switch) - Offset_Pos (Switch) < 0.0;
      else
         In_Conditional_Mode := Current_Pos (Switch) - Offset_Pos (Switch) >= 0.0;
      end if;
   end Setup_For_Conditional_Move;

   procedure Enqueue_Command (Command : Queued_Command) is
   begin
      if not In_Conditional_Mode then
         declare
            Offset : Stepper_Position := Current_Pos - Command.Pos;
         begin
            Current_Pos := Command.Pos;

            loop
               Put ("DATA OUTPUT,");
               Dimensionless_Text_IO.Put (Current_Pos (X_Axis) - Offset_Pos (X_Axis), Aft => 20, Exp => 1);
               Put (",");
               Dimensionless_Text_IO.Put (Current_Pos (Y_Axis) - Offset_Pos (Y_Axis), Aft => 20, Exp => 1);
               Put (",");
               Dimensionless_Text_IO.Put (Current_Pos (Z_Axis) - Offset_Pos (Z_Axis), Aft => 20, Exp => 1);
               Put (",");
               Dimensionless_Text_IO.Put (Current_Pos (E_Axis) - Offset_Pos (E_Axis), Aft => 20, Exp => 1);
               Put_Line ("");

               if Command.Loop_Until_Hit then
                  if Loop_Switch_Target_State = High_State then
                     exit when Current_Pos (Loop_Switch) - Offset_Pos (Loop_Switch) < 0.0;
                  else
                     exit when Current_Pos (Loop_Switch) - Offset_Pos (Loop_Switch) >= 0.0;
                  end if;

                  Offset_Pos := Offset_Pos + Offset;
               else
                  exit;
               end if;
            end loop;
         end;
      end if;

      if Command.Safe_Stop_After then
         In_Conditional_Mode := False;

         --  Send the command many times so the plotter can show it properly.
         for I in 0 .. 5 loop
            Put ("DATA OUTPUT,");
            Dimensionless_Text_IO.Put (Current_Pos (X_Axis) - Offset_Pos (X_Axis), Aft => 20, Exp => 1);
            Put (",");
            Dimensionless_Text_IO.Put (Current_Pos (Y_Axis) - Offset_Pos (Y_Axis), Aft => 20, Exp => 1);
            Put (",");
            Dimensionless_Text_IO.Put (Current_Pos (Z_Axis) - Offset_Pos (Z_Axis), Aft => 20, Exp => 1);
            Put (",");
            Dimensionless_Text_IO.Put (Current_Pos (E_Axis) - Offset_Pos (E_Axis), Aft => 20, Exp => 1);
            Put_Line ("");
         end loop;
      end if;

      My_Controller.Report_Last_Command_Executed (Command.Index);
   end Enqueue_Command;
begin
   My_Controller.Run;
end Prunt_Simulator;
