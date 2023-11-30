#! /bin/bash

echo -e "\nCreamos tablas:"

docker exec -i cassandra cqlsh -e "CREATE keyspace spotify with  replication = {'class': 'SimpleStrategy','replication_factor': '1'};"

echo "- Tabla artist"
docker exec -i cassandra cqlsh -k spotify -e "create table artist(followers varchar(100), genre varchar(100),artist_id varchar(100),popularity varchar(100),name varchar(200));"

echo "- Tabla album"
docker exec -i cassandra cqlsh -k spotify -e "create table album(available_market varchar(100),album_id varchar(100),release_date varchar(100),total_tracks varchar(100),name varchar(200));"

echo "- Tabla track"
docker exec -i cassandra cqlsh -k spotify -e "create table track(album_id varchar(100),available_market varchar(100),disc_number varchar(100),duration_ms varchar(100),explicit varchar(100), track_id varchar(50),popularity varchar(50),track_number varchar(50),name varchar(200));"

echo -e '\nInsertamos datos en tablas:'

echo '- Artistas'
docker exec -i cassandra cqlsh -k spotify -e "copy offset 2 into artist from '/data/monet/artists_mon.csv' on client using delimiters ',',E'\n',E'\"' null as ' ';"

echo '- Albums'
docker exec -i cassandra cqlsh -k spotify -e "copy offset 2 into album from '/data/monet/albums_mon.csv' on client using delimiters ',',E'\n',E'\"' null as ' ';"

echo '- Tracks'
docker exec -i cassandra cqlsh -k spotify -e "copy offset 2 into track from '/data/monet/tracks_mon.csv' on client using delimiters ',',E'\n',E'\"' null as ' ';"
