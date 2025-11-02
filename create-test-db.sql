-- 创建测试用户和数据库
-- 用于后端集成测试

-- 创建用户 p1（如果不存在）
DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_user WHERE usename = 'p1') THEN
    CREATE USER p1 WITH PASSWORD 'p1';
  END IF;
END
$$;

-- 创建数据库 p1（如果不存在）
SELECT 'CREATE DATABASE p1 OWNER p1 ENCODING ''UTF8'''
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'p1')\gexec

-- 授予权限
GRANT ALL PRIVILEGES ON DATABASE p1 TO p1;

-- 切换到 p1 数据库并创建扩展
\c p1

-- 确保 p1 用户拥有 public schema 的权限
GRANT ALL ON SCHEMA public TO p1;
GRANT ALL ON ALL TABLES IN SCHEMA public TO p1;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO p1;

-- 完成
\echo '✅ 测试数据库 p1 创建成功'
