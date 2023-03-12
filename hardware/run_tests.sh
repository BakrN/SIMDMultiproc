# Shell file for running iverilog tests and diplaying GTKwaveforms
# Scoreboard test
# Only execute following two lines if this flag (SB) is defined or if no flags are defined when running the script 

if [ -z "$SB" ]; then
    iverilog -Wall -g2012 -o sim/scoreboard_test.vvp tb_scoreboard.sv 
    vvp sim/scoreboard_test.vvp | tee sim/scoreboard_test.log
    gtkwave sim/scoreboard_test.vcd
fi  
if [ -z "$MEM" ]; then
    iverilog -Wall -g2012 -o sim/tb_mem.vvp tb_mem.sv 
    vvp sim/tb_mem.vvp | tee sim/tb_mem.log
    gtkwave sim/tb_mem.vcd
fi  
if [ -z "$PROC" ]; then
    iverilog -Wall -g2012 -o sim/tb_proc.vvp tb_proc.sv 
    vvp sim/tb_proc.vvp | tee sim/tb_proc.log
    gtkwave sim/tb_proc.vcd
fi  
if [ -z "$ISS" ]; then
    iverilog -Wall -g2012 -o sim/tb_issuer.vvp tb_issuer.sv 
    vvp sim/tb_issuer.vvp | tee sim/issuer.log
    gtkwave sim/tb_issuer.vcd   
fi  

