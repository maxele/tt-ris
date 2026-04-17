#include "Vmain.h"
#include "verilated.h"
#include "verilated_vcd_c.h"

#include <iostream>
#include <SDL3/SDL.h>

vluint64_t main_time = 0;
double sc_time_stamp() { return main_time; }

#define VGA_W 801
#define VGA_H 526

Uint8 pixels[VGA_W*VGA_H][4];

int main(int argc, char **argv) {
	// Verilator {{{
	Verilated::commandArgs(argc, argv);
	Vmain *top = new Vmain;

	// tracing
	Verilated::traceEverOn(true);
	const std::unique_ptr<VerilatedContext> contextp{new VerilatedContext};

	VerilatedVcdC* tfp = nullptr;
	tfp = new VerilatedVcdC;
	top->trace(tfp, 99);
	tfp->open("trace.vcd");

	// Simple 10 ns clock period (toggle every 5 ns)
	const vluint64_t half_period = 5;
	// }}}

	// SDL INIT {{{
	SDL_Window* window;
	SDL_Renderer* renderer;
	SDL_Texture* texture;
	SDL_Init(SDL_INIT_VIDEO);
	window = SDL_CreateWindow("TRUS", 400, 400, SDL_WINDOW_RESIZABLE);
	renderer = SDL_CreateRenderer(window, 0);
	texture = SDL_CreateTexture(renderer, SDL_PIXELFORMAT_RGBA8888, SDL_TEXTUREACCESS_STREAMING, VGA_W, VGA_H);
	memset(pixels, 0, sizeof(pixels));
	if (!window || !renderer || !texture) {
		std::cout << "Failed to initialize SDL\n";
		return 1;
	}
	// }}}

	std::cout << "=== Verilator Testbench ===" << std::endl;
	std::cout << "- Resetting DUT..." << std::endl;

	// Apply reset for the first 20 ns
	top->rst_i = 1;
	for (int i = 0; i < 4; ++i) {
		contextp->timeInc(1);
		top->clk_i = 0; top->eval(); tfp->dump(contextp->time()); main_time += half_period;
		contextp->timeInc(1);
		top->clk_i = 1; top->eval(); tfp->dump(contextp->time()); main_time += half_period;
	}
	top->rst_i = 0;

	std::cout << "- Start simulation..." << std::endl;
	std::cout << "_____________________________________________________________" << std::endl;
	// Run for a configurable number of cycles
	bool quit = false;
	int vga_buf_position = 0;
	while (!quit) {
		SDL_Event e;
		while (SDL_PollEvent(&e))
			if (e.type == SDL_EVENT_QUIT)
				quit = 1;
		int w, h;
		SDL_GetWindowSize(window, &w, &h);
		float aspect_ratio = (float)VGA_W / VGA_H;
		SDL_FRect r;
		r.x = 0; r.y = 0; r.w = w; r.h = h;
		if (w > h * aspect_ratio) {
			r.w = h * aspect_ratio;
			r.x = (w - h * aspect_ratio)/2;
		} else {
			r.h = w / aspect_ratio;
			r.y = (h - w / aspect_ratio)/2;
		}

		const int max_cycles = VGA_W*VGA_H;
		//const int max_cycles = VGA_W;
		for (int cycle = 0; cycle < max_cycles; ++cycle) {
			contextp->timeInc(1);
			top->clk_i = 0; top->eval(); tfp->dump(contextp->time()); main_time += half_period;
			contextp->timeInc(1);
			top->clk_i = 1; top->eval(); tfp->dump(contextp->time()); main_time += half_period;
			pixels[vga_buf_position][3] = top->r_o * (float)255/3;
			pixels[vga_buf_position][2] = top->g_o * (float)255/3;
			pixels[vga_buf_position][1] = top->b_o * (float)255/3;
			pixels[vga_buf_position][0] = 255;
			//std::cout << (int)top->r_o << " : " << (int)top->g_o << " : " << (int)top->b_o << std::endl;
			//std::cout << (int)pixels[vga_buf_position][0] << " : " << (int)pixels[vga_buf_position][1] << " : " << (int)pixels[vga_buf_position][2] << " : " << (int)pixels[vga_buf_position][3] << std::endl;
			vga_buf_position = (vga_buf_position+1) % (VGA_W*VGA_H);
		}
		/*SDL_SetRenderDrawColor(renderer, 0, 0, 0, 1);
		  SDL_RenderClear(renderer);*/
		SDL_Delay(10);
		SDL_UpdateTexture(texture, NULL, pixels, VGA_W*sizeof(4));
		SDL_RenderFillRect(renderer, &r);
		SDL_RenderTexture(renderer, texture, NULL, &r);
		SDL_RenderPresent(renderer);
		/*if (vga_buf_position == 0) memset(pixels, 0, sizeof(pixels));*/
	}
	std::cout << "_____________________________________________________________" << std::endl;
	std::cout << "- Simulation done!" << std::endl;

	// SDL QUIT {{{
	SDL_DestroyTexture(texture);
	SDL_DestroyRenderer(renderer);
	SDL_DestroyWindow(window);
	SDL_Quit();
	// }}}

	if (tfp) tfp->close();   // flush VCD file
	top->final();
	delete top;
	return 0;
}
