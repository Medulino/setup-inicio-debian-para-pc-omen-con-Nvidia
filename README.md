# 🚀 Debian 13 (Trixie) Post-Installation Script

Un script de automatización en Bash diseñado para configurar un sistema recién instalado de **Debian 13 (Trixie)** con entorno **Cinnamon** y tarjeta gráfica **NVIDIA**.

Automatiza la adición de repositorios, la instalación de controladores propietarios mediante DKMS y la configuración del gestor de pantalla optimizado.

---

## ⚠️ Requisitos Previos y Advertencia Crítica

> ### 🔴 IMPORTANTE: Desactivar Secure Boot
> Para que el módulo propietario de NVIDIA se compile y cargue correctamente mediante DKMS, **debes desactivar el Secure Boot (Arranque Seguro) en la BIOS/UEFI** de tu placa base.
> 
> Si el Secure Boot permanece activado, la BIOS bloqueará la carga del controlador y el sistema arrancará en una pantalla negra.

---

## 🛠️ Instalación y Uso

### Opción 1: Un solo comando (vía cURL)

Puedes ejecutar el script directamente desde la terminal sin necesidad de clonar el repositorio manualmente:

```bash
curl -fsSL https://raw.githubusercontent.com/medulino/setup_inicio_debian/main/setup_inicio_debian.sh | bash

