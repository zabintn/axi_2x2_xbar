module id_tagger #(
    parameter ID_TAG   = 1'b0,   // overwrite during instantiation
    parameter ID_WIDTH = 4   
) (
    input  wire [ID_WIDTH-1:0] id_in,
    output wire [ID_WIDTH:0]   id_out
);
    assign id_out = {ID_TAG, id_in};
endmodule
