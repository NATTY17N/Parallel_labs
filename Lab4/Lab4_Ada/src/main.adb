with Ada.Text_IO; use Ada.Text_IO;
with GNAT.Semaphores; use GNAT.Semaphores;

procedure Main is

   protected type My_Semaphore (Start_Count : Integer := 1) is
      entry Acquire;
      procedure Release;
      function Get_Count return Integer;
   private
      Counter : Integer := Start_Count;
   end My_Semaphore;

   protected body My_Semaphore is

      entry Acquire when Counter > 0 is
      begin
         Counter := Counter - 1;
      end Acquire;

      procedure Release is
      begin
         Counter := Counter + 1;
      end Release;

      function Get_Count return Integer is
      begin
         return Counter;
      end Get_Count;

   end My_Semaphore;

   Fork_Semaphores : array (1 .. 5) of My_Semaphore (1);
   Room_Semaphore : Counting_Semaphore (2, Default_Ceiling);

   task type Philosopher_Arbitrator is
      entry Start (Philosopher_ID : Integer);
   end Philosopher_Arbitrator;

   task body Philosopher_Arbitrator is
      Philosopher_ID : Integer;
      Left_Fork_ID, Right_Fork_ID : Integer;
   begin
      accept Start (ID : in Integer) do
         Philosopher_ID := ID;
      end Start;
      Left_Fork_ID  := Philosopher_ID;
      Right_Fork_ID := Philosopher_ID rem 5 + 1;

      for I in 1 .. 10 loop
         Put_Line ("Philosopher " & Philosopher_ID'Img & " is hungry for the " & I'Img & "th time");
         while True loop
            Room_Semaphore.Seize;
            if Fork_Semaphores(Left_Fork_ID).Get_Count > 0 and
               Fork_Semaphores(Right_Fork_ID).Get_Count > 0
            then
               Fork_Semaphores(Left_Fork_ID).Acquire;
               Fork_Semaphores(Right_Fork_ID).Acquire;
               exit;
            else
               Room_Semaphore.Release;
            end if;
         end loop;
         Room_Semaphore.Release;
         Put_Line ("Philosopher " & Philosopher_ID'Img & " is eating for the " & I'Img & "th time");

         Fork_Semaphores(Left_Fork_ID).Release;
         Fork_Semaphores(Right_Fork_ID).Release;

         Put_Line ("Philosopher " & Philosopher_ID'Img & " finished eating");
      end loop;
   end Philosopher_Arbitrator;

   Philosophers : array (1 .. 5) of Philosopher_Arbitrator;
begin
   for I in Philosophers'Range loop
      Philosophers(I).Start(I);
   end loop;

end Main;
