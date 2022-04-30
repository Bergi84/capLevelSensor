library ieee;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

package types is
	type array16B is array(integer range <>) of unsigned(15 downto 0); 
	type array32B is array(integer range <>) of unsigned(31 downto 0); 
	
	type varSizeArray is array (integer range <>, integer range <>) of std_logic;
end package;