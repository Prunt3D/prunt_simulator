with Physical_Types; use Physical_Types;
with Prunt_Glue;     use Prunt_Glue;

package Basic_Stepper_Model is

   type Stepper_Type is record
      Pos         : Length;
      Mm_Per_Step : Length;
      Dir         : Pin_State := Low_State;
      Step        : Pin_State := Low_State;
   end record;

   procedure Take_Step (Stepper : in out Stepper_Type);

end Basic_Stepper_Model;
