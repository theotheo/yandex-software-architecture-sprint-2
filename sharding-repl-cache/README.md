## Как запустить

### Запускаем контейнеры

```bash
docker-compose up -d
```

### Инициализируйте набор реплик конфигурационных серверов

Запустите скрипт

```bash
sh ./setup-mongo.sh
```

Или выполните необходимые операции по шагам

```bash
docker exec -it config-server-1 mongosh --eval '
rs.initiate({
  _id: "config_server",
  configsvr: true,
  members: [
    { _id: 0, host: "config-server-1:27017" },
    { _id: 1, host: "config-server-2:27017" },
    { _id: 2, host: "config-server-3:27017" }
  ]
});
'
```

### Инициализация шарда 1

```bash
docker exec -it shard1-1 mongosh --eval '
rs.initiate(
    {
      _id : "shard1",
      members: [
        { _id : 0, host : "shard1-1:27017" },
        { _id : 1, host : "shard1-2:27017" },
        { _id : 2, host : "shard1-3:27017" }
      ]
    }
);
'
```

### Инициализация шарда 2

```bash
docker exec -it shard2-1 mongosh --eval '
rs.initiate(
    {
      _id : "shard2",
      members: [
        { _id : 0, host : "shard2-1:27017" },
        { _id : 1, host : "shard2-2:27017" },
        { _id : 2, host : "shard2-3:27017" }
      ]
    }
);
'
```

### Инициализация шарда 3

```bash
docker exec -it shard3-1 mongosh --eval '
rs.initiate(
    {
      _id : "shard3",
      members: [
        { _id : 0, host : "shard3-1:27017" },
        { _id : 1, host : "shard3-2:27017" },
        { _id : 2, host : "shard3-3:27017" }
      ]
    }
);
'
```

### Инициализация роутера и настройка шардирования

```bash
docker exec -it mongos-1 mongosh --eval '
// Добавляем шарды
sh.addShard("shard1/shard1-1:27017,shard1-2:27017,shard1-3:27017");
sh.addShard("shard2/shard2-1:27017,shard2-2:27017,shard2-3:27017");
sh.addShard("shard3/shard3-1:27017,shard3-2:27017,shard3-3:27017");

// Включаем шардирование для базы данных
sh.enableSharding("somedb");

// Создаем коллекцию и настраиваем шардирование
db = db.getSiblingDB("somedb");
db.createCollection("helloDoc");
sh.shardCollection("somedb.helloDoc", { "name": "hashed" });

// Добавляем тестовые данные
for(var i = 0; i < 1000; i++) db.helloDoc.insert({age: i, name: "ly" + i});
print("Total documents: " + db.helloDoc.countDocuments());

// Проверяем статус шардирования
sh.status();
'
```

### Проверка статуса шардирования

```bash
docker exec -it mongos-1 mongosh --eval 'sh.status()'
```

### Проверка распределения данных

```bash
docker exec -it mongos-1 mongosh --eval 'db.getSiblingDB("somedb").getCollection("helloDoc").getShardDistribution()'
```
