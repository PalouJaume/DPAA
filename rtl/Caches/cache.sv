module cache #(
    // Cache address width
    parameter int AddrWidth = 32,
    // Cache word width
    parameter int DataWidth = 32, // Bits que ocupa un dato
    // Total cache size (bytes)
    parameter int CacheSize = 1024, 
    // Cache block size (bytes per cache block)
    parameter int BlockSize = 64, // Tamaño de bloque en bytes => 8 datos en cada bloque
    // Number of DataWidth-bit words in cache block
    localparam int BlockWords = BlockSize/ (DataWidth >> 3), // numero de datos en cada bloque => 8 datos en cada bloque.
    // Number of bits needed to address BlockWords DataWidth-bit words in a cache block
    localparam int BlockWidth = $clog2(BlockWords), 
    // Associativity (ways)
    parameter int CacheWays = 2, // Es el número de sets
    // Number of cache sets
    localparam int CacheSets = CacheSize / (BlockSize * CacheWays), // Numero de bloques en cada set de la cache
    // Index width
    localparam int IndexWidth = $clog2(CacheSets), // Número de bits para indexar el bloque en un set
    // Tag width
    localparam int TagWidth = AddrWidth - IndexWidth - BlockWidth // 
) (
    // Clock and reset
    input logic clk_i,
    input logic rst_ni,
    // Processor interface
    input logic cpu_req_i,  // CPU hace petición
    output logic cpu_gnt_o, // CPU confirma petición
    input logic cpu_rw_i,   // CPU solicita lectura o escritura (0 leer/ 1 escribir)
    input logic [AddrWidth-1:0] cpu_addr_i, // Dirección de memoria a la que que quiere acceder o escribir
    input logic [AddrWidth-1:0] cpu_wdata_i, // Dato que quiere escribir en memoria la cpu
    output logic [DataWidth-1:0] cpu_rdata_o, // Dato que quiere leer la cpu
    // Memory interface
    output logic mem_req_o, // Petición 
    input logic mem_gnt_i,
    output logic mem_rw_o,
    output logic [AddrWidth-1:0] mem_addr_o,
    output logic [DataWidth-1:0] mem_wdata_o,
    input logic [DataWidth-1:0] mem_rdata_i
);


// Señales
logic [CacheWays-1:0][BlockWords-1:0] we;
logic [CacheWays-1:0][BlockWords-1:0][DataWidth-1:0] wdata, rdata;
logic [CacheWays-1:0][TagWidth-1:0] wtag, rtag;
logic [CacheWays-1:0] wvalid, rvalid;
logic [CacheWays-1:0] wdirty, rdirty;
logic [CacheWays-1:0] hit;

logic [CacheSets-1:0] index;
//logic [DataWidth-1:0] data;

//always_comb
    //data = rdata[way][word];

always_comb
    foreach (wtag[i]) wtag[i] <= cpu_addr_i;

always_comb
    foreach (rtag[i]) rtag[i] <= cpu_addr_i;

// START MEMORY BANKS
for (genvar i = 0; i < CacheWays; i++)
    begin : gen_way_bank
    // Generate all memory banks required for each cache block/line
    for (genvar j = 0; j < BlockWords; i++)
        begin : gen_block_bank
            // Instantiate single-port RAM memory
            ram #(
                .DataWidth(DataWidth),
                .NPos(CacheSets)
            ) data_mem_i (
                .clk_i(clk_i),
                .a_i(index), // QUE ES INDEX ?
                .we_i(we[i][j]),    // Esto esta relacionado con escribir o leer en cache
                .wd_i(wdata[i][j]), // Lo que se escribe
                .rd_o(rdata[i][j])  // Lo que se lee de la cache
            );
        end
        // Instantiate single-port RAM memory
        ram #(
            .DataWidth(TagWidth + 2), // Store tags + valid + dirty bits
            .NPos(CacheSets)
        ) tags_mem_i (
            .clk_i(clk_i),     
            .a_i(index), // QUE ES EL INDEX ?????
            .we_i(|we[i]), // Escribir 1 / Leer 0
            .wd_i({wdirty[i], wvalid[i], wtag[i]}), 
            .rd_o({rdirty[i, rvalid[i], rtag[i]]})
        );
        // Hit detection logic 

        always_comb
        hit[i] = (rtag[i] == tag) ? rvalid[i] : 1'b0; 
    end 
    // END MEMORY BANK



endmodule : cache