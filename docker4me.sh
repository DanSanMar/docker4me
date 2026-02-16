#!/bin/bash

# --- 1. CONFIGURACIÓN DE ENTORNO Y COLORES ---
export TERM=xterm-256color
BLANCO="\e[1;37m"
AZUL="\e[1;36m"
AMARILLO="\e[1;33m"
ROJO="\e[1;31m"
VERDE="\e[1;32m"
RESET="\e[0m"

# --- NUEVO: DETECTOR DE TERMINAL ---
# Buscamos qué terminal tienes instalada para abrir las nuevas ventanas
detectar_terminal() {
    for term in xfce4-terminal gnome-terminal konsole xterm; do
        if command -v "$term" &>/dev/null; then
            echo "$term"
            return
        fi
    done
}
MY_TERM=$(detectar_terminal)

# --- 2. FUNCIONES DE UTILIDAD Y ESTÉTICA ---

# El "trap" captura Ctrl+C (SIGINT) para salir elegantemente
trap despedida SIGINT

function despedida() {
    echo -e "\n"
    echo -e "${AZUL}%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%${RESET}"
    echo -e "${AZUL}    ¡Gracias por usar Docker4me! Bye!    ${RESET}"
    echo -e "${AZUL}%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%${RESET}"
    exit 0
}

function check_command() {
    if ! command -v "$1" &> /dev/null; then
        echo -e "${ROJO}❌ Error: '$1' no está instalado.${RESET}"
        exit 1
    fi
}

function mostrar_logo() {
    clear
    echo -e "${AZUL}"
    echo "  ██████   ██████   ██████ ██  ██ ███████ ██████  ██  ██ ███    ███ ███████ "
    echo "  ██   ██ ██    ██ ██      ██ ██  ██      ██   ██ ██  ██ ████  ████ ██      "
    echo "  ██   ██ ██    ██ ██      █████  █████   ██████  ███████ ██ ████ ██ █████   "
    echo "  ██   ██ ██    ██ ██      ██  ██ ██      ██   ██     ██ ██  ██  ██ ██      "
    echo "  ██████   ██████   ██████ ██  ██ ███████ ██   ██     ██ ██      ██ ███████ "
    echo -e "${BLANCO}   Docker4me Versión 1.2 - Menú interactivo de selección para Docker${RESET}"
    echo -e "${AZUL}   -------------------------------------------------------------------------${RESET}"
    echo ""
}

# --- 3. FUNCIONES DE GESTIÓN DOCKER (LÓGICA) ---

# Opción 1: Crear un nuevo contenedor desde una imagen
function abrir_imagen() {
    echo -e "${AMARILLO}🔍 Listando imágenes disponibles...${RESET}"
    image=$(docker images --format "{{.Repository}}:{{.Tag}}" | grep -v "<none>" | fzf --height 40% --reverse --header "SELECCIONA IMAGEN PARA LANZAR EN NUEVA VENTANA:")
    
    if [[ -n "$image" ]]; then
        echo -e "${VERDE}🚀 Abriendo $image en ventana independiente...${RESET}"
        # Preparamos el comando con un 'read' al final para que la ventana no se cierre sola
        local cmd="docker run --rm -it $image /bin/bash || docker run --rm -it $image /bin/sh; echo -e '\n${AMARILLO}Presiona Enter para cerrar esta ventana...${RESET}'; read"
        # Lanzamos la terminal detectada en segundo plano
        $MY_TERM -- bash -c "$cmd" &
    else
        echo -e "${AMARILLO}⚠️ No se seleccionó ninguna imagen.${RESET}"
        sleep 1
    fi
}

# Opción 2: Conectar a un contenedor que ya está corriendo
function contenedor_abierto() {
    echo -e "${AMARILLO}🔍 Buscando contenedores activos...${RESET}"
    container=$(docker ps --format "{{.ID}} | {{.Names}} ({{.Image}})" | fzf --height 40% --reverse --header "CONECTAR A CONTENEDOR EN NUEVA VENTANA:")
    
    if [[ -n "$container" ]]; then
        container_id=$(echo "$container" | cut -d' ' -f1)
        echo -e "${VERDE}🚀 Conectando a $container_id en ventana independiente...${RESET}"
        # Preparamos el comando
        local cmd="docker exec -it $container_id /bin/bash || docker exec -it $container_id /bin/sh; echo -e '\n${AMARILLO}Sesión terminada. Presiona Enter para cerrar...${RESET}'; read"
        # Lanzamos en segundo plano
        $MY_TERM -- bash -c "$cmd" &
    else
        echo -e "${AMARILLO}⚠️ No se seleccionó ningún contenedor.${RESET}"
        sleep 1
    fi
}

# Opción 3: Detener (Stop) un contenedor activo
function detener_contenedor() {
    echo -e "${AMARILLO}🔍 Selecciona el contenedor a detener:${RESET}"
    container=$(docker ps --format "{{.ID}} | {{.Names}}" | fzf --height 40% --reverse --header "DETENER CONTENEDOR:")
    
    if [[ -n "$container" ]]; then
        container_id=$(echo "$container" | cut -d' ' -f1)
        echo -e "${AMARILLO}🛑 Deteniendo $container_id...${RESET}"
        docker stop "$container_id" && echo -e "${VERDE}✔ Contenedor detenido.${RESET}"
        sleep 1
    else
        echo -e "${AMARILLO}⚠️ Cancelado.${RESET}"
        sleep 1
    fi
}

# Opción 4: Eliminar (Remove) un contenedor (incluso si está parado)
function eliminar_contenedor() {
    echo -e "${ROJO}🔍 Selecciona el contenedor a ELIMINAR:${RESET}"
    container=$(docker ps -a --format "{{.ID}} | {{.Names}} [{{.Status}}]" | fzf --height 40% --reverse --header "ELIMINAR CONTENEDOR:")
    
    if [[ -n "$container" ]]; then
        container_id=$(echo "$container" | cut -d' ' -f1)
        echo -e "${ROJO}🗑️ Eliminando $container_id...${RESET}"
        docker rm -f "$container_id" && echo -e "${VERDE}✔ Contenedor eliminado.${RESET}"
        sleep 1
    else
        echo -e "${AMARILLO}⚠️ Cancelado.${RESET}"
        sleep 1
    fi
}

# --- 4. VALIDACIONES Y BUCLE PRINCIPAL ---

check_command "fzf"
check_command "docker"

if ! docker ps >/dev/null 2>&1; then
    echo -e "${ROJO}❌ Error: El demonio de Docker no responde.${RESET}"
    echo "Asegúrate de que Docker Desktop o el servicio docker estén iniciados."
    exit 1
fi

# Menú principal
while true; do
    mostrar_logo
    echo -e "${BLANCO}1.${RESET} Crear contenedor desde imagen en nueva ventana (docker run)"
    echo -e "${BLANCO}2.${RESET} Entrar en contenedor activo en nueva ventana (docker exec)"
    echo -e "${BLANCO}3.${RESET} Detener contenedor (docker stop)"
    echo -e "${BLANCO}4.${RESET} Eliminar contenedor (docker rm)"
    echo -e "${BLANCO}5.${RESET} Salir"
    echo -ne "\n${AZUL}Selecciona una opción: ${RESET}"
    read -r opt

    case $opt in
        1) abrir_imagen ;;
        2) contenedor_abierto ;;
        3) detener_contenedor ;;
        4) eliminar_contenedor ;;
        5) despedida ;;
        *) echo -e "${ROJO}Opción no válida.${RESET}"; sleep 1 ;;
    esac
done