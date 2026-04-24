----------------------------------------------------------------------------------
-- Company:          Univerity of Massachusetts 
-- Engineer:         Kevin Andryc
-- 
-- Create Date:      17:50:27 09/19/2010  
-- Module Name:      gpgpu_top_level - arch 
-- Project Name:     GPGPU
-- Target Devices: 
-- Tool versions:    ISE 10.1/// sohuld i try to use the compiler for rtl description!!!! 
-- Description: 
--
----------------------------------------------------------------------------
-- Revisions:       
--  REV:        Date:           Description:
--  0.1.a       9/13/2010       Created Top level file
----------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use work.gpgpu_package.all;

entity gpgpu_ml605_top_level is
	generic(
		GMEM_ADDR_SIZE   : integer := 18;
		CMEM_ADDR_SIZE   : integer := 13;
		SYSMEM_ADDR_SIZE : integer := 18;
		SHMEM_ADDR_SIZE	 : integer := 14
	);
	port(
		sys_clk                  : in  std_logic;
		host_reset               : in  std_logic;
		block_scheduler_en       : in  std_logic;
		kernel_done              : out std_logic;
		smp_done_signal          : out std_logic;
		gmem_cntrl_en_in         : in  std_logic;
		cmem_cntrl_en_in         : in  std_logic;
		sysmem_cntrl_en_in       : in  std_logic;
		gpgpu_config_cntrl_en_in : in  std_logic;
		gpgpu_config_top_cs      : in  std_logic;
		gpgpu_config_top_rw      : in  std_logic;
		gpgpu_config_top_adr     : in  std_logic_vector(31 downto 0);
		gpgpu_config_top_rd_data : out std_logic_vector(31 downto 0);
		gpgpu_config_top_wr_data : in  std_logic_vector(31 downto 0);
		gmem_wr_data_a_in        : in  std_logic_vector(7 downto 0);
		gmem_addr_a_in           : in  std_logic_vector(GMEM_ADDR_SIZE - 1 downto 0);
		gmem_wr_en_a_in          : in  std_logic;
		gmem_rd_data_a_out       : out std_logic_vector(7 downto 0);
		gmem_wr_data_b_in        : in  std_logic_vector(7 downto 0);
		gmem_addr_b_in           : in  std_logic_vector(GMEM_ADDR_SIZE - 1 downto 0);
		gmem_wr_en_b_in          : in  std_logic;
		gmem_rd_data_b_out       : out std_logic_vector(7 downto 0);
		cmem_wr_data_a_in        : in  std_logic_vector(7 downto 0);
		cmem_addr_a_in           : in  std_logic_vector(CMEM_ADDR_SIZE - 1 downto 0);
		cmem_wr_en_a_in          : in  std_logic;
		cmem_rd_data_a_out       : out std_logic_vector(7 downto 0);
		cmem_wr_data_b_in        : in  std_logic_vector(7 downto 0);
		cmem_addr_b_in           : in  std_logic_vector(CMEM_ADDR_SIZE - 1 downto 0);
		cmem_wr_en_b_in          : in  std_logic;
		cmem_rd_data_b_out       : out std_logic_vector(7 downto 0);
		sysmem_wr_data_a_in      : in  std_logic_vector(SYSMEM_DATA_SIZE-1 downto 0);
		sysmem_addr_a_in         : in  std_logic_vector(SYSMEM_ADDR_SIZE - 1 downto 0);
		sysmem_wr_en_a_in        : in  std_logic;
		sysmem_rd_data_a_out     : out std_logic_vector(SYSMEM_DATA_SIZE-1 downto 0);
		sysmem_wr_data_b_in      : in  std_logic_vector(SYSMEM_DATA_SIZE-1 downto 0);
		sysmem_addr_b_in         : in  std_logic_vector(SYSMEM_ADDR_SIZE - 1 downto 0);
		sysmem_wr_en_b_in        : in  std_logic;
		sysmem_rd_data_b_out     : out std_logic_vector(SYSMEM_DATA_SIZE-1 downto 0)
	);
end gpgpu_ml605_top_level;

