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

package body Basic_Stepper_Model is

   procedure Take_Step (Stepper : in out Stepper_Type) is
   begin
      case Stepper.Dir is
         when Low_State =>
            Stepper.Pos := Stepper.Pos - Stepper.Mm_Per_Step;
         when High_State =>
            Stepper.Pos := Stepper.Pos + Stepper.Mm_Per_Step;
      end case;
   end Take_Step;

end Basic_Stepper_Model;
