export default function AdminDashboard() {
  return (
    <main className="flex min-h-screen flex-col items-center justify-center p-24">
      <div className="z-10 w-full max-w-5xl items-center justify-between font-mono text-sm">
        <h1 className="text-4xl font-bold text-center mb-8">
          PitchOne Admin 🔒
        </h1>
        <p className="text-center text-lg text-gray-600 dark:text-gray-400">
          运营风控管理后台
        </p>
        <div className="mt-8 grid grid-cols-2 gap-4 text-center">
          <div className="p-6 border rounded-lg">
            <h3 className="font-semibold">市场管理</h3>
            <p className="text-sm text-gray-500">创建、配置、监控市场</p>
          </div>
          <div className="p-6 border rounded-lg">
            <h3 className="font-semibold">风险控制</h3>
            <p className="text-sm text-gray-500">敞口监控、限额管理</p>
          </div>
          <div className="p-6 border rounded-lg">
            <h3 className="font-semibold">数据分析</h3>
            <p className="text-sm text-gray-500">交易量、收入、用户行为</p>
          </div>
          <div className="p-6 border rounded-lg">
            <h3 className="font-semibold">用户管理</h3>
            <p className="text-sm text-gray-500">用户列表、KYC、黑名单</p>
          </div>
        </div>
        <div className="mt-8 text-center">
          <p className="text-sm text-green-600">管理端应用初始化成功 ✓</p>
        </div>
      </div>
    </main>
  );
}
