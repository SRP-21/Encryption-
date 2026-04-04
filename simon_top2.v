module simon_top2(
    input clk,
    input rst,start,
    input [31:0] text,
    input [63:0] key,
    output reg [31:0] out,
    output reg idle, load, busy, done
);
 
parameter IDLE = 2'b00,
               LOAD = 2'b01,
               BUSY = 2'b10,
               DONE = 2'b11;
               
reg [1:0] CS, NS;
reg [15:0] rk [0:31];   // all round keys
reg [31:0] stagereg;
reg [5:0] i;
reg [15:0] key_val;
wire [31:0] round_out;

integer j;
reg [15:0] k0,k1,k2,k3,temp;


wire [15:0] c = 16'hfffc;
wire [63:0] z = 64'b11111010001001010110000111001101111101000100101011000011100110;




always @(*) begin
    k0 = key[15:0];
    k1 = key[31:16];
    k2 = key[47:32];
    k3 = key[63:48];

    rk[0] = k0;
    rk[1] = k1;
    rk[2] = k2;
    rk[3] = k3;

    for (j=4; j<32; j=j+1) begin
        temp = ({k3[2:0],k3[15:3]}) ^ k1;
        temp = temp ^ ({temp[0],temp[15:1]});

        rk[j] = k0 ^ temp ^ c ^ z[j-4]; 
        k3 = k2;
        k2 = k1;
        k1 = k0;
        k0 = rk[j];     
    end
end

simon_round2 s0 (.text(stagereg), .key(key_val) , .clk(clk), .rst(rst), .round_out(round_out));


    always @(posedge clk or posedge rst)
    begin
        if (rst)
            CS <= IDLE;
        else
            CS <= NS;
    end
    always @(*) begin
        NS = CS;
        case (CS)
            IDLE: if (start) NS = LOAD;
            LOAD: NS = BUSY;
            BUSY: if (i == 6'd31) NS = DONE;
            DONE: NS = IDLE;
            default: NS = IDLE;
        endcase
    end

    always @(*) begin
        idle = 0; load = 0; busy = 0; done = 0;
        case (CS)
            IDLE: idle = 1;
            LOAD: load = 1;
            BUSY: busy = 1;
            DONE: done = 1;
        endcase
    end


always@(posedge clk or posedge rst)
begin
if (rst)begin
stagereg <= 0;
key_val <= 0;
i <=0;
out <= 0;
end
else
begin
case(CS)
LOAD: begin
stagereg <= text;
key_val <= rk[0]; 
i <= 1;
end

BUSY: begin
 stagereg <= round_out;
    key_val <= rk[i+1];   
    i <= i+1;
end

DONE:begin
out <= stagereg;
i <= 0;
end

endcase
end
end
endmodule


