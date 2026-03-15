module regfile
     #(parameter int XLen = 32,
       parameter int NReg = 32,
       parameter int NRegWidth = $clog2(NReg))

     (input logic clk_i,
      input logic rst_ni,
      input logic[NRegWidth-1:0] a1_i,
      input logic[NRegWidth-1:0] a2_i,
      input logic[NRegWidth-1:0] a3_i,
      input logic we3_i,
      input logic[XLen-1:0] wd3_i,
      output logic[XLen-1:0] rd1_o,
      output logic[XLen-1:0] rd2_o);

     logic[XLen-1:0] rf[NReg];

     always_ff @(posedge clk_i or negedge rst_ni)
          if (!rst_ni)
               foreach (rf[i]) rf[i] <= '0;
          else if (we3_i)
               rf[a3_i] <= wd3_i;

     always_comb
          begin
               rd1_o = (a1_i == '0) ? '0 : rf[a1_i];
               rd2_o = (a2_i == '0) ? '0 : rf[a2_i];
          end
          

endmodule : regfile
