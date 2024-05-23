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

with Prunt; use Prunt;

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
