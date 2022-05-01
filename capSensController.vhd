library ieee;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.types.all;

entity capSensController is
generic
(
	capChCnt			: integer range 1 to 16;
	timerWidth		: integer range 1 to 16;
	dischCnt			: integer range 1 to 65536;
	dezRateWidth	: integer range 1 to 16
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
	
	signal aCapInInt	: std_logic_vector(capChCnt-1 downto 0);
	signal bCapInInt	: std_logic_vector(capChCnt-1 downto 0);
	
	signal sample		: std_logic;
	signal timerCnt	: unsigned(timerWidth-1 downto 0);
	
	signal doneTog		: std_logic;
	signal doneTogBuf	: std_logic_vector(1 downto 0);
	
	Type sampArray_t is array (integer range <>) of unsigned(timerWidth-1 downto 0);
	signal aCapSample	: sampArray_t(0 to capChCnt - 1);
	signal bCapSample	: sampArray_t(0 to capChCnt - 1);
	
	Type dezArray_t is array (integer range <>) of unsigned(timerWidth + dezRateWidth - 1 downto 0);
	signal aFilterSumOld 	: dezArray_t(0 to capChCnt-1);
	signal bFilterSumOld		: dezArray_t(0 to capChCnt-1);
	signal aFilterSum 		: dezArray_t(0 to capChCnt-1);
	signal bFilterSum			: dezArray_t(0 to capChCnt-1);
	signal sampleCnt			: unsigned(dezRateWidth-1 downto 0);
begin
	aCapOut <= (others => '0');
	bCapOut <= (others => '1');

	process(clockSamp)
	begin
		if(rising_edge(clockSamp))
		then
			aCapInInt <= aCapIn;
			bCapInInt <= bCapIn;
		
			if(rst = '1')
			then
				sample <= '0';
				timerCnt <= to_unsigned(0, timerCnt'length);
			else
				if(sample = '1')
				then
					aCapOe <= (others => '0');
					bCapOe <= (others => '0');
					
					if(timerCnt > 0)
					then
						aExc <= '1';
						bExc <= '0';
						
						aShld <= '1';
						bShld <= '0';
					else
						aExc <= '0';
						bExc <= '1';
						
						aShld <= '0';
						bShld <= '1';
					end if;
					
					for I in 0 to capChCnt-1 loop
						if(aCapInInt(I) = '0')
						then
							aCapSample(I) <= timerCnt;
						end if;
						if(bCapInInt(I) = '1')
						then
							bCapSample(I) <= timerCnt;
						end if;
					end loop;
					
					if((aCapInInt  = all1 and bCapInInt  = all0) or timerCnt = 2**timerWidth - 1)
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
					
					aExc <= '0';
					bExc <= '1';
						
					aShld <= '0';
					bShld <= '1';
				
					
					if(timerCnt =  dischCnt - 1)
					then
						sample <= '1';
						timerCnt <= to_unsigned(0, timerCnt'length);
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
			doneTogBuf <= doneTogBuf(0) & doneTog;
			if(doneTogBuf(0) /= doneTogBuf(1))
			then
				for I in 0 to capChCnt-1 loop
					aFilterSum(I) <= aFilterSum(I) + aCapSample(I);
					bFilterSum(I) <= bFilterSum(I) + bCapSample(I);
				end loop;

				sampleCnt <= sampleCnt + 1;
			
				if(sampleCnt = 2**dezRateWidth - 1)
				then
					for I in 0 to capChCnt-1 loop
						aCapVal(I) <= (others => '0');
						bCapVal(I) <= (others => '0');
						aCapVal(I)(timerWidth-1 downto 0) <= aFilterSum(I)(timerWidth + dezRateWidth - 1 downto dezRateWidth) - aFilterSumOld(I)(timerWidth + dezRateWidth - 1 downto dezRateWidth);
						bCapVal(I)(timerWidth-1 downto 0) <= bFilterSum(I)(timerWidth + dezRateWidth - 1 downto dezRateWidth) - bFilterSumOld(I)(timerWidth + dezRateWidth - 1 downto dezRateWidth);
						aFilterSumOld(I) <= aFilterSum(I);
						bFilterSumOld(I) <= bFilterSum(I);
					end loop;
					capValUpdate <= '1';
				end if;
			end if;
		end if;
	end process;
end;