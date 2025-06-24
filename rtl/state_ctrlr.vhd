-- Módulo: state_ctrlr
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
entity state_ctrlr is
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
end entity state_ctrlr;

-----------------------------------------------------------
-- Arquitectura
-----------------------------------------------------------
architecture beh of state_ctrlr is

    -------------------------------------------------
    -- Componentes
    -------------------------------------------------
    -- n/a

    -------------------------------------------------
    -- Tipos
    -------------------------------------------------
    type FSM is (S_IDLE, S_NEXT);

    -------------------------------------------------
    -- Constantes
    -------------------------------------------------
    -- n/a

    -------------------------------------------------
    -- Señales
    -------------------------------------------------
    signal r_state      : FSM;
    signal r_cnt_state  : unsigned((G_MEM_SIZE_MAX_L2 - 1) downto 0);

begin

    -------------------------------------------------
    -- Instancias
    -------------------------------------------------
    -- n/a

    -------------------------------------------------
    -- Combinacionales
    -------------------------------------------------
    RD_ADDR_O <= std_logic_vector(r_cnt_state);

    -------------------------------------------------
    -- Procesos
    -------------------------------------------------
    -- FSM
    P_FSM : process (CLK_I, RST_I)
    begin
        if (RST_I = G_RST_POL) then
            r_state     <= S_IDLE;
            r_cnt_state <= (others => '0');
        elsif rising_edge(CLK_I) then

            -- Señal de sincronismo -> Apunta a la posición de memoria 0
            if (CYC_SYNC_I = '1') then
                r_state     <= S_IDLE;
                r_cnt_state <= (others => '0');

            else            
                case r_state is

                    when S_IDLE =>
                        if (EN_I = '1') then
                            r_state <= S_NEXT;
                        end if;
                    
                    when S_NEXT =>
                        -- Espera hasta acabar la cuenta
                        if (CNT_END_I = '1') then
                            if (r_cnt_state < (unsigned(N_ADDR_I) - 1)) then
                                r_cnt_state <= r_cnt_state + 1;
                            elsif (EN_I = '1') then
                                r_cnt_state <= (others => '0');
                            elsif (EN_I = '0') then
                                r_cnt_state <= (others => '0');
                                r_state     <= S_IDLE;
                            end if;
                        end if;

                    when others =>
                        r_state <= S_NEXT;

                end case;
            end if;
        end if;
    end process P_FSM;

end architecture beh;