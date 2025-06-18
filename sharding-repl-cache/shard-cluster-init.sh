#!/bin/bash

# Initialize config servers replica set
docker compose exec -T config-srv-1 mongosh <<EOF
rs.initiate(
    {
        _id: "cfg-srv-rs",
        configsvr: true,
        members: [
            { _id: 0, host: "config-srv-1:27017" }
        ]
    }
)
EOF

sleep 2

# Initialize shard1 replica set
docker compose exec -T shard-1-repl-1 mongosh <<EOF
rs.initiate(
    {
        _id: "shard-1",
        members: [
            { _id: 0, host: "shard-1-repl-1:27017" },
            { _id: 1, host: "shard-1-repl-2:27017" },
            { _id: 2, host: "shard-1-repl-3:27017" }
        ]
    }
)
use somedb
db.createCollection("helloDoc")
EOF

sleep 3

# Initialize shard-2 replica set
docker compose exec -T shard-2-repl-1 mongosh <<EOF
rs.initiate(
    {
        _id: "shard-2",
        members: [
            { _id: 0, host: "shard-2-repl-1:27017" },
            { _id: 1, host: "shard-2-repl-2:27017" },
            { _id: 2, host: "shard-2-repl-3:27017" }
        ]
    }
)
use somedb
db.createCollection("helloDoc")
EOF

sleep 4

# Initialize shard-3 replica set
docker compose exec -T shard-3-repl-1 mongosh <<EOF
rs.initiate(
    {
        _id: "shard-3",
        members: [
            { _id: 0, host: "shard-3-repl-1:27017" },
            { _id: 1, host: "shard-3-repl-2:27017" },
            { _id: 2, host: "shard-3-repl-3:27017" }
        ]
    }
)
use somedb
db.createCollection("helloDoc")
EOF

# Wait a bit for the replica sets to initialize
sleep 15

# Add shards to the cluster via mongos
docker compose exec -T mongos-router mongosh <<EOF
sh.addShard("shard-1/shard-1-repl-1:27017,shard-1-repl-2:27017,shard-1-repl-3:27017");
sh.addShard("shard-2/shard-2-repl-1:27017,shard-2-repl-2:27017,shard-2-repl-3:27017");
sh.addShard("shard-3/shard-3-repl-1:27017,shard-3-repl-2:27017,shard-3-repl-3:27017");

sh.enableSharding("somedb");
sh.shardCollection("somedb.helloDoc", { "name" : "hashed" } )
EOF

sleep 2

docker compose exec -T mongos-router mongosh <<EOF
sh.status()
EOF
