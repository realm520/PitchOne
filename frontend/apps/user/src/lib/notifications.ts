import toast from 'react-hot-toast';

/**
 * 通知工具库
 */

// Toast 通知配置 - 极简深色主题
const baseStyle = {
  background: '#18181b',
  color: '#ffffff',
  border: '1px solid #27272a',
  borderRadius: '8px',
  fontSize: '14px',
  padding: '12px 16px',
};

const toastConfig = {
  success: {
    duration: 3000,
    icon: '✓',
    style: {
      ...baseStyle,
      borderColor: '#3f3f46',
    },
    iconTheme: {
      primary: '#ffffff',
      secondary: '#18181b',
    },
  },
  error: {
    duration: 5000,
    icon: '✕',
    style: {
      ...baseStyle,
      borderColor: '#52525b',
    },
    iconTheme: {
      primary: '#a1a1aa',
      secondary: '#18181b',
    },
  },
  loading: {
    style: baseStyle,
    iconTheme: {
      primary: '#a1a1aa',
      secondary: '#18181b',
    },
  },
  info: {
    duration: 3000,
    icon: '○',
    style: baseStyle,
    iconTheme: {
      primary: '#a1a1aa',
      secondary: '#18181b',
    },
  },
};

/**
 * 成功通知
 */
export function notifySuccess(message: string) {
  toast.success(message, toastConfig.success);
}

/**
 * 错误通知
 */
export function notifyError(message: string) {
  toast.error(message, toastConfig.error);
}

/**
 * 加载通知
 */
export function notifyLoading(message: string) {
  return toast.loading(message, toastConfig.loading);
}

/**
 * 信息通知
 */
export function notifyInfo(message: string) {
  toast(message, toastConfig.info);
}

/**
 * 更新通知（用于更新 loading 状态）
 */
export function updateNotification(toastId: string, type: 'success' | 'error', message: string) {
  if (type === 'success') {
    toast.success(message, { id: toastId, ...toastConfig.success });
  } else {
    toast.error(message, { id: toastId, ...toastConfig.error });
  }
}

/**
 * 关闭通知
 */
export function dismissNotification(toastId?: string) {
  if (toastId) {
    toast.dismiss(toastId);
  } else {
    toast.dismiss();
  }
}

/**
 * 请求浏览器通知权限
 */
export async function requestBrowserNotificationPermission(): Promise<boolean> {
  if (!('Notification' in window)) {
    console.warn('此浏览器不支持桌面通知');
    return false;
  }

  if (Notification.permission === 'granted') {
    return true;
  }

  if (Notification.permission !== 'denied') {
    const permission = await Notification.requestPermission();
    return permission === 'granted';
  }

  return false;
}

/**
 * 发送浏览器通知
 */
export function sendBrowserNotification(title: string, options?: NotificationOptions) {
  if (Notification.permission === 'granted') {
    new Notification(title, {
      icon: '/logo.png',
      badge: '/badge.png',
      ...options,
    });
  }
}

/**
 * 交易通知助手
 */
export const transactionNotifications = {
  /**
   * 交易开始
   */
  start: (action: string) => {
    return notifyLoading(`${action}中...`);
  },

  /**
   * 交易成功
   */
  success: (toastId: string, action: string, details?: string) => {
    updateNotification(toastId, 'success', `${action}成功！${details || ''}`);
    sendBrowserNotification(`${action}成功`, {
      body: details || `您的${action}已成功完成`,
    });
  },

  /**
   * 交易失败
   */
  error: (toastId: string, action: string, error?: string) => {
    updateNotification(toastId, 'error', `${action}失败：${error || '未知错误'}`);
  },
};

/**
 * 下注通知助手
 */
export const betNotifications = {
  /**
   * 下注开始
   */
  placingBet: () => transactionNotifications.start('下注'),

  /**
   * 下注成功
   */
  betPlaced: (toastId: string, amount: string, outcome: string) => {
    transactionNotifications.success(toastId, '下注', `${amount} USDC → ${outcome}`);
  },

  /**
   * 下注失败
   */
  betFailed: (toastId: string, error?: string) => {
    transactionNotifications.error(toastId, '下注', error);
  },

  /**
   * 授权开始
   */
  approvingUSDC: () => transactionNotifications.start('授权 USDC'),

  /**
   * 授权成功
   */
  approvedUSDC: (toastId: string) => {
    transactionNotifications.success(toastId, '授权 USDC', '现在可以开始下注了');
  },

  /**
   * 授权失败
   */
  approveFailed: (toastId: string, error?: string) => {
    transactionNotifications.error(toastId, '授权 USDC', error);
  },
};

/**
 * 赎回通知助手
 */
export const redeemNotifications = {
  /**
   * 赎回开始
   */
  redeeming: () => transactionNotifications.start('赎回'),

  /**
   * 赎回成功
   */
  redeemed: (toastId: string, payout: string) => {
    transactionNotifications.success(toastId, '赎回', `获得 ${payout} USDC`);
  },

  /**
   * 赎回失败
   */
  redeemFailed: (toastId: string, error?: string) => {
    transactionNotifications.error(toastId, '赎回', error);
  },
};

/**
 * 市场通知助手
 */
export const marketNotifications = {
  /**
   * 市场锁盘
   */
  locked: (marketName: string) => {
    notifyInfo(`${marketName} 已锁盘，无法继续下注`);
    sendBrowserNotification('市场已锁盘', {
      body: `${marketName} 已锁盘`,
    });
  },

  /**
   * 市场结算
   */
  resolved: (marketName: string, winnerOutcome: string) => {
    notifySuccess(`${marketName} 已结算：${winnerOutcome} 获胜`);
    sendBrowserNotification('市场已结算', {
      body: `${marketName} - ${winnerOutcome} 获胜`,
    });
  },

  /**
   * 新的下注
   */
  newBet: (amount: string, outcome: string) => {
    notifyInfo(`新下注：${amount} USDC → ${outcome}`);
  },
};
