module spi_peripheral 

(
    input  wire       clk,      // clock
    input  wire       rst_n,     // reset_n - low to reset
    input  wire       SCLK,      // clock
    input  wire       nCS,     // reset_n - low to reset
    /* verilator lint_off UNUSEDSIGNAL */
    input  wire       COPI,
    /* verilator lint_off UNUSEDSIGNAL */

    output  reg [7:0] en_reg_out_7_0,
    output  reg [7:0] en_reg_out_15_8,
    output  reg [7:0] en_reg_pwm_7_0,
    output  reg [7:0] en_reg_pwm_15_8,
    output  reg [7:0] pwm_duty_cycle
);

    reg state; //increase signal width if we increase number of states
    localparam IDLE = 1'b0;
    localparam ACTIVE = 1'b1;

    //synchronizer vars
    reg synch_f1;
    reg nCS1;
    reg synch_f2;
    reg nCS2; 
    
    // need edge level control
    reg prev_synch_f2;


/* verilator lint_off UNUSEDSIGNAL */
    reg prev_nCS2;

    reg nCS_rise;
    reg nCS_fall;
    wire nCS_active;
/* verilator lint_off UNUSEDSIGNAL */

    assign nCS_active = nCS2; 

    // Need to synchronize sclk, ncs because they are asynchronous control signals
    // Using 2-flop synchronizer 

    always@(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            synch_f1 <= 0;
            synch_f2 <= 0;
            prev_synch_f2 <= 0;
            nCS1 <= 0;
            nCS2 <= 0;
            prev_nCS2 <= 0;
            
        end else begin
            //how do I detect sclk rising edge?
            synch_f1 <= SCLK; //catches metastability
            nCS1 <= nCS;

            synch_f2 <= synch_f1; // provides stable synchronized sclk
            nCS2 <= nCS1;
            
            prev_synch_f2 <= synch_f2; // need this for edge detection
            prev_nCS2 <= nCS2;
            // when prev_synch_flop2 == 0 and synch_flop2 == 1 then we have a rising edge in SCLK
            //
        end
    end

    always@(*) begin
           //edge level detection to help state transition
           nCS_rise = ((nCS2==1) && (prev_nCS2==0)); //ACTIVE --> IDLE
           nCS_fall = ((nCS2==0) && (prev_nCS2==1)); //IDLE --> ACTIVE
    end

    //transitions
    always@(posedge clk) begin
        // Need a section here to reset case

        case (state)
            IDLE: if (nCS_rise) state <= ACTIVE;
            ACTIVE: if (nCS_fall) state <= IDLE;
            default: state <= IDLE;
        endcase
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            en_reg_out_7_0   <= 8'd0;
            en_reg_out_15_8  <= 8'd0;
            en_reg_pwm_7_0   <= 8'd0;
            en_reg_pwm_15_8  <= 8'd0;
            pwm_duty_cycle   <= 8'd0;
            end
    end


    //state actions
    always@(posedge clk) begin
        if (rst_n) begin
            
        end else begin

            case (state):
                IDLE: begin 
                
                end

                ACTIVE: begin //need a 16 bit counter

                end

            endcase             
        end
    end

    
endmodule
