// =============================================================================
// Testbench : simon_top_tb
// Purpose   : Verify SIMON-32/64 using EXACTLY the values from the NSA paper
//             eprint.iacr.org/2013/404.pdf, Appendix B and Appendix C.
// ─────────────────────────────────────────────────────────────────────────────
// WHAT APPENDIX B AND C CONTAIN
// ─────────────────────────────────────────────────────────────────────────────
//  Appendix B (Table B.1): One test vector per cipher variant
//  TV1 - Appendix B (full 32-round encrypt):
//    key  = 1918 1110 0908 0100
//    pt   = (x=6565, y=6877)  =>  data_in = 32'h6565_6877
//    ct   = (c69b, e9bb)      =>  expected = 32'hc69b_e9bb
// ─────────────────────────────────────────────────────────────────────────────
// ROUND FUNCTION CONVENTION (matches paper exactly)
//   (x, y) -> ( y ^ f(x) ^ k ,  x )   where  f(x) = (x<<<1 & x<<<8) ^ x<<<2
//   data_in[31:16] = x (left word),  data_in[15:0] = y (right word)
// ─────────────────────────────────────────────────────────────────────────────
`timescale 1ns / 1ps

module simon_top_tb;

    reg         clk;
    reg         rst;
    reg         start;
    reg  [31:0] data_in;
    reg  [63:0] key;
    wire [31:0] data_out;
    wire        done;

    simon_top dut (
        .clk     (clk),
        .rst     (rst),
        .start   (start),
        .data_in (data_in),
        .key     (key),
        .data_out(data_out),
        .done    (done)
    );

    initial clk = 1'b0;
    always  #5 clk = ~clk;

    integer pass_count;
    integer fail_count;

 
    task run_test;
        input [63:0] test_key;
        input [31:0] test_pt;
        input [31:0] test_ct;
        input [7:0]  test_num;
        input [63:0] unused;   
        begin
            rst     = 1'b0;
            start   = 1'b0;
            data_in = test_pt;
            key     = test_key;
            @(posedge clk); #1;
            rst     = 1'b1;
            @(posedge clk); #1;

            start = 1'b1;
            @(posedge clk); #1;
            start = 1'b0;

            wait (done);
            @(posedge clk); #1;

            if (data_out === test_ct) begin
                $display("[PASS] TV%0d  key=%h  pt=%h  ct=%h",
                         test_num, test_key, test_pt, data_out);
                pass_count = pass_count + 1;
            end else begin
                $display("[FAIL] TV%0d  key=%h  pt=%h",
                         test_num, test_key, test_pt);
                $display("       got      = %h", data_out);
                $display("       expected = %h", test_ct);
                fail_count = fail_count + 1;
            end

            repeat (4) @(posedge clk);
        end
    endtask


    initial begin
        pass_count = 0;
        fail_count = 0;

        // ==================================================================
        // TV1 - NSA paper (2013) Appendix B, Table B.
        //   Direct quote from the paper:
        //     Key:        1918  1110  0908  0100
        //     Plaintext:  6565  6877
        //     Ciphertext: c69b  e9bb
        //
        //   Verilog mapping (x = left word, y = right word):
        //     data_in  = {x, y} = 32'h6565_6877
        //     key      = 64'h1918_1110_0908_0100
        //     expected = 32'hc69b_e9bb
        // ==================================================================
        run_test(
            64'h1918_1110_0908_0100,   // key  - paper's key exactly
            32'h6565_6877,              // pt   - paper's Appendix B plaintext
            32'hc69b_e9bb,              // ct   - paper's Appendix B ciphertext
            8'd1,
            64'd0
        );

        run_test(
            64'h1918_1110_0908_0100,   // same key as Appendix B/C
            32'h6fc2_1587,              // pt = Appendix C Pt_16 value
            32'h1e6c_6815,              // ct = computed from paper's own data
            8'd2,
            64'd0
        );

        $display("----------------------------------------");
        $display("Results: %0d PASSED, %0d FAILED", pass_count, fail_count);
        $display("----------------------------------------");
        if (fail_count == 0)
            $display("ALL TESTS PASSED.");
        else
            $display("FAILURES DETECTED.");
        $finish;
    end

endmodule
