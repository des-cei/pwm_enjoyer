-- Módulo: state_ctrlr test bench
-- Autor: Alejandro Martínez Salgado
-- Fecha de creación: 23.06.2025

-----------------------------------------------------------
-- Librerías
-----------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.my_pkg.all;

-----------------------------------------------------------
-- Entidad
-----------------------------------------------------------
entity state_ctrlr_tb is
end entity state_ctrlr_tb;

-----------------------------------------------------------
-- Arquitectura
-----------------------------------------------------------
architecture beh of state_ctrlr_tb is

    -------------------------------------------------
    -- Componentes
    -------------------------------------------------
    component state_ctrlr is
        generic (
            G_RST_POL   : std_logic := '1'
        );
        port (
            CLK_I       : in std_logic;
            RST_I       : in std_logic;                                             -- Reset asíncrono
            EN_I        : in std_logic;                                             -- Señal de habilitación
            N_ADDR_I    : in std_logic_vector((G_MEM_SIZE_MAX_L2 - 1) downto 0);    -- Número de estados del PWM
            CYC_SYNC_I  : in std_logic;                                             -- Señal de sincronismo de todos los PWM
            CNT_END_I   : in std_logic;                                             -- Fin de estado  
            RD_ADDR_O   : out std_logic_vector((G_MEM_SIZE_MAX_L2 - 1) downto 0)    -- Dirección de memoria (estado) a ejecutar
        );
    end component state_ctrlr;

    -------------------------------------------------
    -- Señales
    -------------------------------------------------
    -- Simulación
    constant clk_period : time := (10**9/G_SYS_CLK_HZ) * 1 ns;
    signal sim          : std_logic_vector(47 downto 0) := (others => '0'); -- 6 caracteres ASCII

    -- Port map
    signal CLK_I       : std_logic;
    signal RST_I       : std_logic;                                        
    signal EN_I        : std_logic;                                         
    signal N_ADDR_I    : std_logic_vector((G_MEM_SIZE_MAX_L2 - 1) downto 0);
    signal CYC_SYNC_I  : std_logic;                                         
    signal CNT_END_I   : std_logic;                                         
    signal RD_ADDR_O   : std_logic_vector((G_MEM_SIZE_MAX_L2 - 1) downto 0);

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
        signal en       : out std_logic;
        signal n_addr   : out std_logic_vector;
        signal c_sync   : out std_logic;
        signal cnt_end  : out std_logic
    ) is
    begin
        rst     <= '1';
        en      <= '0';
        n_addr  <= (others => '0');
        c_sync  <= '0';
        cnt_end <= '0';
        p_wait(clk_period);
        rst     <= '0';
    end procedure reset;

    -- Contador de estado
    procedure cnt_est (
        variable duracion   : in integer;
        signal cnt_end      : out std_logic
    ) is begin
        if (duracion = 1) then
            cnt_end <= '1';
        else
            p_wait((duracion - 1) * clk_period);
            cnt_end <= '1';
        end if;
        p_wait(clk_period);
        cnt_end <= '0';
    end procedure cnt_est;

