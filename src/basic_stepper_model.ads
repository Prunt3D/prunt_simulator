with Physical_Types; use Physical_Types;
with Prunt_Glue;     use Prunt_Glue;

package Basic_Stepper_Model is

   type Stepper_Type is record
      Pos         : Length with Volatile;
      Mm_Per_Step : Length with Volatile;
      Dir         : Pin_State := Low_State with Volatile;
      Step        : Pin_State := Low_State with Volatile;
   end record;

   procedure Take_Step (Stepper : in out Stepper_Type);

end Basic_Stepper_Model;
