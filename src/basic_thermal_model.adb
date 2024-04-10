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
