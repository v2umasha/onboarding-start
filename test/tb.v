`timescale 1ns/1ps
`default_nettype none

module tb;

  reg clk;
  reg rst_n;
  reg ena;
  reg [7:0] ui_in;
  reg [7:0] uio_in;

  wire [7:0] uo_out;
  wire [7:0] uio_out;
  /* verilator lint_off UNUSEDSIGNAL */
  wire [7:0] uio_oe;
/* verilator lint_off UNUSEDSIGNAL */

  // Instantiate DUT
  tt_um_uwasic_onboarding_vithurshan_ dut (
      .ui_in(ui_in),
      .uo_out(uo_out),
      .uio_in(uio_in),
      .uio_out(uio_out),
      .uio_oe(uio_oe),
      .ena(ena),
      .clk(clk),
      .rst_n(rst_n)
  );

  // =========================
  // Clock (10 MHz → 100ns period)
  // =========================
  initial clk = 0;
  always #50 clk = ~clk;

  // =========================
  // VCD Dump
  // =========================
  initial begin
      $dumpfile("wave.vcd");
      $dumpvars(0, tb);
  end

  // =========================
  // SPI Signals
  // =========================
  reg ncs;
  reg sclk;
  reg copi;

  // Map into ui_in
  always @(*) begin
      ui_in = {5'b00000, ncs, copi, sclk};
  end

  // =========================
  // SPI Transaction Task
  // =========================
  task send_spi;
      input r_w;
      input [6:0] addr;
      input [7:0] data;
      integer i;
      reg [7:0] first_byte;
      begin
          first_byte = {r_w, addr};

          ncs = 0;

          // Send first byte
          for (i = 7; i >= 0; i = i - 1) begin
              copi = first_byte[i];
              sclk = 0; #5000;
              sclk = 1; #5000;
          end

          // Send data byte
          for (i = 7; i >= 0; i = i - 1) begin
              copi = data[i];
              sclk = 0; #5000;
              sclk = 1; #5000;
          end

          ncs = 1;
          #20000;
      end
  endtask

  // =========================
  // Test Sequence
  // =========================
  initial begin

      ena = 1;
      uio_in = 0;
      ncs = 1;
      sclk = 0;
      copi = 0;

      // Reset
      rst_n = 0;
      #500;
      rst_n = 1;
      #500;

      // Write 0xF0 to address 0
      send_spi(1'b1, 7'h00, 8'hF0);
      #1000;

      $display("uo_out = %h", uo_out);
      $display("uio_out = %h", uio_out);
      $display("uio_oe = %h", uio_oe);

      #100000;

      $finish;
  end

endmodule

// `default_nettype none
// `timescale 1ns / 1ps

// /* This testbench just instantiates the module and makes some convenient wires
//    that can be driven / tested by the cocotb test.py.
// */
// module tb ();

//   // Dump the signals to a VCD file. You can view it with gtkwave or surfer.
//   initial begin
//     $dumpfile("tb.vcd");
//     $dumpvars(0, tb);
//     #1;
//   end

//   // Wire up the inputs and outputs:
//   reg clk;
//   reg rst_n;
//   reg ena;
//   reg [7:0] ui_in;
//   reg [7:0] uio_in;
//   wire [7:0] uo_out;
//   wire [7:0] uio_out;
//   wire [7:0] uio_oe;
// `ifdef GL_TEST
//   wire VPWR = 1'b1;
//   wire VGND = 1'b0;
// `endif

//   // Replace tt_um_example with your module name:
//   tt_um_uwasic_onboarding_vithurshan_ user_project (

//       // Include power ports for the Gate Level test:
// `ifdef GL_TEST
//       .VPWR(VPWR),
//       .VGND(VGND),
// `endif

//       .ui_in  (ui_in),    // Dedicated inputs
//       .uo_out (uo_out),   // Dedicated outputs
//       .uio_in (uio_in),   // IOs: Input path
//       .uio_out(uio_out),  // IOs: Output path
//       .uio_oe (uio_oe),   // IOs: Enable path (active high: 0=input, 1=output)
//       .ena    (ena),      // enable - goes high when design is selected
//       .clk    (clk),      // clock
//       .rst_n  (rst_n)     // not reset
//   );

// endmodule
