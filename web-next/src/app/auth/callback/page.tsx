"use client";

import { useEffect } from 'react';
import { supabase } from '@/lib/supabase';
import { useRouter } from 'next/navigation';

export default function AuthCallback() {
    const router = useRouter();

    useEffect(() => {
        const handleCallback = async () => {
            const { error } = await supabase.auth.exchangeCodeForSession(globalThis.location.search);
            if (error) {
                console.error('Error exchanging code for session:', error.message);
                router.push('/auth?error=OAuth callback failed');
            } else {
                router.push('/dashboard');
            }
        };

        handleCallback();
    }, [router]);

    return (
        <div className="min-h-screen flex items-center justify-center bg-black text-white">
            <div className="flex flex-col items-center gap-4">
                <div className="w-12 h-12 border-4 border-aura-1 border-t-transparent rounded-full animate-spin" />
                <p className="text-sm font-medium tracking-widest uppercase opacity-50">Authenticating...</p>
            </div>
        </div>
    );
}
