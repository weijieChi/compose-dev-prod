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