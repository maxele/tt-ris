`default_nettype none
module tt_um_maxele (
	ui_in,
	uo_out,
	uio_in,
	uio_out,
	uio_oe,
	ena,
	clk,
	rst_n
);
	reg _sv2v_0;
	input wire [7:0] ui_in;
	output wire [7:0] uo_out;
	input wire [7:0] uio_in;
	output wire [7:0] uio_out;
	output wire [7:0] uio_oe;
	input wire ena;
	input wire clk;
	input wire rst_n;
	reg [9:0] x_p;
	reg [9:0] x_n;
	reg [9:0] y_p;
	reg [9:0] y_n;
	reg sync_n;
	reg [1:0] r_n;
	reg [1:0] g_n;
	reg [1:0] b_n;
	reg [9:0] matrix_p [19:0];
	reg [9:0] matrix_n [19:0];
	reg [31:0] lx;
	reg [31:0] ly;
	always @(posedge clk or posedge rst_n)
		if (rst_n) begin
			x_p <= 0;
			y_p <= 0;
			begin : sv2v_autoblock_1
				integer i;
				for (i = 19; i >= 0; i = i - 1)
					begin : sv2v_autoblock_2
						integer j;
						for (j = 9; j >= 0; j = j - 1)
							matrix_p[i][j] <= 0;
					end
			end
			matrix_p[0][0] <= 1;
			matrix_p[0][1] <= 1;
			matrix_p[0][9] <= 1;
			matrix_p[19][0] <= 1;
			matrix_p[19][9] <= 1;
		end
		else begin
			x_p <= x_n;
			y_p <= y_n;
			begin : sv2v_autoblock_3
				integer i;
				for (i = 19; i >= 0; i = i - 1)
					begin : sv2v_autoblock_4
						integer j;
						for (j = 9; j >= 0; j = j - 1)
							matrix_p[i][j] <= matrix_n[i][j];
					end
			end
		end
	function automatic [1:0] sv2v_cast_2;
		input reg [1:0] inp;
		sv2v_cast_2 = inp;
	endfunction
	always @(*) begin
		if (_sv2v_0)
			;
		x_n = x_p + 1;
		y_n = y_p;
		r_n = 2'b00;
		g_n = 2'b00;
		b_n = 2'b00;
		sync_n = 1;
		begin : sv2v_autoblock_5
			integer i;
			for (i = 19; i >= 0; i = i - 1)
				begin : sv2v_autoblock_6
					integer j;
					for (j = 9; j >= 0; j = j - 1)
						matrix_n[i][j] = matrix_p[i][j];
				end
		end
		lx = 0;
		ly = 0;
		if (y_p < 10'd33)
			r_n = 1;
		else if (y_p > (10'd525 - 10'd2)) begin
			sync_n = 0;
			g_n = 1;
		end
		else if (y_p > ((10'd525 - 10'd10) - 10'd2))
			b_n = 1;
		else if (x_p < 10'd48)
			r_n = 2;
		else if (x_p > (10'd800 - 10'd96)) begin
			sync_n = 0;
			g_n = 2;
		end
		else if (x_p > ((10'd800 - 10'd16) - 10'd96))
			b_n = 2;
		else begin
			lx = ({22'b0000000000000000000000, x_p} - 32'h00000030) >> 2;
			ly = ({22'b0000000000000000000000, y_p} - 32'h00000021) >> 2;
			r_n = sv2v_cast_2(lx >> 2);
			g_n = sv2v_cast_2(ly >> 2);
			b_n = sv2v_cast_2((lx >> 6) + ((ly >> 6) * 2));
		end
		if (x_p >= 10'd800) begin
			y_n = y_p + 1;
			x_n = 0;
			if (y_p >= 10'd525) begin
				x_n = 0;
				y_n = 0;
			end
		end
	end
	assign uo_out = 0;
	assign uio_out = {r_n, g_n, b_n, sync_n, 1'b0};
	assign uio_oe = 0;
	wire _unused = &{ena, clk, rst_n, 1'b0};
	initial _sv2v_0 = 0;
endmodule
