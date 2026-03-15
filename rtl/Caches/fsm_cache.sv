module main_fsm_mc
     (input logic clk_i,
      input logic rst_ni,
      input logic cpu_req_i,
      output logic cpu_gnt_o,
      input logic hit,
      );

     typedef enum logic[2:0] {S_IDLE, S_TAG, S_ALLOC, S_WRITE, S_HAND} t_estado;
     t_estado state_q;

     always_ff @(posedge clk_i or negedge rst_ni )
          if (!rst_ni)
               state_q <= S_IDLE;
          else 
               unique case (state_q)
                    S_IDLE : 
                        if (cpu_req_i == 1'b1)
                            state_q <= S_TAG;
                        else 
                            state_q <= S_IDLE;
                    S_TAG :
                        if (hit == 1'b1)
                            state_q <= S_HAND;
                        else 
                            if (/* Dirty bit set*/)
                                state_q <= S_ALLOC;
                            else 
                                state_q <= S_WRITE;
                    S_ALLOC :

                    S_WRITE :

                    S_HAND :
                        if (cpu_req_i == 1'b1 && cpu_gnt_o == 1'b1)
                            state_q <= S_IDLE;

               endcase
        
          
        
endmodule : main_fsm_mc