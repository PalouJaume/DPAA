//
// Microcredencial en Diseño de Procesadores con Arquitectura Abierta
// Cátedra UPM-INDRA en Microelectrónica
//
// Author: Alfonso Rodríguez <alfonso.rodriguezm@upm.es>
// Date: April 2025
//

module slow_mem #(
    // Memory address width
    parameter int AddrWidth = 32,
    // Memory word width
    parameter int DataWidth = 32,
    // Total Memory size (bytes)
    parameter int MemSize = 1024,
    localparam int MemPos = MemSize / (DataWidth >> 3),
    // Memory access latency
    parameter int Latency = 100,
    localparam int LatencyWidth = $clog2(Latency)
) (
    // Clock and reset
    input  logic clk_i,
    input  logic rst_ni,
    // Memory interface
    input  logic mem_req_i,
    output logic mem_gnt_o,
    input  logic mem_rw_i,
    input  logic [AddrWidth-1:0] mem_addr_i,
    input  logic [DataWidth-1:0] mem_wdata_i,
    output logic [DataWidth-1:0] mem_rdata_o
);

    // FSM declarations
    typedef enum logic [1:0] {
        S_IDLE,
        S_TEMP,
        S_HAND
    } state_e;
    state_e state_d, state_q;

    // Variable declarations (input registers)
    logic mem_rw_d, mem_rw_q;
    logic [AddrWidth-1:0] mem_addr_d, mem_addr_q;
    logic [DataWidth-1:0] mem_wdata_d, mem_wdata_q;

    // Variable declarations (output registers)
    logic mem_gnt_d, mem_gnt_q;
    logic [DataWidth-1:0] mem_rdata_d, mem_rdata_q;

    // Variable declarations
    logic we;
    logic [DataWidth-1:0] wdata, rdata;
    logic [LatencyWidth-1:0] cnt;
    logic cnt_en, cnt_ovf;

    // I/O ports
    assign mem_gnt_o = mem_gnt_q;
    assign mem_rdata_o = mem_rdata_q;

    // FSM (state and output equations)
    always_comb begin
        // Default values
        state_d = state_q;

        mem_gnt_d = 1'b0;
        mem_rw_d = mem_rw_q;
        mem_addr_d = mem_addr_q;
        mem_wdata_d = mem_wdata_q;
        mem_rdata_d = '0;

        we = 1'b0;
        wdata = '{default: '0};

        cnt_en = 1'b0;

        unique case (state_q)
            // Idle (waiting for requests from CPU)
            S_IDLE: begin
                if (mem_req_i) begin
                    state_d = S_TEMP;
                    // Capture read/write flag, address and write data
                    mem_rw_d = mem_rw_i;
                    mem_addr_d = mem_addr_i;
                    mem_wdata_d = mem_wdata_i;
                end
            end
            // Emulate a really slow memory by just waiting
            S_TEMP: begin
                cnt_en = 1'b1;
                // Wait until counter overflows
                if (cnt_ovf) begin
                    state_d = S_HAND;
                end
            end
            // Stall (waiting for handshake from CPU)
            S_HAND: begin
                // Send response to CPU
                mem_gnt_d = 1'b1;
                mem_rdata_d = rdata;

                // req/gnt handshake
                if (mem_req_i & mem_gnt_q) begin
                    state_d = S_IDLE;
                    // Write to memory (if required)
                    we = mem_rw_q ? 1'b1 : 1'b0;
                    wdata = mem_wdata_q;
                    // Stop response to CPU (to avoid issues with the extra clock cycle)
                    mem_gnt_d = 1'b0;
                end
            end
            // Default value already covered
            default: ;
        endcase
    end

    // FSM (state registers)
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            state_q <= S_IDLE;
            mem_gnt_q <= 1'b0;
            mem_rw_q <= 1'b0;
            mem_addr_q <= '0;
            mem_wdata_q <= '0;
            mem_rdata_q <= '0;
        end else begin
            state_q <= state_d;
            mem_gnt_q <= mem_gnt_d;
            mem_rw_q <= mem_rw_d;
            mem_addr_q <= mem_addr_d;
            mem_wdata_q <= mem_wdata_d;
            mem_rdata_q <= mem_rdata_d;
        end
    end

    // Counter to introduce latency in read/write operations
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            cnt <= '0;
        end else begin
            if (cnt_en) begin
                if (cnt == (Latency-1)) begin
                    cnt <= '0;
                end else begin
                    cnt <= cnt + 1;
                end
            end
        end
    end
    assign cnt_ovf = ((cnt == (Latency-1)) && cnt_en) ? 1'b1 : 1'b0;

    // Instantiate single-port RAM memory
    ram #(
        .DataWidth(DataWidth),
        .NPos(MemPos)
    ) ram_i (
        .clk_i(clk_i),
        .a_i(mem_addr_q),
        .we_i(we),
        .wd_i(wdata),
        .rd_o(rdata)
    );

endmodule
