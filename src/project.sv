/*
 * Copyright (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

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

	logic [31:0] lx, ly;

	always_ff @(posedge clk_i or posedge rst_i) begin
		if (rst_i) begin
			x_p <= 0;
			y_p <= 0;
			foreach(matrix_p[i])
				foreach(matrix_p[i][j])
					matrix_p[i][j] <= 0;
			matrix_p[0][0] <= 1;
			matrix_p[0][1] <= 1;
			matrix_p[0][9] <= 1;

			matrix_p[19][0] <= 1;
			matrix_p[19][9] <= 1;
		end else begin
			x_p <= x_n;
			y_p <= y_n;
			foreach(matrix_p[i])
				foreach(matrix_p[i][j])
					matrix_p[i][j] <= matrix_n[i][j];
		end
	end

	always_comb begin
		x_n = x_p + 1;
		y_n = y_p;
		r_n = 2'b00;
		g_n = 2'b00;
		b_n = 2'b00;
		sync_n = 1;
		foreach(matrix_n[i])
			foreach(matrix_n[i][j])
				matrix_n[i][j] = matrix_p[i][j];
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
			lx = ({22'b0, x_p} - {22'b0, `HORIZONTAL_BACK_PORCH}) >> 2;
			ly = ({22'b0, y_p} - {22'b0, `VERTICAL_BACK_PORCH}) >> 2;

			r_n = 2'(lx >> 2);
			g_n = 2'(ly >> 2);
			b_n = 2'((lx >> 6) + (ly >> 6)*2);
			//foreach(matrix_p[i,j]) begin
				//if ((`IN(lx-`X-i*`W, 0, `W) && `IN(ly-`Y+j*`W, 0, `W))) begin
				//	r_n = 2;
				//	g_n = 2;
				//	b_n = 2;
				//end
			//end
		end

		if (x_p >= `HORIZONTAL_TOTAL) begin
			y_n = y_p + 1;
			x_n = 0;
			if (y_p >= `VERTICAL_TOTAL) begin
				x_n = 0;
				y_n = 0;
			end
		end
	end

	
	assign r_o = r_n;
	assign g_o = g_n;
	assign b_o = b_n;
	assign sync_o = sync_n;

	// All output pins must be assigned. If not used, assign to 0.
	assign uo_out  = 0;
	assign uio_out = (r_n, g_n, b_n, 2'b0);
	assign uio_oe  = 0;

	// List all unused inputs to prevent warnings
	wire _unused = &{ena, clk, rst_n, 1'b0};

endmodule
