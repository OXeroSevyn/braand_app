"use client";

import React, { createContext, useContext, useEffect, useState, useMemo } from 'react';
import { supabase } from '@/lib/supabase';
import { UserProfile } from '@/types/user';
import { User } from '@supabase/supabase-js';

interface AuthContextType {
    user: UserProfile | null;
    supabaseUser: User | null;
    isLoading: boolean;
    signOut: () => Promise<void>;
}

const AuthContext = createContext<AuthContextType>({
    user: null,
    supabaseUser: null,
    isLoading: true,
    signOut: async () => { },
});

export const AuthProvider = ({ children }: { children: React.ReactNode }) => {
    const [user, setUser] = useState<UserProfile | null>(null);
    const [supabaseUser, setSupabaseUser] = useState<User | null>(null);
    const [isLoading, setIsLoading] = useState(true);

    useEffect(() => {
        // Check active sessions and sets the user
        const initSession = async () => {
            const { data: { session } } = await supabase.auth.getSession();
            setSupabaseUser(session?.user ?? null);
            if (session?.user) {
                await fetchProfile(session.user.id);
            }
            setIsLoading(false);
        };

        initSession();

        // Listen for changes on auth state
        const { data: { subscription } } = supabase.auth.onAuthStateChange(async (event, session) => {
            setSupabaseUser(session?.user ?? null);
            if (session?.user) {
                await fetchProfile(session.user.id);
            } else {
                setUser(null);
            }
            setIsLoading(false);
        });

        return () => {
            subscription.unsubscribe();
        };
    }, []);

    const fetchProfile = async (id: string) => {
        const { data, error } = await supabase
            .from('profiles') // Assuming the table name is 'profiles' based on Flutter code
            .select('*')
            .eq('id', id)
            .single();

        if (data && !error) {
            setUser(data as UserProfile);
        }
    };

    const signOut = async () => {
        await supabase.auth.signOut();
    };

    const value = useMemo(() => ({
        user,
        supabaseUser,
        isLoading,
        signOut
    }), [user, supabaseUser, isLoading]);

    return (
        <AuthContext.Provider value={value}>
            {children}
        </AuthContext.Provider>
    );
};

export const useAuth = () => useContext(AuthContext);
