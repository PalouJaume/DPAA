module ram
     #(parameter int DataWidth = 32,
       parameter int NPos = 1024,
       parameter int NPosWidth = $clog2(NPos))

     (input logic clk_i,
      input logic[NPosWidth-1:0] a_i,
      input logic we_i,
      input logic[DataWidth-1:0] wd_i,
      output logic[DataWidth-1:0] rd_o);

     logic[DataWidth-1:0] mem[NPos];

     always_ff @(posedge clk_i)
          if (we_i)
               mem[a_i] <= wd_i;

     always_comb
          rd_o = mem[a_i];

endmodule : ram