architecture arch of gpgpu_ml605_top_level is

	signal kernel_blocks_per_core : std_logic_vector(3 downto 0);
	signal kernel_num_gprs        : std_logic_vector(8 downto 0);  --gpr: General Purpose Register
	signal kernel_shmem_size      : std_logic_vector(31 downto 0); -- static shared memory size used by kernel
	signal kernel_parameter_size  : std_logic_vector(15 downto 0);
	signal kernel_dyn_shmem_size  : std_logic_vector(31 downto 0); -- dynamic shared memory size used by the kernel
	signal kernel_block_x         : std_logic_vector(15 downto 0); -- block size in the x dimension of the kernel 
	signal kernel_block_y         : std_logic_vector(15 downto 0); -- thread block size in the y direction of the kernel 
	signal kernel_block_z         : std_logic_vector(15 downto 0); -- thread block size in the z direction of the kernel
	signal kernel_grid_x          : std_logic_vector(15 downto 0); -- grid dimension x direction. number of blocks in the x direction in the kernel grid 
	signal kernel_grid_y          : std_logic_vector(15 downto 0); --grid dimension y direction. number of blocks in the y direction in the kernel grid

	signal smp_done : std_logic;  --streaming multiprocessor finished execution of the block 

	signal threads_per_block : std_logic_vector(11 downto 0); --total number of threads per block
	signal num_blocks        : std_logic_vector(3 downto 0); --total number of thread blocks
	signal shmem_base_addr   : std_logic_vector(31 downto 0); --base adress of the shared memory region assigned to a block
	signal shmem_size        : std_logic_vector(31 downto 0); --shared memory size
	signal parameter_size    : std_logic_vector(15 downto 0); 
	signal gprs_size         : std_logic_vector(8 downto 0);
	signal block_x           : std_logic_vector(15 downto 0);
	signal block_y           : std_logic_vector(15 downto 0);
	signal block_z           : std_logic_vector(15 downto 0);
	signal grid_x            : std_logic_vector(15 downto 0);
	signal grid_y            : std_logic_vector(15 downto 0);
	signal block_idx         : std_logic_vector(15 downto 0); 

	signal smp_run_en : std_logic; --enable the streaming multiprocessor to start executing
	
	-- ADDED GIANLUCA ROASCIO
	signal smp_reset : std_logic; --streaming multiprocessor reset
	
	signal block_scheduler_rdy : std_logic; --block scheduler ready

	signal kernel_done_i : std_logic; --kernel done
	--
	-- Configuration

	--gpt says: Configuration of hardware is done through registers. Not through direct control wires.
	--
	signal gpgpu_config_reg_cs       : std_logic;  -- cs: chip select
	signal gpgpu_config_reg_rw       : std_logic;  -- rw: read write control
	signal gpgpu_config_reg_adr      : std_logic_vector(31 downto 0); -- which register adress
	signal gpgpu_config_reg_data_in  : std_logic_vector(31 downto 0); --data written by the host into adressed reg
	signal gpgpu_config_reg_data_out : std_logic_vector(31 downto 0); --data returned to host when reading

	signal gpgpu_config_smp_cs      : std_logic; -- Streaming multiprocessor is selected for this config access
	signal gpgpu_config_smp_rw      : std_logic; -- read/write direction for SMP config space
	signal gpgpu_config_smp_adr     : std_logic_vector(31 downto 0); -- adress line to defy which configuration streaming multiprocesso register
	signal gpgpu_config_smp_rd_data : std_logic_vector(31 downto 0);  --data to store into that configuration register related to the streaming multiprocessor
	signal gpgpu_config_smp_wr_data : std_logic_vector(31 downto 0) :=(others=>'0'); -- value returned from that smp config register

	--
	-- Memory
	--
	signal gmem_wr_data_a : std_logic_vector(7 downto 0); --data to write in the memory, port A
	signal gmem_addr_a    : std_logic_vector(GMEM_ADDR_SIZE - 1 downto 0); --which global memory location, portA
	signal gmem_wr_en_a   : std_logic; --1 means write , 0 means we read
	signal gmem_rd_data_a : std_logic_vector(7 downto 0); --data to read in the memory portA

	signal gmem_wr_data_b : std_logic_vector(7 downto 0);  --data to write in the memory, port B
	signal gmem_addr_b    : std_logic_vector(GMEM_ADDR_SIZE - 1 downto 0); -- which global mem location, portB
	signal gmem_wr_en_b   : std_logic; --1 is write, 0 means read
	signal gmem_rd_data_b : std_logic_vector(7 downto 0); --data to read from the memory port B

	signal smp_gmem_wr_data_a : std_logic_vector(7 downto 0); --write data to global memory port A from the streaming multi processor
	signal smp_gmem_addr_a    : std_logic_vector(GMEM_ADDR_SIZE - 1 downto 0);
	signal smp_gmem_wr_en_a   : std_logic;
	signal smp_gmem_rd_data_a : std_logic_vector(7 downto 0);

	signal smp_gmem_wr_data_b : std_logic_vector(7 downto 0); --write data to global mem portB from streaming multiprocessor
	signal smp_gmem_addr_b    : std_logic_vector(GMEM_ADDR_SIZE - 1 downto 0); --global memory adress for port b driven by smp
	signal smp_gmem_wr_en_b   : std_logic; -- 1 is write, 0 s read, for port b of global memory. driven by smp
	signal smp_gmem_rd_data_b : std_logic_vector(7 downto 0); --wire returning data to smp from global memory port b.

	signal cmem_wr_data_a : std_logic_vector(7 downto 0);  --write data wire of constant memory port A
	signal cmem_addr_a    : std_logic_vector(CMEM_ADDR_SIZE - 1 downto 0); --adress wire of constant memory port A
	signal cmem_wr_en_a   : std_logic; --write or read wire of constnant memory
	signal cmem_rd_data_a : std_logic_vector(7 downto 0); -- read data wire of constnat memory port A

	signal cmem_wr_data_b : std_logic_vector(7 downto 0); --write data wire of constant memory port B
	signal cmem_addr_b    : std_logic_vector(CMEM_ADDR_SIZE - 1 downto 0); -- adress wire of constant memory port B
	signal cmem_wr_en_b   : std_logic; -- write or read wire constant memory port B
	signal cmem_rd_data_b : std_logic_vector(7 downto 0); -- read data wire of constant memory port B

	signal smp_cmem_wr_data_a : std_logic_vector(7 downto 0); -- smp wire used for writing data to port A of constant memory 
	signal smp_cmem_addr_a    : std_logic_vector(CMEM_ADDR_SIZE - 1 downto 0); -- smp wire used for writing adress of port A of constant memory
	signal smp_cmem_wr_en_a   : std_logic; -- smp wire used for selecting read or write operation of port A of constna  memory
	signal smp_cmem_rd_data_a : std_logic_vector(7 downto 0); -- smp wire used for reading port A of constant memory

	signal sysmem_wr_data_a : std_logic_vector(SYSMEM_DATA_SIZE-1 downto 0); --system memory wire for writing data in port A
	signal sysmem_addr_a    : std_logic_vector(SYSMEM_ADDR_SIZE - 1 downto 0); --system memory wire for writing adress port A
	signal sysmem_wr_en_a   : std_logic; --system memory wire for selecting read or write operation
	signal sysmem_rd_data_a : std_logic_vector(SYSMEM_DATA_SIZE-1 downto 0); -- system memory wire for reading the data port A

	signal sysmem_wr_data_b : std_logic_vector(SYSMEM_DATA_SIZE-1 downto 0); --system memory wire for writing data port B
	signal sysmem_addr_b    : std_logic_vector(SYSMEM_ADDR_SIZE - 1 downto 0); --system memory wire for adress port B
	signal sysmem_wr_en_b   : std_logic; --system memory wire for writing or reading data selection port B
	signal sysmem_rd_data_b : std_logic_vector(SYSMEM_DATA_SIZE-1 downto 0); -- system memory read data port B

	signal smp_sysmem_addr    : std_logic_vector(SYSMEM_ADDR_SIZE - 1 downto 0); -- 
	signal smp_sysmem_rd_data : std_logic_vector(SYSMEM_DATA_SIZE - 1 downto 0);
	signal smp_sysmem_addr_a    : std_logic_vector(SYSMEM_ADDR_SIZE - 1 downto 0);
	signal smp_sysmem_wr_en_a   : std_logic;
	signal smp_sysmem_rd_data_a : std_logic_vector(SYSMEM_DATA_SIZE-1 downto 0);
	signal smp_sysmem_addr_b    : std_logic_vector(SYSMEM_ADDR_SIZE - 1 downto 0);
	signal smp_sysmem_wr_en_b   : std_logic;
	signal smp_sysmem_rd_data_b : std_logic_vector(SYSMEM_DATA_SIZE-1 downto 0);

	--notice that in the last 8 signals related to smp and system mem interfaces, there is no smp_sysmem_wr_data_a or smp_sysmem_wr_data_b,
	--implying that the smp only reads from system memory


