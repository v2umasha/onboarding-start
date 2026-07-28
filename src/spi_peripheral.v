`default_nettype none
module spi_peripheral
#(
    parameter FRAME = 16 //number of bits to decode
) 
    
(
    input  wire       clk,      
    input  wire       rst_n,     // reset_n - low to reset
    input  wire       SCLK,      
    input  wire       nCS,     
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

    //synchronizer vars for sclk, ncs, and copi
    reg sclk1;
    reg nCS1;
    reg copi1;
    
    reg sclk2;
    reg nCS2;
    reg copi2; 
   
    
    // need edge level detection
    reg prev_sclk2;
    reg prev_nCS2;

    reg sclk_rise;
    
    reg nCS_rise;
    reg nCS_fall;
    

    reg [4:0] counter;
    reg [FRAME-1:0] shiftReg; // COPI date shifts into here


    // Need to synchronize sclk, ncs because they are asynchronous control signals
    // Using 2-flop synchronizer 

    always@(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sclk1 <= 0;
            sclk2 <= 0;
            prev_sclk2 <= 0;

            nCS1 <= 1; //active low so reset as 1
            nCS2 <= 1;
            prev_nCS2 <= 1;
            
            copi1 <= 0;
            copi2 <= 0;

        end else begin
            //how do I detect sclk rising edge? -> sclk_rise -> compare old and previous values for a rise
            sclk1 <= SCLK; //catches metastability
            nCS1 <= nCS;
            copi1 <= COPI;

            sclk2 <= sclk1; // provides stable synchronized sclk
            nCS2 <= nCS1;
            copi2 <= copi1;
            
            prev_sclk2 <= sclk2; // need this for edge detection
            prev_nCS2 <= nCS2;
            // when prev_synch_flop2 == 0 and synch_flop2 == 1 then we have a rising edge in SCLK
            
        end
    end

    //edge detection logic for chip select and sclk
    always@(*) begin
        //edge level detection to help state transition
        nCS_rise = ((nCS2==1) && (prev_nCS2==0)); //ACTIVE --> IDLE
        nCS_fall = ((nCS2==0) && (prev_nCS2==1)); //IDLE --> ACTIVE

        //edge level detection to help state transition
        sclk_rise = ((sclk2==1) && (prev_sclk2==0)); //rising clk edge detection
    end

    //state transitions -> primarily depends on nCS
    always@(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE; 
        end else begin
            case (state)
                IDLE: if (nCS_fall==1) state <= ACTIVE;
                ACTIVE: if (nCS_rise==1) state <= IDLE;
                default: state <= IDLE; // THIS DOESN'T DO ANYTHING -> state is 1 bit so all cases accounted for
            endcase
        end
    end

    //state actions
    always@(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shiftReg <= 0; 
            counter <= 0;
        end else begin

            case (state)
                IDLE: begin 
                    counter <= 0;
                end

                ACTIVE: begin //// need to be building the signal bit by bit, through the MSB = shift register 
                    if (sclk_rise) begin
                        counter <= counter + 1;
                        shiftReg <= {shiftReg[FRAME-2:0], copi2};
                    end
                end  
            endcase             
        end
    end


    always @(posedge clk or negedge rst_n) begin //async reset
        if (!rst_n) begin
            en_reg_out_7_0   <= 8'd0;
            en_reg_out_15_8  <= 8'd0;
            en_reg_pwm_7_0   <= 8'd0;
            en_reg_pwm_15_8  <= 8'd0;
            pwm_duty_cycle   <= 8'd0;
        end else begin
            //this is where we update the output regs
            // the most efficient way to go about this is to look at shiftReg[15]
            // if this is 1 we can look into cases otherwise ignore the transaction

            if (nCS_rise && (counter == FRAME)) begin // nCS rises indicates end of transaction
                if (shiftReg[FRAME-1] == 1) begin
                    case (shiftReg[14:8])
                        7'h00: en_reg_out_7_0 <= shiftReg[7:0];
                        7'h01: en_reg_out_15_8 <= shiftReg[7:0];
                        7'h02: en_reg_pwm_7_0 <= shiftReg[7:0];
                        7'h03: en_reg_pwm_15_8 <= shiftReg[7:0];
                        7'h04: pwm_duty_cycle <= shiftReg[7:0];
                        default: ; // invalid address --> do nothing
                    endcase
                end
            end
        end

    end

endmodule
