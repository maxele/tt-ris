/*
 * Copyright (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`define HORIZONTAL_TOTAL         10'd800
`define VERTICAL_TOTAL           10'd525

`define HORIZONTAL_FRONT_PORCH   10'd16
`define HORIZONTAL_BACK_PORCH    10'd48
`define HORIZONTAL_SYNC          10'd96

`define VERTICAL_FRONT_PORCH     10'd10
`define VERTICAL_BACK_PORCH      10'd33
`define VERTICAL_SYNC            10'd2

`define IS_PRESSED_RIGHT		 uio_in == 1 << 0
`define IS_PRESSED_DOWN 		 uio_in == 1 << 1
`define IS_PRESSED_LEFT 		 uio_in == 1 << 2
`define IS_PRESSED_SPACE		 uio_in == 1 << 3
`define IS_PRESSED_A    		 uio_in == 1 << 4
`define IS_PRESSED_B    		 uio_in == 1 << 5
`define IS_PRESSED_X     	 uio_in == 1 << 6
`define IS_PRESSED_Y    		 uio_in == 1 << 7

`default_nettype none

/* verilator lint_off DECLFILENAME */
module tt_um_maxele (
	input  wire [7:0] ui_in,    // Dedicated inputs
	output wire [7:0] uo_out,   // Dedicated outputs
	input  wire [7:0] uio_in,   // IOs: Input path
	output wire [7:0] uio_out,  // IOs: Output path
	output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
	input  wire       ena,      // always 1 when the design is powered, so you can ignore it
	input  wire       clk,      // clock
	input  wire       rst_n     // reset_n - low to reset
);

	logic [9:0] x_p, x_n;
	logic [9:0] y_p, y_n;

	logic sync_n;
	logic [1:0] r_n;
	logic [1:0] g_n;
	logic [1:0] b_n;

	logic [9:0] matrix_p[19:0];
	logic [9:0] matrix_n[19:0];

	logic [3:0] active_p[3:0];
	logic [3:0] active_n[3:0];

	logic [3:0] ax_p, ax_n;
	logic [4:0] ay_p, ay_n;

	logic [27:0] lx, ly;
	logic [5:0] frames_n, frames_p;

	typedef enum logic [0:0] { STATE_DROP, STATE_IDLE } state_t;
	state_t state_p, state_n;

	always_ff @(posedge clk or posedge rst_n) begin
		if (rst_n) begin
			x_p <= 0;
			y_p <= 0;
			ax_p <= 4'd3;
			ay_p <= 5'd20;

			frames_p <= 1;
			state_p <= STATE_IDLE;

			foreach(matrix_p[i, j]) begin
				matrix_p[i][j] <= 0;
			end
			foreach(active_p[i, j]) begin
				active_p[i][j] <= 0;
			end


			matrix_p[0][0] <= 1;
			matrix_p[0][1] <= 1;
			matrix_p[0][9] <= 1;

			matrix_p[19][0] <= 1;
			matrix_p[19][9] <= 1;
			
			active_p[1][1] <= 1;
			active_p[1][2] <= 1;
			active_p[2][1] <= 1;
			active_p[2][2] <= 1;
		end else begin
			x_p <= x_n;
			y_p <= y_n;
			ax_p <= ax_n;
			ay_p <= ay_n;
			frames_p <= frames_n;
			foreach(matrix_n[i, j]) begin
				matrix_p[i][j] <= matrix_n[i][j];
			end
			foreach(active_n[i, j]) begin
				active_p[i][j] <= active_n[i][j];
			end
			state_p <= state_n;
		end
	end

	always_comb begin // state machine
		state_n = state_p;
		ax_n = ax_p;
		ay_n = ay_p;
		case (state_p)
			STATE_IDLE: begin
				if (x_p == 0 && y_p == 0 && frames_p == 0) begin
					state_n = STATE_DROP;
				end
			end
			STATE_DROP: begin
				//ay_p > 0 && 
				ay_n = ay_p-1;
				state_n = STATE_IDLE;
			end
		endcase
	end

	always_comb begin // display logic
		x_n = x_p + 1;
		y_n = y_p;
		frames_n = frames_p;
		r_n = 2'b00;
		g_n = 2'b00;
		b_n = 2'b00;
		sync_n = 1;
		foreach(matrix_n[i, j]) begin
			matrix_n[i][j] = matrix_p[i][j];
		end
		foreach(active_p[i, j]) begin
			active_n[i][j] = active_p[i][j];
		end
		lx = 0;
		ly = 0;

		//if (`H_BACK_PORCH < x_p && x_p < `H_FRONT_PORCH)
		//end else if ((x_p >> 4 & 1) > 0) begin

		if (y_p < `VERTICAL_BACK_PORCH) begin
			r_n = 1;
		end else if (y_p > `VERTICAL_TOTAL-`VERTICAL_SYNC) begin
			sync_n = 0;
			g_n = 1;
		end else if (y_p > `VERTICAL_TOTAL-`VERTICAL_FRONT_PORCH-`VERTICAL_SYNC) begin
			b_n = 1;
		end else if (x_p < `HORIZONTAL_BACK_PORCH) begin
			r_n = 2;
		end else if (x_p > `HORIZONTAL_TOTAL-`HORIZONTAL_SYNC) begin
			sync_n = 0;
			g_n = 2;
		end else if (x_p > `HORIZONTAL_TOTAL-`HORIZONTAL_FRONT_PORCH-`HORIZONTAL_SYNC) begin
			b_n = 2;
		end else begin
			lx = ({18'b0, x_p} - {18'b0, `HORIZONTAL_BACK_PORCH}) >> 4;
			ly = ({18'b0, y_p} - {18'b0, `VERTICAL_BACK_PORCH}) >> 4;
			// Die koordinaten der Matrix starten unten links, die
			// des aktiven hingegen, starten oben links, damit es
			// keine negativen y koordinaten haben kann.
			// Wenn AYC oder AXC "kleiner null" sind, dann underflowen sie, also sind sie sehr groß
			`define AY ly - (7 + 20 - {23'b0, ay_p})
			`define AX lx - (10 + {23'b0, ax_p})
			`define MY 19-(ly - 7)
			`define MX lx-10

			if (ly == 10 && lx > 20 && lx < 26) begin // frames counter (damit stück fällt)
				b_n = 1;
				if ((frames_p >> (25-lx) & 1) == 1) begin
					b_n = 3;
				end
			end

			if (ly == 14 && lx > 20 && lx < 28) begin
				b_n = 1;
				if ((uio_in >> (27-lx) & 1) == 1) begin
					b_n = 3;
				end
			end

			if (`AY < 4 && `AX < 4) begin // aktives stück
				if (active_p[`AY][`AX]) begin
					g_n = 2;
				end else begin
					g_n = 1;
				end
			end

			if (`MY < 20 && `MX < 10) begin // matrix
				if (matrix_p[`MY][`MX]) begin
					r_n = 2;
				end else begin
					r_n = 1;
				end
			end
		end

		if (x_p >= `HORIZONTAL_TOTAL) begin
			y_n = y_p + 1;
			x_n = 0;
			if (y_p >= `VERTICAL_TOTAL) begin
				x_n = 0;
				y_n = 0;
				frames_n = (frames_p+1) % 6'b100;
			end
		end
	end

	
	// All output pins must be assigned. If not used, assign to 0.
	assign uo_out = {r_n, g_n, b_n, sync_n, 1'b0};
	assign uio_out  = 0;
	assign uio_oe  = 0;

	// List all unused inputs to prevent warnings
	wire _unused = &{uio_in, ui_in, ena};

endmodule