begin

	-- Dummy smp_done output for top-level design
	smp_done_signal <= smp_done;
	kernel_done     <= kernel_done_i;

	--
	-- Configuration. remember that configuration registers They’re control/state registers that define how the GPU runs a kernel
	--preetty sure that the host/top module drives the configuration register before the execution of the kernel,
	--while in execution the smp controls them if it may ether need for instance to read kernel launch dimensions or parameters of that sort
	--
	--deciding who gets to talk to the configuration registers on the basis of gpgpu_config_cntrl_en_in
	--if either the top host or the smp...

	gpgpu_config_reg_cs      <= gpgpu_config_top_cs when (gpgpu_config_cntrl_en_in = '1') else gpgpu_config_smp_cs;
	gpgpu_config_reg_rw      <= gpgpu_config_top_rw when (gpgpu_config_cntrl_en_in = '1') else gpgpu_config_smp_rw;
	gpgpu_config_reg_adr     <= gpgpu_config_top_adr when (gpgpu_config_cntrl_en_in = '1') else gpgpu_config_smp_adr;
	gpgpu_config_reg_data_in <= gpgpu_config_top_wr_data when (gpgpu_config_cntrl_en_in = '1') else gpgpu_config_smp_wr_data;

	gpgpu_config_top_rd_data <= gpgpu_config_reg_data_out when (gpgpu_config_cntrl_en_in = '1') else (others => '0');
	gpgpu_config_smp_rd_data <= gpgpu_config_reg_data_out when (gpgpu_config_cntrl_en_in = '0') else (others => '0');

	-- instantiation of the config part of GPU module.
	-- hardware equivalent of a “control panel” that stores all the kernel launch parameters and exposes them to the rest of the design
	
	uGPGPUConfiguration : gpgpu_configuration				
		port map(
			clk_in                 => sys_clk,
			host_reset             => host_reset,
			reset_registers        => host_reset,
			config_reg_cs          => gpgpu_config_reg_cs,
			config_reg_rw          => gpgpu_config_reg_rw,
			config_reg_adr         => gpgpu_config_reg_adr,
			config_reg_data_in     => gpgpu_config_reg_data_in,
			config_reg_data_out    => gpgpu_config_reg_data_out,
			kernel_blocks_per_core => kernel_blocks_per_core,
			kernel_num_gprs        => kernel_num_gprs,
			kernel_shmem_size      => kernel_shmem_size,
			kernel_parameter_size  => kernel_parameter_size,
			kernel_dyn_shmem_size  => kernel_dyn_shmem_size,
			kernel_block_x         => kernel_block_x,
			kernel_block_y         => kernel_block_y,
			kernel_block_z         => kernel_block_z,
			kernel_grid_x          => kernel_grid_x,
			kernel_grid_y          => kernel_grid_y
		);

	--
	-- Block Scheduler					-- how is designed?? is it structural or behavioral???
	--
	uBlockScheduler : block_scheduler
		port map(
			clk_in                    => sys_clk,
			host_reset                => host_reset,
			en                        => block_scheduler_en,
			kernel_blocks_per_core_in => kernel_blocks_per_core, --how many blocks can be active per smp ( resource limit i think )
			kernel_num_gprs_in        => kernel_num_gprs, --How many registers per thread/block ( impacts occupancy )
			kernel_shmem_size_in      => kernel_shmem_size,
			kernel_parameter_size_in  => kernel_parameter_size,
			kernel_dyn_shmem_size_in  => kernel_dyn_shmem_size,
			kernel_block_x_in         => kernel_block_x,  --threads in each block dimension x y z
			kernel_block_y_in         => kernel_block_y,
			kernel_block_z_in         => kernel_block_z,
			kernel_grid_x_in          => kernel_grid_x, --how many blocks exist in the grid.
			kernel_grid_y_in          => kernel_grid_y,
			smp_done_in               => smp_done,  --this is the way for the smp to tell scheduler that it has finished executing a block it gave to him. 
													--scheduler will use this to decide if is ok to increment block_idx, launch the next block, or eventually assert kernel_done
			threads_per_block_out     => threads_per_block,  --output signals which are sent to smp
			num_blocks_out            => num_blocks,
			shmem_base_addr_out       => shmem_base_addr,
			shmem_size_out            => shmem_size,
			parameter_size_out        => parameter_size,
			gprs_size_out             => gprs_size,
			block_x_out               => block_x,
			block_y_out               => block_y,
			block_z_out               => block_z,
			grid_x_out                => grid_x,
			grid_y_out                => grid_y,
			block_idx_out             => block_idx,  --This is the block ID being assigned
			--smp_reset_out             => open,
			smp_reset_out			  => smp_reset,  --Allows the scheduler to reset the SMP between kernels or before starting.
			smp_en_out                => smp_run_en, --This is the “GO” signal: “Start executing now with the current block parameters.”
			rdy                       => block_scheduler_rdy, --scheduler is ready / configured / able to launch.
			kernel_done               => kernel_done_i --Means “all blocks are finished.
		);  --takes the “kernel launch configuration” (grid/block sizes, resource usage, etc.) and turns it into work assignments for the SMP
			--it’s the hardware version of the runtime deciding: how many thread blocks exist, which block index to run next, when to start the SM, when the kernel is finished.


	--
	-- Streaming Multiprocessor - for the moment, there is just one of them
	--
	uStreamingMultiProcessor : streaming_multiprocessor
		generic map(
			STREAMING_MULTIPROCESSOR_ID => x"00",
			GMEM_ADDR_SIZE              => GMEM_ADDR_SIZE,
			CMEM_ADDR_SIZE              => CMEM_ADDR_SIZE,
			SYSMEM_ADDR_SIZE            => SYSMEM_ADDR_SIZE -- Address sizes tell the SMP how wide its address buses must be to talk to
		)
		port map(
			clk_in                   => sys_clk,
			--host_reset               => host_reset,
			host_reset				 => smp_reset,
			threads_per_block_in     => threads_per_block, --total threads this block has
			num_blocks_in            => num_blocks,  --total blocks in kernel
			shmem_base_addr_in       => shmem_base_addr,
			shmem_size_in            => shmem_size,  --shared memory region assigned to this block
			parameter_size_in        => parameter_size,  --how many bytes/words of parameters exist (so SMP knows how much to fetch)
			gprs_size_in             => gprs_size,  --register allocation info
			block_x_in               => block_x,
			block_y_in               => block_y,
			block_z_in               => block_z,
			grid_x_in                => grid_x,
			grid_y_in                => grid_y,
			block_idx_in             => block_idx,
			smp_run_en               => smp_run_en,  --start executing the assigned block
			gpgpu_config_reg_cs      => gpgpu_config_smp_cs, 
			gpgpu_config_reg_rw      => gpgpu_config_smp_rw,
			gpgpu_config_reg_adr     => gpgpu_config_smp_adr,
			gpgpu_config_reg_rd_data => gpgpu_config_smp_rd_data, --so that smp is able to read configuration register 
			gmem_wr_data_a           => smp_gmem_wr_data_a,
			gmem_addr_a              => smp_gmem_addr_a,
			gmem_wr_en_a             => smp_gmem_wr_en_a,
			gmem_rd_data_a           => smp_gmem_rd_data_a,
			gmem_wr_data_b           => smp_gmem_wr_data_b,
			gmem_addr_b              => smp_gmem_addr_b,
			gmem_wr_en_b             => smp_gmem_wr_en_b,
			gmem_rd_data_b           => smp_gmem_rd_data_b,  --This is the SMP acting like a “load/store unit” that can issue memory requests
			cmem_wr_data_a           => smp_cmem_wr_data_a,
			cmem_addr_a              => smp_cmem_addr_a,
			cmem_wr_en_a             => smp_cmem_wr_en_a,
			cmem_rd_data_a           => smp_cmem_rd_data_a, --host loads constants before run, SMP reads them during execution
			sysmem_addr 			 => smp_sysmem_addr_a,
			sysmem_rd_data  		 => smp_sysmem_rd_data_a,
			--sysmem_addr_a            => smp_sysmem_addr_a,
			--sysmem_wr_en_a           => smp_sysmem_wr_en_a,
			--sysmem_rd_data_a         => smp_sysmem_rd_data_a,
			--sysmem_addr_b            => smp_sysmem_addr_b,
			--sysmem_wr_en_b           => smp_sysmem_wr_en_b,
			--sysmem_rd_data_b         => smp_sysmem_rd_data_b,
			smp_done				 => smp_done  -- I finished executing that block
		);

	-- WAITING FOR 2ND SMP INSERTION
	smp_sysmem_addr_b <= (others => '0');

	--
	-- Global Memory
	--
	-- on the basis of the gmem_cntrl_en_in signal it defines who controls the global memory. when 1, the host controls, when 0 the smp does.

	gmem_wr_data_a     <= gmem_wr_data_a_in when (gmem_cntrl_en_in = '1') else smp_gmem_wr_data_a;
	gmem_addr_a        <= gmem_addr_a_in when (gmem_cntrl_en_in = '1') else smp_gmem_addr_a;
	gmem_wr_en_a       <= gmem_wr_en_a_in when (gmem_cntrl_en_in = '1') else smp_gmem_wr_en_a;
	gmem_rd_data_a_out <= gmem_rd_data_a when (gmem_cntrl_en_in = '1') else (others => '0');
	smp_gmem_rd_data_a <= gmem_rd_data_a when (gmem_cntrl_en_in = '0') else (others => '0');

	gmem_wr_data_b     <= gmem_wr_data_b_in when (gmem_cntrl_en_in = '1') else smp_gmem_wr_data_b;
	gmem_addr_b        <= gmem_addr_b_in when (gmem_cntrl_en_in = '1') else smp_gmem_addr_b;
	gmem_wr_en_b       <= gmem_wr_en_b_in when (gmem_cntrl_en_in = '1') else smp_gmem_wr_en_b;
	gmem_rd_data_b_out <= gmem_rd_data_b when (gmem_cntrl_en_in = '1') else (others => '0');
	smp_gmem_rd_data_b <= gmem_rd_data_b when (gmem_cntrl_en_in = '0') else (others => '0');

	uGlobalMemory : dp_ram 
	generic map(
		RAM_SIZE => 262144, 
		RAM_A_WIDTH => GMEM_ADDR_SIZE, 
		RAM_D_WIDTH => 8
		-- synthesis translate_off
	    ,
	    --RAM_INIT_FILE => "./global_mem.mif" 					--check this one !!!!!
		RAM_INIT_FILE => "C:\Users\giovi\OneDrive\Desktop\Magistrale\Tesi\FlexGripPlus\Open-GPGPU-FlexGrip-\FlexGripPlus_4.4\RTL\TB\TP\global_mem.mif"

		-- synthesis translate_on
	)
	port map(
		rst  => host_reset,
		clk  => sys_clk,
		addr_a => gmem_addr_a,
		we_a   => gmem_wr_en_a,
		din_a  => gmem_wr_data_a,
		dout_a => gmem_rd_data_a,
		addr_b => gmem_addr_b,
		we_b   => gmem_wr_en_b,
		din_b  => gmem_wr_data_b,
		dout_b => gmem_rd_data_b
	);

	--
	-- Constant Memory
	--
	cmem_wr_data_a     <= cmem_wr_data_a_in when (cmem_cntrl_en_in = '1') else (others => '0');
	cmem_addr_a        <= cmem_addr_a_in when (cmem_cntrl_en_in = '1') else smp_cmem_addr_a;
	cmem_wr_en_a       <= cmem_wr_en_a_in when (cmem_cntrl_en_in = '1') else '0';  --smp performs a read from port A of constant memory
	cmem_rd_data_a_out <= cmem_rd_data_a when (cmem_cntrl_en_in = '1') else (others => '0');
	smp_cmem_rd_data_a <= cmem_rd_data_a when (cmem_cntrl_en_in = '0') else (others => '0');

	
	cmem_wr_data_b     <= cmem_wr_data_b_in when (cmem_cntrl_en_in = '1') else (others => '0');   -- port b is not used by SMP
	cmem_addr_b        <= cmem_addr_b_in when (cmem_cntrl_en_in = '1') else (others => '0');  
	cmem_wr_en_b       <= cmem_wr_en_b_in when (cmem_cntrl_en_in = '1') else  '0';
	cmem_rd_data_b_out <= cmem_rd_data_b when (cmem_cntrl_en_in = '1') else (others => '0');

	uConstantMemory : dp_ram generic map(RAM_SIZE => 8192, RAM_A_WIDTH => CMEM_ADDR_SIZE, RAM_D_WIDTH => 8
		-- synthesis translate_off
	    ,
	    --RAM_INIT_FILE => "./constant_mem.mif" 							-- check this one again, which constants it has??
		RAM_INIT_FILE => "C:\Users\giovi\OneDrive\Desktop\Magistrale\Tesi\FlexGripPlus\Open-GPGPU-FlexGrip-\FlexGripPlus_4.4\RTL\constant_mem.mif"

		-- synthesis translate_on
	)
	port map(
		rst  => host_reset,
		clk  => sys_clk,
		addr_a => cmem_addr_a,
		we_a   => cmem_wr_en_a,
		din_a  => cmem_wr_data_a,
		dout_a => cmem_rd_data_a,
		addr_b => cmem_addr_b,
		we_b   => cmem_wr_en_b,
		din_b  => cmem_wr_data_b,
		dout_b => cmem_rd_data_b
	);

	--
	-- System Memory
	--
	sysmem_wr_data_a     <= sysmem_wr_data_a_in when (sysmem_cntrl_en_in = '1') else (others => '0');
	sysmem_addr_a        <= sysmem_addr_a_in when (sysmem_cntrl_en_in = '1') else smp_sysmem_addr_a;
	sysmem_wr_en_a       <= sysmem_wr_en_a_in when (sysmem_cntrl_en_in = '1') else '0';  --smp forced to only read the system memory when it is selected to communicate with it
	sysmem_rd_data_a_out <= sysmem_rd_data_a when (sysmem_cntrl_en_in = '1') else (others => '0');
	smp_sysmem_rd_data_a <= sysmem_rd_data_a when (sysmem_cntrl_en_in = '0') else (others => '0');

	sysmem_wr_data_b     <= sysmem_wr_data_b_in when (sysmem_cntrl_en_in = '1') else (others => '0');
	sysmem_addr_b        <= sysmem_addr_b_in when (sysmem_cntrl_en_in = '1') else smp_sysmem_addr_b;
	sysmem_wr_en_b       <= sysmem_wr_en_b_in when (sysmem_cntrl_en_in = '1') else '0';
	sysmem_rd_data_b_out <= sysmem_rd_data_b when (sysmem_cntrl_en_in = '1') else (others => '0');
	smp_sysmem_rd_data_b <= sysmem_rd_data_b when (sysmem_cntrl_en_in = '0') else (others => '0');

	uSystemMemoryController : system_memory_cntlr
    generic map(SYSMEM_ADDR_SIZE => SYSMEM_ADDR_SIZE)
	port map(
		clk_in         => sys_clk,
		mem_data_in_a  => sysmem_wr_data_a,
		mem_addr_in_a  => sysmem_addr_a,
		mem_wr_en_a    => sysmem_wr_en_a,
		mem_data_out_a => sysmem_rd_data_a,
		mem_data_in_b  => sysmem_wr_data_b,
		mem_addr_in_b  => sysmem_addr_b,
		mem_wr_en_b    => sysmem_wr_en_b,
		mem_data_out_b => sysmem_rd_data_b
	);

end arch;
