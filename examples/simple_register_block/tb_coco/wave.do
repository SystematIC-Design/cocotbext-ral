onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /example/pclk_i
add wave -noupdate /example/preset_ni
add wave -noupdate -expand /example/apb_h2d_i
add wave -noupdate -expand /example/apb_d2h_o
add wave -noupdate /example/count_en
add wave -noupdate /example/count_q
add wave -noupdate /example/irq_en
add wave -noupdate -expand /example/hw2reg.status.active
add wave -noupdate -expand /example/hw2reg.status.irq
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {84776 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 2
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ps} {619501 ps}
