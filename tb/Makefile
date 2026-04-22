VERILATOR := verilator
VERILATOR_FLAGS := -Wno-fatal -Wall --trace --timing

test: ./obj_dir/Vtt_um_maxele
	make -C obj_dir -f Vtt_um_maxele.mk
	./obj_dir/Vtt_um_maxele

.PHONY: verilator
./obj_dir/Vtt_um_maxele: ../src/project.sv tb.cpp
	rm -f ./obj_dir/Vtt_um_maxele
	$(VERILATOR) $(VERILATOR_FLAGS) \
		--cc ../src/project.sv tb.cpp \
		--top-module tt_um_maxele \
		--exe tb.cpp \
		-CFLAGS -lSDL3 \
		-LDFLAGS -lSDL3

.PHONY: clean
clean:
	rm -rf obj_dir
