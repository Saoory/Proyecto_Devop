# Proyecto DevOps: Microservicios con AWS, EKS y CI/CD

Este repositorio contiene la arquitectura y el código para el despliegue automático de una aplicación de microservicios (Frontend, Backend Ventas y Backend Despachos) utilizando prácticas modernas de DevOps, Infraestructura como Código (IaC) y Despliegue Continuo (CD).

---

## Desarrollo Local (Inicio Rápido)

Para levantar el entorno completo de desarrollo en tu máquina local utilizando Docker Compose, sigue estos pasos:

### Prerrequisitos
* Tener instalado Docker Desktop con soporte para contenedores Linux.

### Pasos para iniciar
1. **Clonar el repositorio y entrar al proyecto:**
   ```bash
   git clone <URL_DEL_REPOSITORIO>
   cd Proyecto_Devop
   ```

2. **Ejecutar el entorno:**
   Construye las imágenes locales y levanta todos los contenedores (Frontend, Backends y Base de Datos MySQL):
   ```bash
   docker compose up --build
   ```

3. **Acceder a la aplicación:**
   Abre tu navegador web e ingresa a:
   **http://localhost:3000**

4. **Detener el proyecto:**
   Para apagar los contenedores y liberar los puertos del sistema:
   ```bash
   docker compose down
   ```

---

## Despliegue Automatizado en la Nube (GitHub Actions)

Toda la infraestructura y la aplicación se despliegan de forma automática al realizar cambios en el repositorio.

### Paso 1: Configurar las Credenciales en GitHub
Antes de subir tu código, debes pasarle las llaves de AWS a GitHub Actions para que tenga permisos de construcción:
1. Ve a tu repositorio en GitHub -> Settings -> Secrets and variables -> Actions.
2. Registra los siguientes Repository Secrets con tus credenciales actualizadas de AWS Academy:
   * `AWS_ACCESS_KEY_ID`
   * `AWS_SECRET_ACCESS_KEY`
   * `AWS_SESSION_TOKEN`
   * `AWS_REGION` (us-east-1)

### Paso 2: Gatillar el Pipeline
Simplemente sube tus cambios a la rama principal:
```bash
git add .
git commit -m "deploy: infraestructura y aplicación"
git push origin main
```
> **¿Qué pasa internamente?** El pipeline `terraform.yml` creará la red (VPC) y el clúster (EKS). Inmediatamente después, el pipeline `cd.yml` empaquetará tus microservicios en Docker, los subirá a Amazon ECR y ejecutará un `kubectl apply` para encender todo en AWS sin intervención manual.

---

## Anexo: Despliegue Manual (Solo para pruebas o contingencias)

Si necesitas desplegar la infraestructura a mano desde tu terminal local sin usar los pipelines de GitHub:

1. Asegúrate de tener Docker Desktop corriendo con Kubernetes activado.
2. Abre tu terminal, navega a la carpeta y exporta tus credenciales temporales:
   ```bash
   cd infra/terraform

   export AWS_ACCESS_KEY_ID="tu_access_key"
   export AWS_SECRET_ACCESS_KEY="tu_secret_key"
   export AWS_SESSION_TOKEN="tu_session_token"
   export AWS_DEFAULT_REGION="us-east-1"
   ```
3. Ejecuta el aprovisionamiento manual:
   ```bash
   terraform init
   terraform apply -auto-approve
   ```