module uart_tx #(
    parameter CLKS_PER_BIT = 868  // 100 MHz clock / 115200 baud
)(
    input  wire       clk, // defining Clock
    input  wire       tx_start, // starting the inputs (Going High 1)
    input  wire [7:0] tx_data, //User inputs the Byte that they want to send in
    output reg        tx_line, //
    output reg        tx_done
);

    // FSM state encoding
    localparam IDLE    = 3'd0; // state 0 to 4 so then 5 states
    localparam START   = 3'd1;
    localparam DATA    = 3'd2;
    localparam STOP    = 3'd3;
    localparam CLEANUP = 3'd4;

    reg [2:0] state = IDLE;
    reg [$clog2(CLKS_PER_BIT):0] clk_cnt = 0;
    reg [2:0] bit_idx = 0;
    reg [7:0] tx_buf  = 0; // this copies the data and holds it so it doesnt get over written by the next input the user can send

    always @(posedge clk) begin
        case (state)
            IDLE: begin
                tx_line <= 1'b1;   // line idles HIGH
                tx_done <= 1'b0;
                clk_cnt <= 0;
                bit_idx <= 0;
                if (tx_start) begin
                    tx_buf <= tx_data;
                    state  <= START;
                end
            end

            START: begin
                tx_line <= 1'b0;   // start bit is LOW
                if (clk_cnt < CLKS_PER_BIT - 1)
                    clk_cnt <= clk_cnt + 1;
                else begin
                    clk_cnt <= 0;
                    state   <= DATA;
                end
            end

            DATA: begin
                tx_line <= tx_buf[bit_idx];
                if (clk_cnt < CLKS_PER_BIT - 1)
                    clk_cnt <= clk_cnt + 1;
                else begin
                    clk_cnt <= 0;
                    if (bit_idx < 7)
                        bit_idx <= bit_idx + 1;
                    else begin
                        bit_idx <= 0;
                        state   <= STOP;
                    end
                end
            end

            STOP: begin
                tx_line <= 1'b1;   // stop bit is HIGH
                if (clk_cnt < CLKS_PER_BIT - 1)
                    clk_cnt <= clk_cnt + 1;
                else begin
                    clk_cnt <= 0;
                    tx_done <= 1'b1;
                    state   <= CLEANUP;
                end
            end

            CLEANUP: begin
                tx_done <= 1'b0;
                state   <= IDLE;
            end
        endcase
    end
endmodule