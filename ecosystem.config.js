module.exports = {
  apps: [
    {
      name: 'anvil',
      script: 'anvil',
      args: '--host 0.0.0.0',
      cwd: '/home/harry/code/PitchOne/contracts',
      interpreter: 'none',
      autorestart: true,
      watch: false,
      max_memory_restart: '1G',
      env: {
        RUST_LOG: 'info'
      },
      error_file: '/tmp/anvil-error.log',
      out_file: '/tmp/anvil-out.log',
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
      merge_logs: true
    },
    {
      name: 'pitchone-user',
      script: 'pnpm',
      args: 'dev:user',
      cwd: '/home/harry/code/PitchOne/frontend',
      interpreter: 'none',
      autorestart: true,
      watch: false,
      max_memory_restart: '2G',
      env: {
        NODE_ENV: 'development'
      },
      error_file: '/tmp/pitchone-user-error.log',
      out_file: '/tmp/pitchone-user-out.log',
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
      merge_logs: true
    },
    {
      name: 'pitchone-admin',
      script: 'pnpm',
      args: 'dev:admin',
      cwd: '/home/harry/code/PitchOne/frontend',
      interpreter: 'none',
      autorestart: true,
      watch: false,
      max_memory_restart: '2G',
      env: {
        NODE_ENV: 'development'
      },
      error_file: '/tmp/pitchone-admin-error.log',
      out_file: '/tmp/pitchone-admin-out.log',
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
      merge_logs: true
    }
  ]
};
