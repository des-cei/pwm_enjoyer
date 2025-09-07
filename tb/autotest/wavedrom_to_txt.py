# Alejandro Martínez Salgado
# Fecha creación: 29.08.2025
# Fecha última modificación: 29.08.2025

# Este módulo toma como entrada un fichero .jason y exporta los datos a un fichero .txt.
# El objetivo es generar en última instancia un autotest de vhdl.

import json
import sys
import re
from pprint import pprint as pp


def pseudojson_a_json (texto: str) -> str:
    """
    Convierte un pseudo-JSON estilo JS a JSON válido.
    - Añade comillas dobles a las claves sin comillas.
    - Cambia comillas simples por comillas dobles.
    - Elimina comas sobrantes antes de ']' o '}'.
    """
    # Añadir comillas a claves no citadas {signal: -> {"signal":
    texto = re.sub(r'([{,]\s*)([A-Za-z0-9_]+)\s*:', r'\1"\2":', texto)

    # Sustituir comillas simples por comillas dobles
    texto = texto.replace("'", '"')

    # Quitar comas sobrantes antes de ']' o '}'
    texto = re.sub(r',(\s*[}\]])', r'\1', texto)

    return texto.strip()


def procesar_json (ruta_json):
    with open(ruta_json, "r", encoding="utf-8") as f:
        raw = f.read()

    # Arreglar pseudojson
    raw = pseudojson_a_json(raw)

    # Parsear a JSON válido
    try:
        data = json.loads(raw)
    except json.JSONDecodeError as e:
        print("Error al parsear JSON corregido.")
        print("Texto corregido era:\n", raw)
        raise e

    # Obtener datos
    resultado = []
    for fila in data.get("signal", []):
        dic = {
            "nombre": fila.get("name", ""),
            "datos": fila.get("wave", ""),
            "info": fila.get("data", [])
        }
        resultado.append(dic)
    return resultado


def tabular_datos (signal):
    """Convierte las señales en forma de diccionario a tablas de datos"""
    datos = {"nombre": "", "datos": []}
    datos_wd = []
    datos_n = []
    datos_slv = []

    # Cabecera
    datos["nombre"] = signal["nombre"]

    # Datos en formato Wavedrom
    for valor in signal["datos"]:
        datos_wd.append(valor)
    # print(datos_wd)

    # Sustitución del campo "info" (data) en "datos" (wave)
    sust = {
        "1": "1", "0": "0",
        "p": "1", "P": "1",
        "n": "0", "N": "0",
        "h": "1", "H": "1",
        "l": "0", "L": "0",
        "x": "U", "X": "U"
        }
    j = 0
    for valor in datos_wd:
        if valor in sust:
            last = sust[valor]
        elif (valor == "."):
            last = last
        elif (valor == "|"):
            datos_n.append("REPEAT")
            continue
        elif signal["info"]:
            last = signal["info"][j]
            j += 1
        datos_n.append(last)
    # print(datos_n)

    # Convertir los datos a binario
    # NOTE (*) Tener en cuenta que el autotest.vhd solo reconoce bit, es decir, 1 o 0
    for valor in datos_n:
        if valor == "U":
            if formato == "08b":
                # datos_slv.append("UUUUUUUU") (*)
                datos_slv.append("00000000")
            else:
                raise ValueError("Formato desconocido")
        elif valor == "REPEAT":
            datos_slv.append("UUUUUUUU")
        elif valor.isdigit():
            datos_slv.append(format(int(valor), formato))
        else:
            datos_slv.append("XXXXXXXX")
    # print(datos_slv)

    # Lista completa
    datos["datos"] = datos_slv
    # print(datos)
    # print("-------------")

    return datos


def exportar_txt (tabla_ordenada, fichero):
    """Extrae, traspone y exporta los datos de cada señal"""
    with open(fichero, "w", encoding="utf-8") as f:
        # Extraer solo los "datos" de cada señal
        datos = [item["datos"] for item in tabla_ordenada]
    
        # Trasponer filas -> columnas
        for fila in zip(*datos):
            f.write(" ".join(fila) + "\n")

    print(f"{fichero} creado correctamente.")


