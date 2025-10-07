# mongo-sharding-repl

#### Инструкция по настройке шардирования и репликации в проекте _mongo-sharding-repl_

1. Запустите проект:
    ```shell
    docker-compose up -d
    ```
    
    Должно подняться 11 контейнеров:
    ```shell
    NAME              IMAGE                                COMMAND                  SERVICE           CREATED          STATUS          PORTS
   config_server_1   dh-mirror.gitverse.ru/mongo:latest   "docker-entrypoint.s…"   config_server_1   32 seconds ago   Up 32 seconds   27017/tcp
   config_server_2   dh-mirror.gitverse.ru/mongo:latest   "docker-entrypoint.s…"   config_server_2   32 seconds ago   Up 32 seconds   27017/tcp
   config_server_3   dh-mirror.gitverse.ru/mongo:latest   "docker-entrypoint.s…"   config_server_3   32 seconds ago   Up 32 seconds   27017/tcp
   mongos            dh-mirror.gitverse.ru/mongo:latest   "docker-entrypoint.s…"   mongos            32 seconds ago   Up 31 seconds   0.0.0.0:27017->27017/tcp, [::]:27017->27017/tcp
   pymongo_api       mongo-sharding-repl-pymongo_api      "uvicorn app:app --h…"   pymongo_api       32 seconds ago   Up 31 seconds   0.0.0.0:8080->8080/tcp, [::]:8080->8080/tcp
   shard1_1          dh-mirror.gitverse.ru/mongo:latest   "docker-entrypoint.s…"   shard1_1          32 seconds ago   Up 32 seconds   27017/tcp
   shard1_2          dh-mirror.gitverse.ru/mongo:latest   "docker-entrypoint.s…"   shard1_2          32 seconds ago   Up 32 seconds   27017/tcp
   shard1_3          dh-mirror.gitverse.ru/mongo:latest   "docker-entrypoint.s…"   shard1_3          32 seconds ago   Up 32 seconds   27017/tcp
   shard2_1          dh-mirror.gitverse.ru/mongo:latest   "docker-entrypoint.s…"   shard2_1          32 seconds ago   Up 32 seconds   27017/tcp
   shard2_2          dh-mirror.gitverse.ru/mongo:latest   "docker-entrypoint.s…"   shard2_2          32 seconds ago   Up 32 seconds   27017/tcp
   shard2_3          dh-mirror.gitverse.ru/mongo:latest   "docker-entrypoint.s…"   shard2_3          32 seconds ago   Up 32 seconds   27017/tcp
    ```

2. Инициализируйте кластер:
   
   Инициализация кластера автоматизирована. Скрипт init.sh содержит команды по настройке репликасетов, 
   шардирования и репликации. Также с помощью скрипта можно добавить тестовые данные.  
   Доступные команды:  
   - -s [INT] - время ожидания синхронизации в секундах 
   - -i - флаг генерации тестовых данных  
   
   Пример использования:
   ```shell
   # Выполнить инициализацию кластера с задержкой в 60 секунд для ожидания синхронизации данных и добавить тестовые данные
   init.sh -s 60 -i
   ```
   
В случае успеха в статусе mongos должны быть видны реплики:  
```shell
shards
[
  {
    _id: 'shard1RS',
    host: 'shard1RS/shard1_1:27018,shard1_2:27018,shard1_3:27018',
    state: 1,
    topologyTime: Timestamp({ t: 1759853555, i: 12 }),
    replSetConfigVersion: Long('1')
  },
  {
    _id: 'shard2RS',
    host: 'shard2RS/shard2_1:27019,shard2_2:27019,shard2_3:27019',
    state: 1,
    topologyTime: Timestamp({ t: 1759853556, i: 8 }),
    replSetConfigVersion: Long('1')
  }
]
```