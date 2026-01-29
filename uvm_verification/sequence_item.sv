`include "uvm_macros.svh"
import uvm_pkg::*;

class sha256_sequence_item extends uvm_sequence_item;
    `uvm_object_utils(sha256_sequence_item)
    
    typedef enum {NUMERIC,UPPER_CASE,LOWER_CASE,SPECIAL,MIXED} input_type;
    rand input_type data_type;
    rand bit [7:0] my_data[]; 
    bit [5:0] byte_enable;
    bit msg_valid;
    bit [255:0] fin_hash;
    rand bit rst_n;
    
    // CORRECTED: Proper constraint structure with if-else inside foreach
    constraint input_content{ 
        my_data.size() inside { [1:55] };
        foreach (my_data[i]){
            if(data_type == NUMERIC){
                my_data[i] inside {[8'd48 : 8'd57]};
            }
            else if(data_type == UPPER_CASE){
                my_data[i] inside {[8'd65 : 8'd90]};
            }
            else if(data_type == LOWER_CASE){
                my_data[i] inside {[8'd97 : 8'd122]};
            }
            else if(data_type == SPECIAL){
                my_data[i] inside {[8'd32 : 8'd47], [8'd58 : 8'd64], 
                                   [8'd91 : 8'd96],[8'd123 : 8'd126]};
            }
            else if(data_type == MIXED){
                my_data[i] inside {[48:57],[65:90],[97:122]};
            }
        }
    }
    
    function new(string name = "sha256_sequence_item");
        super.new(name);
    endfunction
    
endclass