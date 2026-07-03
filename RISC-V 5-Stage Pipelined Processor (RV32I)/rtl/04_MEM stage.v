module data_memory(

    input clk,

    input mem_read,
    input mem_write,

    input [2:0] funct3,

    input [31:0] address,
    input [31:0] write_data,

    output reg [31:0] read_data

);

    reg [7:0] mem [0:1023];

    // Write
    always @(posedge clk)
    begin

        if(mem_write)
        begin

            case(funct3)

                // SB
                3'b000:
                    mem[address] <= write_data[7:0];

                // SH
                3'b001:
                begin
                    mem[address]     <= write_data[7:0];
                    mem[address + 1] <= write_data[15:8];
                end

                // SW
                3'b010:
                begin
                    mem[address]     <= write_data[7:0];
                    mem[address + 1] <= write_data[15:8];
                    mem[address + 2] <= write_data[23:16];
                    mem[address + 3] <= write_data[31:24];
                end

            endcase

        end

    end


    // Read
    always @(*)
    begin

        read_data = 32'b0;

        if(mem_read)
        begin

            case(funct3)

                // LB
                3'b000:
                    read_data =
                    {{24{mem[address][7]}}, mem[address]};

                // LH
                3'b001:
                    read_data =
                    {{16{mem[address+1][7]}}, mem[address+1], mem[address]};

                // LW
                3'b010:
                    read_data =  {mem[address+3], mem[address+2], mem[address+1],mem[address]};

                // LBU
                3'b100:
                    read_data = {24'b0, mem[address]};

                // LHU
                3'b101:
                    read_data = {16'b0, mem[address+1], mem[address]};

                default:
                    read_data = 32'b0;

            endcase

        end

    end

endmodule
