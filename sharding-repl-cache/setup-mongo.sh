#!/bin/bash

# Цвета для вывода
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Инициализируем набор реплик конфигурационных серверов ===${NC}"
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

# Ждем некоторое время для инициализации config-серверов
echo -e "${BLUE}=== Ждем 10 секунд для инициализации config-серверов ===${NC}"
sleep 10

echo -e "${BLUE}=== Инициализация шарда 1 ===${NC}"
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

echo -e "${BLUE}=== Инициализация шарда 2 ===${NC}"
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

echo -e "${BLUE}=== Инициализация шарда 3 ===${NC}"
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

# Ждем некоторое время для инициализации шардов
echo -e "${BLUE}=== Ждем 20 секунд для инициализации шардов ===${NC}"
sleep 20

echo -e "${BLUE}=== Инициализация роутера и настройка шардирования ===${NC}"
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

echo -e "${GREEN}=== Установка и настройка шардирования MongoDB завершена ===${NC}"
echo -e "${BLUE}=== Проверка статуса шардирования ===${NC}"
docker exec -it mongos-1 mongosh --eval 'sh.status()'

echo -e "${BLUE}=== Проверка распределения данных ===${NC}"
docker exec -it mongos-1 mongosh --eval 'db.getSiblingDB("somedb").getCollection("helloDoc").getShardDistribution()'

echo -e "${GREEN}=== Все готово! MongoDB с шардированием успешно настроена ===${NC}"