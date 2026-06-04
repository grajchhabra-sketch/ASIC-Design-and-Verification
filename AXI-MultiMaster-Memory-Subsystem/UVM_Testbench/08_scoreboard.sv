
class axi_scoreboard extends uvm_scoreboard;

  `uvm_component_utils(axi_scoreboard)

  uvm_analysis_imp #(axi_txn,axi_scoreboard) sb_port;

  bit [31:0] mem [256];

  function new(string name,
               uvm_component parent);
    super.new(name,parent);
    sb_port = new("sb_port",this);
  endfunction

  function void build_phase(uvm_phase phase);

    super.build_phase(phase);

    foreach(mem[i])
      mem[i] = 0;

    `uvm_info("SB",
              "Scoreboard Built",
              UVM_LOW)

  endfunction

  function void write(axi_txn tx);

    int index;

    index = tx.addr[9:2];

    if(tx.write)
    begin

      mem[index] = tx.data;

      `uvm_info("SB",
      $sformatf(
      "WRITE ADDR=%h DATA=%h",
      tx.addr,
      tx.data),
      UVM_LOW)

    end
    else
    begin

      if(mem[index] != tx.rdata)
      begin

        `uvm_error("SB",
        $sformatf(
        "READ MISMATCH ADDR=%h EXP=%h GOT=%h",
        tx.addr,
        mem[index],
        tx.rdata))
      end
      else
      begin

        `uvm_info("SB",
        $sformatf(
        "READ MATCH ADDR=%h DATA=%h",
        tx.addr,
        tx.rdata),
        UVM_LOW)
      end

    end

  endfunction

endclass
