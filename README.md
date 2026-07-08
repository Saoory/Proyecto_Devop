PARA INICIALIZAR

Abrir docker (kubernete activado)
cd infra/terraform
export aws_access_key_id=
export aws_secret_access_key=
aws_session_token=
export aws_default_region="us-east-1"

terraform init
(terraform plan)
terraform apply

Github
poner secrets

realizar commit para el despliegue del ci/cd


## Inicio rápido

1. Clonar el repositorio.

```bash
git clone <URL_DEL_REPOSITORIO>
```

2. Ingresar al proyecto.

```bash
cd Proyecto_Devop
```

3. Ejecutar Docker Compose.

```bash
docker compose up --build
```

4. Abrir la aplicación.

```
http://localhost:3000
```

5. Para detener el proyecto.

```bash
docker compose down
```
