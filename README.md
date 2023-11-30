# proyectoNoSql23
Conexion de API a Mongo mediante Python, y ETL para carga en base de grafos y una base columnar

Integrantes:
* Manuel Hermida
* Fernando
* Ian Carbajal

## Instalacion de contenedores

Descarga el proyecto utilizando `git clone`.

A partir del uso de **docker-compose** podemos generar una aplicación con múltiples contenedores. Para lograrlo, definimos nuestros servicios en el archivo `docker-compose.yaml` para, posteriormente, correrlos de manera conjunta en un ambiente aislado. Dentro de tu terminal y en el directorio en el cual descargaste los archivos, ejecuta el siguiente comando para iniciar los contenedores:

```shell
docker-compose down --volumes
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
docker-compose down --volumes
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

#### Top 5 canciones más populares con su artista, año y album
```js
db.tracks.aggregate([
  { $unwind: "$artists" },
  { $group: { _id: "$album.id",
      mostPopularTrack: { $first: {
          popularity: "$popularity", name: "$name", artist: "$artists.name", trackId: "$id" } } } },
  { $sort: { "mostPopularTrack.popularity": -1, "mostPopularTrack.trackId": -1 } },
  { $limit: 5 },
  { $lookup: { from: "albums", localField: "_id", foreignField: "id", as: "albumInfo" } },
  { $unwind: "$albumInfo" },
  { $project: { _id: 0, name: "$mostPopularTrack.name", popularity: "$mostPopularTrack.popularity",
 albumName: "$albumInfo.name", releaseDate: { $dateToString: { format: "%Y-%m", date: { $toDate: "$albumInfo.release_date" } } },
 artistName: "$mostPopularTrack.artist", } }
])
```

#### ¿Cuantas canciones se lanzan por mes?
```js
db.tracks.aggregate([
   { $match: { $expr: {$eq: [{$strLenCP: '$album.release_date'}, 10] } } },
   { $project: { _id: 0, 'mes': {$month: { $toDate: '$album.release_date' } } } },
   { $group: { _id:'$mes', count: {$count: {}} } },
   { $project: { 'mes': '$_id', 'count': 1, _id:0 } },
   { $sort: { 'count': -1 } }
]);
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
Usando el usuario neo4j y esta contraseña:
```shell
neoneoneo
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

#### Top 5 duos más populares
```cypher
MATCH (a1:Artist)<-[:SANG_BY]-(song:Song)-[:SANG_BY]->(a2:Artist)
WITH a1, a2, COLLECT(DISTINCT song.name) AS popularSongs, AVG(song.popularity) AS avgPopularity
WHERE SIZE(popularSongs) >= 3 AND a1 < a2
RETURN a1.name AS artist1, a2.name AS artist2, popularSongs, avgPopularity
ORDER BY avgPopularity DESC, SIZE(popularSongs) DESC
LIMIT 5;
```
####  10 canciones en las cuales colaboraron más artistas
```cypher
MATCH (s:Song)-[:SANG_BY]->(a:Artist)
WITH s, COUNT(DISTINCT a) AS numCollaborators
RETURN s.name AS song_name, numCollaborators
ORDER BY numCollaborators DESC
LIMIT 10;
```

### Cassandra

En caso de tener el contenedor apagado:

```shell
docker start cassandradb
```

Iniciamos la terminal de cassandra (puedes necesitar correrlo varias veces en lo que inicia bien):

```shell
docker exec -it cassandradb cqlsh
```

Ya dentro de cassandra:

```shell
use spotify
```

#### ¿Cuales albumes tiene más de 200 canciones?
```SQL
SELECT name,total_tracks 
FROM spotify.albums 
WHERE total_tracks>200 allow filtering;

```

#### ¿Cuales son los artistas que tienen más de 50,000,000 de followers?
```SQL
SELECT name, genres, followers
FROM spotify.artists
WHERE followers>50000000 allow filtering;
```

#### ¿Qué canciones tienen una duración mayor a 10 minutos?
```SQL
SELECT name, duration_ms
FROM spotify.tracks
WHERE duration_ms > 600000  ALLOW FILTERING;
```

## Resultados

Si quieres ver de manera visual los resultados de los queries, ingresa al siguiente [link](Resultados.pdf)

## Finalizacion

En caso de querer eliminar los contenedores, podemos usar `docker compose down --volume`. Si no, podemos ejecutar la siguiente línea (seguimos en el path del proyecto) y solo prender los contenedores requeridos la siguiente vez:

```shell
docker-compose stop
```
