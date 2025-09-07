-- Módulo: test de autovalidación de state_ctrlr
-- Autor: Alejandro Martínez Salgado
-- Fecha de creación: 27.08.2025

-----------------------------------------------------------
-- Librerías
-----------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

library work;
use work.my_pkg.all;

-----------------------------------------------------------
-- Entidad
-----------------------------------------------------------
entity state_ctrlr_autotest_tb is
    generic (
        -- Ficheros .txt
        C_N_INPUTS          : integer := 12; -- Número de entradas (columnas)
        C_N_OUTPUTS         : integer := 5; -- Número de salidas (columnas)
        C_WIDTH             : integer := 8; -- Número de bits de las señales
        C_INPUTS_PATH       : string := "\\AMS_NAS\home\Universidad\TFM\pwm_enjoyer\tb\autotest\state_ctrlr_inputs.txt";
        C_OUTPUTS_REF_PATH  : string := "\\AMS_NAS\home\Universidad\TFM\pwm_enjoyer\tb\autotest\state_ctrlr_outputs_ref.txt";
        C_OUTPUTS_PATH      : string := "\\AMS_NAS\home\Universidad\TFM\pwm_enjoyer\tb\autotest\state_ctrlr_outputs.txt";
        -- C_INPUTS_PATH       : string := "C:\Users\ajmsalgado\SynologyDrive\Universidad\TFM\pwm_enjoyer\tb\autotest\pwm_dp_mem_inputs.txt";
        -- C_OUTPUTS_REF_PATH  : string := "C:\Users\ajmsalgado\SynologyDrive\Universidad\TFM\pwm_enjoyer\tb\autotest\pwm_dp_mem_outputs_ref.txt";
        -- C_OUTPUTS_PATH      : string := "C:\Users\ajmsalgado\SynologyDrive\Universidad\TFM\pwm_enjoyer\tb\autotest\pwm_dp_mem_outputs.txt";
        -- Genéricos del componente
        C_DATA_W    : integer   := G_STATE_MAX_L2;
        C_ADDR_W    : integer   := G_MEM_SIZE_MAX_L2;
        C_MAX_PUL_W : integer   := G_PERIOD_MAX_L2;
        C_MEM_DEPTH : integer   := G_MEM_SIZE_MAX_N;
        C_MEM_MODE  : string    := "LOW_LATENCY";
        C_RST_POL   : std_logic := G_RST_POL
    );
end entity state_ctrlr_autotest_tb;

-----------------------------------------------------------
-- Arquitectura
-----------------------------------------------------------
architecture beh of state_ctrlr_autotest_tb is

    -------------------------------------------------
    -- Componentes
    -------------------------------------------------
    component state_ctrlr is
        generic (
            G_RST_POL   : std_logic := '1'
        );
        port (
            CLK_I           : in std_logic;
            RST_I           : in std_logic;                                             -- Reset asíncrono
            EN_I            : in std_logic;                                             -- Señal de habilitación
            N_ADDR_I        : in std_logic_vector((G_MEM_SIZE_MAX_L2 - 1) downto 0);    -- Número de estados del PWM
            N_TOT_CYC_I     : in std_logic_vector((G_PERIOD_MAX_L2 - 1) downto 0);      -- Número total de ciclos que dura la configuración
            UPD_MEM_I       : in std_logic;                                             -- Señal de actualización de memoria
            CNT_END_I       : in std_logic;                                             -- Fin de estado
            NEXT_CONFIG_I   : in mem;                                                   -- Siguiente configuración
            RD_ADDR_O       : out std_logic_vector((G_MEM_SIZE_MAX_L2 - 1) downto 0);   -- Dirección de memoria (estado) a leer
            EN_CNT_O        : out std_logic;                                            -- Habiltador del contador
            SWITCH_MEM_O    : out std_logic;                                            -- Cambio de memoria
            LAST_CYC_O      : out std_logic;                                            -- Inidicador de último ciclo
            EN_WR_CONFIG_O  : out std_logic                                             -- Bloqueo de escritura de configuración
        );
    end component state_ctrlr;

    -------------------------------------------------
    -- Señales
    -------------------------------------------------
    -- Simulación
    constant clk_period : time := 20 ns;

    -- Port map
    signal CLK_I           : std_logic;
    signal RST_I           : std_logic;                                             -- Reset asíncrono
    signal EN_I            : std_logic;                                             -- Señal de habilitación
    signal N_ADDR_I        : std_logic_vector((G_MEM_SIZE_MAX_L2 - 1) downto 0);    -- Número de estados del PWM
    signal N_TOT_CYC_I     : std_logic_vector((G_PERIOD_MAX_L2 - 1) downto 0);      -- Número total de ciclos que dura la configuración
    signal UPD_MEM_I       : std_logic;                                             -- Señal de actualización de memoria
    signal CNT_END_I       : std_logic;                                             -- Fin de estado
    signal NEXT_CONFIG_I   : mem  := (others => (others => '0'));                   -- Siguiente configuración
    signal RD_ADDR_O       : std_logic_vector((G_MEM_SIZE_MAX_L2 - 1) downto 0);    -- Dirección de memoria (estado) a leer
    signal EN_CNT_O        : std_logic;                                             -- Habiltador del contador
    signal SWITCH_MEM_O    : std_logic;                                             -- Cambio de memoria
    signal LAST_CYC_O      : std_logic;                                             -- Inidicador de último ciclo
    signal EN_WR_CONFIG_O  : std_logic; 

    -- Vectores de datos
    type vec_input is array (0 to (C_N_INPUTS - 1)) of bit_vector((C_WIDTH - 1) downto 0);
    type vec_output is array (0 to (C_N_OUTPUTS - 1)) of bit_vector((C_WIDTH - 1) downto 0);

    -------------------------------------------------
    -- Funciones y procedimientos
    -------------------------------------------------
    -- n/a

