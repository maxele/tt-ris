VERILATOR := verilator
VERILATOR_FLAGS := -Wno-fatal -Wall --trace --timing

test: ./obj_dir/Vmain
	make -C obj_dir -f Vmain.mk
	./obj_dir/Vmain

.PHONY: verilator
./obj_dir/Vmain: main.sv tb.cpp
	rm -f ./obj_dir/Vmain
	$(VERILATOR) $(VERILATOR_FLAGS) \
		--cc main.sv tb.cpp \
		--top-module main \
		--exe tb.cpp \
		-CFLAGS -lSDL3 \
		-LDFLAGS -lSDL3

.PHONY: clean
clean:
	rm -rf obj_dir