begin

    -------------------------------------------------
    -- Instancias
    -------------------------------------------------
    uut : component state_ctrlr
        generic map (
            G_RST_POL   => G_RST_POL
        )
        port map (
            CLK_I       => CLK_I,
            RST_I       => RST_I,
            EN_I        => EN_I,
            N_ADDR_I    => N_ADDR_I,
            CYC_SYNC_I  => CYC_SYNC_I,
            CNT_END_I   => CNT_END_I,
            RD_ADDR_O   => RD_ADDR_O
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

    -------------------------------------------------
    -- Estímulos
    -------------------------------------------------
    P_STIM : process

        variable v_estado     : integer range 0 to G_MEM_SIZE_MAX_N := 0;
        variable v_duracion   : integer range 0 to G_STATE_MAX_N    := 0;

    begin

        assert FALSE report "Start simulation" severity note;

        ------------------------------
        -- Init
        ------------------------------
        sim <= x"49_4E_49_54_20_20";
        reset(RST_I, EN_I, N_ADDR_I, CYC_SYNC_I, CNT_END_I);
        p_wait(10*clk_period);

        ------------------------------
        -- Test 1
        --  4 estados: 4-5-2-3
        --  Ciclo y medio
        ------------------------------
        sim         <= x"54_45_53_54_20_31";
        N_ADDR_I    <= std_logic_vector(to_unsigned(4, N_ADDR_I'length));
        EN_I        <= '1';

        -- 1.1
        v_estado    := 1;
        v_duracion  := 4;
        cnt_est(v_duracion, CNT_END_I);

        -- 1.2
        v_estado    := 2;
        v_duracion  := 5;
        cnt_est(v_duracion, CNT_END_I);

        -- 1.3
        v_estado    := 3;
        v_duracion  := 2;
        cnt_est(v_duracion, CNT_END_I);

        -- 1.4
        v_estado    := 4;
        v_duracion  := 3;
        cnt_est(v_duracion, CNT_END_I);

        -- 2.1
        v_estado    := 1;
        v_duracion  := 4;
        cnt_est(v_duracion, CNT_END_I);

        -- 2.2
        v_estado    := 2;
        v_duracion  := 5;
        cnt_est(v_duracion, CNT_END_I);

        -- Desactiva
        EN_I <= '0';

        -- 2.3
        v_estado    := 3;
        v_duracion  := 2;
        cnt_est(v_duracion, CNT_END_I);

        -- 2.4
        v_estado    := 4;
        v_duracion  := 3;
        cnt_est(v_duracion, CNT_END_I);

        ------------------------------
        -- Test 2
        --  3 estados: 7-1-3
        --  1 ciclo y medio y entra SYNC
        ------------------------------
        sim         <= x"54_45_53_54_20_32";
        N_ADDR_I    <= std_logic_vector(to_unsigned(3, N_ADDR_I'length));
        EN_I        <= '1';

        -- 1.1
        v_estado    := 1;
        v_duracion  := 7;
        cnt_est(v_duracion, CNT_END_I);

        -- 1.2
        v_estado    := 2;
        v_duracion  := 1;
        cnt_est(v_duracion, CNT_END_I);

        -- 1.3
        v_estado    := 3;
        v_duracion  := 3;
        cnt_est(v_duracion, CNT_END_I);

        -- 2.1
        v_estado    := 1;
        v_duracion  := 7;
        cnt_est(v_duracion, CNT_END_I);

        -- 2.2
        v_estado    := 2;
        v_duracion  := 1;
        cnt_est(v_duracion, CNT_END_I);

        -- Actualiza memoria: 2-3-2
        CYC_SYNC_I <= '1';
        p_wait(clk_period);
        CYC_SYNC_I <= '0';

        -- 3.1
        v_estado    := 1;
        v_duracion  := 2;
        cnt_est(v_duracion, CNT_END_I);

        -- 3.2
        v_estado    := 2;
        v_duracion  := 3;
        cnt_est(v_duracion, CNT_END_I);

        -- 3.3
        v_estado    := 3;
        v_duracion  := 2;
        cnt_est(v_duracion, CNT_END_I);

        ------------------------------
        -- Reset
        --  4 estados: 4-5-2-3
        ------------------------------
        sim         <= x"52_45_53_45_54_20";
        N_ADDR_I    <= std_logic_vector(to_unsigned(4, N_ADDR_I'length));
        EN_I        <= '1';

        -- 1.1
        v_estado    := 1;
        v_duracion  := 4;
        cnt_est(v_duracion, CNT_END_I);

        -- 1.2
        v_estado    := 2;
        v_duracion  := 5;
        cnt_est(v_duracion, CNT_END_I);

        -- Reset
        reset(RST_I, EN_I, N_ADDR_I, CYC_SYNC_I, CNT_END_I);
        p_wait(10*clk_period);

        ------------------------------
        -- End
        ------------------------------
        sim <= x"45_4E_44_49_4E_47";
        p_wait(10*clk_period);

        assert FALSE report "End simulation" severity failure;

    end process;

end architecture beh;