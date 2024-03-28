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
