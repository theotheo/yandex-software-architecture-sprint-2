

## Как запустить

### Запускаем контейнеры

### Инициализация конфигурационного сервера

```bash
docker exec -it configServer mongosh --port 27015 --eval '
rs.initiate({
  _id: "config_server",
  configsvr: true,
  members: [
    { _id: 0, host: "configServer:27015" }
  ]
});
'
```

### Инициализация шарда 1

```bash
docker exec -it shard1 mongosh --port 27018 --eval '

rs.initiate(
    {
      _id : "shard1",
      members: [
        { _id : 0, host : "shard1:27018" },
       // { _id : 1, host : "shard2:27019" }
      ]
    }
);
'
```

### Инициализация шарда 2

```bash
docker exec -it shard2 mongosh --port 27019 --eval '

rs.initiate(
    {
      _id : "shard2",
      members: [
        // { _id : 1, host : "shard1:27018" }
        { _id : 0, host : "shard2:27019" },
      ]
    }
);
'
```

### Инициализация роутера

```bash
docker exec -it router mongosh --port 27020 --eval '

sh.addShard("shard1/shard1:27018");
sh.addShard("shard2/shard2:27019");

sh.enableSharding("somedb");
sh.shardCollection("somedb.helloDoc", { "name": "hashed" });

use somedb;

for(var i = 0; i < 1000; i++) db.helloDoc.insert({age: i, name: "ly" + i});
print("Total documents: " + db.helloDoc.countDocuments());
'
```

