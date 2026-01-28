module top;

    logic clk;
    logic rst_n;
    hash256 sif(clk);

    hash_core DUT(.clk(clk),.rst_n(sif.rst_n),.Kt_i(sif.Kt_i),.Wt_i(sif.Wt_i),
         .A_i(sif.A_i),.B_i(sif.B_i),.C_i(sif.C_i),.D_i(sif.D_i),.E_i(sif.E_i),.F_i(sif.F_i),.G_i(sif.G_i),.H_i(sif.H_i),
         .A_o(sif.A_o),.B_o(sif.B_o),.C_o(sif.C_o),.D_o(sif.D_o),.E_o(sif.E_o),.F_o(sif.F_o),.G_o(sif.G_o),.H_o(sif.H_o),
          .finall(sif.finall),.done(sif.done));


    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
    rst_n = 0;
    #20 rst_n =1;
    end
    
    initial begin
    uvm_config_db#(virtual hash256)::set(null,"env.agt.drv","vif",sif);
    uvm_config_db#(virtual hash256)::set(null,"env.agt.mon","vif",sif);
            run_test("sha256_test");

     end
endmodule
        
