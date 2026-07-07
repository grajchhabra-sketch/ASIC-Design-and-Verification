    module rr_arbiter #(
    parameter N = 3
)(
    input              clk,
    input              reset,
    input  [N-1:0]     req,
    input              tx_done,
    output reg [N-1:0] grant
);

reg [1:0] last_grant;
reg busy;

always @(posedge clk or posedge reset)
begin

    if(reset)
    begin
        grant      <= 3'b000;
        last_grant <= 2'd2;
        busy       <= 1'b0;
    end

    else
    begin

        
        if(busy)
        begin

            if(tx_done)
            begin
                busy  <= 1'b0;
                grant <= 3'b000;
            end

        end


        else
        begin

            case(last_grant)

            2'd2:
            begin
                if(req[0])
                begin
                    grant      <= 3'b001;
                    last_grant <= 2'd0;
                    busy       <= 1'b1;
                end
                else if(req[1])
                begin
                    grant      <= 3'b010;
                    last_grant <= 2'd1;
                    busy       <= 1'b1;
                end
                else if(req[2])
                begin
                    grant      <= 3'b100;
                    last_grant <= 2'd2;
                    busy       <= 1'b1;
                end
            end


            2'd0:
            begin
                if(req[1])
                begin
                    grant      <= 3'b010;
                    last_grant <= 2'd1;
                    busy       <= 1'b1;
                end
                else if(req[2])
                begin
                    grant      <= 3'b100;
                    last_grant <= 2'd2;
                    busy       <= 1'b1;
                end
                else if(req[0])
                begin
                    grant      <= 3'b001;
                    last_grant <= 2'd0;
                    busy       <= 1'b1;
                end
            end


            2'd1:
            begin
                if(req[2])
                begin
                    grant      <= 3'b100;
                    last_grant <= 2'd2;
                    busy       <= 1'b1;
                end
                else if(req[0])
                begin
                    grant      <= 3'b001;
                    last_grant <= 2'd0;
                    busy       <= 1'b1;
                end
                else if(req[1])
                begin
                    grant      <= 3'b010;
                    last_grant <= 2'd1;
                    busy       <= 1'b1;
                end
            end

            default:
            begin
                grant <= 3'b000;
            end

            endcase

        end

    end

end


property p_onehot_grant;
@(posedge clk) disable iff(reset)
$onehot0(grant);
endproperty

assert property(p_onehot_grant)
else $error("Multiple masters granted simultaneously");

property p_hold_grant_until_done;
@(posedge clk) disable iff(reset)
busy && !tx_done |=> $stable(grant);
endproperty

assert property(p_hold_grant_until_done)
else $error("Grant changed before transaction completed");

endmodule
