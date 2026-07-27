`timescale 1ns/1ps

module tb_multiplier;

    //------------------------------------------------------------
    // DUT Signals
    //------------------------------------------------------------
    logic         clk;
    logic         rst_n;

    logic [31:0]  a;
    logic [31:0]  b;
    logic         in_valid_i;
    logic [1:0]   op_sel;
    logic         out_ready_i;

    logic         out_valid_o;
    logic         in_ready_o;
    logic [31:0]  resultado;

    //------------------------------------------------------------
    // DUT
    //------------------------------------------------------------
    multiplier dut (
        .clk(clk),
        .rst_n(rst_n),
        .a(a),
        .b(b),
        .in_valid_i(in_valid_i),
        .op_sel(op_sel),
        .out_ready_i(out_ready_i),
        .out_valid_o(out_valid_o),
        .in_ready_o(in_ready_o),
        .resultado(resultado)
    );

    //------------------------------------------------------------
    // Clock
    //------------------------------------------------------------
    initial clk = 0;
    always #5 clk = ~clk;

    //------------------------------------------------------------
    // Counters
    //------------------------------------------------------------
    integer pass_cnt = 0;
    integer fail_cnt = 0;

    //------------------------------------------------------------
    // Reference model
    //------------------------------------------------------------
    function automatic logic [31:0] model
    (
        input logic [31:0] aa,
        input logic [31:0] bb,
        input logic [1:0]  op
    );

        logic signed [63:0] ss;
        logic signed [63:0] su;
        logic        [63:0] uu;

        begin

            ss = $signed(aa) * $signed(bb);
            su = $signed(aa) * $signed({1'b0,bb});
            uu = aa * bb;

            case(op)

                2'b00: model = uu[31:0];      // MUL

                2'b01: model = ss[63:32];     // MULH

                2'b10: model = su[63:32];     // MULHSU

                2'b11: model = uu[63:32];     // MULHU

            endcase

        end

    endfunction

    //------------------------------------------------------------
    // One transaction
    //------------------------------------------------------------
    task automatic execute_test
    (
        input logic [31:0] aa,
        input logic [31:0] bb,
        input logic [1:0]  op
    );

        logic [31:0] expected;

        begin

            expected = model(aa,bb,op);

            //----------------------------
            // Wait until DUT is ready
            //----------------------------
            while(!in_ready_o)
                @(posedge clk);

            //----------------------------
            // Send request
            //----------------------------
            @(posedge clk);

            a          <= aa;
            b          <= bb;
            op_sel     <= op;
            in_valid_i <= 1'b1;

            @(posedge clk);

            in_valid_i <= 1'b0;

            //----------------------------
            // Wait response
            //----------------------------
            while(!out_valid_o)
                @(posedge clk);

            //----------------------------
            // Compare
            //----------------------------
            if(resultado === expected) begin

                pass_cnt++;

            end
            else begin

                fail_cnt++;

                $display("\n========================================");
                $display("FAIL @ %0t",$time);
                $display("Operation : %b",op);
                $display("A         : %h",aa);
                $display("B         : %h",bb);
                $display("Expected  : %h",expected);
                $display("Received  : %h",resultado);
                $display("========================================\n");

            end

            @(posedge clk);

        end

    endtask

    //------------------------------------------------------------
    // Reset
    //------------------------------------------------------------
    initial begin

        rst_n       = 0;
        in_valid_i  = 0;
        out_ready_i = 1;
        a           = 0;
        b           = 0;
        op_sel      = 0;

        repeat(5)
            @(posedge clk);

        rst_n = 1;

    end

    //------------------------------------------------------------
    // Main Test
    //------------------------------------------------------------
    integer i;

    initial begin

        wait(rst_n);

        //--------------------------------------------------------
        // Directed tests
        //--------------------------------------------------------

        execute_test(32'd0,32'd0,2'b00);
        execute_test(32'd1,32'd1,2'b00);
        execute_test(32'd10,32'd20,2'b00);

        execute_test(32'hFFFFFFFF,32'd2,2'b00);

        execute_test(-32'sd1,-32'sd1,2'b01);
        execute_test(-32'sd10,32'sd5,2'b01);
        execute_test(32'sd5000,-32'sd200,2'b01);

        execute_test(-32'sd15,32'd123,2'b10);
        execute_test(32'sd100000,32'd7654,2'b10);

        execute_test(32'hFFFFFFFF,32'hFFFFFFFF,2'b11);
        execute_test(32'h80000000,32'h80000000,2'b11);
        execute_test(32'h12345678,32'hABCDEF01,2'b11);

        //--------------------------------------------------------
        // Corner cases
        //--------------------------------------------------------

        execute_test(32'h00000000,32'hFFFFFFFF,2'b00);
        execute_test(32'hFFFFFFFF,32'h00000000,2'b01);
        execute_test(32'h80000000,32'hFFFFFFFF,2'b10);
        execute_test(32'h7FFFFFFF,32'h7FFFFFFF,2'b01);
        execute_test(32'h80000000,32'h80000000,2'b01);

        //--------------------------------------------------------
        // Random tests
        //--------------------------------------------------------

        for(i=0;i<5000;i++) begin

            execute_test(
                $urandom,
                $urandom,
                $urandom_range(0,3)
            );

        end

        //--------------------------------------------------------
        // Report
        //--------------------------------------------------------

        $display("");
        $display("======================================");
        $display("Simulation Finished");
        $display("--------------------------------------");
        $display("PASS : %0d",pass_cnt);
        $display("FAIL : %0d",fail_cnt);
        $display("======================================");

        if(fail_cnt==0)
            $display("ALL TESTS PASSED");
        else
            $display("THERE ARE FAILING TESTS");

        $finish;

    end

endmodule