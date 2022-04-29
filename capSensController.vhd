library ieee;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.types.all;

entity capSensController is
generic
(
	capChCnt		: integer range 1 to 16;
	dischCnt		: integer range 1 to 65535
);
port
(
	clockSamp		: in std_logic;
	clockReg			: in std_logic;
	rst				: in std_logic;
	
	aExc				: out std_logic;
	aShld				: out std_logic;
	aCapIn			: in std_logic_vector(capChCnt-1 downto 0);
	aCapOut			: out std_logic_vector(capChCnt-1 downto 0);
	aCapOe			: out std_logic_vector(capChCnt-1 downto 0);
	
	bExc				: out std_logic;
	bShld				: out std_logic;
	bCapIn			: in std_logic_vector(capChCnt-1 downto 0);
	bCapOut			: out std_logic_vector(capChCnt-1 downto 0);
	bCapOe			: out std_logic_vector(capChCnt-1 downto 0);
	
	aCapVal			: out array16B(0 to capChCnt-1);
	bCapVal			: out array16B(0 to capChCnt-1);
	capValUpdate	: out std_logic
);
end;

architecture behavioral of capSensController is
	constant all1		: std_logic_vector(capChCnt-1 downto 0) := (others => '1');
	constant all0		: std_logic_vector(capChCnt-1 downto 0) := (others => '0');
	
	signal sample		: std_logic;
	signal timerCnt	: unsigned(15 downto 0);
	
	signal doneTog		: std_logic;
	signal doneTogOld	: std_logic;
	
	signal aCapSample	: array16B(0 to capChCnt - 1);
	signal bCapSample	: array16B(0 to capChCnt - 1);
begin
	aCapOut <= (others => '0');
	bCapOut <= (others => '1');

	process(clockSamp)
	begin
		if(rising_edge(clockSamp))
		then
			if(rst = '1')
			then
				sample <= '0';
				timerCnt <= to_unsigned(0, timerCnt'length);
			else
				if(sample = '1')
				then
					aCapOe <= (others => '0');
					bCapOe <= (others => '0');
					
					aExc <= '1';
					bExc <= '0';
					
					aShld <= '1';
					bShld <= '0';
					
					for I in 0 to capChCnt-1 loop
						if(aCapIn(I) = '0')
						then
							aCapSample(I) <= timerCnt;
						end if;
						if(bCapIn(I) = '1')
						then
							bCapSample(I) <= timerCnt;
						end if;
					end loop;
					
					if((aCapIn  = all1 and bCapIn  = all0) or timerCnt = x"FFFF")
					then
						timerCnt <= to_unsigned(0, timerCnt'length);
						sample <= '0';
						doneTog <= doneTog xor '1';
					else
						timerCnt <= timerCnt + 1;
					end if;
				else
					aCapOe <= (others => '1');
					bCapOe <= (others => '1');
				
					if(timerCnt = dischCnt)
					then
						timerCnt <= to_unsigned(0, timerCnt'length);
						sample <= '1';
					else
						timerCnt <= timerCnt + 1;
					end if;
				end if;
			end if;
		end if;
	end process;
	
	process(clockReg)
	begin
		if(rising_edge(clockReg))
		then
			capValUpdate <= '0';
			if(doneTogOld /= doneTog)
			then
				capValUpdate <= '1';
				for I in 0 to capChCnt-1 loop
					aCapVal(I) <= aCapSample(I);
					bCapVal(I) <= bCapSample(I);
				end loop;
			end if;
			doneTogOld <= doneTog;
		end if;
	end process;
end;