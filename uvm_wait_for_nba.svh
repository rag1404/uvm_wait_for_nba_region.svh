// Code your testbench here
// or browse Examples
import uvm_pkg::*;
`include "uvm_macros.svh"
program tb;

// Simple transaction which has 3 fields data,addr,wr_en
class transaction extends uvm_object; 
  rand bit[3:0] data;
  rand bit[5:0] addr;
  rand bit wr_en;
  
  `uvm_object_utils_begin(transaction);
  `uvm_field_int(data,UVM_ALL_ON)
  `uvm_field_int(addr,UVM_ALL_ON)
  `uvm_field_int(wr_en,UVM_ALL_ON)
  `uvm_object_utils_end;
  
  
  function new (string name  = "transaction");
    super.new(name);
  endfunction  
    
endclass


// comp_a is the initator in this program which randomizes the transaction and calls the put method. 
class comp_a extends uvm_component;
  `uvm_component_utils (comp_a)
  
  uvm_blocking_put_port #(transaction) trans_out;
  
  function new (string name = "comp_a", uvm_component parent);
    super.new(name,parent);
  endfunction
  
   function void build_phase(uvm_phase phase);
     trans_out = new("trans_out",this);
  endfunction
  
  task run_phase (uvm_phase phase);
    transaction tx;
    
   
    tx = transaction::type_id::create("tx", this);
    
    void'(tx.randomize());
    `uvm_info(get_type_name(),$sformatf(" tranaction randomized"),UVM_LOW)
    tx.print();
    `uvm_info(get_type_name(),$sformatf(" tranaction sending to comp_b"),UVM_LOW)
    trans_out.put(tx);

  endtask  
  
endclass


// comp_b has a imp port where we need to implement the put method.
class comp_b extends uvm_component;
  `uvm_component_utils (comp_b)
  
 uvm_blocking_get_port #(transaction) trans_in;
 
  
  function new (string name = "comp_b", uvm_component parent);
    super.new(name,parent);
  endfunction
  
   function void build_phase(uvm_phase phase);
     trans_in = new("trans_in",this);
  endfunction
  
  task run_phase (uvm_phase phase);
    transaction trans;
    #100;
    `uvm_info(get_type_name(),$sformatf(" Received trans On comp_b "),UVM_LOW)
    trans_in.get(trans);
    `uvm_info(get_type_name(),$sformatf(" transaction from comp_a \n %s",trans.sprint()),UVM_LOW)


  endtask  
  
endclass




// env is connecting both the comp_a and parent_comp_b 
// env has a tlm_fifo which has put_export and get_export methods
// comp_a producer is connected to put_export while comp_b consumer is connected to get_export method
class my_env extends uvm_env;
  `uvm_component_utils(my_env)
  
  uvm_tlm_fifo #(transaction) tlm_fifo;
  comp_a test_a;
  comp_b test_b;
  
  function new (string name = "my_env", uvm_component parent=null);
    super.new(name,parent);
  endfunction
  
   function void build_phase(uvm_phase phase);
     test_a = comp_a::type_id::create("test_a",this);
     test_b = comp_b::type_id::create("test_b",this);
     tlm_fifo = new("tlm_fifo",this);
  endfunction
  
  function void connect_phase(uvm_phase phase);
    test_a.trans_out.connect(tlm_fifo.put_export);
    test_b.trans_in.connect(tlm_fifo.get_export);
  endfunction
 
  
endclass

class base_test extends uvm_test;

  `uvm_component_utils(base_test)
  
  int y = 5;
 
  my_env env;

  
  function new(string name = "base_test",uvm_component parent=null);
    super.new(name,parent);
  endfunction : new

 
   function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    uvm_config_db#(int)::set(null, "*", "test_var", y);
    env = my_env::type_id::create("env", this);
  endfunction : build_phase
  
 
  
   function void end_of_elaboration();
   
    print();
  endfunction
  
  virtual task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    #500;
    phase.drop_objection(this);
  endtask
  
endclass : base_test

int test;

  initial begin
    
    run_test("base_test");  
  end  
  
  initial begin
    //wait(0); 
   // #0;
    uvm_wait_for_nba_region;
     if (!(uvm_config_db#(int)::get(null, "*", "test_var", test))) 
       `uvm_fatal("Error", "Could not get value test var") 
       else `uvm_info("Initial block", $sformatf ("Retreived value is %d",test),UVM_LOW);
  end
  
endprogram
