import requests
import base64
import pymongo
import datetime
from py2neo import Graph, Node, Relationship, NodeMatcher

# --------------------------------- Spotify Connection -------------------------------------

# Set your Spotify API credentials
client_id = 'b38132eea44845dea8ed79e258b80762'
client_secret = 'f0a68e72bb82459e9b4ab23456266dc9'

#TOKEN API

token = {"grant_type": "client_credentials"}
cred = f"{client_id}:{client_secret}"
cred_b64 = base64.b64encode(cred.encode())
headers = {"Authorization": f"Basic {cred_b64.decode()}"}

r = requests.post("https://accounts.spotify.com/api/token", data=token, headers=headers)
if r.status_code not in range(200, 299):
    raise Exception("Could not authenticate client.")

data = r.json()
now = datetime.datetime.now()
access_token = data['access_token']

def get(access_token, lista, limite, year, type):
    offset = 0
    for _ in range(round(limite/50)):
        print('.', end='', flush=True)
        response = requests.get(
         f'https://api.spotify.com/v1/search?q=year%3A{year}&type={type}&limit=50&offset={offset}',
            headers={
                "Authorization": f"Bearer {access_token}",
                'Content-Type': 'application/json'
            }
        )
        json_resp = response.json()
        tipo_aux = f"{type}s"
        if tipo_aux in list(json_resp.keys()):
            current_data = json_resp[tipo_aux]['items']
            lista.extend(current_data)
            offset += 50
        else:
            break
    return lista

artistas=[]
for a in range(2013, 2023):
    print(f'\n\t Artistas {a} ', end='')
    artistas = get(access_token, artistas, 1000, a, 'artist')

dict_artistas = [artista for artista in artistas if isinstance(artista, dict)]

albums=[]
for a in range(2013, 2023):
    print(f'\n\t Albums {a} ', end='')
    albums = get(access_token, albums, 1000, a, 'album')

dict_album = [album for album in albums if isinstance(album, dict)]

canciones=[]
for a in range(2013, 2023):
    print(f'\n\t Canciones {a} ', end='')
    canciones = get(access_token, canciones, 1000, a, 'track')

dict_canciones = [cancion for cancion in canciones if isinstance(cancion, dict)]

# --------------------------------- Mongo DB -----------------------------------------------

client = pymongo.MongoClient("mongodb://mongodb:27017")
db = client["spotify"]

# Resetear las colecciones cada que corremos el codigo
collection_name = ["artists", "tracks", "albums"]

for collection in collection_name:
    if collection in db.list_collection_names():
        db[collection].drop()

artist_coll = db["artists"]
tracks_coll = db["tracks"]
albums_coll = db["albums"]

# 1. Insertar Artistas
db["artists"].insert_many(dict_artistas)
# 2. Insertar Albums
db['albums'].insert_many(dict_album)
# 3. Insertar Canciones
db['tracks'].insert_many(dict_canciones)

print(f"\n\nInsercion correcta en Mongo:")
print(f"- {len(dict_artistas)} artistas")
print(f"- {len(dict_canciones)} canciones")
print(f"- {len(dict_album)} albumes")

# --------------------------------- Neo4j -----------------------------------------------

# Connect to Neo4j
neo4j_uri = "neo4j://neo4jdb:7687"  
neo4j_user = "neo4j"  
neo4j_password = "neoneoneo"  
graph = Graph(neo4j_uri, auth=(neo4j_user, neo4j_password))
matcher = NodeMatcher(graph)

# Reseatear la base de datos
graph.delete_all()

# Creacion de los nodos de artistas

for artist in dict_artistas:
    artist_node = Node("Artist", artist_id=artist["id"], name=artist["name"], popularity=artist["popularity"],
                        followers=artist["followers"]["total"], href=artist["href"], uri=artist["uri"])
    graph.merge(artist_node, "Artist", "artist_id")
    
    for genre in artist["genres"]:
        genre_node = Node("Genre", name=genre)
        graph.merge(genre_node, "Genre", "name")

        relationship = Relationship(artist_node, "HAS_GENRE", genre_node)
        graph.create(relationship)
print(f"\nSuccessful insertion of artists in Neo4j")

n = 0
for album in dict_album:
    album_node = Node("Album", album_id=album["id"], name=album["name"], release_date=album["release_date"],
                      release_date_precision=album["release_date_precision"], total_tracks=album["total_tracks"],
                      href=album["href"], uri=album["uri"])

    for artist in album["artists"]:
        artist_node = matcher.match("Artist", artist_id=artist["id"]).first()
        if artist_node != None:
            relationship = Relationship(artist_node, "CONTRIBUTED_TO", album_node)
            graph.create(relationship)
            n += 1
print(f"Successful insertion of albums in Neo4j - with {n} relations")

m = 0
m2 = 0
for cancion in dict_canciones:
    cancion_node = Node("Song", song_id=cancion["id"], name=cancion["name"], release_date=cancion["album"]["release_date"], popularity=cancion["popularity"],
                        duration_ms=cancion["duration_ms"], explicit=cancion["explicit"], disc_number=cancion["disc_number"],
                        track_number=["track_number"], href=cancion["href"], uri=cancion["uri"])
    
    for artist in cancion["artists"]:
        artist_node = matcher.match("Artist", artist_id=artist["id"]).first()
        if artist_node != None:
            relationship = Relationship(cancion_node, "SANG_BY", artist_node)
            graph.create(relationship)
            m += 1

    album_node = matcher.match("Album", album_id=cancion["album"]["id"]).first()
    if album_node != None:
        relationship = Relationship(cancion_node, "INCLUDED_IN", album_node)
        graph.create(relationship)
        m2 += 1
print(f"Successful insertion of songs in Neo4j - with {m} + {m2} relations")

