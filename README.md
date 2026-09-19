# Project 06：Compose Dev / Prod 分離

這是一個 Docker Compose 學習專案。

## 學習目標

1. 使用 Docker 建立一致的 Node.js TypeScript 開發環境。
2. 使用 bind mount 讓 Host 原始碼即時同步到 Development Container。
3. 使用 `tsx watch` 建立開發時的自動重新載入環境。
4. 使用 multi-stage Dockerfile 建立 Production Image。
5. 理解 Development、Test、Build 與 Production 環境的差異。
6. 使用 Git 保存每個學習階段的版本歷程。

## 預計架構

Development：

```text
Host Source Code
      │
      │ bind mount
      ▼
Development Container
      │
      └── npm run dev
            │
            └── tsx watch
```

Production：

```text
Source Code
     │
     ▼
Docker Build
     │
     ├── npm ci
     ├── npm run build
     │
     ▼
   dist/
     │
     ▼
Production Image
     │
     └── node dist/app.js
```

## Development / Production Workflow

### Development

Development uses:

- `Dockerfile.dev`
- `compose.dev.yaml`
- source bind mounts
- Docker-managed `node_modules`
- `tsx watch`

Flow:

```text
VS Code
  ↓
Linux workspace
  ↓ bind mount
Development Container
  ↓
tsx watch
  ↓
Node.js
````

Start:

```bash
docker compose -f compose.dev.yaml up --build
```

Stop:

```bash
docker compose -f compose.dev.yaml down
```

---

### Production

Production uses:

* multi-stage `Dockerfile`
* `compose.prod.yaml`
* compiled JavaScript
* production dependencies only
* no source bind mounts

Flow:

```text
Source Code
  ↓
Build Stage
  ↓
TypeScript Compiler
  ↓
dist/
  ↓
Production Stage
  ↓
Production Image
  ↓
node dist/app.js
```

Start:

```bash
docker compose -f compose.prod.yaml up --build -d
```

View logs:

```bash
docker compose -f compose.prod.yaml logs -f
```

Stop:

```bash
docker compose -f compose.prod.yaml down
```

---

## Environment Model

```text
Development
    ↓
Local Test
    ↓
CI
    ↓
Production Image
    ↓
Staging
    ↓
Production
```

Development prioritizes fast feedback and uses bind mounts.

CI builds and tests a fixed Git revision without relying on
developer workstation files.

Staging and Production should ideally use the same built image,
with environment-specific configuration supplied externally.