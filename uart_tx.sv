module uart_tx #(
    parameter CLKS_PER_BIT = 868  // 100 MHz clock / 115200 baud
)(
    input  logic       clk, // defining Clock
    input  logic       tx_start, // starting the inputs (Going High 1)
    input  logic [7:0] tx_data, //User inputs the Byte that they want to send in
    output logic        tx_line, //
    output logic        tx_done
);

    // FSM state encoding
  typedef enum logic [2:0] {IDLE, START, DATA, STOP, CLEANUP} state_t;

	state_t state = IDLE;
    
	 logic [$clog2(CLKS_PER_BIT):0] clk_cnt = 0;
    logic [2:0] bit_idx = 0;
    logic [7:0] tx_buf  = 0; // this copies the data and holds it so it doesnt get over written by the next input the user can send

    always_ff @(posedge clk) begin // always ff means this block is meant to be flip flops and assigns flip flops to the Variables *holds that many bits
        case (state)
            IDLE: begin
                tx_line <= 1'b1;   // line idles HIGH holds 1 bit
                tx_done <= 1'b0; // line holds 1 bit 
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
                    tx_done <= 1'b1; // (1 bit  wide) ' - (in binary) - (value = 1)
                    state   <= CLEANUP; // arrow "<=" it means put this value into this signal at the next clock tick
                end
            end

            CLEANUP: begin
                tx_done <= 1'b0; // (1 bit  wide) ' - (in binary) - (value = 0)
                state   <= IDLE;
            end
				
				default: state <= IDLE;
        endcase
    end
endmodule