library STD;
use STD.TEXTIO.ALL;
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.STD_LOGIC_TEXTIO.all;

entity SDD1Map is
	port(
		MCLK			: in std_logic;
		RST_N			: in std_logic;
		ENABLE		: in std_logic := '1';
		
		CA   			: in std_logic_vector(23 downto 0);
		DI				: in std_logic_vector(7 downto 0);
		DO				: out std_logic_vector(7 downto 0);
		CPURD_N		: in std_logic;
		CPUWR_N		: in std_logic;
		
		PA				: in std_logic_vector(7 downto 0);
		PARD_N		: in std_logic;
		PAWR_N		: in std_logic;
		
		ROMSEL_N		: in std_logic;
		RAMSEL_N		: in std_logic;
		
		SYSCLKF_CE	: in std_logic;
		SYSCLKR_CE	: in std_logic;
		REFRESH		: out std_logic;
		
		IRQ_N			: out std_logic;

		ROM_ADDR		: out std_logic_vector(22 downto 0);
		ROM_Q			: in  std_logic_vector(15 downto 0);
		ROM_CE_N		: out std_logic;
		ROM_OE_N		: out std_logic;
		ROM_WORD		: out std_logic;
		
		BSRAM_ADDR	: out std_logic_vector(19 downto 0);
		BSRAM_D		: out std_logic_vector(7 downto 0);
		BSRAM_Q		: in  std_logic_vector(7 downto 0);
		BSRAM_CE_N	: out std_logic;
		BSRAM_OE_N	: out std_logic;
		BSRAM_WE_N	: out std_logic;

		MAP_CTRL		: in std_logic_vector(7 downto 0);
		ROM_MASK		: in std_logic_vector(23 downto 0);
		BSRAM_MASK	: in std_logic_vector(23 downto 0);
		
		BRK_OUT		: out std_logic;
		DBG_REG		: in std_logic_vector(7 downto 0) := (others => '0');
		DBG_DAT_IN	: in std_logic_vector(7 downto 0) := (others => '0');
		DBG_DAT_OUT	: out std_logic_vector(7 downto 0);
		DBG_DAT_WR	: in std_logic := '0'
	);
end SDD1Map;

architecture rtl of SDD1Map is

	signal SDD1_ROM_A : std_logic_vector(23 downto 0);
	signal ROM_RD_N : std_logic;
	signal BSRAM_CS_N	: std_logic;
	signal SDD1_DO	: std_logic_vector(7 downto 0);

	signal MAP_SEL : std_logic;
begin
	
	MAP_SEL <= '1' when MAP_CTRL(7 downto 4) = X"5" else '0';

	-- SDD1
	SDD1 : entity work.SDD1
	port map(
		RST_N			=> RST_N and MAP_SEL,
		CLK			=> MCLK,
		ENABLE		=> ENABLE,

		CA				=> CA,
		CPURD_N		=> CPURD_N,
		CPUWR_N		=> CPUWR_N,
		DO				=> SDD1_DO,
		DI				=> DI,
		
		SYSCLKF_CE	=> SYSCLKF_CE,
		SYSCLKR_CE	=> SYSCLKR_CE,

		ROM_A			=> SDD1_ROM_A,
		ROM_DO		=> ROM_Q,
		ROM_RD_N		=> ROM_RD_N,
		
		DBG_REG		=> DBG_REG,
		DBG_DAT_OUT	=> DBG_DAT_OUT
	);

	ROM_ADDR <= (others => '1') when MAP_SEL = '0' else SDD1_ROM_A(22 downto 0) and ROM_MASK(22 downto 0);
	ROM_CE_N <= not MAP_SEL;
	ROM_OE_N <= ROM_RD_N or not MAP_SEL;
	ROM_WORD <= MAP_SEL;

	BSRAM_CS_N <= '0' when CA(23 downto 18) = x"7" & "00" or (CA(22) = '0' and CA(15 downto 13) = "011") else '1';
	BSRAM_ADDR <= (others => '1') when MAP_SEL = '0' else ("0" & CA(19 downto 16) & CA(14 downto 0)) and BSRAM_MASK(19 downto 0);
	BSRAM_CE_N <= BSRAM_CS_N or not MAP_SEL;
	BSRAM_OE_N <= CPURD_N or not MAP_SEL;
	BSRAM_WE_N <= CPUWR_N or not MAP_SEL;
	BSRAM_D    <= (others => '1') when MAP_SEL = '0' else DI;

	DO <= (others => '1') when MAP_SEL = '0' else BSRAM_Q when BSRAM_CS_N = '0' else SDD1_DO;
	
	IRQ_N <= '1';
	BRK_OUT <= '0';
	REFRESH <= '0';
end rtl;