begin

    -------------------------------------------------
    -- Instancias
    -------------------------------------------------
    uut : component state_ctrlr
        generic map (
            G_RST_POL   => G_RST_POL
        )
        port map (
            CLK_I           => CLK_I,
            RST_I           => RST_I,
            EN_I            => EN_I,
            N_ADDR_I        => N_ADDR_I,
            N_TOT_CYC_I     => N_TOT_CYC_I,
            UPD_MEM_I       => UPD_MEM_I,
            CNT_END_I       => CNT_END_I,
            NEXT_CONFIG_I   => NEXT_CONFIG_I,
            RD_ADDR_O       => RD_ADDR_O,
            EN_CNT_O        => EN_CNT_O,
            SWITCH_MEM_O    => SWITCH_MEM_O,
            LAST_CYC_O      => LAST_CYC_O,
            EN_WR_CONFIG_O  => EN_WR_CONFIG_O
        );

    -------------------------------------------------
    -- Procesos
    -------------------------------------------------
    -- Reloj
    P_CLK : process
    begin
        CLK_I <= '1';
        wait for clk_period/2;
        CLK_I <= '0';
        wait for clk_period/2;
    end process;

    -- Reset
    P_RST : process
    begin
        RST_I <= G_RST_POL;
        wait for clk_period;
        RST_I <= not G_RST_POL;
        wait;
    end process;

    -------------------------------------------------
    -- Estímulos
    -------------------------------------------------
    -- Lectura de los datos de entrada
    P_INPUT : process
        file read_file      : text;         -- Archivo de lectura
        variable line_in    : line;         -- Línea de lectura
        variable data_in    : vec_input;    -- Dato extraído
    begin

        file_open(read_file, C_INPUTS_PATH, read_mode); -- Abre el archivo de lectura
        while not endfile(read_file) loop
            -- wait until rising_edge(CLK_I);
            wait until CLK_I'event and (CLK_I = '1');
            readline(read_file, line_in);               -- Lee fila a fila
            for i in 0 to (C_N_INPUTS - 1) loop
                read(line_in, data_in(i));              -- Lee dato a dato, separados por espacios
            end loop;
            -- User TODO: Asignación de entradas
            EN_I                <= to_stdlogicvector(data_in(0))(0);
            N_ADDR_I            <= to_stdlogicvector(data_in(1))((C_ADDR_W - 1 ) downto 0);
            N_TOT_CYC_I         <= to_stdlogicvector(data_in(2))((C_MAX_PUL_W - 1 ) downto 0);
            UPD_MEM_I           <= to_stdlogicvector(data_in(3))(0);
            CNT_END_I           <= to_stdlogicvector(data_in(4))(0);
            NEXT_CONFIG_I(0)    <= to_stdlogicvector(data_in(5))((C_DATA_W - 1 ) downto 0);
            NEXT_CONFIG_I(1)    <= to_stdlogicvector(data_in(6))((C_DATA_W - 1 ) downto 0);
            NEXT_CONFIG_I(2)    <= to_stdlogicvector(data_in(7))((C_DATA_W - 1 ) downto 0);
            NEXT_CONFIG_I(3)    <= to_stdlogicvector(data_in(8))((C_DATA_W - 1 ) downto 0);
            NEXT_CONFIG_I(4)    <= to_stdlogicvector(data_in(9))((C_DATA_W - 1 ) downto 0);
            NEXT_CONFIG_I(5)    <= to_stdlogicvector(data_in(10))((C_DATA_W - 1 ) downto 0);
            NEXT_CONFIG_I(6)    <= to_stdlogicvector(data_in(11))((C_DATA_W - 1 ) downto 0);
            ---------------------------------------
        end loop;
        -- wait until rising_edge(CLK_I);
        wait until CLK_I'event and (CLK_I = '1');
        file_close(read_file);

        assert FALSE report "End inputs reading" severity note;
        wait;

    end process;

    -- Lectura y comparación de las salidas con el modelo
    --  y escritura con los valores de salida obtenidos
    P_COMPARE : process
        file read_file      : text;         -- Archivo de lectura
        variable line_in    : line;         -- Línea de lectura
        variable data_in    : vec_output;   -- Dato extraído
        variable index      : integer := 1; -- Indicador de línea
        file write_file     : text;         -- Archivo de escritura
        variable line_out   : line;         -- Línea de lectura
        variable data_out   : vec_output;   -- Dato escrito
    begin

        file_open(read_file, C_OUTPUTS_REF_PATH, read_mode);    -- Abre el archivo de lectura
        file_open(write_file, C_OUTPUTS_PATH, write_mode);      -- Abre el archivo de escritura
        while not endfile(read_file) loop
            wait until rising_edge(CLK_I);
            readline(read_file, line_in);                       -- Lee fila a fila
            index := index + 1;
            -- User TODO: Asignación de salidas
            data_out(0)((RD_ADDR_O'length - 1) downto 0) := to_bitvector(RD_ADDR_O);
            data_out(1)(0) := to_bit(EN_CNT_O);
            data_out(2)(0) := to_bit(SWITCH_MEM_O);
            data_out(3)(0) := to_bit(LAST_CYC_O);
            data_out(4)(0) := to_bit(EN_WR_CONFIG_O);
            ----------------------------------------
            for i in 0 to (C_N_OUTPUTS - 1) loop
                read(line_in, data_in(i));                          -- Lee dato a dato, separados por espacios
                write(line_out, data_out(i), right, (C_WIDTH + 1)); -- Escribe dato a dato, separados por espacios
            end loop;
            writeline(write_file, line_out);                        -- Escribe fila a fila
            -- User TODO: Comparación de salidas
            assert data_out(0) = data_in(0)
                report ":( Wrong ADDR output. Obtained: " & integer'image(to_integer(unsigned(to_stdlogicvector(data_out(0))))) &
                    " Expected: " & integer'image(to_integer(unsigned(to_stdlogicvector(data_in(0))))) & " at step: " & integer'image(index)
                severity failure;
            assert data_out(1) = data_in(1)
                report ":( Wrong EN_CNT output. Obtained: " & integer'image(to_integer(unsigned(to_stdlogicvector(data_out(1))))) &
                    " Expected: " & integer'image(to_integer(unsigned(to_stdlogicvector(data_in(1))))) & " at step: " & integer'image(index)
                severity failure;
            assert data_out(2) = data_in(2)
                report ":( Wrong SWITCH_MEM output. Obtained: " & integer'image(to_integer(unsigned(to_stdlogicvector(data_out(1))))) &
                    " Expected: " & integer'image(to_integer(unsigned(to_stdlogicvector(data_in(1))))) & " at step: " & integer'image(index)
                severity failure;
            assert data_out(3) = data_in(3)
                report ":( Wrong LAST_CYC output. Obtained: " & integer'image(to_integer(unsigned(to_stdlogicvector(data_out(1))))) &
                    " Expected: " & integer'image(to_integer(unsigned(to_stdlogicvector(data_in(1))))) & " at step: " & integer'image(index)
                severity failure;
            assert data_out(4) = data_in(4)
                report ":( Wrong EN_WR_CONFIG output. Obtained: " & integer'image(to_integer(unsigned(to_stdlogicvector(data_out(1))))) &
                    " Expected: " & integer'image(to_integer(unsigned(to_stdlogicvector(data_in(1))))) & " at step: " & integer'image(index)
                severity failure;
            ---------------------------------------
        end loop;
        wait until rising_edge(CLK_I);
        file_close(read_file);
        file_close(write_file);

        assert FALSE report "\_(^^ )_/ Simulation successfull! \_(^^ )_/" severity failure;

    end process;

end architecture beh;