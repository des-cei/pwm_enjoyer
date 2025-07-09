-- Módulo: pwm_dp_mem test bench
-- Autor: Alejandro Martínez Salgado
-- Fecha de creación: 07.07.2025

-----------------------------------------------------------
-- Librerías
-----------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library work;
use work.my_pkg.all;

-----------------------------------------------------------
-- Entidad
-----------------------------------------------------------
entity pwm_dp_mem_tb is
end entity pwm_dp_mem_tb;

-----------------------------------------------------------
-- Arquitectura
-----------------------------------------------------------
architecture beh of pwm_dp_mem_tb is

    -------------------------------------------------
    -- Componentes
    -------------------------------------------------
    component pwm_dp_mem is
        generic (
            G_DATA_W    : integer   := 32;    -- Ancho de datos en bits (G_STATE_MAX_L2)
            G_ADDR_W    : integer   := 32;    -- Ancho de direcciones en bits (G_MEM_SIZE_MAX_L2)
            G_MEM_DEPTH : integer   := 4096;  -- Profundidad de memoria (G_MEM_SIZE_MAX_N)
            G_MEM_MODE  : string    := "LOW_LATENCY";   -- Modo de funcionamiento de la memoria ("HIGH_PERFORMANCE"/"LOW_LATENCY")
            G_RST_POL   : std_logic := '1'
        );
        port (
            CLK_I       : in std_logic;     
            RST_I       : in std_logic;
            WR_EN_I     : in std_logic;                                 -- Enable de escritura
            WR_ADDR_I   : in std_logic_vector((G_ADDR_W - 1) downto 0); -- Dirección de escritura
            WR_DATA_I   : in std_logic_vector((G_DATA_W - 1) downto 0); -- Dato de escritura
            CYC_SYNC_I  : in std_logic;                                 -- Señal de actualización de memoria
            RD_ADDR_I   : in std_logic_vector((G_ADDR_W - 1) downto 0); -- Dirección de lectura
            RD_DATA_O   : out std_logic_vector((G_DATA_W - 1) downto 0) -- Dato de lectura
        );
    end component pwm_dp_mem;

    -------------------------------------------------
    -- Señales
    -------------------------------------------------
    -- Simulación
    constant clk_period : time := (10**9/G_SYS_CLK_HZ) * 1 ns;
    signal sim          : std_logic_vector(47 downto 0) := (others => '0'); -- 6 caracteres ASCII

    -- Port map
    signal CLK_I        : std_logic;     
    signal RST_I        : std_logic;
    signal WR_EN_I      : std_logic;                                
    signal WR_ADDR_I    : std_logic_vector((G_MEM_SIZE_MAX_L2 - 1) downto 0);
    signal WR_DATA_I    : std_logic_vector((G_STATE_MAX_L2 - 1) downto 0);
    signal CYC_SYNC_I   : std_logic;                                
    signal RD_ADDR_I    : std_logic_vector((G_MEM_SIZE_MAX_L2 - 1) downto 0) := (others => '0');
    signal RD_DATA_O    : std_logic_vector((G_STATE_MAX_L2 - 1) downto 0);

    -- Soporte
    type memory is array (0 to (G_MEM_SIZE_MAX_N - 1)) of integer;
    signal mem          : memory := (others => 0);
    signal s_n_est      : integer range 0 to (G_MEM_SIZE_MAX_N - 1) := 0;
    signal s_wait_cnt   : integer range 0 to G_STATE_MAX_N;

    -------------------------------------------------
    -- Funciones y procedimientos
    -------------------------------------------------
    -- Wait
    procedure p_wait (
        constant period : in time
    ) is
    begin
        wait for 0.99*period;
        wait until rising_edge(CLK_I);
    end procedure p_wait;

    -- Reset
    procedure reset (
        signal rst      : out std_logic;
        signal wr_en    : out std_logic;
        signal wr_addr  : out std_logic_vector;
        signal wr_data  : out std_logic_vector;
        signal cyc_sync : out std_logic
    ) is
    begin
        rst         <= '1';
        wr_en       <= '0';
        wr_addr     <= (others => '0');
        wr_data     <= (others => '0');
        cyc_sync    <= '0';
        p_wait(clk_period);
        rst         <= '0';
    end procedure reset;

