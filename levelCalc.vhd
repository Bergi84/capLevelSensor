library ieee;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.types.all;

entity levelCalc is
generic
(
	refAirCapRatio		: integer range 1 to 256; 
	refFluCapRatio		: integer range 1 to 256;
	measCapRatio		: integer range 1 to 256;
	
	dataWidth			: integer range 1 to 16
);
port
(
	clock					: in std_logic;
	rst					: in std_logic;

	valRefAir			: in unsigned(dataWidth - 1 downto 0);
	valRefFlu			: in unsigned(dataWidth - 1 downto 0);
	valMeas				: in unsigned(dataWidth - 1 downto 0);
	valUpdate			: in std_logic;
	
	recOffset			: in std_logic;
	
	level					: out unsigned(7 downto 0)
);
end;

architecture behavioral of levelCalc is
	constant ratioRefAirToFlu		: integer := (refAirCapRatio*256)/refFluCapRatio;
	constant ratioRefAirToMeas		: integer := (refAirCapRatio*256)/measCapRatio;
	
	COMPONENT lpm_divide
	GENERIC (
		lpm_drepresentation		: STRING;
		lpm_hint						: STRING;
		lpm_nrepresentation		: STRING;
		lpm_type						: STRING;
		lpm_widthd					: NATURAL;
		lpm_widthn					: NATURAL
	);
	PORT (
			denom			: IN STD_LOGIC_VECTOR (dataWidth + 16 DOWNTO 0);
			numer			: IN STD_LOGIC_VECTOR (dataWidth + 16 DOWNTO 0);
			quotient		: OUT STD_LOGIC_VECTOR (7 DOWNTO 0);
			remain		: OUT STD_LOGIC_VECTOR (dataWidth + 16 DOWNTO 0)
	);
	END COMPONENT;

	signal recOffsetInt			: std_logic;
	signal recOffsetLatch		: std_logic;
	signal recOffsetCnt			: unsigned(7 downto 0);
	
	signal offsetAir				: unsigned(dataWidth - 1 downto 0);
	signal offsetFlu				: unsigned(dataWidth - 1 downto 0);
	signal offsetMeas				: unsigned(dataWidth - 1 downto 0);
	
	signal offsetDrift			: signed(dataWidth downto 0);
	signal normCapFlu				: signed(dataWidth + 16 downto 0);
	signal normCapMeas			: signed(dataWidth + 16 downto 0);
	
	signal levelInt				: std_logic_vector(7 downto 0);
	
	signal triCalc1				: std_logic;
	signal triCalc2				: std_logic;
begin
	LPM_DIVIDE_component : LPM_DIVIDE
	GENERIC MAP (
		lpm_drepresentation => "SIGNED",
		lpm_hint => "MAXIMIZE_SPEED=5,LPM_REMAINDERPOSITIVE=TRUE",
		lpm_nrepresentation => "SIGNED",
		lpm_type => "LPM_DIVIDE",
		lpm_widthd => dataWidth + 16,
		lpm_widthn => dataWidth + 16
	)
	PORT MAP (
		denom => std_logic_vector(normCapFlu),
		numer => std_logic_vector(normCapMeas),
		quotient => levelInt,
		remain => open
	);

	process(clock)
	begin
		if(rising_edge(clock))
		then
			recOffsetInt <= recOffset;
		
			if(rst = '1')
			then
				recOffsetCnt <= (others => '0');
			else
				if(recOffsetInt = '1')
				then
					recOffsetLatch <= '1';	
				end if;
				
				if(valUpdate = '1')
				then
					if(recOffsetLatch ='1')
					then
						if(recOffsetCnt = 0 or offsetAir > valRefAir)
						then
							offsetAir <= valRefAir;
						end if;
						
						if(recOffsetCnt = 0 or offsetFlu > valRefFlu)
						then
							offsetFlu <= valRefFlu;
						end if;
						
						if(recOffsetCnt = 0 or offsetMeas > valMeas)
						then
							offsetMeas <= valMeas;
						end if;				
					
						recOffsetCnt <= recOffsetCnt + 1;
						if(recOffsetCnt = 255)
						then
							recOffsetLatch <= '0';
						end if;
					else
						offsetDrift <= (signed('0' & valRefAir) - signed('0' & offsetAir));
						triCalc1 <= '1';
					end if;
				end if;
				
				if(triCalc1 = '1')
				then
					normCapFlu <= (signed('0' & valRefFlu) - signed('0' & offsetFlu) + offsetDrift) * to_signed(ratioRefAirToFlu, 16);
					normCapMeas <= (signed('0' & valMeas) - signed('0' & offsetMeas) + offsetDrift) * to_signed(ratioRefAirToMeas * 256, 16);
				end if;
				
				level <= unsigned(levelInt);
			end if;
		end if;
	end process;
end;