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
    }
  ]
};