begin

    -------------------------------------------------
    -- Instancias
    -------------------------------------------------
    uut : component pwm_dp_mem
        generic map (
            G_DATA_W    => G_STATE_MAX_L2,
            G_ADDR_W    => G_MEM_SIZE_MAX_L2,
            G_MEM_DEPTH => G_MEM_SIZE_MAX_N,
            G_MEM_MODE  => "LOW_LATENCY",
            G_RST_POL   => G_RST_POL
        )
        port map (
            CLK_I       => CLK_I,
            RST_I       => RST_I,
            WR_EN_I     => WR_EN_I,
            WR_ADDR_I   => WR_ADDR_I,
            WR_DATA_I   => WR_DATA_I,
            CYC_SYNC_I  => CYC_SYNC_I,
            RD_ADDR_I   => RD_ADDR_I,
            RD_DATA_O   => RD_DATA_O 
        );

    -------------------------------------------------
    -- Procesos
    -------------------------------------------------
    -- Reloj
    P_CLK : process
    begin
        CLK_I <= '0';
        wait for clk_period/2;
        CLK_I <= '1';
        wait for clk_period/2;
    end process;

    -- Contador de estados
    P_CNT : process (CLK_I, RST_I, CYC_SYNC_I)
    begin
        if (RST_I = G_RST_POL) then
            RD_ADDR_I <= (others => '0');
            s_wait_cnt <= 0;
        elsif rising_edge(CLK_I) then

            if (CYC_SYNC_I = '1') then
            -- if rising_edge(CYC_SYNC_I) then
                RD_ADDR_I <= (others => '0');
                s_wait_cnt <= 0;
            -- end if;
            elsif (s_wait_cnt < (mem(to_integer(unsigned(RD_ADDR_I))) - 1)) then
            -- elsif (s_wait_cnt < (to_integer(unsigned(RD_DATA_O)) - 1)) then
                s_wait_cnt <= s_wait_cnt + 1;
            elsif (unsigned(RD_ADDR_I) < to_unsigned((s_n_est - 1), RD_ADDR_I'length)) then
                s_wait_cnt <= 0;
                RD_ADDR_I <= std_logic_vector(unsigned(RD_ADDR_I) + 1);
            else
                s_wait_cnt <= 0;
                RD_ADDR_I <= (others => '0');
            end if;


        end if; 
    end process;

    -------------------------------------------------
    -- Estímulos
    -------------------------------------------------
    P_STIM : process
    begin

        assert FALSE report "Start simulation" severity note;

        ------------------------------
        -- Init
        ------------------------------
        sim <= x"49_4E_49_54_20_20";
        reset(RST_I, WR_EN_I, WR_ADDR_I, WR_DATA_I, CYC_SYNC_I);
        p_wait(10*clk_period);

        ------------------------------
        -- WRITE 1
        --  6 estados, WR en A
        ------------------------------
        sim <= x"57_52_20_31_20_20";
        s_n_est <= 6;
        p_wait(clk_period);

        for i in 0 to (s_n_est - 1) loop
            WR_EN_I     <= '1';
            WR_ADDR_I   <= std_logic_vector(to_unsigned(i, WR_ADDR_I'length));
            WR_DATA_I   <= std_logic_vector(to_unsigned((2*(i+1)), WR_DATA_I'length));
            mem(i)      <= (2*(i+1));
            p_wait(clk_period);
        end loop;

        WR_EN_I     <= '0';
        p_wait(clk_period);

        ------------------------------
        -- READ 1
        --  6 estados, RD de A
        ------------------------------
        sim <= x"52_44_20_31_20_20";
        
        CYC_SYNC_I  <= '1';
        p_wait(clk_period);
        CYC_SYNC_I  <= '0';
        
        p_wait(150*clk_period);

        ------------------------------
        -- WRITE 2
        --  4 estados, WR en B
        ------------------------------
        sim <= x"57_52_20_32_20_20";
        s_n_est <= 4;
        p_wait(clk_period);

        for i in 0 to (s_n_est - 1) loop
            WR_EN_I     <= '1';
            WR_ADDR_I   <= std_logic_vector(to_unsigned(i, WR_ADDR_I'length));
            WR_DATA_I   <= std_logic_vector(to_unsigned((10 - 3*i), WR_DATA_I'length));
            mem(i)      <= (10 - 3*i);
            p_wait(clk_period);
        end loop;

        WR_EN_I     <= '0';
        p_wait(clk_period);

        ------------------------------
        -- READ 2
        --  4 estados, RD de B
        ------------------------------
        sim <= x"52_44_20_32_20_20";
        
        CYC_SYNC_I  <= '1';
        p_wait(clk_period);
        CYC_SYNC_I  <= '0';
        
        p_wait(150*clk_period);

        ------------------------------
        -- WRITE 3
        --  8 estados, WR en A
        ------------------------------
        sim <= x"57_52_20_33_20_20";
        s_n_est <= 8;
        p_wait(clk_period);

        for i in 0 to (s_n_est - 1) loop
            WR_EN_I     <= '1';
            WR_ADDR_I   <= std_logic_vector(to_unsigned(i, WR_ADDR_I'length));
            WR_DATA_I   <= std_logic_vector(to_unsigned((i mod 3), WR_DATA_I'length));
            mem(i)      <= (i mod 3);
            p_wait(clk_period);
        end loop;

        WR_EN_I     <= '0';
        p_wait(clk_period);

        ------------------------------
        -- READ 3
        --  8 estados, RD de A
        ------------------------------
        sim <= x"52_44_20_33_20_20";
        
        CYC_SYNC_I  <= '1';
        p_wait(clk_period);
        CYC_SYNC_I  <= '0';
        
        p_wait(150*clk_period);

        ------------------------------
        -- RESET
        ------------------------------
        sim <= x"52_45_53_45_54_20";
        
        RST_I <= '1';
        p_wait(clk_period);
        RST_I <= '0';
        
        p_wait(10*clk_period);
               
        ------------------------------
        -- End
        ------------------------------
        sim <= x"45_4E_44_49_4E_47";
        p_wait(10*clk_period);

        assert FALSE report "End simulation" severity failure;

    end process;

end architecture beh;