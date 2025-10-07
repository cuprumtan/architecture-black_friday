# sharding-repl-cache

#### Инструкция по настройке шардирования и репликации в проекте _sharding-repl-cache_

1. Запустите проект:
    ```shell
    docker-compose up -d
    ```
    
    Должно подняться 12 контейнеров:
    ```shell
   NAME              IMAGE                                COMMAND                  SERVICE           CREATED          STATUS          PORTS
   config_server_1   dh-mirror.gitverse.ru/mongo:latest   "docker-entrypoint.s…"   config_server_1   39 seconds ago   Up 38 seconds   27017/tcp
   config_server_2   dh-mirror.gitverse.ru/mongo:latest   "docker-entrypoint.s…"   config_server_2   39 seconds ago   Up 38 seconds   27017/tcp
   config_server_3   dh-mirror.gitverse.ru/mongo:latest   "docker-entrypoint.s…"   config_server_3   39 seconds ago   Up 38 seconds   27017/tcp
   mongos            dh-mirror.gitverse.ru/mongo:latest   "docker-entrypoint.s…"   mongos            39 seconds ago   Up 38 seconds   0.0.0.0:27017->27017/tcp, [::]:27017->27017/tcp
   pymongo_api       sharding-repl-cache-pymongo_api      "uvicorn app:app --h…"   pymongo_api       39 seconds ago   Up 38 seconds   0.0.0.0:8080->8080/tcp, [::]:8080->8080/tcp
   redis             redis:alpine                         "docker-entrypoint.s…"   redis             39 seconds ago   Up 38 seconds   0.0.0.0:6379->6379/tcp, [::]:6379->6379/tcp
   shard1_1          dh-mirror.gitverse.ru/mongo:latest   "docker-entrypoint.s…"   shard1_1          39 seconds ago   Up 38 seconds   27017/tcp
   shard1_2          dh-mirror.gitverse.ru/mongo:latest   "docker-entrypoint.s…"   shard1_2          39 seconds ago   Up 38 seconds   27017/tcp
   shard1_3          dh-mirror.gitverse.ru/mongo:latest   "docker-entrypoint.s…"   shard1_3          39 seconds ago   Up 38 seconds   27017/tcp
   shard2_1          dh-mirror.gitverse.ru/mongo:latest   "docker-entrypoint.s…"   shard2_1          39 seconds ago   Up 38 seconds   27017/tcp
   shard2_2          dh-mirror.gitverse.ru/mongo:latest   "docker-entrypoint.s…"   shard2_2          39 seconds ago   Up 38 seconds   27017/tcp
   shard2_3          dh-mirror.gitverse.ru/mongo:latest   "docker-entrypoint.s…"   shard2_3          39 seconds ago   Up 38 seconds   27017/tcp
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

#### Redis  
Сравним результаты повторного выполнения запроса `GET /helloDoc/users`:  

Без Redis (проект mongo-sharding-repl):  
```shell
docker logs pymongo_api
{"asctime": "2025-10-07 16:42:18,358", "process": 1, "levelname": "INFO", "X-API-REQUEST-ID": "861e1f6e-b377-4b57-b6cf-56ae7c95f4e7", "request": {"method": "GET", "path": "/helloDoc/users", "ip": "172.18.0.1"}, "response": {"status": "successful", "status_code": 200, "time_taken": "1.0224s"}}
{"asctime": "2025-10-07 16:42:21,588", "process": 1, "levelname": "INFO", "X-API-REQUEST-ID": "4c767843-8b28-42cc-b4c3-0add9b7544fd", "request": {"method": "GET", "path": "/helloDoc/users", "ip": "172.18.0.1"}, "response": {"status": "successful", "status_code": 200, "time_taken": "1.0236s"}}
{"asctime": "2025-10-07 16:42:24,861", "process": 1, "levelname": "INFO", "X-API-REQUEST-ID": "91c56561-cd1e-4a89-8af8-36e04f1bc2d4", "request": {"method": "GET", "path": "/helloDoc/users", "ip": "172.18.0.1"}, "response": {"status": "successful", "status_code": 200, "time_taken": "1.0245s"}}
{"asctime": "2025-10-07 16:42:27,396", "process": 1, "levelname": "INFO", "X-API-REQUEST-ID": "7a537d2f-64e8-4715-b756-6995eaf98798", "request": {"method": "GET", "path": "/helloDoc/users", "ip": "172.18.0.1"}, "response": {"status": "successful", "status_code": 200, "time_taken": "1.0096s"}}
{"asctime": "2025-10-07 16:42:29,913", "process": 1, "levelname": "INFO", "X-API-REQUEST-ID": "8cd67889-f736-49b5-a982-df9f97a7fbdd", "request": {"method": "GET", "path": "/helloDoc/users", "ip": "172.18.0.1"}, "response": {"status": "successful", "status_code": 200, "time_taken": "1.0192s"}}
```

С Redis (текущий проект):  
```shell
docker logs pymongo_api
{"asctime": "2025-10-07 16:33:34,288", "process": 1, "levelname": "INFO", "X-API-REQUEST-ID": "bc922d31-3f0a-419e-967c-e9badc1e7ada", "request": {"method": "GET", "path": "/helloDoc/users", "ip": "172.18.0.1"}, "response": {"status": "successful", "status_code": 200, "time_taken": "1.0398s"}}
{"asctime": "2025-10-07 16:33:35,572", "process": 1, "levelname": "INFO", "X-API-REQUEST-ID": "86481659-bdae-4ca6-92d4-01b234ea3ae9", "request": {"method": "GET", "path": "/helloDoc/users", "ip": "172.18.0.1"}, "response": {"status": "successful", "status_code": 200, "time_taken": "0.0075s"}}
{"asctime": "2025-10-07 16:33:36,959", "process": 1, "levelname": "INFO", "X-API-REQUEST-ID": "33e6b2d6-3044-42ec-8bdb-fae3cf2b83bf", "request": {"method": "GET", "path": "/helloDoc/users", "ip": "172.18.0.1"}, "response": {"status": "successful", "status_code": 200, "time_taken": "0.0013s"}}
{"asctime": "2025-10-07 16:33:37,476", "process": 1, "levelname": "INFO", "X-API-REQUEST-ID": "4c8adbc4-f6e8-4707-a6fb-c16d4083dd53", "request": {"method": "GET", "path": "/helloDoc/users", "ip": "172.18.0.1"}, "response": {"status": "successful", "status_code": 200, "time_taken": "0.0011s"}}
{"asctime": "2025-10-07 16:33:37,829", "process": 1, "levelname": "INFO", "X-API-REQUEST-ID": "6918c35a-00ed-4825-82c6-a5ce386ae93d", "request": {"method": "GET", "path": "/helloDoc/users", "ip": "172.18.0.1"}, "response": {"status": "successful", "status_code": 200, "time_taken": "0.0016s"}}
```