def concatenar_txt(archivo1, archivo2, archivo_salida):
    with open(archivo1, "r", encoding="utf-8") as f1, \
         open(archivo2, "r", encoding="utf-8") as f2, \
         open(archivo_salida, "w", encoding="utf-8") as salida:
        
        # Escribir contenido del primer archivo
        salida.write(f1.read())
        # Escribir contenido del segundo archivo
        salida.write(f2.read())

    print(f"{archivo_salida} creado correctamente.")


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Uso: python wavedrom_to_txt.py archivo.json")
        sys.exit(1)

    # Se obtienen los datos crudos del pseudo .json
    ruta = sys.argv[1]
    signals = procesar_json(ruta)

    # for i in signals:
    #     print(i)

    # Se convierte al formato de tabla requerido
    tabla = []
    formato = "08b"   # Formato del dato de salida. "08b" = 8 bits
    for signal in signals:
        tabla.append(tabular_datos(signal))
        # print(tabular_datos(signal)["nombre"])
    # pp(tabla)

    # TODO A partir de aquí todo podría mejorar con una interfaz gráfica

    # Se clasifican las señales por orden deseado de aparición y se clasifican entre I/O o descartes
    orden = [
        {"nombre": "CLK",		    "tipo": "NO",   "orden": 0},
        {"nombre": "EN",		    "tipo": "I",    "orden": 1},
        {"nombre": "NEXT_CONFIG_0",	"tipo": "I",    "orden": 6},
        {"nombre": "NEXT_CONFIG_1",	"tipo": "I",    "orden": 7},
        {"nombre": "NEXT_CONFIG_2",	"tipo": "I",    "orden": 8},
        {"nombre": "NEXT_CONFIG_3",	"tipo": "I",    "orden": 9},
        {"nombre": "NEXT_CONFIG_4",	"tipo": "I",    "orden": 10},
        {"nombre": "NEXT_CONFIG_5",	"tipo": "I",    "orden": 11},
        {"nombre": "NEXT_CONFIG_6",	"tipo": "I",    "orden": 12},
        {"nombre": "N_ADDR",	    "tipo": "I",    "orden": 2},
        {"nombre": "N_TOT_CYC",		"tipo": "I",    "orden": 3},
        {"nombre": "UPD_MEM",	    "tipo": "I",    "orden": 4},
        {"nombre": "RD_ADDR",       "tipo": "O",    "orden": 1},
        {"nombre": "RD_DATA",		"tipo": "NO",   "orden": 0},
        {"nombre": "CNT_END",	    "tipo": "I",    "orden": 5},
        {"nombre": "LAST_CYC",      "tipo": "O",    "orden": 4},
        {"nombre": "SWITCH_MEM",    "tipo": "O",    "orden": 3},
        {"nombre": "EN_CNT",		"tipo": "O",    "orden": 2},
        {"nombre": "STATE",	        "tipo": "NO",   "orden": 0},
        {"nombre": "EN_WR_CONFIG",  "tipo": "O",    "orden": 5}
    ]

    # Añade los campos nuevos a los señales
    for signal in tabla:
        for clasif in orden:
            if clasif["nombre"] == signal["nombre"]:
                signal["tipo"] = clasif["tipo"]
                signal["orden"] = clasif["orden"]
    # pp(tabla)

    # Se separan las tablas de I/O
    tabla_in = [signal for signal in tabla if (signal["tipo"] == "I")]
    tabla_out = [signal for signal in tabla if (signal["tipo"] == "O")]
    # pp(tabla_in)
    # print("----------------------")
    # pp(tabla_out)

    # Se ordenan
    tabla_in_ordenada = sorted(tabla_in, key=lambda x: x["orden"])
    tabla_out_ordenada = sorted(tabla_out, key=lambda x: x["orden"])
    # pp(tabla_in_ordenada)
    # print("----------------------")
    # pp(tabla_out_ordenada)

    # concatenar = True
    concatenar = False

    if not concatenar:
        # Se exportan los dos ficheros
        exportar_txt(tabla_in_ordenada, ruta[:-5] + "_inputs.txt")
        exportar_txt(tabla_out_ordenada, ruta[:-5] + "_outputs_ref.txt")
    else:
        # Para simulaciones largas, concatenar dos archivos:
        concatenar_txt("pwm_dp_mem_1_inputs.txt", "pwm_dp_mem_2_inputs.txt", "pwm_dp_mem_inputs.txt")
        concatenar_txt("pwm_dp_mem_1_outputs_ref.txt", "pwm_dp_mem_2_outputs_ref.txt", "pwm_dp_mem_outputs_ref.txt")
