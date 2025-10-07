#!/bin/bash

# Default values
SLEEP_TIME=60
INSERT_DATA=false

# Parse command line arguments
while getopts "s:i" opt; do
  case $opt in
    s)
      SLEEP_TIME="$OPTARG"
      ;;
    i)
      INSERT_DATA=true
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      echo "Usage: $0 [-s seconds] [-i]" >&2
      echo "  -s seconds   Time to wait for services to start (default: 60)" >&2
      echo "  -i           Insert test data into the database" >&2
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done

echo "Initializing sharded MongoDB cluster with replication"

# Initialize Config Server Replica Set
echo "Initializing Config Server Replica Set..."
docker compose exec -T config_server_1 mongosh --port 27017 --quiet <<EOF
rs.initiate({
  _id: 'configRS',
  configsvr: true,
  members: [
    { _id: 0, host: 'config_server_1:27017' },
    { _id: 1, host: 'config_server_2:27017' },
    { _id: 2, host: 'config_server_3:27017' }
  ]
})
EOF
echo "Initialized Config Server Replica Set"

# Initialize Shard 1 Replica Set
echo "Initializing Shard 1 Replica Set..."
docker compose exec -T shard1_1 mongosh --port 27018 --quiet <<EOF
rs.initiate({
  _id: 'shard1RS',
  members: [
    { _id: 0, host: 'shard1_1:27018' },
    { _id: 1, host: 'shard1_2:27018' },
    { _id: 2, host: 'shard1_3:27018' }
  ]
})
EOF
echo "Initialized Shard 1 Replica Set"

# Initialize Shard 2 Replica Set
echo "Initializing Shard 2 Replica Set..."
docker compose exec -T shard2_1 mongosh --port 27019 --quiet <<EOF
rs.initiate({
  _id: 'shard2RS',
  members: [
    { _id: 0, host: 'shard2_1:27019' },
    { _id: 1, host: 'shard2_2:27019' },
    { _id: 2, host: 'shard2_3:27019' }
  ]
})
EOF
echo "Initialized Shard 2 Replica Set"


echo "Waiting for replica sets to synchronize for ${SLEEP_TIME} seconds..."
sleep "$SLEEP_TIME"

# Add shards to mongos
echo "Adding shards to the cluster..."
docker compose exec -T mongos mongosh --port 27017 --quiet <<EOF
sh.addShard('shard1RS/shard1_1:27018,shard1_2:27018,shard1_3:27018');
sh.addShard('shard2RS/shard2_1:27019,shard2_2:27019,shard2_3:27019');
EOF
echo "Added shards to the cluster"

# Enable sharding for the database
echo "Enabling sharding for the 'somedb' database..."
docker compose exec -T mongos mongosh --port 27017 --quiet <<EOF
sh.enableSharding('somedb');
EOF
echo "Enabled sharding for the 'somedb' database"

# Configure shard collection
echo "Configuring shard collection..."
docker compose exec -T mongos mongosh --port 27017 --quiet <<EOF
sh.shardCollection('somedb.helloDoc', { _id: 'hashed' });
EOF
echo "Configured shard collection"

# Insert test data
if [ "$INSERT_DATA" = true ]; then
  echo "Inserting test data..."
  docker compose exec -T mongos mongosh --port 27017 --quiet <<EOF
use somedb;
for(var i = 0; i < 1000; i++) {
  db.helloDoc.insertOne({
    age: Math.floor(Math.random() * 71) + 20,
    name: 'user' + i,
    email: 'user' + i + '@example.com',
    created_at: new Date()
  })
}
EOF
  echo "Inserted test data"
fi

echo "Initialization completed"