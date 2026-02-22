module spi_peripheral 

(
    input  wire       clk,      // clock
    input  wire       rst_n,     // reset_n - low to reset
    input  wire       SCLK,      // clock
    input  wire       nCS,     // reset_n - low to reset
    input  wire       COPI,

    output  reg [7:0] en_reg_out_7_0,
    output  reg [7:0] en_reg_out_15_8,
    output  reg [7:0] en_reg_pwm_7_0,
    output  reg [7:0] en_reg_pwm_15_8,
    output  reg [7:0] pwm_duty_cycle
);

    reg state; //increase signal width if we increase number of states
    localparam IDLE = 1'b0;
    localparam ACTIVE = 1'b1;


    // CDC --> Need to use synchronizer flops to line up with SCLK pos edge 
    always@(posedge clk) begin
        if (rst_n) begin
            
        end else begin
            //how do I detect sclk rising edge?
            synch_flop1 <= SCLK;
            synch_flop2 <= synch_flop1;
            // synch_flop2 will be equal to the opposite of synch_flop1
            // when synch_flop2==1 and synch_flop1=0

        end

    end

    //transitions
    always@(posedge clk) begin
        // probably need a section here to reset case

        case (state)
            IDLE: if (nCS==0) state <= ACTIVE;
            ACTIVE: if (nCS==1) state <= IDLE;
            default: state <= IDLE;
        endcase
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