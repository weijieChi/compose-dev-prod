import express from "express";

// ==========================================================
// Express Application
// ==========================================================

// 建立 Express Application instance。
const app = express();

// ==========================================================
// Middleware
// ==========================================================

// 讓 Express 可以解析 JSON request body。
//
// 例如未來：
//
// POST /tasks
//
// {
//   "title": "Learn Docker"
// }
//
// Express 就可以透過 req.body 取得資料。
app.use(express.json());

// ==========================================================
// Application Configuration
// ==========================================================

// 從環境變數 PORT 取得 HTTP Server port。
//
// 如果沒有設定 PORT，就預設使用 3000。
//
// Number() 是因為 process.env 的值一定是 string | undefined。
const PORT = Number(process.env.PORT ?? 3000);

// ==========================================================
// Routes
// ==========================================================

// 最基本的 API endpoint。
//
// 用途：
// 1. 確認 Application 正常啟動。
// 2. 後面觀察 Development / Production 環境差異。
app.get("/", (_req, res) => {
  res.json({
    message: "Project 06 - Compose Dev / Prod Lab",

    // NODE_ENV 後面會由 Docker Compose 傳入。
    //
    // Development：
    // NODE_ENV=development
    //
    // Production：
    // NODE_ENV=production
    environment: process.env.NODE_ENV ?? "not-set",
  });
});

// Health Check endpoint。
//
// 後面學 Compose healthcheck 時，Container 可以透過
// HTTP request 確認 Application 是否真的正常提供服務。
app.get("/health", (_req, res) => {
  res.status(200).json({
    status: "ok",
  });
});

// ==========================================================
// HTTP Server
// ==========================================================

// 使用 0.0.0.0，而不是只綁 localhost。
//
// localhost：
//
// Node.js 只接受 Container 自己內部的 loopback connection。
//
// 0.0.0.0：
//
// Node.js 接受所有 Container network interface 的連線。
//
// 後面 Docker port mapping：
//
// Host :3000
//    ↓
// Container :3000
//    ↓
// Node.js 0.0.0.0:3000
//
// 才能正常存取。
app.listen(PORT, "0.0.0.0", () => {
  console.log(`Server is running on http://localhost:${PORT}`);
});
