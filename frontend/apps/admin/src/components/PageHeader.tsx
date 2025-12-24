'use client';

import { ReactNode } from 'react';
import Link from 'next/link';
import { Button } from '@pitchone/ui';

export interface PageHeaderProps {
    title: string;
    description?: string;
    actions?: ReactNode;
    backLink?: {
        href: string;
        label: string;
    };
}

export function PageHeader({
    title,
    description,
    actions,
    backLink = { href: '/', label: '返回看板' },
}: PageHeaderProps) {
    return (
        <div className="bg-white dark:bg-gray-800 border-b dark:border-gray-700">
            <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
                <div className="flex items-center justify-between">
                    <div>
                        <h1 className="text-3xl font-bold text-gray-900 dark:text-white">
                            {title}
                        </h1>
                        {description && (
                            <p className="mt-2 text-sm text-gray-500 dark:text-gray-400">
                                {description}
                            </p>
                        )}
                    </div>
                    <div className="flex items-center gap-3">
                        {actions}
                        <Link href={backLink.href}>
                            <Button variant="neon">{backLink.label}</Button>
                        </Link>
                    </div>
                </div>
            </div>
        </div>
    );
}
