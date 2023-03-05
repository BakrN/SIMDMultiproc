# Shell file for running iverilog tests and diplaying GTKwaveforms

# Scoreboard test
# Only execute following two lines if this flag (SB) is defined or if no flags are defined when running the script
if [ -z "$SB" ]; then

    iverilog -Wall -g2012 -o sim/scoreboard_test tb_scoreboard.sv 
    vvp sim/scoreboard_test | tee sim/scoreboard_test.log
    gtkwave sim/scoreboard_test.vcd

fi  



