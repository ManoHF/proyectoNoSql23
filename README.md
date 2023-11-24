# proyectoNoSql23
Conexion de API a Mongo mediante Python, y ETL para carga en base de grafos

## Queries por BD

### Mongo

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

#### Top 3 de artistas con mayores colaboraciones por año
```cypher
MATCH (a1:Artist)<-[:SANG_BY]-(s:Song)-[:SANG_BY]->(a2:Artist)
             WHERE a1 <> a2
             WITH a1, date(toString(s.release_date)).year AS collaboration_year, count(s) AS collaborations
             ORDER BY collaboration_year, collaborations DESC
             WITH collaboration_year, COLLECT({artist: a1.name, collaborations: collaborations})[..3] AS top3Collaborators
             RETURN collaboration_year, top3Collaborators;
```
