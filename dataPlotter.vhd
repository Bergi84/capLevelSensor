library ieee;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.types.all;

entity dataPlotter is
generic
(
	valNibblCnt		: integer range 1 to 4;
	dataValCnt		: integer range 1 to 16;
	
	bautrateDiv		: integer range 1 to 65535
);
port
(
	clock 			: in std_logic;
	rst				: in std_logic;
	
	data				: in array16B(0 to dataValCnt-1);
	
	triPlot			: in std_logic;
	
	uartTx			: out std_logic
);
end;

architecture behavioral of dataPlotter is
	signal dataInt	: array16B(0 to dataValCnt-1);

	type bitState_t is
	(
		BS_startBit,
		BS_data,
		BS_stopBit
	);
	signal bitState	: bitState_t;
	
	type printState_t is
	(
		PS_Idle,
		PS_pre_0,
		PS_pre_x,
		PS_val,
		PS_post_space,
		PS_post_return
	);
	signal printState : printState_t;

	signal bitPos		: unsigned (2 downto 0);
	signal nibblePos	: unsigned (2 downto 0);
	signal valPos		: unsigned (3 downto 0);
	
	signal divCnt		: unsigned (15 downto 0);
	
	signal char			: unsigned (7 downto 0);
	signal charDone	: std_logic;
	
	signal nextBit		: std_logic;
begin
	process(clock)
	begin
		if(rising_edge(clock))
		then
			if(rst = '1')
			then
				charDone <= '1';
				bitState <= BS_startBit;
				printState <= PS_Idle;
				bitPos <= to_unsigned(0, bitPos'length);
				nibblePos <= to_unsigned(valNibblCnt - 1, nibblePos'length);
				valPos <= to_unsigned(0, valPos'length);
			else
				if(charDone = '1')
				then
					case printState is
						when PS_Idle =>
							if(triPlot = '1')
							then
								printState <= PS_pre_0;
								dataInt <= data;
							end if;
							
						when PS_pre_0 =>
							printState <= PS_pre_x;
							charDone <= '0';
							char <= x"30";		-- ASCII 0
						
						when PS_pre_x =>
							printState <= PS_val;
							charDone <= '0';
							char <= x"78";		-- ASCII x
						
						when PS_val =>
							charDone <= '0';
							if(dataInt(to_integer(valPos))(3 + to_integer(nibblePos) * 4 downto to_integer(nibblePos) * 4) > x"9")
							then
								char <= dataInt(to_integer(valPos))(3 + to_integer(nibblePos) * 4 downto to_integer(nibblePos) * 4) + x"37";
							else
								char <= dataInt(to_integer(valPos))(3 + to_integer(nibblePos) * 4 downto to_integer(nibblePos) * 4) + x"30";
							end if;		
							
							if(nibblePos = 0)
							then
								nibblePos <= to_unsigned(valNibblCnt - 1, nibblePos'length);
								printState <= PS_post_space;
							else
								nibblePos <= nibblePos - 1;
							end if;
							
						when PS_post_space =>
							charDone <= '0';
							char <= x"20";		-- ASCII x
							
							if(valPos = dataValCnt - 1)
							then
								valPos <= to_unsigned(0, valPos'length);
								printState <= PS_post_return;
							else
								valPos <= valPos + 1;
								printState <= PS_pre_0;
							end if;
							
						when PS_post_return =>
							printState <= PS_Idle;
							charDone <= '0';
							char <= x"0D";		-- ASCII CR
					end case;
				end if;
				
				if(divCnt = bautrateDiv - 1)
				then
					divCnt <= to_unsigned(0, divCnt'length);
					nextBit <= '1';
				else
					divCnt <= divCnt + 1;
					nextBit <= '0';
				end if;
				
				if(nextBit = '1')
				then
					case bitState is
						when BS_startBit =>
							if(charDone = '0')
							then
								uartTx <= '0';
								bitState <= BS_data;
							end if;
							
						when BS_data =>
							uartTx <= char(to_integer(bitPos));
							
							if(bitPos = 7)
							then
								bitPos <= to_unsigned(0, bitPos'length);
								bitState <= BS_stopBit;
								charDone <= '1';
							else
								bitPos <= bitPos + 1;
							end if;
							
						when BS_stopBit =>
							uartTx <= '1';
							bitState <= BS_startBit;
					end case;
				end if;
			end if;
		end if;
	end process;
end;