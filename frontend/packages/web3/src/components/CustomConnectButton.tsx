'use client';

import { ConnectButton } from '@rainbow-me/rainbowkit';
import { useTranslation } from '@pitchone/i18n';

export function CustomConnectButton() {
  const { t } = useTranslation();

  return (
    <ConnectButton.Custom>
      {({
        account,
        chain,
        openAccountModal,
        openChainModal,
        openConnectModal,
        mounted,
      }) => {
        const ready = mounted;
        const connected = ready && account && chain;

        return (
          <div
            {...(!ready && {
              'aria-hidden': true,
              style: {
                opacity: 0,
                pointerEvents: 'none',
                userSelect: 'none',
              },
            })}
          >
            {(() => {
              if (!connected) {
                return (
                  <button
                    onClick={openConnectModal}
                    className="inline-flex items-center justify-center px-3 py-1.5 text-sm font-semibold rounded-lg bg-white text-zinc-900 hover:bg-zinc-200 transition-all duration-300"
                  >
                    {t('common.connectWallet')}
                  </button>
                );
              }

              if (chain.unsupported) {
                return (
                  <button
                    onClick={openChainModal}
                    className="inline-flex items-center justify-center px-3 py-1.5 text-sm font-semibold rounded-lg bg-zinc-700 text-zinc-300 border border-dashed border-zinc-500 hover:bg-zinc-600 transition-all duration-300"
                  >
                    {t('common.wrongNetwork')}
                  </button>
                );
              }

              return (
                <div className="flex items-center gap-2">
                  <button
                    onClick={openChainModal}
                    className="inline-flex items-center justify-center w-8 h-8 rounded-lg bg-dark-card border border-dark-border hover:border-zinc-600 hover:bg-dark-hover transition-all duration-300"
                    title={chain.name}
                  >
                    {chain.hasIcon && chain.iconUrl ? (
                      <img
                        alt={chain.name ?? 'Chain icon'}
                        src={chain.iconUrl}
                        className="w-5 h-5 rounded-full"
                      />
                    ) : (
                      <div className="w-5 h-5 rounded-full bg-zinc-600" />
                    )}
                  </button>

                  <button
                    onClick={openAccountModal}
                    className="inline-flex items-center justify-center gap-2 px-3 py-1.5 text-sm font-semibold rounded-lg bg-dark-card text-gray-200 border border-dark-border hover:border-zinc-600 hover:bg-dark-hover transition-all duration-300"
                  >
                    <span>{account.displayName}</span>
                    {account.displayBalance && (
                      <span className="text-zinc-400">
                        {account.displayBalance}
                      </span>
                    )}
                  </button>
                </div>
              );
            })()}
          </div>
        );
      }}
    </ConnectButton.Custom>
  );
}
