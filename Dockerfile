# ==========================================================
# Project 06 - Production Dockerfile
# ==========================================================
#
# 這份 Dockerfile 用來建立 Production Image。
#
# 和 Dockerfile.dev 最大的不同：
#
# Development：
#
#   Host source
#       ↓ bind mount
#   Container
#       ↓
#   tsx watch
#
#
# Production：
#
#   Source Code
#       ↓
#   docker build
#       ↓
#   TypeScript compile
#       ↓
#   dist/*.js
#       ↓
#   Production Image
#       ↓
#   node dist/app.js
#
#
# Production 不需要：
#
# - bind mount
# - tsx
# - TypeScript compiler
# - @types/*
# - watch
# - src/
#
# 因此使用 multi-stage build，
# 將「編譯環境」與「正式執行環境」分開。
#
# ==========================================================



# ==========================================================
# Stage 1：Build
# ==========================================================
#
# Build Stage 專門負責：
#
# 1. 安裝完整 dependencies
# 2. 取得 TypeScript source
# 3. 執行 TypeScript compiler
# 4. 產生 dist/
#
# 這個 Stage 最後不會成為正式執行的 Container。
#
# ==========================================================

FROM node:24-bookworm-slim AS build


# ----------------------------------------------------------
# Build Working Directory
# ----------------------------------------------------------
#
# Builder 裡面的 Application 工作目錄。
#
WORKDIR /app


# ----------------------------------------------------------
# Copy Dependency Definitions
# ----------------------------------------------------------
#
# 先只 COPY：
#
# package.json
# package-lock.json
#
# 讓 npm ci 可以利用 Docker layer cache。
#
COPY package.json package-lock.json ./


# ----------------------------------------------------------
# Install All Dependencies
# ----------------------------------------------------------
#
# Build TypeScript 時需要：
#
# typescript
# @types/node
# @types/express
#
# 這些都屬於 devDependencies。
#
# 所以 Build Stage 必須安裝完整 dependencies：
#
# dependencies
# +
# devDependencies
#
RUN npm ci


# ----------------------------------------------------------
# Copy TypeScript Configuration
# ----------------------------------------------------------
#
# tsc 編譯時需要 tsconfig.json。
#
COPY tsconfig.json ./


# ----------------------------------------------------------
# Copy Application Source
# ----------------------------------------------------------
#
# Production build 不使用 bind mount。
#
# Source Code 直接 COPY 進 Build Stage，
# 因此這次 docker build 使用的是一份固定 snapshot。
#
COPY src ./src


# ----------------------------------------------------------
# Compile TypeScript
# ----------------------------------------------------------
#
# package.json：
#
# "build": "tsc"
#
# 執行後：
#
# /app/src/app.ts
#
#       ↓
#
# TypeScript Compiler
#
#       ↓
#
# /app/dist/app.js
#
RUN npm run build



# ==========================================================
# Stage 2：Production Runtime
# ==========================================================
#
# 第二個 FROM 代表開始一個新的 Stage。
#
# 這個 Stage 不會自動包含 Build Stage 的：
#
# - node_modules
# - TypeScript
# - tsx
# - src/
# - Build cache
#
# 除非我們明確 COPY 過來。
#
# 這就是 multi-stage build 的重點。
#
# ==========================================================

FROM node:24-bookworm-slim AS production


# ----------------------------------------------------------
# Runtime Working Directory
# ----------------------------------------------------------
#
WORKDIR /app


# ----------------------------------------------------------
# Production Environment
# ----------------------------------------------------------
#
# Application 可以透過：
#
# process.env.NODE_ENV
#
# 取得 production。
#
ENV NODE_ENV=production


# ----------------------------------------------------------
# Copy Dependency Definitions
# ----------------------------------------------------------
#
# Runtime 仍然需要 package.json / package-lock.json，
# 因為接下來要安裝 Production dependencies。
#
COPY package.json package-lock.json ./


# ----------------------------------------------------------
# Install Production Dependencies Only
# ----------------------------------------------------------
#
# --omit=dev：
#
# 不把 devDependencies 實際安裝進 node_modules。
#
# 所以：
#
# express          ✅
#
# typescript       ❌
# tsx              ❌
# @types/node      ❌
# @types/express   ❌
#
# 正式環境只留下執行 Application 真正需要的套件。
#
RUN npm ci --omit=dev


# ----------------------------------------------------------
# Copy Build Output
# ----------------------------------------------------------
#
# 這是 multi-stage build 最重要的一行之一。
#
# 從前面的：
#
# build Stage
#
# 取得：
#
# /app/dist
#
# COPY 到 Production Stage：
#
# /app/dist
#
# Source Code src/*.ts 不會被帶進 Production Image。
#
COPY --from=build /app/dist ./dist


# ----------------------------------------------------------
# Application Port
# ----------------------------------------------------------
#
# Express Application 使用 3000 port。
#
# EXPOSE 只是 Image metadata。
#
# 真正 Host → Container port mapping
# 仍然需要 docker run -p 或 Compose ports。
#
EXPOSE 3000


# ----------------------------------------------------------
# Production Startup Command
# ----------------------------------------------------------
#
# Development：
#
# npm run dev
#   ↓
# tsx watch src/app.ts
#
#
# Production：
#
# node dist/app.js
#
# 不需要 TypeScript compiler，
# 也不需要 watch。
#
CMD ["node", "dist/app.js"]