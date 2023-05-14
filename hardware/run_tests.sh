config_file="sim/config.txt"
config_values=""
while IFS='=' read -r line; do
config_values+="-D$line "
done < "$config_file"
command="iverilog -DDEBUG -g2012 " 
command+=$config_values
command+=" -o sim/tb_top.vvp tb_top.sv cam/*.v"
eval $command
command="vvp sim/tb_top.vvp"
eval $command

