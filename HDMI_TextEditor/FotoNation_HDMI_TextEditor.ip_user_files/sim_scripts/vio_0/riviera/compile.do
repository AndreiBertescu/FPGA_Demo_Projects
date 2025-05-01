transcript off
onbreak {quit -force}
onerror {quit -force}
transcript on

vlib work
vmap -link {C:/Users/andre/Documents/IMPORTANT/FotoNation_HDMI_TextEditor/FotoNation_HDMI_TextEditor.cache/compile_simlib/riviera}
vlib riviera/xpm
vlib riviera/xil_defaultlib

vlog -work xpm  -incr "+incdir+../../../../FotoNation_HDMI_TextEditor.gen/sources_1/ip/vio_0/hdl/verilog" "+incdir+../../../../FotoNation_HDMI_TextEditor.gen/sources_1/ip/vio_0/hdl" -l xpm -l xil_defaultlib \
"D:/Apps/Vivado/2023.1/data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv" \
"D:/Apps/Vivado/2023.1/data/ip/xpm/xpm_memory/hdl/xpm_memory.sv" \

vcom -work xpm -93  -incr \
"D:/Apps/Vivado/2023.1/data/ip/xpm/xpm_VCOMP.vhd" \

vlog -work xil_defaultlib  -incr -v2k5 "+incdir+../../../../FotoNation_HDMI_TextEditor.gen/sources_1/ip/vio_0/hdl/verilog" "+incdir+../../../../FotoNation_HDMI_TextEditor.gen/sources_1/ip/vio_0/hdl" -l xpm -l xil_defaultlib \
"../../../../FotoNation_HDMI_TextEditor.gen/sources_1/ip/vio_0/sim/vio_0.v" \

vlog -work xil_defaultlib \
"glbl.v"

