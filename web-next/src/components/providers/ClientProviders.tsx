"use client";

import { AuthProvider, useAuth } from "@/context/AuthContext";
import { useRouter, usePathname } from "next/navigation";
import { useEffect } from "react";

export function ClientProviders({ children }: { readonly children: React.ReactNode }) {
    return (
        <AuthProvider>
            <AuthGuard>
                {children}
            </AuthGuard>
        </AuthProvider>
    );
}

function AuthGuard({ children }: { readonly children: React.ReactNode }) {
    const { user, isLoading } = useAuth();
    const router = useRouter();
    const pathname = usePathname();

    useEffect(() => {
        if (!isLoading) {
            if (!user && pathname.startsWith('/dashboard')) {
                router.push('/auth');
            } else if (user && pathname === '/auth') {
                router.push('/dashboard');
            }
        }
    }, [user, isLoading, pathname, router]);

    if (isLoading) {
        return (
            <div className="min-h-screen flex items-center justify-center bg-black">
                <div className="w-8 h-8 border-2 border-white/20 border-t-white rounded-full animate-spin" />
            </div>
        );
    }

    return <>{children}</>;
}
