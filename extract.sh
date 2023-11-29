 
#! /bin/bash

WORKING_DIR=$PWD

echo "Unwinds para Cassandra:"

echo -e "\n\tArtists -> géneros"
#Unwind de los artistas sobre los géneros
docker exec -it mongodb mongosh --quiet \
--eval 'use spotify' \
--eval 'db.artists.aggregate([{$unwind:"$genres"}, {$project:{_id:0}}, {$out:"uw_artists"}])'

echo -e "\tAlbums -> 'available markets'"
#Unwind de albums sobre available_markets
docker exec -it mongodb mongosh --quiet \
--eval 'use spotify' \
--eval 'db.albums.aggregate([{$unwind:"$available_markets"}, {$project:{_id:0}}, {$out:"uw_albums"}])'

echo -e "\tTracks -> 'available markets'"
#Unwind de tracks sobre available_markets
docker exec -it mongodb mongosh --quiet \
--eval 'use spotify' \
--eval 'db.tracks.aggregate([{$unwind:"$available_markets"}, {$project: {_id:0}}, {$out:"uw_tracks"}])'

docker exec mongodb mkdir -p data


echo "Exportamos archivos json"

COLLECTION_NAME='uw_albums'
OUTPUT_FILE='/data/albums.json'
docker exec mongodb mongoexport -d 'spotify' -c $COLLECTION_NAME --out $OUTPUT_FILE > /dev/null
echo -e '\n'

# Extraemos los artistas
COLLECTION_NAME='uw_artists'
OUTPUT_FILE='/data/artists.json'
docker exec mongodb mongoexport -d 'spotify' -c $COLLECTION_NAME --out $OUTPUT_FILE > /dev/null
echo -e '\n'

# Extraemos las canciones
COLLECTION_NAME='uw_tracks'
OUTPUT_FILE='/data/tracks.json'
docker exec mongodb mongoexport -d 'spotify' -c $COLLECTION_NAME --out $OUTPUT_FILE > /dev/null
echo -e '\n'

ID_CONTAINER=$(docker ps -aqf "name=mongodb")
docker cp $ID_CONTAINER:/data $WORKING_DIR/
#docker exec $ID_CONTAINER cp /data_spotify $WORKING_DIR

echo "Obtenemos archivos csv para Cassandra"

rm -fr $WORKING_DIR/csv
mkdir -p $WORKING_DIR/csv/cas


echo 'followers,genre,artist_id,popularity,name' > $WORKING_DIR/csv/cas/artists.csv
echo 'available_market,album_id,release_date,total_tracks,name' > $WORKING_DIR/csv/cas/albums.csv
echo 'album_id,available_market,disc_number,duration_ms,explicit,track_id,popularity,track_number,name' > $WORKING_DIR/csv/cas/tracks.csv

echo -e '\n\t- Convirtiendo artistas'
jq -r '[.followers.total, .genres, .id, .popularity, .name] | @csv' $WORKING_DIR/data/artists.json | awk -F, '{printf "%s,%s,%s,%s,%s\n", $1, $2, $3, $4, $5}' >> $WORKING_DIR/csv/cas/artists.csv
echo -e '\t- Convirtiendo albums'
jq -r '[.available_markets, .id, .release_date, .total_tracks, .name] | @csv' $WORKING_DIR/data/albums.json | awk -F, '{printf "%s,%s,%s, %s,%s\n", $1, $2, $3, $4, $5}' >> $WORKING_DIR/csv/cas/albums.csv
echo -e '\t- Convirtiendo tracks'
jq -r '[.album.id, .available_markets, .disc_number, .duration_ms, .explicit, .id, .popularity, .track_number, .name] | @csv' $WORKING_DIR/data/tracks.json | awk -F, '{printf "%s,%s,%s,%s,%s,%s,%s,%s,%s\n", $1, $2, $3, $4, $5, $6, $7, $8, $9}' >> $WORKING_DIR/csv/cas/tracks.csv


#Artists
cat $WORKING_DIR/csv/cas/artists.csv | sed 's/.$//' | sed 's/$/"/' | sed '1s/.$//' | sed "$ d" | sed 's/"//g' | sed 's/\r/\\r/g' | sed 's/\\//g' | sed "s/[#|$|%|*|@|&|'|-|_|¿|?|+|=]//g" | sed 's/[^a-zA-Z0-9, -]//g' > $WORKING_DIR/csv/cas/artists-c.csv
#Albums
cat $WORKING_DIR/csv/cas/albums.csv | sed 's/.$//' | sed 's/$/"/' | sed '1s/.$//' | sed "$ d" | sed 's/"//g' | sed 's/\r/\\r/g' | sed 's/\\//g' | sed "s/[#|$|%|*|@|&|'|-|_|¿|?|+|=]//g" | sed 's/[^a-zA-Z0-9, -]//g' > $WORKING_DIR/csv/cas/albums-c.csv
#Tracks
cat $WORKING_DIR/csv/cas/tracks.csv | sed 's/.$//' | sed 's/$/"/' | sed '1s/.$//' | sed "$ d" | sed 's/"//g' | sed 's/\r/\\r/g' | sed 's/\\//g' | sed "s/[#|$|%|*|@|&|'|-|_|¿|?|+|=]//g" | sed 's/[^a-zA-Z0-9, -]//g' > $WORKING_DIR/csv/cas/tracks-c.csv

#Eliminamos los csv auxiliares
rm $WORKING_DIR/csv/cas/artists.csv
rm $WORKING_DIR/csv/cas/albums.csv
rm $WORKING_DIR/csv/cas/tracks.csv
