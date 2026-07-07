class axi_sequence extends uvm_sequence #(axi_transaction);

    `uvm_object_utils(axi_sequence)

    int num_tx = 200;

    function new(string name = "axi_sequence");
        super.new(name);
    endfunction

    task body();

        axi_transaction tx;

        repeat(num_tx)
        begin
            tx = axi_transaction::type_id::create("tx");

            start_item(tx);

            assert(tx.randomize())
            else
                `uvm_fatal("SEQ", "Randomization Failed")

            finish_item(tx);
        end

        directed_write(32'h00000000, 32'h00000000, 1);
        directed_write(32'h00000004, 32'h50000000, 0);
        directed_write(32'h00008000, 32'h90000000, 1);
        directed_write(32'h00008004, 32'hF0000000, 0);
        directed_write(32'hFFFFFFFC, 32'h00000001, 1);
        directed_write(32'hFFFFFFF8, 32'hFFFFFFFF, 0);

        directed_read(32'h00000000, 1);
        directed_read(32'h00000004, 0);
        directed_read(32'h00008000, 1);
        directed_read(32'h00008004, 0);
        directed_read(32'hFFFFFFFC, 1);
        directed_read(32'hFFFFFFF8, 0);

    endtask

    task directed_write(bit [31:0] addr,
                        bit [31:0] data,
                        bit bready_val);

        axi_transaction tx;

        tx = axi_transaction::type_id::create("tx");

        start_item(tx);

        tx.awvalid = 1;
        tx.arvalid = 0;
        tx.wvalid  = 1;
        tx.awaddr  = addr;
        tx.wdata   = data;
        tx.bready  = bready_val;
        tx.rready  = 1;

        finish_item(tx);

    endtask

    task directed_read(bit [31:0] addr,
                       bit rready_val);

        axi_transaction tx;

        tx = axi_transaction::type_id::create("tx");

        start_item(tx);

        tx.awvalid = 0;
        tx.arvalid = 1;
        tx.araddr  = addr;
        tx.bready  = 1;
        tx.rready  = rready_val;

        finish_item(tx);

    endtask

endclass
