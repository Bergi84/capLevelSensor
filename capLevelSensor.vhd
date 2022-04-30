library ieee;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.types.all;

entity capLevelSensor is
port
(
	clk50Mhz		: in std_logic;
	
	led			: out std_logic_vector (7 downto 0);
	
	aExc			: out std_logic;
	aShld			: out std_logic;
	aCap			: inOut std_logic_vector(3 downto 0);
	
	bExc			: out std_logic;
	bShld			: out std_logic;
	bCap			: inOut std_logic_vector(3 downto 0);
	
	uartTx		: out std_logic
);
end;

architecture behavioral of capLevelSensor is
	signal clk100Mhz			: std_logic;
	signal clk200Mhz			: std_logic;
	signal pllLocked			: std_logic;
	
	signal aCapIn				: std_logic_vector(3 downto 0);
	signal aCapOut				: std_logic_vector(3 downto 0);
	signal aCapOe				: std_logic_vector(3 downto 0);
	signal bCapIn				: std_logic_vector(3 downto 0);
	signal bCapOut				: std_logic_vector(3 downto 0);
	signal bCapOe				: std_logic_vector(3 downto 0);
	
	signal aCapVal				: array16B(0 to 3);
	signal bCapVal				: array16B(0 to 3);
	signal capValUpdate		: std_logic;
	
	signal capFiltVal			: array32B(0 to 7);
	
	signal aCapValFiltUpdate : std_logic_vector(3 downto 0);
	signal bCapValFiltUpdate : std_logic_vector(3 downto 0);
	
	signal rst					: std_logic;
begin
	rst <= not pllLocked;

	Inst_pll: entity work.pll
	port map
	(
		inclk0 => clk50Mhz,
		c0 => clk100Mhz,
		c1	=> clk200Mhz,
		locked => pllLocked
	);
	
	Inst_ioBuf_aCap: entity work.ioBuf
	port map
	( 
		datain => aCapOut,
		oe => aCapOe,
		dataio => aCap,
		dataout => aCapIn
	); 
	
	Inst_ioBuf_bCap: entity work.ioBuf
	port map
	( 
		datain => bCapOut,
		oe => bCapOe,
		dataio => bCap,
		dataout => bCapIn
	); 
	
	Inst_capSensCon: entity work.capSensController
	generic map
	(
		capChCnt => 4, 
		dischCnt => 256
	)
	port map
	(
		clockSamp => clk200Mhz,
		clockReg	=> clk50Mhz,
		rst => rst,
		
		aExc => aExc,
		aShld => aShld,
		aCapIn => aCapIn,
		aCapOut => aCapOut,
		aCapOe => aCapOe,
		
		bExc => bExc,
		bShld => bShld,
		bCapIn => bCapIn,
		bCapOut => bCapOut,
		bCapOe => bCapOe,
		
		aCapVal => aCapVal,
		bCapVal => bCapVal,
		capValUpdate => capValUpdate
	);

	Inst_dezFilter: for I in 0 to 3 generate
	begin
		Inst_aDezFilter: entity work.dezFilter
		generic map
		(
			dezRate => 1024,
			inWidth => 16,
			outWidth => 32
		)
		port map
		(
			clock	=> clk50Mhz,
			
			inVal => aCapVal(I),
			inUpdate => capValUpdate,
			
			outVal => capFiltVal(I),
			outUpdate => aCapValFiltUpdate(I)
		);
		
		Inst_bDezFilter: entity work.dezFilter
		generic map
		(
			dezRate => 1024,
			inWidth => 16,
			outWidth => 32
		)
		port map
		(
			clock	=> clk50Mhz,
			
			inVal => bCapVal(I),
			inUpdate => capValUpdate,
			
			outVal => capFiltVal(I + 4),
			outUpdate => bCapValFiltUpdate(I)
		);
	end generate;
	
	Inst_dataPlotter: entity work.dataPlotter
	generic map
	(
		valNibblCnt => 8,
		dataValCnt => 8,
		
		bautrateDiv	=> 434
	)
	port map
	(
		clock => clk50Mhz,
		rst => rst,
		
		data => capFiltVal,
		
		triPlot => '1',
		
		uartTx => uartTx
	);
end;