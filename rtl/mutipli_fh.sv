module multiplier (
    input  logic        clk,
    input  logic        rst_n,
    input  logic [31:0] a,
    input  logic [31:0] b,
    input  logic        in_valid_i,
    input  logic [1:0]  op_sel,
    input  logic        out_ready_i,
    
    output logic        out_valid_o,
    output logic        in_ready_o,
    output logic [31:0] resultado
);
    typedef enum logic [2:0] {IDLE, MUL, MULT_0,
    MULT_1, MULT_2, MULT_3, RESULT} state_t;

    state_t state, next_state;

    logic [31:0] register_a, register_b;
    logic [1:0]  operation;

    // registradores e fios de apoio
    logic [63:0] acumulador, next_acumulador;
    logic [31:0] next_resultado;

    // 00 = MUL | 01 = MULH | 10 = MULHSU | 11 = MULHU
    logic sinal_a, sinal_b;
    assign sinal_a = (operation == 2'b01) || (operation == 2'b10);
    assign sinal_b = (operation == 2'b01);

    // multiplicador 17x17; bit extra para o sinal
    logic signed [16:0] mul_x, mul_y;
    logic signed [33:0] mul_out;
    assign mul_out = mul_x * mul_y;

    always_comb begin
        // valores padroes
        next_state      = state;
        next_resultado  = resultado;
        next_acumulador = acumulador;
        out_valid_o     = 1'b0;
        in_ready_o      = 1'b0;

        mul_x = '0;
        mul_y = '0;

        case (state)
            IDLE: begin
                in_ready_o = 1'b1;
                if (in_valid_i) begin
                    if (op_sel == 2'b00) begin
                        next_state = MUL;
                    end else begin
                        next_state = MULT_0;
                    end
                end
            end

            MUL: begin
                next_resultado = register_a * register_b;
                next_state = RESULT;
            end

            MULT_0: begin
                // P0 = A_L (sem sinal) * B_L (sem sinal)
                mul_x = {1'b0, register_a[15:0]};
                mul_y = {1'b0, register_b[15:0]};
                next_acumulador = {30'd0, mul_out};
                next_state = MULT_1;
            end

            MULT_1: begin
                // P1 = A_H (sinal/sem) * B_L (sem snal)
                mul_x = {(sinal_a & register_a[31]), register_a[31:16]};
                mul_y = {1'b0, register_b[15:0]};

                // soma desolcando 16 bits
                next_acumulador = acumulador + { {14{mul_out[33]}}, mul_out, 16'd0};
                next_state = MULT_2;
            end

            MULT_2: begin
                // P2 = A_L (nao sinal) * B_H (sinal/nao sinal)
                mul_x = {1'b0, register_a[15:0]};
                mul_y = {sinal_b & register_b[31], register_b[31:16]};

                // descola 16 bits e extende sinal
                next_acumulador = acumulador + { {14{mul_out[33]}}, mul_out, 16'd0};
                next_state = MULT_3;
            end

            MULT_3: begin
                // P3 = A_H (sinal/nao sinal) * B_H (sinal/nao sinal)
                mul_x = {(sinal_a & register_a[31]), register_a[31:16]};
                mul_y = {(sinal_b & register_b[31]), register_b[31:16]};

                // descola 32 bits
                next_acumulador = acumulador + {mul_out[31:0], 32'd0};

                next_resultado = next_acumulador[63:32];
                next_state = RESULT;
            end

            RESULT: begin
                out_valid_o = 1'b1;
                if (out_ready_i) begin
                    next_state = IDLE;
                end
            end

            default: next_state = IDLE;
        endcase
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state      <= IDLE;
            resultado  <= 32'b0;
            register_a <= 32'b0;
            register_b <= 32'b0;
            operation  <= 2'b00;
            acumulador <= 64'b0;
        end else begin
            state      <= next_state;
            resultado  <= next_resultado;
            acumulador <= next_acumulador;

            // handshake inicial
            if (state == IDLE && in_valid_i) begin
                register_a <= a;
                register_b <= b;
                operation  <= op_sel;
            end
        end
    end

endmodule
