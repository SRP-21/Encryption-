// =============================================================================
// Module  : simon_fsm
// Purpose : Control FSM for SIMON-32/64 encryption.
//           Sequences: IDLE -> LOAD (1 cycle) -> ROUND (32 cycles) -> DONE
// Round counter behaviour
//   - Cleared to 0 in LOAD state.
//   - Incremented every cycle in ROUND state.
//   - Transition ROUND -> DONE when round_cnt == 5'd31  (i.e. after the
//     32nd round_en pulse, rounds 0..31 have been applied).
// =============================================================================
module simon_fsm (
    input  wire clk,
    input  wire rst,      // active-low synchronous reset
    input  wire start,    // pulse high for one cycle to begin encryption
    output reg  load,     // asserted for one cycle to latch plaintext & key
    output reg  round_en, // asserted for 32 cycles (one per round)
    output reg  done      // pulses high for one cycle when encryption is done
);
-
    localparam [1:0]
        IDLE  = 2'b00,
        LOAD  = 2'b01,
        ROUND = 2'b10,
        DONE  = 2'b11;
  
    reg [1:0] cs, ns;
    reg [4:0] round_cnt;   // 0..31  (5 bits - wide enough for value 31)


    always @(posedge clk) begin
        if (!rst) begin
            cs        <= IDLE;
            round_cnt <= 5'd0;
        end
        else begin
            cs <= ns;

            // Round counter update (registered for synthesis cleanliness)
            case (cs)
                LOAD:  round_cnt <= 5'd0;
                ROUND: round_cnt <= round_cnt + 5'd1;
                default: round_cnt <= round_cnt; // hold
            endcase
        end
    end

-
    always @(*) begin
        ns = cs; // default: stay
        case (cs)
            IDLE:  if (start)                  ns = LOAD;
            LOAD:                              ns = ROUND;
            ROUND: if (round_cnt == 5'd31)     ns = DONE;
            DONE:                              ns = IDLE;
            default:                           ns = IDLE;
        endcase
    end


    always @(*) begin
        load     = 1'b0;
        round_en = 1'b0;
        done     = 1'b0;
        case (cs)
            LOAD:  load     = 1'b1;
            ROUND: round_en = 1'b1;
            DONE:  done     = 1'b1;
            default: ; // all outputs 0
        endcase
    end

endmodule
