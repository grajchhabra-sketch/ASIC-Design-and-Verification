      
      class axi_scoreboard extends uvm_scoreboard;

    `uvm_component_utils(axi_scoreboard)

    uvm_analysis_imp #(axi_transaction, axi_scoreboard) mon2scb;

    function new(string name = "axi_scoreboard", uvm_component parent);
        super.new(name, parent);
        mon2scb = new("mon2scb", this);
    endfunction

    function void write(axi_transaction tx);

        $display("SCOREBOARD");

        if(tx.awvalid)
        begin
            $display("WRITE TRANSACTION");
            $display("Address : %h", tx.awaddr);
            $display("Data    : %h", tx.wdata);

            if(tx.wvalid)
                $display("RESULT  : WRITE PASS");
            else
                $display("RESULT  : WRITE FAIL (WDATA Missing)");
        end

        else if(tx.arvalid)
        begin
            $display("READ TRANSACTION");
            $display("Address : %h", tx.araddr);
            $display("RESULT  : READ PASS");
        end

        else
        begin
            $display("NO VALID TRANSACTION");
        end

    endfunction

endclass
