vlib questa_lib/work
vlib questa_lib/msim

vlib questa_lib/msim/xpm
vlib questa_lib/msim/xil_defaultlib

vmap xpm questa_lib/msim/xpm
vmap xil_defaultlib questa_lib/msim/xil_defaultlib

vlog -work xpm  -incr -mfcu  -sv "+incdir+../../../../FotoNation_HDMI_TextEditor.gen/sources_1/ip/vio_0/hdl/verilog" "+incdir+../../../../FotoNation_HDMI_TextEditor.gen/sources_1/ip/vio_0/hdl" \
"D:/Apps/Vivado/2023.1/data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv" \
"D:/Apps/Vivado/2023.1/data/ip/xpm/xpm_memory/hdl/xpm_memory.sv" \

vcom -work xpm  -93  \
"D:/Apps/Vivado/2023.1/data/ip/xpm/xpm_VCOMP.vhd" \

vlog -work xil_defaultlib  -incr -mfcu  "+incdir+../../../../FotoNation_HDMI_TextEditor.gen/sources_1/ip/vio_0/hdl/verilog" "+incdir+../../../../FotoNation_HDMI_TextEditor.gen/sources_1/ip/vio_0/hdl" \
"../../../../FotoNation_HDMI_TextEditor.gen/sources_1/ip/vio_0/sim/vio_0.v" \

vlog -work xil_defaultlib \
"glbl.v"

