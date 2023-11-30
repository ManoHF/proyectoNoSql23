#! /bin/bash

WORKING_DIR=$PWD

echo -e "\nCreamos tablas cassandra:"


docker exec -i cassandra cqlsh -e "CREATE keyspace spotify with  replication = {'class': 'SimpleStrategy','replication_factor': '1'};"

docker exec -i cassandra cqlsh -e "use spotify;"
docker exec -i cassandra cqlsh -e "drop table spotify.artists;drop table spotify.albums;drop table spotify.tracks;"

echo "- Tabla artist"
docker exec -i cassandra cqlsh -k spotify -e "CREATE TABLE artists (
                                                followers varchar,
                                                genre varchar,
                                                artist_id varchar PRIMARY KEY,
                                                popularity varchar,
                                                name varchar
                                            );"

echo "- Tabla album"
docker exec -i cassandra cqlsh -k spotify -e "CREATE TABLE albums (
                                                available_markets varchar,
                                                album_id varchar PRIMARY KEY,
                                                release_date varchar,
                                                total_tracks varchar,
                                                name varchar
                                            );"

echo "- Tabla track"
docker exec -i cassandra cqlsh -k spotify -e "CREATE TABLE tracks (
                                                album_id varchar,
                                                available_markets varchar,
                                                disc_number varchar,
                                                duration_ms varchar,
                                                explicit varchar,
                                                track_id varchar PRIMARY KEY,
                                                popularity varchar,
                                                track_number varchar,
                                                name varchar
                                            );"

echo -e '\nInsertamos datos en tablas:'

echo '- Artistas'
cat $WORKING_DIR/csv/cas/artists-c.csv | docker exec -i cassandra cqlsh -k spotify -e "COPY artists FROM stdin WITH DELIMITER=',' AND HEADER=TRUE;"

echo '- Albums'
cat $WORKING_DIR/csv/cas/albums-c.csv | docker exec -i cassandra cqlsh -k spotify -e "COPY albums FROM stdin WITH DELIMITER=',' AND HEADER=TRUE;"

echo '- Tracks'
cat $WORKING_DIR/csv/cas/tracks-c.csv | docker exec -i cassandra cqlsh -k spotify -e "COPY tracks FROM stdin WITH DELIMITER=',' AND HEADER=TRUE;"
