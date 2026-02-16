🐳 Docker4me

Docker4me es un menú interactivo en Bash que facilita la gestión de contenedores Docker desde la terminal.
Permite crear, acceder, detener y eliminar contenedores utilizando una interfaz amigable basada en fzf, todo desde nuevas ventanas de terminal.

✅ Ideal para desarrolladores que trabajan frecuentemente con Docker y quieren una experiencia más visual e interactiva.

🚀 Características

🔍 Selección interactiva de imágenes y contenedores con fzf

🆕 Lanzamiento de contenedores en nuevas ventanas de terminal

🔗 Conexión a contenedores activos en ventana independiente

🛑 Detener contenedores fácilmente

🗑️ Eliminar contenedores (incluso detenidos)

🎨 Interfaz con colores y menú visual

🧠 Detección automática de terminal compatible:

xfce4-terminal

gnome-terminal

konsole

xterm

📦 Requisitos

🐳 Docker

🔎 fzf

Sistema Linux con entorno gráfico

Una de las siguientes terminales instalada:

xfce4-terminal

gnome-terminal

konsole

xterm

⚙️ Instalación

Clona el repositorio:

git clone https://github.com/DanSanMar/docker4me.git
cd docker4me


Da permisos de ejecución al script:

chmod +x docker4me.sh


Ejecuta:

./docker4me.sh

🖥️ Uso

Al ejecutar el script, verás un menú interactivo con las siguientes opciones:

1. Crear contenedor desde imagen en nueva ventana (docker run)
2. Entrar en contenedor activo en nueva ventana (docker exec)
3. Detener contenedor (docker stop)
4. Eliminar contenedor (docker rm)
5. Salir

1️⃣ Crear contenedor desde imagen

Muestra las imágenes disponibles.

Permite seleccionar una con fzf.

Abre una nueva ventana con docker run -it.

Intenta /bin/bash y si no existe, usa /bin/sh.

2️⃣ Entrar en contenedor activo

Lista contenedores en ejecución.

Permite conectarse con docker exec -it.

Abre sesión en nueva ventana.

3️⃣ Detener contenedor

Lista contenedores activos.

Ejecuta docker stop.

4️⃣ Eliminar contenedor

Lista todos los contenedores (activos y detenidos).

Ejecuta docker rm -f.

🛡️ Validaciones

El script verifica automáticamente:

Que docker esté instalado

Que fzf esté instalado

Que el demonio de Docker esté activo

Que exista una terminal compatible para abrir nuevas ventanas

Si alguna validación falla, el script muestra un mensaje de error y se detiene.

🧠 ¿Cómo funciona?

Docker4me utiliza:

docker images y docker ps con formato personalizado

fzf para selección interactiva

docker run, docker exec, docker stop y docker rm

trap para capturar Ctrl+C y salir limpiamente

Detección automática de terminal instalada mediante command -v

🎯 Casos de uso recomendados

Desarrollo backend con múltiples contenedores

Testing rápido de imágenes

Laboratorios y aprendizaje de Docker

Entornos DevOps locales

Usuarios que prefieren una interfaz interactiva sin usar Docker Desktop

📄 Licencia

MIT License
Libre para usar, modificar y distribuir.

👨‍💻 Autor
DanSanMar