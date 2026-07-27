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

    // ------------------------------------------------------------
    // op_sel
    // 00 = MUL
    // 01 = MULH
    // 10 = MULHSU
    // 11 = MULHU
    // ------------------------------------------------------------

    typedef enum logic [2:0] {
        IDLE,
        MUL,
        STEP0,
        STEP1,
        STEP2,
        FINISH,
        RESULT
    } state_t;

    state_t state, next_state;

    // operandos registrados
    logic [31:0] reg_a, reg_b;
    logic [1:0]  reg_op;

    // ------------------------------------------------------------
    // multiplicador 17x17 reutilizado
    // ------------------------------------------------------------
    logic signed [16:0] mul_a, mul_b;
    logic signed [33:0] mul_out;

    assign mul_out = mul_a * mul_b;

    // ------------------------------------------------------------
    // registradores de acumulação (estilo CV32E40P)
    // ------------------------------------------------------------
    logic signed [33:0] acc_reg, acc_next;
    logic signed [33:0] part_reg, part_next;

    logic [31:0] result_next;

    // resultado final de 64 bits reconstruído
    logic signed [63:0] full_result, full_result_next;

    // sinais
    logic signed_a, signed_b;

    assign signed_a = (reg_op == 2'b01) || (reg_op == 2'b10);
    assign signed_b = (reg_op == 2'b01);

    // ------------------------------------------------------------
    // combinacional
    // ------------------------------------------------------------
    always_comb begin
        next_state       = state;
        acc_next         = acc_reg;
        part_next        = part_reg;
        full_result_next = full_result;
        result_next      = resultado;

        out_valid_o = 1'b0;
        in_ready_o  = 1'b0;

        mul_a = '0;
        mul_b = '0;

        case (state)

            // ----------------------------------------------------
            IDLE: begin
                in_ready_o = 1'b1;

                if (in_valid_i) begin
                    if (op_sel == 2'b00)
                        next_state = MUL;
                    else
                        next_state = STEP0;
                end
            end

            // ----------------------------------------------------
            // MUL = 1 ciclo
            // ----------------------------------------------------
            MUL: begin
                result_next = (reg_a * reg_b);
                next_state  = RESULT;
            end

            // ----------------------------------------------------
            // STEP0 : AL * BL
            // ----------------------------------------------------
            STEP0: begin
                mul_a = {1'b0, reg_a[15:0]};
                mul_b = {1'b0, reg_b[15:0]};

                acc_next         = mul_out;
                full_result_next = {{30{1'b0}}, mul_out};

                next_state = STEP1;
            end

            // ----------------------------------------------------
            // STEP1 : AL * BH
            // ----------------------------------------------------
            STEP1: begin
                mul_a = {1'b0, reg_a[15:0]};
                mul_b = {signed_b & reg_b[31], reg_b[31:16]};

                part_next = mul_out;
                next_state = STEP2;
            end

            // ----------------------------------------------------
            // STEP2 : AH * BL
            // ----------------------------------------------------
            STEP2: begin
                mul_a = {signed_a & reg_a[31], reg_a[31:16]};
                mul_b = {1'b0, reg_b[15:0]};

                acc_next = acc_reg + part_reg + mul_out;

                full_result_next =
                    full_result +
                    ($signed(part_reg) <<< 16) +
                    ($signed(mul_out)  <<< 16);

                next_state = FINISH;
            end

            // ----------------------------------------------------
            // FINISH : AH * BH
            // ----------------------------------------------------
            FINISH: begin
                mul_a = {signed_a & reg_a[31], reg_a[31:16]};
                mul_b = {signed_b & reg_b[31], reg_b[31:16]};

                full_result_next =
                    full_result +
                    ($signed(mul_out) <<< 32);

                result_next = full_result_next[63:32];

                next_state = RESULT;
            end

            // ----------------------------------------------------
            RESULT: begin
                out_valid_o = 1'b1;

                if (out_ready_i)
                    next_state = IDLE;
            end

            default: next_state = IDLE;
        endcase
    end

    // ------------------------------------------------------------
    // sequencial
    // ------------------------------------------------------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state       <= IDLE;
            reg_a       <= '0;
            reg_b       <= '0;
            reg_op      <= '0;
            acc_reg     <= '0;
            part_reg    <= '0;
            full_result <= '0;
            resultado   <= '0;

        end else begin
            state       <= next_state;
            acc_reg     <= acc_next;
            part_reg    <= part_next;
            full_result <= full_result_next;
            resultado   <= result_next;

            // captura operandos
            if (state == IDLE && in_valid_i) begin
                reg_a  <= a;
                reg_b  <= b;
                reg_op <= op_sel;
            end
        end
    end

endmodule