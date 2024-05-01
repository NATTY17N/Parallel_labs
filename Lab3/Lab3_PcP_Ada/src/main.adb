with Ada.Text_IO; use Ada.Text_IO;
with GNAT.Semaphores; use GNAT.Semaphores;
with Ada.Containers.Indefinite_Doubly_Linked_Lists;
use Ada.Containers.Indefinite_Doubly_Linked_Lists;
with Ada.Numerics.Discrete_Random;

procedure Main is
   package String_Lists is new Indefinite_Doubly_Linked_Lists (String);

   type RandRange is range 1 .. 100;

   protected ProductionControl is
      procedure Set_Total_Items (Total : in Integer);
      procedure Decrement_Produced_Items;
      procedure Decrement_Consumed_Items;
      function Is_Production_Complete return Boolean;
      function Is_Consumption_Complete return Boolean;
   private
      Left_Produced_Items : Integer := 0;
      Left_Consumed_Items : Integer := 0;
   end ProductionControl;

   protected body ProductionControl is
      procedure Set_Total_Items (Total : in Integer) is
      begin
         Left_Produced_Items := Total;
         Left_Consumed_Items := Total;
      end Set_Total_Items;

      procedure Decrement_Produced_Items is
      begin
         if Left_Produced_Items > 0 then
            Left_Produced_Items := Left_Produced_Items - 1;
         end if;
      end Decrement_Produced_Items;

      procedure Decrement_Consumed_Items is
      begin
         if Left_Consumed_Items > 0 then
            Left_Consumed_Items := Left_Consumed_Items - 1;
         end if;
      end Decrement_Consumed_Items;

      function Is_Production_Complete return Boolean is
      begin
         return Left_Produced_Items = 0;
      end Is_Production_Complete;

      function Is_Consumption_Complete return Boolean is
      begin
         return Left_Consumed_Items = 0;
      end Is_Consumption_Complete;

   end ProductionControl;

   Storage_Size  : Integer := 3;
   Num_Suppliers : Integer := 1;
   Num_Receivers : Integer := 4;
   Total_Items   : Integer := 10;

   Storage        : String_Lists.List;
   Access_Control : Counting_Semaphore (1, Default_Ceiling);
   Full_Storage   : Counting_Semaphore (Storage_Size, Default_Ceiling);
   Empty_Storage  : Counting_Semaphore (0, Default_Ceiling);

   task type Supplier is
      entry Initialize (ID : Integer);
   end Supplier;

   task body Supplier is
      package Random_Int is new Ada.Numerics.Discrete_Random (RandRange);
      use Random_Int;
      Supplier_ID   : Integer;
      Random_Gen : Generator;
      Item_Value : Integer;
   begin
      accept Initialize (ID : Integer) do
         Supplier_ID := ID;
      end Initialize;
      Reset (Random_Gen);
      while not ProductionControl.Is_Production_Complete loop
         ProductionControl.Decrement_Produced_Items;
         Full_Storage.Seize;
         Access_Control.Seize;

         Item_Value := Integer (Random (Random_Gen));
         Storage.Append ("item" & Item_Value'Img);
         Put_Line ("Supplier #" & Supplier_ID'Img & " adds item" & Item_Value'Img);

         Access_Control.Release;
         Empty_Storage.Release;
      end loop;
      Put_Line
        ("Supplier #" & Supplier_ID'Img & " finished working");
   end Supplier;

   task type Receiver is
      entry Initialize (ID : Integer);
   end Receiver;

   task body Receiver is
      Receiver_ID : Integer;
   begin
      accept Initialize (ID : Integer) do
         Receiver_ID := ID;
      end Initialize;
      while not ProductionControl.Is_Consumption_Complete loop
         ProductionControl.Decrement_Consumed_Items;
         Empty_Storage.Seize;
         Access_Control.Seize;

         declare
            Item_Value : String := First_Element (Storage);
         begin
            Put_Line
              ("Receiver #" & Receiver_ID'Img & " took " & Item_Value);
            Storage.Delete_First;

            Access_Control.Release;
            Full_Storage.Release;
         end;
      end loop;
      Put_Line("Receiver #" & Receiver_ID'Img & " finished working");
   end Receiver;

   type Supplier_Array is array (Integer range <>) of Supplier;
   type Receiver_Array is array (Integer range <>) of Receiver;

begin
   declare
      Suppliers : Supplier_Array (1 .. Num_Suppliers);
      Receivers : Receiver_Array (1 .. Num_Receivers);
   begin
      ProductionControl.Set_Total_Items (Total => Total_Items);

      for I in 1 .. Num_Suppliers loop
         Suppliers (I).Initialize (I);
      end loop;

      for I in 1 .. Num_Receivers loop
         Receivers (I).Initialize (I);
      end loop;

   end;
end Main;
