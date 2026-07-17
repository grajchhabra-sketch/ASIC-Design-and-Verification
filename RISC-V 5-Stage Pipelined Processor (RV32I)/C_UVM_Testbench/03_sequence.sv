
class riscv_sequence extends uvm_sequence #(riscv_seq_item);

    `uvm_object_utils(riscv_sequence)

    function new(string name = "riscv_sequence");
        super.new(name);
    endfunction

    task body();

        riscv_seq_item req;

      repeat (1000) begin

            req = riscv_seq_item::type_id::create("req");

            start_item(req);

            finish_item(req);

        end

    endtask

endclass
