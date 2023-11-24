# proyectoNoSql23
Conexion de API a Mongo mediante Python, y ETL para carga en base de grafos

Integrantes:
* Manuel Hermida
* Fernando
* Ian

## Instalacion de contenedores

A partir del uso de **docker-compose** podemos generar una aplicación con múltiples contenedores. Para lograrlo, definimos nuestros servicios en el archivo `docker-compose.yaml` para, posteriormente, correrlos de manera conjunta en un ambiente aislado. Dentro de tu terminal y en el directorio en el cual descargaste los archivos, ejecuta el siguiente comando para iniciar los contenedores:

```shell
docker-compose up --build -d
```

Una vez terminada la creación de los contenedores, se ejecutará de manera automática el script `nombre_final.py`. Inicialmente no se verá nada, pero puedes seguir el proceso del script ejecutando:

```shell
docker logs -f python_load
```
La carga toma aproximadamente **15 minutos**.

### En caso de error

Si la API de Spotify llega a cerrar la conexión antes de terminar la carga, ejecuta las siguiente linea y repite el proceso de instalación

```shell
docker-compose down
```

## Queries por BD

### Mongo

En caso de tener el contenedor apagado:

```shell
docker start mongodb
```

Iniciamos la terminal de mongo:

```shell
docker exec -it mongodb mongosh
```

Ya dentro de la terminal nos vamos a la base correspondiente:
```shell
use spotify
```

#### Número de artistas clasificados por género
```js
db.artists.aggregate([
  { $unwind: "$genres" },
  { $group: { _id: "$genres", artistas: { $sum: 1 } } },
  { $sort: { artistas: -1 } },
  { $project: { _id: 0, genero: "$_id", artistas: 1 } }
])
```

### Neo4j

En caso de tener el contenedor apagado:

```shell
docker start neo4jdb
```

Iniciamos la terminal de neo4j:

```shell
docker exec -it neo4jdb cypher-shell
```

#### Top 3 de artistas con mayores colaboraciones por año
```cypher
MATCH (a1:Artist)<-[:SANG_BY]-(s:Song)-[:SANG_BY]->(a2:Artist)
             WHERE a1 <> a2
             WITH a1, date(toString(s.release_date)).year AS collaboration_year, count(s) AS collaborations
             ORDER BY collaboration_year, collaborations DESC
             WITH collaboration_year, COLLECT({artist: a1.name, collaborations: collaborations})[..3] AS top3Collaborators
             RETURN collaboration_year, top3Collaborators;
```

## Finalizacion

En caso de querer eliminar los contenedores, podemos usar `docker compose down`. Si no, podemos ejecutar la siguiente línea y solo prender los contenedores requeridos la siguiente vez:

´´´shell
docker-compose stop
´´´
