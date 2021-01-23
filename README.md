# uvm_wait_for_nba_region.svh
A program to demonstrate the race condition in TB and solve it !!

````systemverilog

We have a config_db call in base test to set the variable y and retreive it. 

If you comment out the code uvm_wait_for_nba_region from Initial block you would see the config db call Fatals out. Because the Get call doesn't see the Set call at all.

That is because of the System verilog Event scheduler.

First the initial, always blocks executes. When we call the run_test, the phases doesnt not start immediately, it waits for a #0.

To fix this, we have 2 ways either add the delay explicitly #0 and run it this pushes the event to farther end of the queue.

More cleaner way is to add uvm_wait_for_nba_region that waits for the first NBA to occur and then once you make the get call, you will see the value from set.

initial begin
   
    uvm_wait_for_nba_region;
     if (!(uvm_config_db#(int)::get(null, "*", "test_var", test))) 
       `uvm_fatal("Error", "Could not get value test var") 
       else `uvm_info("Initial block", $sformatf ("Retreived value is %d",test),UVM_LOW);
  end
  
  ````
